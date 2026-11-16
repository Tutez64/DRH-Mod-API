package mods.api;

import modding.ModContext;
import mods.api._internal.Hub;

/**
 * What subscribing a handler returns, such as each `on...` of `Context`.
 *
 * @since 1.0
 */
class Subscription {
	/** False once cancelled, or once the mod that subscribed failed. */
	public var active(get, never):Bool;

	var owner:ModContext;

	var event:String;

	var call:Dynamic;

	var cancelled:Bool = false;

	@:allow(mods.api._internal.Hub)
	function new(owner:ModContext, event:String, call:Dynamic) {
		this.owner = owner;
		this.event = event;
		this.call = call;
	}

	function get_active():Bool {
		return !cancelled && owner.alive;
	}

	/** Stops the handler; a second call does nothing. */
	public function cancel():Void {
		if (cancelled)
			return;
		cancelled = true;
		Hub.unlisten(this);
	}
}
