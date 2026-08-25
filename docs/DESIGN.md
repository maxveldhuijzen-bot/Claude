# Design and tuning notes

## The core loop, and why it has those numbers

```
swing at a node  ──▶  backpack fills  ──▶  walk to vault  ──▶  coins
      ▲                                                          │
      └──── better collector / bigger backpack / next zone ◀──────┘
                                   │
                     eggs ──▶ pets ──▶ bigger multipliers
                                   │
                              rebirth ──▶ prisms ──▶ permanent upgrades
```

A vault run should be long enough that filling feels earned and short enough
that the walk never feels like a chore. The target is **roughly 30 seconds of
swinging per run**, held constant for the entire game.

That constancy is the whole reason capacity is multiplier-scaled:

```
auraPerSwing = power × auraMult × zoneMult
capacity     = backpackCapacity × auraMult × zoneMult
timeToFill   = capacity / (auraPerSwing / interval)
             = (backpackCapacity / power) × interval
```

`auraMult` and `zoneMult` cancel. Time to fill depends only on the ratio of the
backpack tier to the collector tier — two numbers in config, both of which stay
readable. Backpack capacities are set to about 150× the matching collector's
power, which lands between 30 and 150 real swings once node-shatter bonuses are
counted.

Simulated, greedy play reaches:

| | rebirth 1 | rebirth 4 | rebirth 8 |
| --- | --- | --- | --- |
| no pets | ~11 min | ~20 min | ~29 min |
| typical pets | ~4 min | ~9 min | ~12 min |

## Currencies

| | Earned by | Spent on | Reset by rebirth |
| --- | --- | --- | --- |
| **Aura** | Swinging at nodes | Selling at a vault | yes (carried only) |
| **Coins** | Selling aura | Collectors, backpacks, zones, eggs | yes |
| **Prisms** | Rebirthing, quests, dailies | 8 permanent upgrades, 7 cosmetics | no |

Rebirth costs `60,000 × 3.25^n` coins and pays `floor(3 + 2n + n^1.4)` prisms.
It clears coins, carried aura, and both tier ladders. It **keeps** pets,
prisms, upgrades, cosmetics and unlocked zones — which is what makes each run
strictly faster than the last instead of feeling like a punishment.

## Rewards that never need rebalancing

Reward tables use `coinsAsRebirthFraction` rather than flat coin amounts. A
reward defined as "40% of your current rebirth cost" is worth the same amount
of *progress* on day one and at rebirth 40. Quest goals do the same thing from
the other side, scaling off the best zone the player has unlocked:

```lua
goal = baseGoal × Zones.best(profile.zones).auraMult
```

So "farm 40K aura" becomes "farm 800M aura" on its own as the player moves up,
and no reward table has to be touched when the endgame moves.

## Luck

```lua
adjusted = weight * luck ^ (1 - weight / maxWeight)
```

The exponent is ~0 for the commonest row and ~1 for the rarest, so `luck` is
exactly the multiplier applied to the rarest drop and nothing is boosted more
than that.

| luck | Common | Uncommon | Rare | Epic | Legendary | Secret |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 45.2% | 13.6% | 4.1% | 0.90% | 0.18% | 1 in 55,000 |
| 4 | 30.7% | 24.3% | 9.8% | 2.39% | 0.49% | 1 in 20,000 |
| 15 | 17.3% | 34.6% | 18.3% | 4.92% | 1.03% | 1 in 9,600 |

Luck comes from pets, the Fortune upgrade, the x2 Luck gamepass and potions,
multiplied together.

## Server authority

| Client sends | Server checks |
| --- | --- |
| "I swung at this node" | node exists and is alive, you are in range, you have unlocked its zone, you have swing budget, your backpack is not full |
| "hatch this egg, 3x" | egg exists, batch size is legal, zone unlocked, coins sufficient, pet limit not exceeded — then rolls server-side |
| "equip pet uid 47" | you own uid 47, it is not already equipped, you have a free slot |
| "fuse 5 of these" | you own 5 unequipped copies at that tier |
| any menu action | rate limit (14/sec), payload is a table, action exists |

Swings use a token bucket: 3 in reserve, refilling one per 0.28s. Bursty enough
to feel instant, capped over any sustained period.

Selling requires standing on a vault pad, and that check lives inside
`FarmService.sell` rather than at its call site — so the function is safe to
call from anywhere, including from a remote, without it ever becoming a
sell-from-anywhere exploit that skips the walk back.

Zone walls are decoration. The real gate is a half-second guard loop that
teleports anyone standing on an unearned platform back to their best unlocked
zone, so no movement exploit gains anything.

## Replication

Two channels at different rates, because they have different costs:

| Channel | Contents | Rate |
| --- | --- | --- |
| `State` | currencies, multipliers, capacity, boosts | ≤ 10 Hz, only when dirty |
| `Profile` | pets, quests, upgrades, zones, stats | ≤ 2 Hz, only when dirty |

Services call `Replicator.markHot()` / `markProfile()` after mutating a profile
and never build payloads themselves.

Public flair — equipped pets, aura trail, collector tier, rebirth count — is
published as **Player attributes**, which replicate to everyone. That is how
other players' pets get drawn without the server sending anyone's inventory to
anyone else.

## Persistence

One DataStore key per player, holding `{ data, lock }`. The lock records a job
id and a timestamp:

- **Acquire on join.** If another live server holds the lock, retry with
  backoff, then kick with a "rejoin in a minute" message rather than loading a
  stale copy.
- **A lock older than 15 minutes** is a crashed server, and is taken over.
- **Release on leave** writes the profile and clears the lock in one
  `UpdateAsync`.
- **Never clobber.** Every write re-checks the lock and aborts if it has been
  taken, so a slow save from a dying server cannot overwrite a live session.

New keys added to `ProfileTemplate` are backfilled onto existing saves by
`TableUtil.reconcile`, so shipping a feature does not need a migration.
`ProfileTemplate.migrate` exists for changes reconcile cannot express.

## Known trade-offs

- **Nodes are shared.** A much stronger player in your zone will break nodes
  before you reach them. Zones gate by progression so co-located players tend to
  have similar power, and respawn is 6 seconds. If you want per-player nodes,
  make `WorldService.nodes` a per-player table and render them client-side —
  more work, more instances, no shared world feel.
- **Pet ViewportFrames cost render passes.** The Index tab shows 55 at once.
  The "Reduce effects" setting swaps them for flat swatches.
- **`GetSortedAsync` runs on a 90 second timer**, not on demand. Leaderboard
  boards are eventually consistent by design; the request budget matters more
  than the freshness here.
