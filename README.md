# DRH Mod API

The official API of [Dungeon Rampage Haxe](https://github.com/Tutez64/Dungeon-Rampage-Haxe) every mod builds on: a stable layer over the game, so mods keep working across its updates.

[DRH Launcher](https://github.com/Tutez64/DRH-Launcher) installs it with the mods that need it.

## For modders

This repository is the mod's folder: clone it into a mods folder as `api/` and it runs as is.

A mod names the version it is written and tested against in its `mod.json` (`"api": "1.0"`; any later `1.x` is accepted) and its entry extends `mods.api.Mod`:

```haxe
package mods.my_mod;

import mods.api.Context;

class Main extends mods.api.Mod {
	override public function init(context:Context):Void {
		context.log("loaded");
	}
}
```

Each release's notes list what it added. What a version promises, and what the mod covers, are in DRH's [modding document](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/modding.md#the-api-mod).
