# DRH Mod API

The official API of [Dungeon Rampage Haxe](https://github.com/Tutez64/Dungeon-Rampage-Haxe) mods, installed by [DRH Launcher](https://github.com/Tutez64/DRH-Launcher).

<!-- drh:show -->
Every mod builds on it: a stable layer over the game, so mods keep working across its updates. The launcher installs it automatically.
<!-- /drh:show -->

## For modders

A mod names the version it is written and tested against in its `mod.json` (`"api": "1.0"`; any later `1.x` is accepted), and DRH Launcher installs it with the mod, `--run-mod` included. Its entry extends `mods.api.Mod`:

```haxe
package mods.my_mod;

import mods.api.Context;

class Main extends mods.api.Mod {
	override public function init(context:Context):Void {
		context.log("loaded");
	}
}
```

What it offers, and what its version promises, are in its [reference](docs/api.md); each release's notes list what it added. The steps to make a mod are in [Making a mod](https://github.com/Tutez64/Dungeon-Rampage-Haxe/blob/master/docs/making-a-mod.md).
