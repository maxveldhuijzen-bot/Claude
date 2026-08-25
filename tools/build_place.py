#!/usr/bin/env python3
"""
Build a Roblox .rbxlx place file from the Rojo project tree.

Rojo is the nicer day-to-day workflow, but it needs the plugin and a running
server. This produces a plain place file you can double-click into Studio with
no tooling at all, from exactly the same sources.

    python3 tools/build_place.py [--project default.project.json] [--out build/AuraFarmSimulator.rbxlx]

Supported subset of the Rojo project format: $className, $path, $properties
(string / bool / number), and the standard file-name conventions:

    init.lua          -> ModuleScript named after the folder
    init.server.lua   -> Script
    init.client.lua   -> LocalScript
    name.server.lua   -> Script
    name.client.lua   -> LocalScript
    name.lua          -> ModuleScript
    a directory       -> Folder (when it has no init file)
"""

import argparse
import json
import os
import sys
from xml.sax.saxutils import escape

HEADER = (
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" '
    'version="4">'
)

INIT_KINDS = {
    "init.server.lua": "Script",
    "init.client.lua": "LocalScript",
    "init.lua": "ModuleScript",
}

SUFFIX_KINDS = [
    (".server.lua", "Script"),
    (".client.lua", "LocalScript"),
    (".lua", "ModuleScript"),
    (".luau", "ModuleScript"),
]


class Builder:
    def __init__(self, root):
        self.root = root
        self.referent = 0
        self.lines = []
        self.counts = {}

    def next_referent(self):
        value = f"RBX{self.referent}"
        self.referent += 1
        return value

    def emit(self, depth, text):
        self.lines.append("\t" * depth + text)

    # -- properties ---------------------------------------------------------

    def write_properties(self, depth, name, extra=None, source=None):
        self.emit(depth, "<Properties>")
        self.emit(depth + 1, f'<string name="Name">{escape(name)}</string>')

        if source is not None:
            self.emit(depth + 1, f'<ProtectedString name="Source">{cdata(source)}</ProtectedString>')

        for key, value in (extra or {}).items():
            if isinstance(value, bool):
                self.emit(depth + 1, f'<bool name="{key}">{"true" if value else "false"}</bool>')
            elif isinstance(value, (int, float)):
                self.emit(depth + 1, f'<float name="{key}">{value}</float>')
            elif isinstance(value, str):
                self.emit(depth + 1, f'<string name="{key}">{escape(value)}</string>')
            else:
                print(f"  ! skipping unsupported property {key}={value!r}", file=sys.stderr)

        self.emit(depth, "</Properties>")

    # -- filesystem ---------------------------------------------------------

    def classify(self, filename):
        for suffix, class_name in SUFFIX_KINDS:
            if filename.endswith(suffix):
                return filename[: -len(suffix)], class_name
        return None, None

    def write_path(self, depth, name, path):
        """Emit the instance a filesystem path maps to, plus its descendants."""
        if os.path.isfile(path):
            _, class_name = self.classify(os.path.basename(path))
            if not class_name:
                return
            self.write_script(depth, name, class_name, read(path))
            return

        # A directory: an init file decides the class, otherwise it is a Folder.
        class_name = "Folder"
        source = None
        skip = set()

        for init_name, init_class in INIT_KINDS.items():
            init_path = os.path.join(path, init_name)
            if os.path.isfile(init_path):
                class_name = init_class
                source = read(init_path)
                skip.add(init_name)
                break

        referent = self.next_referent()
        self.counts[class_name] = self.counts.get(class_name, 0) + 1
        self.emit(depth, f'<Item class="{class_name}" referent="{referent}">')
        self.write_properties(depth + 1, name, None, source)

        for entry in sorted(os.listdir(path)):
            if entry in skip or entry.startswith("."):
                continue
            child = os.path.join(path, entry)
            if os.path.isdir(child):
                self.write_path(depth + 1, entry, child)
            else:
                child_name, child_class = self.classify(entry)
                if child_class:
                    self.write_script(depth + 1, child_name, child_class, read(child))

        self.emit(depth, "</Item>")

    def write_script(self, depth, name, class_name, source):
        referent = self.next_referent()
        self.counts[class_name] = self.counts.get(class_name, 0) + 1
        self.emit(depth, f'<Item class="{class_name}" referent="{referent}">')
        self.write_properties(depth + 1, name, None, source)
        self.emit(depth, "</Item>")

    # -- project tree -------------------------------------------------------

    def write_node(self, depth, name, node):
        class_name = node.get("$className")
        path = node.get("$path")

        if path and not class_name:
            self.write_path(depth, name, os.path.join(self.root, path))
            return

        if not class_name:
            class_name = "Folder"

        referent = self.next_referent()
        self.counts[class_name] = self.counts.get(class_name, 0) + 1
        self.emit(depth, f'<Item class="{class_name}" referent="{referent}">')
        self.write_properties(depth + 1, name, node.get("$properties"))

        for key, child in node.items():
            if key.startswith("$"):
                continue
            self.write_node(depth + 1, key, child)

        self.emit(depth, "</Item>")

    def build(self, project):
        tree = project["tree"]
        self.lines = [HEADER, '\t<Meta name="ExplicitAutoJoints">true</Meta>']

        for key, child in tree.items():
            if key.startswith("$"):
                continue
            self.write_node(1, key, child)

        self.lines.append("</roblox>")
        return "\n".join(self.lines) + "\n"


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def cdata(text):
    """Wrap source in CDATA, splitting on any literal ]]> that would end it."""
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default="default.project.json")
    parser.add_argument("--out", default=None)
    args = parser.parse_args()

    root = os.path.dirname(os.path.abspath(args.project)) or "."
    project = json.loads(read(args.project))

    out = args.out or os.path.join(root, "build", f"{project.get('name', 'place')}.rbxlx")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    builder = Builder(root)
    xml = builder.build(project)

    with open(out, "w", encoding="utf-8") as handle:
        handle.write(xml)

    size = os.path.getsize(out)
    print(f"built {out}  ({size / 1024:.1f} KiB, {builder.referent} instances)")
    for class_name, count in sorted(builder.counts.items(), key=lambda item: -item[1]):
        print(f"  {count:>4}  {class_name}")


if __name__ == "__main__":
    main()
