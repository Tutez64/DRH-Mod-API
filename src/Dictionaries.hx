package mods.api;

/**
 * Reads and writes a dictionary of the game (`ASDictionary` in its classes), met
 * [beyond the `api`](#beyond-the-api).
 *
 * The game keeps the entries whose key is a text, a number or a boolean apart from the others. A mod's
 * own `dictionary[key]`, `get`, `set`, `exists`, `remove`, `keys` and loops on it do not reach them:
 * what the game wrote the mod does not see, and what a mod writes the game does not find. These reach
 * every entry, whatever its key. Anything that is not a dictionary is refused with a throw.
 *
 * @since 1.4
 */
class Dictionaries {
	/** The game's own functions, reached by name: its dictionary type has no form a mod can name. */
	static var game:Dynamic = Type.resolveClass("_ASDictionary.ASDictionary_Impl_");

	/** What the game takes for a dictionary: any map, under the name it has once built. */
	static var type:Dynamic = Type.resolveClass("haxe.IMap");

	static var getIn:Dynamic = Reflect.field(game, "getIn");

	static var setIn:Dynamic = Reflect.field(game, "setIn");

	static var existsIn:Dynamic = Reflect.field(game, "existsIn");

	static var removeIn:Dynamic = Reflect.field(game, "removeIn");

	static var keysIn:Dynamic = Reflect.field(game, "keysIn");

	static var valuesIn:Dynamic = Reflect.field(game, "valuesIn");

	/** The value under the key, null when there is none. */
	public static function get(dictionary:Dynamic, key:Dynamic):Dynamic {
		return exists(dictionary, key) ? Reflect.callMethod(game, getIn, [dictionary, key]) : null;
	}

	/** Puts the value under the key. */
	public static function set(dictionary:Dynamic, key:Dynamic, value:Dynamic):Void {
		Reflect.callMethod(game, setIn, [checked(dictionary), key, value]);
	}

	/** Whether there is an entry under the key. */
	public static function exists(dictionary:Dynamic, key:Dynamic):Bool {
		return Reflect.callMethod(game, existsIn, [checked(dictionary), key]);
	}

	/** Removes the entry; whether there was one. */
	public static function remove(dictionary:Dynamic, key:Dynamic):Bool {
		return Reflect.callMethod(game, removeIn, [checked(dictionary), key]);
	}

	/** Every key. A copy. */
	public static function keys(dictionary:Dynamic):Array<Dynamic> {
		return collect(Reflect.callMethod(game, keysIn, [checked(dictionary)]));
	}

	/** Every value. A copy. */
	public static function values(dictionary:Dynamic):Array<Dynamic> {
		return collect(Reflect.callMethod(game, valuesIn, [checked(dictionary)]));
	}

	static function checked(dictionary:Dynamic):Dynamic {
		if (!Std.isOfType(dictionary, type))
			throw "not a dictionary: " + Std.string(dictionary);
		return dictionary;
	}

	static function collect(iterator:Iterator<Dynamic>):Array<Dynamic> {
		var all:Array<Dynamic> = [];
		while (iterator.hasNext())
			all.push(iterator.next());
		return all;
	}
}
