package mods.api.settings;

import mods.api.Subscription;
import mods.api._internal.Entry;
import mods.api._internal.Hub;
import mods.api._internal.Options;

/**
 * An on/off option, declared with `Settings.flag`.
 *
 * @since 1.3
 */
class Flag {
	/** Its value now. Setting it shows in the menu and is kept, as when the player sets it. */
	public var value(get, set):Bool;

	var entry:Entry;

	@:allow(mods.api.settings.Settings)
	function new(entry:Entry) {
		this.entry = entry;
	}

	function get_value():Bool {
		return entry.value == true;
	}

	function set_value(value:Bool):Bool {
		Options.set(entry, value);
		return value;
	}

	/**
	 * The value changed, with the new one: set by the player in the menu, by the menu's reset, or by the
	 * mod. In town or during a run.
	 */
	public function onChange(handler:Bool->Void):Subscription {
		return Hub.listen(entry.owner.core, entry.event, handler);
	}
}
