package mods.api;

import modding.ModContext;
import mods.api._internal.Hub;

/**
 * What a mod's entry extends: the `entry` of `mod.json` names a class of `src/` that extends
 * `mods.api.Mod`. Its three methods are optional.
 *
 * A throw in `init` or `ready` fails the mod: its subscriptions stop and its overlay layer is removed,
 * and the mods that depend on it fail too. A throw in an event handler is only logged, under the mod.
 *
 * @since 1.0
 */
class Mod extends modding.Mod {
	var apiContext:Null<Context>;

	/** Called before any of the game exists: subscribe here. */
	public function init(context:Context):Void {}

	/**
	 * Called once the account, tables and clocks exist, before the game loop. Once per run, not again on
	 * a return to town. Never called when the game stops booting (connection error); an account without
	 * a hero still gets it.
	 */
	public function ready(context:Context):Void {}

	/** Called on a graceful exit, even after the mod failed. */
	public function dispose():Void {}

	// The three run at the core's `onInit`, `onReady` and `onDispose`.

	override public function onInit(ctx:ModContext):Void {
		apiContext = new Context(ctx);
		Hub.know(ctx);
		init(apiContext);
	}

	override public function onReady(ctx:ModContext):Void {
		ready(apiContext);
	}

	override public function onDispose():Void {
		dispose();
	}
}
