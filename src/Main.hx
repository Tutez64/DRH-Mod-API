package mods.api;

import modding.ModContext;

/** The `api` mod itself: turns the core's game events into the wrappers and events `Context` hands out. */
class Main extends modding.Mod {
	override public function onInit(ctx:ModContext):Void {
		Hub.start(ctx);
	}

	override public function onReady(ctx:ModContext):Void {
		Hub.ready();
	}
}
