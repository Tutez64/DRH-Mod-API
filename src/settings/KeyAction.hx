package mods.api.settings;

import mods.api.Subscription;
import mods.api._internal.Entry;
import mods.api._internal.Hub;
import mods.api._internal.Options;

/** A key action of `Keys.action`. */
class KeyAction {
	/** Whether its key is down now, with its modifiers. */
	public var held(get, never):Bool;

	/** What is bound, as the menu names keys, to show to the player: "SHIFT+R", empty when nothing is. */
	public var label(get, never):String;

	var entry:Entry;

	@:allow(mods.api.settings.Keys)
	function new(entry:Entry) {
		this.entry = entry;
	}

	function get_held():Bool {
		return Options.isHeld(entry);
	}

	function get_label():String {
		return Options.keyLabel(entry);
	}

	/**
	 * The action is pressed: once per press, not for a held key's repeats, not while a text field such
	 * as the chat has focus nor while the settings menu is open. The game never sees that press.
	 */
	public function onPress(handler:Void->Void):Subscription {
		return Hub.listen(entry.owner.core, entry.event, handler == null ? null : function(_:Dynamic) handler());
	}
}
