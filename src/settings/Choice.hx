package mods.api.settings;

import mods.api.Subscription;
import mods.api._internal.Entry;
import mods.api._internal.Hub;
import mods.api._internal.Options;

/** An option of `Settings.choice`: one of its declared values. */
class Choice {
	/** Its value now. Setting it shows in the menu and is kept; a value that is not one of its choices is refused. */
	public var value(get, set):String;

	var entry:Entry;

	@:allow(mods.api.settings.Settings)
	function new(entry:Entry) {
		this.entry = entry;
	}

	function get_value():String {
		return entry.value;
	}

	function set_value(value:String):String {
		if (entry.values.indexOf(value) < 0)
			throw "option " + entry.id + ": " + value + " is not one of its choices";
		Options.set(entry, value);
		return value;
	}

	/** The value changed: set by the player in the menu, by its reset, or by the mod. In town or during a run. */
	public function onChange(handler:String->Void):Subscription {
		return Hub.listen(entry.owner.core, entry.event, handler);
	}
}
