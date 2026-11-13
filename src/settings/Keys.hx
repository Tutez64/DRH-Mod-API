package mods.api.settings;

import input.keyBindings.KeyBindings;
import modding.ModContext;
import mods.api._internal.Entry;
import mods.api._internal.ModOptions;
import mods.api._internal.Options;

/**
 * `context.keys`: a mod's key actions, which the player rebinds in the CONTROLS tab of the game's
 * settings menu. Declare them in `init`.
 *
 * A mod is told when its action is pressed: it never reads a key code. A key is one action's, the
 * game's own included: binding one takes it from the action that had it, and an action whose key is
 * already held when it is declared starts with none.
 */
class Keys {
	var owner:ModOptions;

	@:allow(mods.api.Context)
	function new(core:ModContext) {
		owner = Options.of(core);
	}

	/**
	 * An action, with the key it has until the player changes it: an OpenFL key code, such as
	 * `Keyboard.F6`. Escape, Enter, F8 and F11 cannot be bound.
	 *
	 * `shift`, `ctrl` and `alt` are the modifiers a press needs held. The player cannot change them yet
	 * and will later, so the action must make sense without them.
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
