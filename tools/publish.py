#!/usr/bin/env python3
"""
Publish the built place file to Roblox via Open Cloud.

    export ROBLOX_API_KEY="..."          # never commit this
    python3 tools/publish.py --universe 1234567890 --place 9876543210

Setup on the Creator Hub (create.roblox.com → Open Cloud → API Keys):
  1. Create an API key.
  2. Add the "universe-places" API system.
  3. Add your experience, and give it the "write" operation.
  4. Add your IP (or 0.0.0.0/0 while testing) to the allowed IP list.

Universe ID and place ID both come from the experience's page on the Creator
Hub — the place ID is in the place's URL, the universe ID is on the experience
overview.

--version-type saved  uploads without going live (default)
--version-type published  makes it the live version players join
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

ENDPOINT = "https://apis.roblox.com/universes/v1/{universe}/places/{place}/versions?versionType={kind}"

CONTENT_TYPES = {
    ".rbxlx": "application/xml",
    ".rbxl": "application/octet-stream",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--universe", required=True, help="Universe (experience) ID")
    parser.add_argument("--place", required=True, help="Place ID")
    parser.add_argument("--file", default="build/AuraFarmSimulator.rbxlx")
    parser.add_argument("--version-type", default="saved", choices=["saved", "published"])
    args = parser.parse_args()

    key = os.environ.get("ROBLOX_API_KEY")
    if not key:
        sys.exit("ROBLOX_API_KEY is not set. Export it rather than passing it on the command line.")

    if not os.path.isfile(args.file):
        sys.exit(f"{args.file} does not exist — run tools/build_place.py first.")

    extension = os.path.splitext(args.file)[1].lower()
    content_type = CONTENT_TYPES.get(extension)
    if not content_type:
        sys.exit(f"Don't know how to upload {extension} files.")

    with open(args.file, "rb") as handle:
        payload = handle.read()

    url = ENDPOINT.format(
        universe=args.universe,
        place=args.place,
        kind=args.version_type.capitalize(),
    )

    request = urllib.request.Request(
        url,
        data=payload,
        method="POST",
        headers={"x-api-key": key, "Content-Type": content_type},
    )

    print(f"uploading {args.file} ({len(payload) / 1024:.1f} KiB) as versionType={args.version_type.capitalize()}")

    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            body = json.loads(response.read().decode())
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")
        print(f"failed: HTTP {error.code}\n{detail}", file=sys.stderr)
        if error.code == 401:
            print("\n401 usually means the key is wrong, or your IP is not in the key's allow list.", file=sys.stderr)
        if error.code == 403:
            print("\n403 usually means the key lacks universe-places:write for this experience.", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as error:
        sys.exit(f"failed to reach Roblox: {error.reason}")

    version = body.get("versionNumber")
    print(f"done — place version {version}")
    if args.version_type == "saved":
        print("Uploaded as a saved version. Publish it from Studio, or re-run with --version-type published.")


if __name__ == "__main__":
    main()
