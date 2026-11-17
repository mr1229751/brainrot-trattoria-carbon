# Brainrot Trattoria

**Brainrot Trattoria** is a complete 3D multiplayer Roblox brainrot tycoon, collection, and heist experience built entirely from Luau source and Roblox primitives with Rojo (`v7.7.1`). Collectible culinary-cyber creatures march down a neon-lit central conveyor, earn cash per second on display pedestals inside your purple industrial base, roll powerful visual & income mutations, and tempt rival players to sneak past unlocked red laser gates and steal your rarest catches!

---

## Core Gameplay Loop

1. **Claim Your Base** — Up to 8 players receive an individual purple industrial base (`Base #1`–`Base #8`, 4 West and 4 East) facing the Central Conveyor, complete with panoramic front windows, 10 interior display slots, a Green Cash Collection Platform, and a Red Laser Security Gate.
2. **Buy Brainrots off the Central Conveyor** — Creatures spawn continuously at the North Conveyor Portal with floating rarity-colored info tags (`NAME`, `RARITY`, `$INCOME/SECOND`, `PURCHASE PRICE`). Hold **`[E]`** to buy; your creature physically walks down the promenade into a free pedestal slot in your base.
3. **Roll Rare Mutations** — Every spawn rolls on the mutation ladder:
   - **Radioactive (`3x` income, `10%`)** — Neon lime-green body, rising radioactive bubbles, and green highlight aura.
   - **Golden (`8x` income, `2%`)** — Reflective gold `Foil`/`Glass` finish, golden highlight, and 3 orbiting neon stars.
   - **Void (`25x` income, `0.2%`)** — Dark `ForceField` shell over a pulsing purple neon core with a magenta energy trail.
4. **Collect Cash & Manage Slots** — Step onto your base's **Green Cash Platform** to collect accumulated income (`IncomePerSecond × Mutation × Rebirth Multiplier`) with floating `+$Cash` popups. Hold **`[R]`** on any owned slot to sell a creature (`50%` refund) and free space for higher tiers.
5. **Lock Your Lasers or Steal from Rivals** — Press **`[F]`** at your base's **Lock Button** to power on the **Red Laser Security Gate** (`60s` base duration, scaling with Rebirths) — owners walk right through while rivals are physically blocked. Catch an **UNLOCKED** rival base and hold **`[E — STEAL]`** to hoist their creature overhead with a **`[STEALING!]`** alert tag! Sprint back into your own base to claim it before the owner tags you or hits you with defensive gear.
6. **Gear Up at the Striped Shop Stalls** — Visit **Chef Volt** in the North Plaza (or open **`SHOP`**) to buy functional tools:
   - **Turbo Slap Glove** — Knock rivals flying and instantly foil active steals.
   - **Neon Speed Coil** — `+45%` WalkSpeed while held.
   - **Laser Shock Trap** — Deploy up to 2 armed plasma traps that zap intruders and recover stolen creatures.
   - **Guardian Repulsor** — `14`-stud defensive shockwave blast around your character.
   - **Cosmic Gravity Coil** — `+30%` WalkSpeed and boosted jump power.
7. **Ascend at the Golden Rebirth Shrine** — Visit **Aurelio the Eternal** at the South Plaza Shrine (or open **`REBIRTH`**). Rebirth costs scale `×8` per tier and reset cash/slots in exchange for **permanent Income Multipliers (`+0.75x`), `+10%` WalkSpeed, `+10s` Base Lock Duration, and `+15%` Mutation Luck**, while keeping your **Collection Index** and **Shop Equipment**.

---

## Original Cast (18 Collectible Creatures • 7 Rarities)

| Rarity | Tag Color | Creatures |
| :--- | :--- | :--- |
| **Common** | Gray | Rigatoni Rex, Signor Espresso, Garlic Goober |
| **Uncommon** | Green | Scooter Piccione, Mozzarella Boss, Gelato Giraffe |
| **Rare** | Blue | Maestro Crostaceo, Capitano Cannoli, Gondola Gator |
| **Epic** | Purple | Mecha Lasagna 9000, Diva Tentacolo, Barone Tartufo |
| **Legendary** | Gold | Don Vesuvio, Gladiatore Grande |
| **Mythic** | Red-Pink | Serafino Spaghetto, Squalo Macchiato |
| **Secret** | Neon Rainbow | Imperatore Cosmico, Nonna Omnipotente |

---

## Controls

- **`WASD` / Thumbstick** — Move through the 3D arena
- **`E`** — Buy conveyor creature / Steal from unlocked rival slot / Rebirth at Shrine / Buy Stall gear
- **`F`** — Activate or deactivate your base's Red Laser Security Gate
- **`R`** — Sell a creature in your own base (`50%` value)
- **`Left Click` / Tap** — Activate equipped Shop Tool (Slap, Shock Trap, Repulsor)
- **`B` / `G` / `C`** — Toggle **Shop**, **Rebirth**, or **Index** panels

---

## Project Layout (Rojo)

- `default.project.json` — Maps `src/shared` → `ReplicatedStorage`, `src/server` → `ServerScriptService`, `src/client` → `StarterPlayerScripts`, and `src/gui` → `StarterGui`.
- `src/shared/` — `GameConfig`, `CreatureConfig` (18 creature configs & primitive 3D builders), `MutationConfig`, `EconomyConfig`, `ShopConfig`, `FormatUtil`.
- `src/server/` — `Main.server`, `WorldBuilder`, `PlayerDataService` (DataStore with retries + Studio memory fallback), `BaseService`, `CreatureService`, `ConveyorService`, `EconomyService`, `TheftService`, `ShopService`, `RebirthService`, `NotificationService`, `ShowcaseService`.
- `src/client/` — `ClientController.client`, `UIController`, `InteractionController`.
- `src/gui/` — `MainHUD`, `ShopUI`, `RebirthUI`, `IndexUI`, `NotificationUI`, `TutorialUI`.
- `main.ts` & `vendor/makefun-roblox.ts` — Untouched `make.fun` submission entrypoint and dossier builder.

---

## Building `game.rbxl` & Taking Showcase Screenshots

Build the binary place file from `src/` using Rojo:

```bash
rojo build default.project.json -o game.rbxl
```

### Studio Showcase Mode (`ShowcaseService`)
When opened and played inside **Roblox Studio** (`RunService:IsStudio() == true`), `ShowcaseService` automatically stages screenshot-ready scenes using the live game builders (never active in published Roblox servers):
- **Two Pre-Filled Rival Bases** (`Base #6` showing `"UNLOCKED 0:04"` with a **Golden Secret** on front Pedestal #1, and `Base #7` locked behind active **Red Lasers**).
- **Conveyor Rarity Parade** (`Rigatoni Rex` Common, `Mecha Lasagna 9000` Epic, and **Golden `Imperatore Cosmico` Secret** side-by-side with tags).
- **Mid-Steal Dummy Avatar** sprinting outside `Base #6` carrying a glowing Epic (`Diva Tentacolo`) overhead with the **`[STEALING!]`** tag.
- **`$250M` Showcase Cash** on the local player so buying, laser locking, equipment tools, Index, and Rebirth can all be photographed immediately.

After publishing your place on Roblox, update `PLAY.json`, place 3–4 screenshots (`<= 256 KiB` each, `1280x720` recommended) in `screenshots/`, and verify the dossier output locally:

```bash
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```
