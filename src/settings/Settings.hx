package mods.api.settings;

import modding.ModContext;
import mods.api._internal.Entry;
import mods.api._internal.ModOptions;
import mods.api._internal.Options;

/**
 * `context.settings`: a mod's options, shown in the game's settings menu and kept in the mod's data
 * folder. Declare them in `init`: each answers its value from then on.
 *
 * An `id` names the option in the mod's file: keep it across versions. The label and the description
 * are what the menu shows, the label after the mod's name.
 */
class Settings {
	var owner:ModOptions;

	@:allow(mods.api.Context)
	function new(core:ModContext) {
		owner = Options.of(core);
	}

	/** An on/off option. */
	public function flag(id:String, label:String, description:String, defaultValue:Bool = false):Flag {
		var entry = owner.add(Entry.FLAG, id, label, description);
		entry.defaultValue = defaultValue;
		var stored:Dynamic = owner.storedOption(id);
		entry.value = Std.isOfType(stored, Bool) ? stored : defaultValue;
		Options.declared(entry);
		return new Flag(entry);
	}

	/**
	 * One value among several: `choices` gives each value and the label the menu shows for it, such as
	 * `[{value: "en", label: "English"}, {value: "es", label: "Spanish"}]`.
	 */
	public function choice(id:String, label:String, description:String, choices:Array<Dynamic>, defaultValue:String):Choice {
		if (choices == null || choices.length == 0)
			throw "option " + id + ": no choices";
		var values:Array<String> = [];
		var labels:Array<String> = [];
		for (item in choices) {
			var value:Dynamic = item == null ? null : item.value;
			var shown:Dynamic = item == null ? null : item.label;
			if (!Std.isOfType(value, String) || !Std.isOfType(shown, String) || shown == "")
				throw "option " + id + ": a choice needs a value and a label, both text";
			// The menu shows labels in capitals, and tells the choices apart by them.
			var upper:String = (shown : String).toUpperCase();
			if (values.indexOf(value) >= 0 || labels.indexOf(upper) >= 0)
				throw "option " + id + ": choice " + value + " given twice";
			values.push(value);
			labels.push(upper);
		}
		if (values.indexOf(defaultValue) < 0)
			throw "option " + id + ": its default is not one of its choices";
		var entry = owner.add(Entry.CHOICE, id, label, description);
		entry.values = values;
		entry.labels = labels;
		entry.defaultValue = defaultValue;
		var stored:Dynamic = owner.storedOption(id);
		entry.value = Std.isOfType(stored, String) && values.indexOf(stored) >= 0 ? stored : defaultValue;
		Options.declared(entry);
		return new Choice(entry);
	}

	/** A number from `minimum` to `maximum` by `step`, shown with `decimals` digits after the point. */
	public function slider(id:String, label:String, description:String, minimum:Float, maximum:Float, step:Float, defaultValue:Float,
			decimals:Int = 0):Slider {
		if (!(maximum > minimum) || !(step > 0))
			throw "option " + id + ": its range is empty";
		var entry = owner.add(Entry.SLIDER, id, label, description);
		entry.minimum = minimum;
		entry.maximum = maximum;
		entry.step = step;
		entry.decimals = decimals < 0 ? 0 : decimals;
		entry.defaultValue = Slider.within(entry, defaultValue);
		var stored:Dynamic = owner.storedOption(id);
		entry.value = Std.isOfType(stored, Float) ? Slider.within(entry, stored) : entry.defaultValue;
		Options.declared(entry);
		return new Slider(entry);
	}
}
