package mods.api.settings;

import mods.api.Subscription;
import mods.api._internal.Entry;
import mods.api._internal.Hub;
import mods.api._internal.Options;

/**
 * A row of the menu that is a button, declared with `Settings.button`.
 *
 * @since 1.4
 */
class Button {
	/**
	 * Whether the game shows it, which DRH 18 and later do. Without it, give the player another way, such
	 * as a key action of `Keys`.
	 */
	public var shown(get, never):Bool;

	var entry:Entry;

	@:allow(mods.api.settings.Settings)
	function new(entry:Entry) {
		this.entry = entry;
	}

	function get_shown():Bool {
		return Options.buttons();
	}

	/** The button is pressed, the menu staying open. */
	public function onPress(handler:Void->Void):Subscription {
		return Hub.listen(entry.owner.core, entry.event, handler == null ? null : function(_:Dynamic) handler());
	}
}
