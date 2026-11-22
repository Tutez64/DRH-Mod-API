# The `api` reference

Everything the `api` mod offers, by package. Its version covers this text: a fix is a patch, an addition a minor, a change to what is written here a major ([Versioning](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/modding.md#versioning)). `Since` is the version a type or a member came in, and each release's notes list what it added. The steps to make a mod are in [Making a mod](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/making-a-mod.md).

`mods.api._internal` is not part of it.

A mod written only against this page is a stable-only mod, labelled `API` in the launcher: it keeps working across DRH updates as long as the `api` major does not change. Drawing on the overlay with OpenFL is part of it. Anything else of the game is [beyond the `api`](#beyond-the-api).

<!-- api:reference, written by tools/ApiDoc.hx from the comments of src/: change those -->

- [`mods.api`](#modsapi): [Mod](#mod), [Context](#context), [State](#state), [Subscription](#subscription), [Dictionaries](#dictionaries)
- [`mods.api.dungeon`](#modsapidungeon): [Floor](#floor), [Tile](#tile), [Monster](#monster), [Hero](#hero), [Player](#player)
- [`mods.api.account`](#modsapiaccount): [Account](#account), [Inventory](#inventory), [OwnedHero](#ownedhero), [Weapon](#weapon), [Pet](#pet), [Stack](#stack)
- [`mods.api.settings`](#modsapisettings): [Settings](#settings), [Flag](#flag), [Choice](#choice), [Slider](#slider), [Button](#button), [Keys](#keys), [KeyAction](#keyaction)
- [Drawing](#drawing)
- [Beyond the `api`](#beyond-the-api)

## mods.api

### Mod

`mods.api.Mod`, since 1.0

What a mod's entry extends: the `entry` of `mod.json` names a class of `src/` that extends `mods.api.Mod`. Its three methods are optional.

A throw in `init` or `ready` fails the mod: its subscriptions stop and its overlay layer is removed, and the mods that depend on it fail too. A throw in an event handler is only logged, under the mod.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `init(context:Context)` | `Void` | 1.0 | Called before any of the game exists: subscribe here. |
| `ready(context:Context)` | `Void` | 1.0 | Called once the account, tables and clocks exist, before the game loop. Once per run, not again on a return to town. Never called when the game stops booting (connection error); an account without a hero still gets it. |
| `dispose()` | `Void` | 1.0 | Called on a graceful exit, even after the mod failed. |

### Context

`mods.api.Context`, since 1.0

What `init` and `ready` receive.

Each `on...` subscribes a handler to an event and returns its [`Subscription`](#subscription). A null handler is refused.

Order: `init`, `onTablesLoaded`, `ready`, then everything else. A hero and a monster always come after their floor. Town has neither. A monster's events hand it copied at that moment: tell one from another by its `id`.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `overlay` | `Sprite` | 1.0 | This mod's layer, an OpenFL `Sprite` above the game and its letterbox, stacked in load order. Removed if the mod fails. |
| `resources` | `String` | 1.0 | This mod's `Resources/` folder, absolute and without a trailing slash: its own files, such as `BitmapData.fromFile(resources + "/icon.png")`, the only ones its release holds besides its code. They never replace the game's. |
| `data` | `String` | 1.0 | This mod's folder to write in, absolute and without a trailing slash, created on first read: anything it keeps. Kept when the mod is updated or uninstalled. Its `settings.json` is the `api`'s, for [`Settings`](#settings) and [`Keys`](#keys). |
| `state` | [`State`](#state) | 1.0 | The live game, shared by every mod. |
| `viewWidth`, `viewHeight` | `Float` | 1.0 | Size of the game's view in overlay coordinates; 0 before `ready`. |
| `settings` | [`Settings`](#settings) | 1.3 | This mod's options, shown in the game's settings menu. |
| `keys` | [`Keys`](#keys) | 1.3 | This mod's key actions, which the player rebinds. |
| `core` | `ModContext` | 1.0 | The core this context wraps: [beyond the `api`](#beyond-the-api). |
| `log(message:String)` | `Void` | 1.0 | Writes `mod <id>: <message>` to the game's log, and to the output of `--run-mod`. |
| `isActive(id:String)` | `Bool` | 1.5 | Whether the mod of that id runs: enabled, started, and not failed since. Ask from `ready` on: in `init`, a mod that starts after this one is not there yet. |
| `onTablesLoaded(handler:Void->Void)` | [`Subscription`](#subscription) | 1.0 | The game's tables are in, the account is not read against them yet. Before `ready`, so subscribe in `init`. |
| `onTownEnter(handler:Void->Void)` | [`Subscription`](#subscription) | 1.0 | Town entered, including a return from a dungeon. |
| `onTownExit(handler:Void->Void)` | [`Subscription`](#subscription) | 1.0 | Town left. |
| `onFloorEnter(handler:Floor->Void)` | [`Subscription`](#subscription) | 1.0 | A dungeon floor starts, its grid built and its `map` set (its art may still be loading). |
| `onFloorExit(handler:Floor->Void)` | [`Subscription`](#subscription) | 1.0 | A dungeon floor ends. |
| `onHeroSpawned(handler:Hero->Void)` | [`Subscription`](#subscription) | 1.0 | A hero, local or of another player, is on a dungeon floor and ready. Always after its floor's `onFloorEnter`. |
| `onHeroDespawned(handler:Hero->Void)` | [`Subscription`](#subscription) | 1.0 | A hero leaves the floor. It still reads in the handlers, empty after them. |
| `onMonsterSpawned(handler:Monster->Void)` | [`Subscription`](#subscription) | 1.5 | An enemy of the heroes, as [`Floor.monsters`](#floor) lists them, is ready on the floor. Always after its floor's `onFloorEnter`. |
| `onMonsterHurt(handler:Monster->Void)` | [`Subscription`](#subscription) | 1.5 | The hit points of a monster told as spawned changed, down or up. |
| `onMonsterDespawned(handler:Monster->Void)` | [`Subscription`](#subscription) | 1.5 | A monster told as spawned died or left, or its floor ends: once for each, before its floor's `onFloorExit`. |
| `onKeyDown(handler:UInt->Bool)` | [`Subscription`](#subscription) | 1.0 | A key goes down, with its OpenFL key code: once per press, not for a held key's repeats, not while a text field such as the chat has focus. Return true to keep the key: the game never sees that press, neither its own shortcuts (Enter opening the chat) nor OpenFL's (Tab moving the focus), nor its repeats and release. For the keys of a mod's own window while it is open, such as Enter and Escape: a shortcut is a key action of [`Keys`](#keys). |

### State

`mods.api.State`, since 1.0

The live game, read now: `context.state`, shared by every mod.

A hero and its player are two objects: a [`Hero`](#hero) is what a player plays on one floor, and each floor gives a new one; its [`Player`](#player) is the account behind it, the same from its first hero to the end of the dungeon.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `account` | [`Null<Account>`](#account) | 1.0 | The account, null until `ready`. |
| `inTown` | `Bool` | 1.2 | Whether the game is in town: true from `onTownEnter` to `onTownExit`. |
| `floor` | [`Null<Floor>`](#floor) | 1.0 | The dungeon floor in progress; null in town. |
| `heroes` | [`Array<Hero>`](#hero) | 1.0 | The heroes on the floor, local and remote. A copy. |
| `players` | [`Array<Player>`](#player) | 1.0 | The players met in the dungeon in progress, in order of arrival, those who left included; emptied when it is left, for the town (before `onTownEnter`) or for another dungeon. A copy. |

### Subscription

`mods.api.Subscription`, since 1.0

What subscribing a handler returns, such as each `on...` of [`Context`](#context).

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `active` | `Bool` | 1.0 | False once cancelled, or once the mod that subscribed failed. |
| `cancel()` | `Void` | 1.0 | Stops the handler; a second call does nothing. |

### Dictionaries

`mods.api.Dictionaries`, since 1.4

Reads and writes a dictionary of the game (`ASDictionary` in its classes), met [beyond the `api`](#beyond-the-api).

The game keeps the entries whose key is a text, a number or a boolean apart from the others. A mod's own `dictionary[key]`, `get`, `set`, `exists`, `remove`, `keys` and loops on it do not reach them: what the game wrote the mod does not see, and what a mod writes the game does not find. These reach every entry, whatever its key. Anything that is not a dictionary is refused with a throw.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `Dictionaries.get(dictionary:Dynamic, key:Dynamic)` | `Dynamic` | 1.4 | The value under the key, null when there is none. |
| `Dictionaries.set(dictionary:Dynamic, key:Dynamic, value:Dynamic)` | `Void` | 1.4 | Puts the value under the key. |
| `Dictionaries.exists(dictionary:Dynamic, key:Dynamic)` | `Bool` | 1.4 | Whether there is an entry under the key. |
| `Dictionaries.remove(dictionary:Dynamic, key:Dynamic)` | `Bool` | 1.4 | Removes the entry; whether there was one. |
| `Dictionaries.keys(dictionary:Dynamic)` | `Array<Dynamic>` | 1.4 | Every key. A copy. |
| `Dictionaries.values(dictionary:Dynamic)` | `Array<Dynamic>` | 1.4 | Every value. A copy. |

## mods.api.dungeon

### Floor

`mods.api.dungeon.Floor`, since 1.0

A dungeon floor.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `id` | `UInt` | 1.0 | The floor's object id. |
| `number` | `Int` | 1.0 | 1-based index of the floor inside its dungeon. |
| `map` | `String` | 1.0 | The game's map node constant; empty once the floor is gone. |
| `tiles` | [`Array<Tile>`](#tile) | 1.1 | Its tiles as the server laid them out, read now: the whole floor from the start, rooms not reached yet included. Filler the server sends is in it, not the filler the game adds on its own around the floor. Empty once the floor is gone. A copy. |
| `monsters` | [`Array<Monster>`](#monster) | 1.1 | The heroes' living enemies the game knows on the floor, read now: rooms not reached yet included, and those a generator spawns later. Anything of the foes' team, such as the Cracked Walls guarding the Golem in Twisted Jungle Boss or the Barrel Monsters of Knight Fortress Boss; not breakable props, nor traps that hurt everyone. None yet at `onFloorEnter`; empty once the floor is gone. A copy. |

### Tile

`mods.api.dungeon.Tile`, since 1.1

A square room of a floor, copied when read.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `Tile.SIZE` | `900` | 1.1 | Side of every tile, in world units. |
| `x`, `y` | `Int` | 1.1 | World position of its top-left corner, in the coordinates of [`Hero.x`](#hero) and [`Hero.y`](#hero). |
| `id` | `String` | 1.1 | Its id in the floor's tile library. |
| `category` | `String` | 1.1 | `STARTING_TILE`, `BASIC_TILE`, `EXIT_TILE`, `BOSS_TILE`, `PUZZLE_TILE`, `SECRET_TILE`, `TRAP_TILE` or `FILLER_TILE`, as the library says; empty when unknown. |
| `exits` | `Array<Bool>` | 1.1 | Its open sides, indexed by `UP`, `RIGHT`, `DOWN` and `LEFT`, as the library says. Two tiles are joined only when both facing sides are open; a boss arena spanning several tiles can have none and still be open. |
| `Tile.UP`, `Tile.RIGHT`, `Tile.DOWN`, `Tile.LEFT` | `0`, `1`, `2`, `3` | 1.1 | The indexes of `exits`. |
| `contains(px:Float, py:Float)` | `Bool` | 1.1 | Whether a world point is inside it, such as a hero's position. |

### Monster

`mods.api.dungeon.Monster`, since 1.1

A living enemy of the heroes, copied when read or when an event hands it. The game has no reliable notion of a boss: tell one by its `name`, and its dungeon by the floor's `map`.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `id` | `UInt` | 1.1 | Its object id on the floor, the same from one read to the next. |
| `name` | `String` | 1.1 | Its name in the game's data, such as `Golem Boss`. |
| `x`, `y` | `Float` | 1.1 | World position, in the coordinates of [`Hero.x`](#hero) and [`Hero.y`](#hero). |
| `healthBar` | `Bool` | 1.1 | Whether the game shows a health bar over it, as it does for the big ones: bosses, minibosses, and some others. |
| `hp`, `maxHp` | `UInt` | 1.5 | Its hit points, 0 once dead, and what they are when it is whole, with what its buffs add. |

### Hero

`mods.api.dungeon.Hero`, since 1.0

A hero on a dungeon floor. Fields read the live hero and go empty after the `onHeroDespawned` handlers.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `id` | `UInt` | 1.0 | The hero's object id on the floor, not an account. |
| `local` | `Bool` | 1.0 | True for the local player's hero. |
| `player` | [`Null<Player>`](#player) | 1.0 | Its player; null only if the game sent no account for it. |
| `classId`, `className` | `UInt`, `String` | 1.0 | The hero class: the game's id and the name it shows. |
| `level` | `UInt` | 1.0 |  |
| `ascension` | `UInt` | 1.4 | How many times the hero ascended: the number in its star. 0 for a hero that never did. |
| `x`, `y` | `Float` | 1.1 | World position; 0 once gone. |
| `weapons` | [`Array<Weapon>`](#weapon) | 1.0 | Equipped weapons by slot, empty slots left out. A copy. |

### Player

`mods.api.dungeon.Player`, since 1.0

A player met in the dungeon in progress, the local one included, kept once they have left: `hero` is then null, and the rest holds what was last read from their hero.

`addFriend`, `block` and `report` return false when there is nobody to act on (the local player). `sent` runs once the server accepted, never on cancel or error.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `accountId` | `UInt` | 1.0 |  |
| `local` | `Bool` | 1.0 | True for the local player. |
| `name` | `String` | 1.0 | Screen name. |
| `hero` | [`Null<Hero>`](#hero) | 1.0 | Its hero on the current floor; null between floors and once the player has left. |
| `isFriend` | `Bool` | 1.0 | Whether the local account has this player as a friend. |
| `createPortrait(size:Float)` | `Sprite` | 1.0 | The player's picture, as on the end screen: the icon of their hero's skin, centred in a `size` square. |
| `createAscensionStar(size:Float)` | `Sprite` | 1.4 | The ascension star of their hero with its number, as the game shows it by a portrait, centred in a `size` square. Empty for a hero that never ascended. |
| `addFriend(?sent:Void->Void)` | `Bool` | 1.0 | Sends a friend request, as the end screen does. |
| `block(?sent:Void->Void)` | `Bool` | 1.0 | Asks for confirmation with the game's popup, then blocks the player. |
| `report(?sent:Void->Void)` | `Bool` | 1.0 | Opens the game's report popup. The match lists the players with a hero on the floor, plus this one if they have left, close to the end screen's four slots. |

## mods.api.account

### Account

`mods.api.account.Account`, since 1.0

The local account, from `ready`, read live.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `id` | `UInt` | 1.0 |  |
| `hasActiveAvatar`, `activeAvatarId` | `Bool`, `UInt` | 1.0 | Whether a hero is selected in town, and its id (as [`OwnedHero.id`](#ownedhero)), 0 when there is none; follows a change of selection. |
| `coins`, `gems`, `trophies` | `UInt` | 1.0 |  |
| `inventory` | [`Inventory`](#inventory) | 1.0 | What the account owns. |

### Inventory

`mods.api.account.Inventory`, since 1.0

What the account owns. Each list is a copy, in no particular order. Coin and XP boosters, chests and keys are not covered yet.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `heroes` | [`Array<OwnedHero>`](#ownedhero) | 1.0 | The account's heroes, with what each has equipped. |
| `weapons` | [`Array<Weapon>`](#weapon) | 1.0 | Weapons in storage, not equipped (`slot` -1). |
| `weaponLimit` | `UInt` | 1.0 | Size of the weapon storage; unopened chests take room in it too. |
| `pets` | [`Array<Pet>`](#pet) | 1.0 | Pets in storage, not equipped. |
| `consumables` | [`Array<Stack>`](#stack) | 1.0 | Consumables in storage: potions and bombs. |

### OwnedHero

`mods.api.account.OwnedHero`, since 1.0

A hero of the account, copied when read, with what it carries into a dungeon; not a [`Hero`](#hero) on a floor.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `id` | `UInt` | 1.0 | As [`Account.activeAvatarId`](#account). |
| `classId`, `className`, `level` | `UInt`, `String`, `UInt` | 1.0 | As on [`Hero`](#hero). |
| `ascension` | `UInt` | 1.4 | As [`Hero.ascension`](#hero). |
| `skinId` | `UInt` | 1.0 | The game's skin id. |
| `weapons`, `pets`, `consumables` | [`Array<Weapon>`](#weapon), [`Array<Pet>`](#pet), [`Array<Stack>`](#stack) | 1.0 | Equipped, by slot, empty slots left out. |
| `equipPet(pet:Pet, ?done:Bool->Void)` | `Bool` | 1.2 | Equips the pet on this hero, in town, as the inventory does but without its popup: the pet this hero carries goes back to storage, and `pet` leaves the hero carrying it. `done` runs once: true once the server accepted, false on an error, which the game shows. Returns false when there is nothing to do: out of town, `pet` already on this hero or not the account's, or a move still in progress, of any mod. |

### Weapon

`mods.api.account.Weapon`, since 1.0

A weapon, copied when read: it does not follow later changes.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `slot` | `Int` | 1.0 | 0-based slot on the hero carrying it, -1 in storage. |
| `id`, `name` | `UInt`, `String` | 1.0 | The game's id of the weapon's kind, and its name as the inventory shows it, without its modifiers. |
| `uid` | `UInt` | 1.6 | This weapon's own id in the account, unlike `id`, which every weapon of its kind shares, however alike two of them are. 0 for a weapon a hero carries in a dungeon, which the game only knows by its kind. |
| `power`, `requiredLevel` | `UInt` | 1.0 |  |
| `rarity`, `rarityColor`, `legendary` | `String`, `UInt`, `Bool` | 1.0 | The game's rarity constant (empty when unknown), the text color it uses for it, and whether it is legendary. |
| `createIcon(size:Float)` | `Sprite` | 1.0 | The game's icon on its rarity background, centred in a `size` square; hovering it shows the game's tooltip. Empty before `ready`. |

### Pet

`mods.api.account.Pet`, since 1.0

A pet, copied when read.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `id`, `name` | `UInt`, `String` | 1.0 | The game's id of the pet's kind, and its name as the inventory shows it. |
| `uid` | `UInt` | 1.2 | This pet's own id in the account, unlike `id`, which every pet of its kind shares. |
| `attackRating`, `defenseRating`, `speedRating` | `UInt` | 1.0 |  |

### Stack

`mods.api.account.Stack`, since 1.0

Some of one stackable item, such as a potion or a bomb.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `id`, `name` | `UInt`, `String` | 1.0 | The game's item id and its name. |
| `count` | `UInt` | 1.0 |  |

## mods.api.settings

### Settings

`mods.api.settings.Settings`, since 1.3

`context.settings` declares a mod's options. The game's settings menu shows them in its MODS tab (ADVANCED before DRH 18, which has no such tab), under a header with the mod's name, and the player sets them there as the game's own. Declare them in `init`: each answers its value from then on, read from the mod's `settings.json`.

`id` names the option in the mod's file: unique among the mod's options, and the same across its versions. Another mod may use the same. `label` is the row's title, shown in capitals on one line: about 15 characters fit a slider, 19 the others, and a longer one is made smaller, then cut. `description` shows under a flag's label only: the game's rows for a choice, a slider and a key have no room for one. A declaration that cannot be shown throws: an id declared twice, no choices, a default that is not one of them, an empty range.

The menu's reset puts every option back to its declared default. An option the mod no longer declares stays in the file, ignored.

The file is the `api`'s: it writes it whole at the first change, and nothing else stays in it. A mod that kept a `settings.json` of its own before reads it in `init`, then gives each option the value it had (`flag.value = ...`), so the player's choices carry over; whatever else it kept there goes to another file.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `flag(id:String, label:String, description:String, defaultValue:Bool = false)` | [`Flag`](#flag) | 1.3 | An on/off option. |
| `choice(id:String, label:String, description:String, choices:Array<Dynamic>, defaultValue:String)` | [`Choice`](#choice) | 1.3 | One value among `choices`, each `{value, label}`, both text: `[{value: "en", label: "English"}, {value: "es", label: "Spanish"}]`. The menu shows the labels, in capitals, and they differ. |
| `slider(id:String, label:String, description:String, minimum:Float, maximum:Float, step:Float, defaultValue:Float, decimals:Int = 0)` | [`Slider`](#slider) | 1.3 | A number in a range, shown with `decimals` digits after the point. |
| `button(id:String, label:String, caption:String)` | [`Button`](#button) | 1.4 | A row that is a button, with `caption` written on it, such as one that opens the mod's own window. It holds no value. |

### Flag

`mods.api.settings.Flag`, since 1.3

An on/off option, declared with [`Settings.flag`](#settings).

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `value` | `Bool` | 1.3 | Its value now. Setting it shows in the menu and is kept, as when the player sets it. |
| `onChange(handler:Bool->Void)` | [`Subscription`](#subscription) | 1.3 | The value changed, with the new one: set by the player in the menu, by the menu's reset, or by the mod. In town or during a run. |

### Choice

`mods.api.settings.Choice`, since 1.3

One value among several, declared with [`Settings.choice`](#settings).

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `value` | `String` | 1.3 | Its value now: the chosen `value`. Setting it shows in the menu and is kept, as when the player sets it; a value that is not one of its choices is refused. |
| `onChange(handler:String->Void)` | [`Subscription`](#subscription) | 1.3 | The value changed, with the new one: set by the player in the menu, by the menu's reset, or by the mod. In town or during a run. |

### Slider

`mods.api.settings.Slider`, since 1.3

A number in a range, declared with [`Settings.slider`](#settings).

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `value` | `Float` | 1.3 | Its value now. Setting it shows in the menu and is kept, as when the player sets it; one outside its range is brought within it. |
| `onChange(handler:Float->Void)` | [`Subscription`](#subscription) | 1.3 | The value changed, with the new one: set by the player in the menu, by the menu's reset, or by the mod. In town or during a run. |

### Button

`mods.api.settings.Button`, since 1.4

A row of the menu that is a button, declared with [`Settings.button`](#settings).

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `shown` | `Bool` | 1.4 | Whether the game shows it, which DRH 18 and later do. Without it, give the player another way, such as a key action of [`Keys`](#keys). |
| `onPress(handler:Void->Void)` | [`Subscription`](#subscription) | 1.4 | The button is pressed, the menu staying open. |

### Keys

`mods.api.settings.Keys`, since 1.3

`context.keys` declares a mod's key actions. The game's settings menu shows them at the end of CONTROLS, under a header with the mod's name, and the player rebinds them there. Declare them in `init`.

A mod never reads the key code: the player may have changed it, or given the action a second key.

A key is one action's, the game's own included. Binding a key in the menu takes it from the action that had it. An action whose key is already held when its mod loads, by the game or by a mod loaded before, starts with none, and has it at a later start once it is free: do not declare a key the game uses. The menu compares the key alone: R and Shift+R are the same key.

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `action(id:String, label:String, description:String, key:UInt, shift:Bool = false, ctrl:Bool = false, alt:Bool = false)` | [`KeyAction`](#keyaction) | 1.3 | A key action. `key` is the OpenFL key code it has until the player changes it, such as `Keyboard.F6`; Escape, Enter, F8 and F11 cannot be bound, and declaring one throws. `shift`, `ctrl` and `alt` are the modifiers a press needs held, which the row's title names (`RESTART (SHIFT+)`). The player cannot change them yet and will later: the action must make sense without them. |

### KeyAction

`mods.api.settings.KeyAction`, since 1.3

A key action, declared with [`Keys.action`](#keys).

| Member | Type | Since | What |
| --- | --- | --- | --- |
| `held` | `Bool` | 1.3 | Whether its key is down now, with its modifiers. |
| `label` | `String` | 1.3 | What is bound, as the menu names keys, to show the player: `"SHIFT+R"`, empty when nothing is. |
| `onPress(handler:Void->Void)` | [`Subscription`](#subscription) | 1.3 | The action is pressed: once per press, not for a held key's repeats, not while a text field such as the chat has focus, nor while the settings menu is open. The game never sees that press. |

<!-- /api:reference -->

## Drawing

Add OpenFL display objects to `context.overlay`; place them with `viewWidth` and `viewHeight`, which change with the window. `createPortrait`, `createAscensionStar` and `createIcon` return OpenFL `Sprite`s for the overlay: their art appears once loaded. They need no cleanup: drop them like any sprite.

## Beyond the `api`

`context.core` is the game's core (`modding.ModContext`), and through it the game's own classes: its generic events (any game object ready or gone, fields the server sends, state changes), `facade` (from `ready`), and from there the game's event bus (`facade.eventManager`). Using any of it makes the mod `extends`: `uses: ["extends"]` and `drh` in `mod.json`, a warning in the launcher, and no promise across DRH updates. [DRH-Mod-Inspector](https://github.com/Tutez64/DRH-Mod-Inspector) is an example, and a tool to see what is there. The core's events and rules: [Game events](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/modding.md#game-events).

A dictionary of the game met there is read and written with [`Dictionaries`](#dictionaries).

What a mod needs from there and others would too is a candidate for a later `api`: say so on Discord or in this repository's issues.
