# Aura Farm Simulator

A complete, shippable Roblox simulator — world, economy, pets, rebirths,
quests, monetization and persistence — built from source and packaged as a
place file you can open in Studio right now.

**Open `build/AuraFarmSimulator.rbxlx` in Roblox Studio and press Play.** No
plugins, no toolchain, no uploaded assets.

---

## The loop

Swing your collector at aura nodes → carry the aura to a vault → sell it for
coins → buy a better collector, a bigger backpack, and the next zone → hatch
eggs for pets that multiply everything → rebirth to trade it all for prisms and
a permanent bonus → do it again, faster.

| System | What it does |
| --- | --- |
| **9 zones** | Progression spine. Later zones multiply aura *and* sell value. One is VIP-only. |
| **14 collectors / 14 backpacks** | The two coin sinks that gate the early loop. |
| **55 pets across 8 eggs** | Rarity ladder from Common to Secret, each pet procedurally modelled. |
| **Golden & Rainbow fusion** | 5 duplicates combine into a 2.5x tier, 5 of those into a 7x tier. |
| **Rebirth + prism shop** | 8 permanent upgrades, 7 cosmetic auras, unbounded rebirth count. |
| **Quests, dailies, playtime, codes** | Four reward tracks that scale to the player's current zone. |
| **Gamepasses & products** | Five passes, six products, all wired and safe to ship unconfigured. |
| **Leaderboards** | OrderedDataStore top-10 boards for rebirths and lifetime aura. |

Everything is generated at runtime — platforms, nodes, vaults, egg stands,
pets, tools, UI. There is not a single uploaded asset ID in the project, which
is why the whole game is a 260 KiB file that cannot break from a missing model.

---

## Getting it into Studio

Three routes, in increasing order of how much you plan to work on it.

**1. Just open it.** `File → Open from File…` → `build/AuraFarmSimulator.rbxlx`.

**2. Rojo, for live editing.** `rojo serve`, then Connect from the Rojo plugin.
Edit files here, watch them update in Studio.

**3. Open Cloud, to publish from a script.**
```bash
python3 tools/build_place.py
ROBLOX_API_KEY=... python3 tools/publish.py --universe <id> --place <id>
```

Full detail, including how to let Claude Code drive Studio directly, is in
[docs/CONNECTING_CLAUDE.md](docs/CONNECTING_CLAUDE.md).

---

## Layout

```
src/shared/          ReplicatedStorage.Shared — config + modules both sides use
  Config/            every tunable number in the game
  Modules/           Format, Signal, Net, Rng, TableUtil, Palette
src/server/          ServerScriptService.Server
  init.server.lua    bootstrap: requires services, init()s them, start()s them
  Services/          17 services, one concern each
src/client/          StarterPlayer.StarterPlayerScripts.Client
  init.client.lua    same bootstrap shape
  Controllers/       8 controllers + the menu panel definitions
  UI/                element helpers, widgets, window shell, pet model builder
tools/               place-file builder and Open Cloud publisher
docs/                setup and design notes
```

Services and controllers are plain modules with optional `init(registry)` and
`start()`. Each gets the same registry table, which is how they reach each
other without circular `require`s. `init()` wires connections and must not
yield; `start()` runs in its own thread and may loop forever.

---

## Design decisions worth knowing

**The server owns every number.** The client sends intent — "I swung at that
node", "hatch this egg" — and never an amount. `FarmService` re-checks the
node, your range, your zone access and your swing budget on every hit.

**One remote for menus.** Every menu action goes through a single
`RemoteFunction` router, so rate limiting, payload validation and error
handling exist in exactly one place. Handlers return `(ok, resultOrMessage)`;
anything that throws is caught and reported instead of hanging the UI.

**Capacity scales with your multipliers.** A fixed backpack cap looks fine on
paper and collapses the moment zone and pet multipliers compound — by mid-game
a "full" backpack is less than one swing. Scaling capacity by the same
multipliers as aura per swing makes time-to-fill depend only on
`capacity / power`, so a vault run stays ~30 seconds from tutorial to endgame.

**Luck raises the floor, not the ceiling.** `adjusted = weight * luck^(1 - weight/maxWeight)`
multiplies the rarest drop by your luck stat and leaves the commonest
untouched. The tempting alternative, `weight^(1/luck)`, flattens the whole
distribution — at luck 8 a Secret lands at 5% and the chase is over. Here it
moves from 1-in-55,000 to 1-in-13,000.

**Saves are session-locked.** Two servers can never hold the same profile, so
the classic join/rejoin duplication exploit does not work. A lock older than 15
minutes is treated as a crashed server and taken over. In Studio the store is
swapped for an in-memory mock, so playtests never touch live data.

**Purchases confirm after the save.** `ProcessReceipt` records the purchase id,
saves, and only then returns `PurchaseGranted` — a crash mid-purchase means
Roblox retries rather than the player paying for nothing.

**Pets are client-rendered.** Equipped pets are published as a Player
attribute, so every client can draw everyone's pets without the server
replicating inventories. The models are anchored and never enter the physics
solver.

---

## Making it yours

| To change | Edit |
| --- | --- |
| Any balance number | `src/shared/Config/Settings.lua` |
| Zones, costs, colours | `src/shared/Config/Zones.lua` |
| Pets and rarities | `src/shared/Config/Pets.lua` |
| Hatch pools and odds | `src/shared/Config/Eggs.lua` |
| Rebirth curve and prism shop | `src/shared/Config/Rebirth.lua` |
| Redeemable codes | `src/shared/Config/Codes.lua` |
| Gamepass / product IDs | `src/shared/Config/Monetization.lua` |

**Monetization ships switched off on purpose.** Every asset ID is `0`, the shop
labels those entries "NOT SET UP", and `MarketplaceService` is never called
with an invalid ID. Create the passes and products on the Creator Hub, paste
the numbers in, and the same code paths start working with no other change.

Adding a zone is a single entry in `Zones.lua` — the world builder reads the
list and generates the platform, nodes, vault, egg stand, kiosk, altar, bridge
and signage from it.

More on the economy, the reward tracks and the tuning philosophy in
[docs/DESIGN.md](docs/DESIGN.md).

---

## Before you publish

1. Paste real gamepass and product IDs into `Config/Monetization.lua`.
2. Set `Settings.StudioSaveEnabled = false` (the default) so playtests stay off
   live data, and enable **Studio Access to API Services** in Game Settings so
   DataStores work in the real game.
3. Change `Settings.DataStoreName` if you ever want a clean slate — the old key
   is untouched, so you can roll back.
4. Rotate the codes in `Config/Codes.lua`; the shipped ones are placeholders.
