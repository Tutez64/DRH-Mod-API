package mods.api.settings;

import mods.api.Subscription;
import mods.api._internal.Entry;
import mods.api._internal.Hub;
import mods.api._internal.Options;

/** A button of `Settings.button`. */
class Button {
	/** Whether the game's menu shows it: from DRH 18 on. Without it, give the player another way, such as a key action. */
	public var shown(get, never):Bool;

	var entry:Entry;

	@:allow(mods.api.settings.Settings)
	function new(entry:Entry) {
		this.entry = entry;
	}

	function get_shown():Bool {
		return Options.buttons();
	}

	/** The button is pressed, in the game's settings menu, which stays open. */
	public function onPress(handler:Void->Void):Subscription {
		return Hub.listen(entry.owner.core, entry.event, handler == null ? null : function(_:Dynamic) handler());
	}
}
