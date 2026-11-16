package mods.api.settings;

import input.keyBindings.KeyBindings;
import modding.ModContext;
import mods.api._internal.Entry;
import mods.api._internal.ModOptions;
import mods.api._internal.Options;

/**
 * `context.keys` declares a mod's key actions. The game's settings menu shows them at the end of
 * CONTROLS, under a header with the mod's name, and the player rebinds them there. Declare them in
 * `init`.
 *
 * A mod never reads the key code: the player may have changed it, or given the action a second key.
 *
 * A key is one action's, the game's own included. Binding a key in the menu takes it from the action
 * that had it. An action whose key is already held when its mod loads, by the game or by a mod loaded
 * before, starts with none, and has it at a later start once it is free: do not declare a key the game
 * uses. The menu compares the key alone: R and Shift+R are the same key.
 *
 * @since 1.3
 */
class Keys {
	var owner:ModOptions;

	@:allow(mods.api.Context)
	function new(core:ModContext) {
		owner = Options.of(core);
	}

	/**
	 * A key action. `key` is the OpenFL key code it has until the player changes it, such as
	 * `Keyboard.F6`; Escape, Enter, F8 and F11 cannot be bound, and declaring one throws. `shift`, `ctrl`
	 * and `alt` are the modifiers a press needs held, which the row's title names (`RESTART (SHIFT+)`).
	 * The player cannot change them yet and will later: the action must make sense without them.
	 */
	public function action(id:String, label:String, description:String, key:UInt, shift:Bool = false, ctrl:Bool = false, alt:Bool = false):KeyAction {
		var code:Int = key;
		if (!KeyBindings.isBindable(code))
			throw "key action " + id + ": key " + code + " cannot be bound";
		var entry = owner.add(Entry.KEY, id, label, description);
		entry.defaultKey = code;
		entry.key = code;
		entry.shift = shift;
		entry.ctrl = ctrl;
		entry.alt = alt;
		var stored:Dynamic = owner.storedKey(id);
		if (stored != null && Reflect.isObject(stored)) {
			entry.key = slot(stored.key);
			entry.alternate = slot(stored.alternate);
		}
		Options.declared(entry);
		return new KeyAction(entry);
	}

	static function slot(stored:Dynamic):Int {
		if (!Std.isOfType(stored, Int))
			return 0;
		var code:Int = stored;
		return KeyBindings.isBindable(code) ? code : 0;
	}
}
