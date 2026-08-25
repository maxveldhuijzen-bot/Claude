# Letting Claude drive Roblox Studio

You asked how to set things up so I can reach your Roblox Studio and build
games in it. Here is the honest answer, plus the three setups that actually
work today.

## The one thing that is not possible

**This session cannot reach your Studio.** I am running in a cloud container,
and the Studio integration below speaks over *stdio* to a process on your own
machine. There is no hosted endpoint I can dial into from here. Any tool that
claims otherwise is talking about a local setup.

So the split is:

| I do this from the cloud | You do this on your machine |
| --- | --- |
| Write and review the whole codebase | Run Claude Code locally and connect it to Studio |
| Build the `.rbxlx` place file | Open it, or let Rojo sync it |
| Push to GitHub | Pull, playtest, publish |

## Option 1 — Studio's built-in MCP server (the real "Claude controls Studio")

Roblox ships an MCP server inside Studio itself. Once connected, an AI client
can read your data model, write scripts, run Luau, and start a playtest —
directly in your open place.

1. In Studio, open **Assistant**.
2. Click **…** → **Manage MCP Servers**.
3. Turn on **Enable Studio as MCP server**.
4. Expand **Quick connect** and toggle **Claude Code** on.

If you would rather wire it up by hand, it is a stdio server:

- **Windows:** `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
- **macOS:** `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`

Restart your client afterwards. Studio's MCP panel shows a green indicator when
a client is attached.

Then run `claude` in this repo **on your own machine** and it can edit the files
*and* manipulate the live place at the same time. That is the setup you want
for iterating on a game.

> Roblox's older standalone `Roblox/studio-rust-mcp-server` is archived. The
> built-in server is the supported path now.

## Option 2 — Rojo (best for real development)

Rojo syncs this repo's `src/` folder into Studio live. I edit files, you see
them appear in the Explorer a second later. No copy-paste, and Git stays the
source of truth.

```bash
aftman install          # or: cargo install rojo
rojo serve              # reads default.project.json
```

Then install the **Rojo** plugin in Studio, open it, and click **Connect**.

This is the workflow most professional Roblox teams use, and it is why this
project is laid out as `src/shared`, `src/server`, `src/client` rather than as
a binary place file.

## Option 3 — Open Cloud (publish without opening Studio at all)

Roblox's Open Cloud API accepts a place file over HTTP, so a build can go
straight to a live experience from CI or a script.

```bash
export ROBLOX_API_KEY="..."
python3 tools/build_place.py
python3 tools/publish.py --universe <universeId> --place <placeId> --version-type published
```

Create the key at **Creator Hub → Open Cloud → API Keys**, add the
**universe-places** system, grant **write** on your experience, and allow your
IP. `tools/publish.py` explains the common 401/403 causes if it fails.

This is the closest thing to "Claude publishes to Roblox for you" — with the
caveat that the key lives on your machine, where it belongs. Do not paste an
API key into a chat with me or anyone else.

## What I would do

Use **Rojo + local Claude Code** as the daily loop, turn on the **built-in MCP
server** when you want me poking at the live data model, and keep **Open
Cloud** for pushing releases. All three read from this same repo.
