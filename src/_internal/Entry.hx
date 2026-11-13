package mods.api._internal;

import settings.model.SettingDefinition;

/** One option or key action a mod declared, and where it stands: its value, and its row in the game's menu once it has one. */
class Entry {
	public static inline final FLAG = 0;

	public static inline final CHOICE = 1;

	public static inline final SLIDER = 2;

	public static inline final KEY = 3;

	public var owner:ModOptions;

	public var kind:Int;

	/** As the mod names it, unique among its options, or among its actions. */
	public var id:String;

	public var label:String;

	public var description:String;

	/** A flag's `Bool`, a choice's declared value, a slider's `Float`. Unused by a key. */
	public var defaultValue:Dynamic;

	public var value:Dynamic;

	/** A choice's declared values and what the menu shows for each. */
	public var values:Array<String> = [];

	public var labels:Array<String> = [];

	public var minimum:Float = 0;

	public var maximum:Float = 1;

	public var step:Float = 1;

	public var decimals:Int = 0;

	/** A key action's two slots, 0 for none, and the key it declared. */
	public var key:Int = 0;

	public var alternate:Int = 0;

	public var defaultKey:Int = 0;

	/**
	 * The key it wanted and left to the action that held it, 0 for none: what its file keeps, so that it
	 * has the key again once nobody else does.
	 */
	public var yielded:Int = 0;

	/** The modifiers the action declared, which a press needs held. */
	public var shift:Bool = false;

	public var ctrl:Bool = false;

	public var alt:Bool = false;

	/** Its definition in the game's catalog, null until the game has its settings and once the mod failed. */
	public var definition:Null<SettingDefinition>;

	/** The name its handlers listen under. */
	public var event:String;

	public function new(owner:ModOptions, kind:Int, id:String, label:String, description:String) {
		this.owner = owner;
		this.kind = kind;
		this.id = id;
		this.label = label;
		this.description = description;
		event = (kind == KEY ? "key:" : "option:") + owner.id + "." + id;
	}

	/** The id of its definition in the game's catalog, where every mod's and the game's share one space. */
	public function gameId():String {
		return "mods." + owner.id + (kind == KEY ? ".key." : ".") + id;
	}

	/** The label of a choice's value, the default's when the value is not one of them. */
	public function labelOf(value:Dynamic):String {
		var index = values.indexOf(Std.string(value));
		if (index < 0)
			index = values.indexOf(Std.string(defaultValue));
		return index < 0 ? "" : labels[index];
	}
}
