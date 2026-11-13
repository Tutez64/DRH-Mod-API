package mods.api.settings;

import mods.api.Subscription;
import mods.api._internal.Entry;
import mods.api._internal.Hub;
import mods.api._internal.Options;

/** A number option of `Settings.slider`. */
class Slider {
	/** Its value now. Setting it shows in the menu and is kept, brought within its range. */
	public var value(get, set):Float;

	var entry:Entry;

	@:allow(mods.api.settings.Settings)
	function new(entry:Entry) {
		this.entry = entry;
	}

	@:allow(mods.api.settings.Settings)
	static function within(entry:Entry, value:Float):Float {
		if (Math.isNaN(value))
			return entry.minimum;
		return value < entry.minimum ? entry.minimum : (value > entry.maximum ? entry.maximum : value);
	}

	function get_value():Float {
		return entry.value;
	}

	function set_value(value:Float):Float {
		var kept = within(entry, value);
		Options.set(entry, kept);
		return kept;
	}

	/** The value changed: set by the player in the menu, by its reset, or by the mod. In town or during a run. */
	public function onChange(handler:Float->Void):Subscription {
		return Hub.listen(entry.owner.core, entry.event, handler);
	}
}
