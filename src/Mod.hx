package mods.api;

import modding.ModContext;

/**
 * Base class of every mod's entry (`mod.json` `entry`). All three methods are optional.
 *
 * `init` runs before any of the game exists, `ready` once the account and clocks exist and before the
 * loop, `dispose` on a graceful exit: the core's `onInit`, `onReady` and `onDispose`, at the same moments.
 */
class Mod extends modding.Mod {
	var apiContext:Null<Context>;

	public function init(context:Context):Void {}

	public function ready(context:Context):Void {}

	public function dispose():Void {}

	override public function onInit(ctx:ModContext):Void {
		apiContext = new Context(ctx);
		init(apiContext);
	}

	override public function onReady(ctx:ModContext):Void {
		ready(apiContext);
	}

	override public function onDispose():Void {
		dispose();
	}
}
