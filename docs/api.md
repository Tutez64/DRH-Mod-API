# The `api` reference

Everything the `api` mod offers, by what a mod does with it. Its version covers this text: a fix is a patch, an addition a minor, a change to what is written here a major ([Versioning](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/modding.md#versioning)). Each release's notes list what it added. The steps to make a mod are in [Making a mod](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/making-a-mod.md).

Its types sit by what they read: `mods.api` (`Mod`, `Context`, `State`, `Subscription`), `mods.api.dungeon` (`Floor`, `Tile`, `Monster`, `Hero`, `Player`) and `mods.api.account` (`Account`, `Inventory`, `OwnedHero`, `Weapon`, `Pet`, `Stack`). `mods.api._internal` is not part of it.

A mod written only against this page is a stable-only mod, labelled `API` in the launcher: it keeps working across DRH updates as long as the `api` major does not change. Drawing on the overlay with OpenFL is part of it. Anything else of the game is [beyond the `api`](#beyond-the-api).

## Entry and lifecycle

The `entry` of `mod.json` names a class of `src/` that extends `mods.api.Mod`. Its three methods are optional:

| Method | When |
| --- | --- |
| `init(context:Context)` | Before any of the game exists: subscribe here. |
| `ready(context:Context)` | Once the account, tables and clocks exist, before the game loop. Once per run, not again on a return to town. Never runs when the game stops booting (connection error); an account without a hero still gets it. |
| `dispose()` | On a graceful exit, even after the mod failed. |

A throw in `init` or `ready` fails the mod: its subscriptions stop and its overlay layer is removed, and the mods that depend on it fail too. A throw in an event handler is only logged, under the mod.

## Context

What `init` and `ready` receive.

| Member | What |
| --- | --- |
| `log(message)` | Writes `mod <id>: <message>` to the game's log, and to the output of `--run-mod`. |
| `state` | The live game, shared by every mod: [State](#state). |
| `overlay` | This mod's layer, an OpenFL `Sprite` above the game, stacked in load order. Removed if the mod fails. |
| `viewWidth`, `viewHeight` | Size of the game's view in overlay coordinates; 0 before `ready`. |
| `resources` | This mod's `Resources/` folder, absolute: its own files, such as `BitmapData.fromFile(resources + "/icon.png")`, the only ones its release holds besides its code. They never replace the game's. |
| `data` | This mod's folder to write in, absolute, created on first read: its settings or anything it keeps. Kept when the mod is updated or uninstalled. |
| `on…(handler)` | [Events](#events). |
| `core` | The core this context wraps: [beyond the `api`](#beyond-the-api). |

## Events

Each `on…` returns a `Subscription`: `cancel()` stops it, a second call does nothing, and `active` is false once cancelled or once the mod failed. A null handler is refused.

| Event | Handler | When |
| --- | --- | --- |
| `onTablesLoaded` | `Void->Void` | The game's tables are in, the account is not read against them yet. Before `ready`, so subscribe in `init`. |
| `onTownEnter`, `onTownExit` | `Void->Void` | Town entered, including a return from a dungeon, and left. |
| `onFloorEnter`, `onFloorExit` | `Floor->Void` | A dungeon floor starts, its grid built (its art may still be loading), and ends. |
| `onHeroSpawned` | `Hero->Void` | A hero, local or of another player, is on a dungeon floor and ready. Always after its floor's `onFloorEnter`. |
| `onHeroDespawned` | `Hero->Void` | A hero leaves the floor. It still reads in the handlers, empty after them. |
| `onKeyDown` | `UInt->Bool` | A key goes down, with its OpenFL key code: once per press, not for a held key's repeats, not while a text field such as the chat has focus. Return true to keep the key: the game never sees that press. |

Order: `init`, `onTablesLoaded`, `ready`, then everything else. A hero always comes after its floor. Town has no heroes.

## State

`context.state`, read live:

| Member | What |
| --- | --- |
| `account` | [Account](#account), null until `ready`. |
| `floor` | The dungeon [Floor](#floor) in progress; null in town. |
| `heroes` | The [heroes](#hero) on the floor, local and remote. A copy. |
| `players` | The [players](#player) met in the dungeon in progress, in order of arrival, those who left included; emptied on `onTownEnter`. A copy. |

A hero and its player are two objects: a `Hero` is what a player plays on one floor, and each floor gives a new one; its `Player` is the account behind it, the same from its first hero to the return to town.

### Floor

| Member | What |
| --- | --- |
| `id` | The floor's object id. |
| `number` | 1-based index of the floor inside its dungeon. |
| `map` | The game's map node constant; empty once the floor is gone. |
| `tiles` | Its [tiles](#tile) as the server laid them out, read now: the whole floor from the start, rooms not reached yet included. Filler the server sends is in it, not the filler the game adds on its own around the floor. Empty once the floor is gone. A copy. |
| `monsters` | The heroes' living [enemies](#monster) the game knows on the floor, read now: rooms not reached yet included, and those a generator spawns later. Anything of the foes' team, such as the Cracked Walls guarding the Golem in Twisted Jungle Boss or the Barrel Monsters of Knight Fortress Boss; not breakable props, nor traps that hurt everyone. None yet at `onFloorEnter`; empty once the floor is gone. A copy. |

### Tile

A square room of a floor, copied when read.

| Member | What |
| --- | --- |
| `x`, `y` | World position of its top-left corner, in the coordinates of a hero's `x` and `y`. |
| `SIZE` | Side of every tile, 900. |
| `id` | Its id in the floor's tile library. |
| `category` | `STARTING_TILE`, `BASIC_TILE`, `EXIT_TILE`, `BOSS_TILE`, `PUZZLE_TILE`, `SECRET_TILE`, `TRAP_TILE` or `FILLER_TILE`, as the library says; empty when unknown. |
| `exits` | Its open sides, indexed by `UP`, `RIGHT`, `DOWN` and `LEFT`, as the library says. Two tiles are joined only when both facing sides are open; a boss arena spanning several tiles can have none and still be open. |
| `contains(x, y)` | Whether a world point is inside it, such as a hero's position. |

### Monster

A living enemy of the heroes, copied when read. The game has no reliable notion of a boss: tell one by its `name`, and its dungeon by the floor's `map`.

| Member | What |
| --- | --- |
| `id` | Its object id on the floor, the same from one read to the next. |
| `name` | Its name in the game's data, such as `Golem Boss`. |
| `x`, `y` | World position, in the coordinates of a hero's `x` and `y`. |
| `healthBar` | Whether the game shows a health bar over it, as it does for the big ones: bosses, minibosses, and some others. |

### Hero

Fields read the live hero and go empty after the `onHeroDespawned` handlers.

| Member | What |
| --- | --- |
| `id` | The hero's object id on the floor, not an account. |
| `local` | True for the local player's hero. |
| `player` | Its [Player](#player); null only if the game sent no account for it. |
| `classId`, `className` | The hero class: the game's id and the name it shows. |
| `level` | |
| `x`, `y` | World position; 0 once gone. |
| `weapons` | Equipped [weapons](#weapon) by slot, empty slots left out. A copy. |

### Player

| Member | What |
| --- | --- |
| `accountId` | |
| `local` | True for the local player. |
| `name` | Screen name. |
| `hero` | Its hero on the current floor; null between floors and once the player has left. |
| `isFriend` | Whether the local account has this player as a friend. |
| `createPortrait(size)` | The player's picture, as on the end screen: the icon of their hero's skin, centred in a `size` square. |
| `addFriend(?sent)` | Sends a friend request, as the end screen does. |
| `block(?sent)` | Asks for confirmation with the game's popup, then blocks the player. |
| `report(?sent)` | Opens the game's report popup. |

The last three return false when there is nobody to act on (the local player). `sent` runs once the server accepted, never on cancel or error.

### Account

From `ready`, read live.

| Member | What |
| --- | --- |
| `id` | |
| `hasActiveAvatar`, `activeAvatarId` | Whether a hero is selected in town, and its id (as `OwnedHero.id`); follows a change of selection. |
| `coins`, `gems`, `trophies` | |
| `inventory` | What the account owns: [Inventory](#inventory). |

### Inventory

Each list is a copy, in no particular order.

| Member | What |
| --- | --- |
| `heroes` | The account's [heroes](#ownedhero), with what each has equipped. |
| `weapons` | [Weapons](#weapon) in storage, not equipped (`slot` -1). |
| `weaponLimit` | Size of the weapon storage; unopened chests take room in it too. |
| `pets` | [Pets](#pet) in storage, not equipped. |
| `consumables` | [Consumables](#stack) in storage: potions and bombs. |

Coin and XP boosters, chests and keys are not covered yet.

### OwnedHero

A hero of the account, copied when read, with what it carries into a dungeon; not a `Hero` on a floor.

| Member | What |
| --- | --- |
| `id` | As `Account.activeAvatarId`. |
| `classId`, `className`, `level` | As on `Hero`. |
| `skinId` | The game's skin id. |
| `weapons`, `pets`, `consumables` | Equipped, by slot, empty slots left out. |

### Weapon

Copied when read: it does not follow later changes.

| Member | What |
| --- | --- |
| `slot` | 0-based slot on the hero carrying it, -1 in storage. |
| `id`, `name` | The game's item id, and its name as the inventory shows it, without its modifiers. |
| `power`, `requiredLevel` | |
| `rarity`, `rarityColor`, `legendary` | The game's rarity constant (empty when unknown), the text color it uses for it, and whether it is legendary. |
| `createIcon(size)` | The game's icon on its rarity background, centred in a `size` square; hovering it shows the game's tooltip. Empty before `ready`. |

### Pet

| Member | What |
| --- | --- |
| `id`, `name` | The game's id of the pet's kind, and its name as the inventory shows it. |
| `attackRating`, `defenseRating`, `speedRating` | |

### Stack

Some of one stackable item, such as a potion or a bomb.

| Member | What |
| --- | --- |
| `id`, `name` | The game's item id and its name. |
| `count` | |

## Drawing

Add OpenFL display objects to `context.overlay`; place them with `viewWidth` and `viewHeight`, which change with the window. `createPortrait` and `createIcon` return OpenFL `Sprite`s for the overlay: their art appears once loaded, and is released when the sprite is removed from its parent.

## Beyond the `api`

`context.core` is the game's core (`modding.ModContext`), and through it the game's own classes: its generic events (any game object ready or gone, fields the server sends, state changes), `facade` (from `ready`), and from there the game's event bus (`facade.eventManager`). Using any of it makes the mod `extends`: `uses: ["extends"]` and `drh` in `mod.json`, a warning in the launcher, and no promise across DRH updates. [DRH-Mod-Inspector](https://github.com/Tutez64/DRH-Mod-Inspector) is an example, and a tool to see what is there. The core's events and rules: [Game events](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/modding.md#game-events).

What a mod needs from there and others would too is a candidate for a later `api`: say so on Discord or in this repository's issues.
