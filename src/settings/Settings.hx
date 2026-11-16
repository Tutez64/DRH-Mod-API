package mods.api.settings;

import modding.ModContext;
import mods.api._internal.Entry;
import mods.api._internal.ModOptions;
import mods.api._internal.Options;

/**
 * `context.settings` declares a mod's options. The game's settings menu shows them in its MODS tab
 * (ADVANCED before DRH 18, which has no such tab), under a header with the mod's name, and the player
 * sets them there as the game's own. Declare them in `init`: each answers its value from then on, read
 * from the mod's `settings.json`.
 *
 * `id` names the option in the mod's file: unique among the mod's options, and the same across its
 * versions. Another mod may use the same. `label` is the row's title, shown in capitals on one line:
 * about 15 characters fit a slider, 19 the others, and a longer one is made smaller, then cut.
 * `description` shows under a flag's label only: the game's rows for a choice, a slider and a key have
 * no room for one. A declaration that cannot be shown throws: an id declared twice, no choices, a
 * default that is not one of them, an empty range.
 *
 * The menu's reset puts every option back to its declared default. An option the mod no longer
 * declares stays in the file, ignored.
 *
 * The file is the `api`'s: it writes it whole at the first change, and nothing else stays in it. A mod
 * that kept a `settings.json` of its own before reads it in `init`, then gives each option the value it
 * had (`flag.value = ...`), so the player's choices carry over; whatever else it kept there goes to
 * another file.
 *
 * @since 1.3
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
	 * One value among `choices`, each `{value, label}`, both text:
	 * `[{value: "en", label: "English"}, {value: "es", label: "Spanish"}]`. The menu shows the labels, in
	 * capitals, and they differ.
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

	/** A number in a range, shown with `decimals` digits after the point. */
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

	/**
	 * A row that is a button, with `caption` written on it, such as one that opens the mod's own window.
	 * It holds no value.
	 * @since 1.4
	 */
	public function button(id:String, label:String, caption:String):Button {
		var entry = owner.add(Entry.BUTTON, id, label, "");
		entry.caption = caption == null ? "" : caption;
		Options.declared(entry);
		return new Button(entry);
	}
}
