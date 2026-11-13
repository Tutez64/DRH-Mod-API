package mods.api._internal;

import input.keyBindings.KeyNames;
import modding.ModContext;
import openfl.Vector;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import settings.model.KeyBindingValue;
import settings.model.SettingBuilder;
import settings.model.SettingDefinition;
import settings.model.SettingsModel;

/**
 * Every mod's options and key actions, shown in the game's own settings menu. Not for mods: they go
 * through `Context.settings` and `Context.keys`.
 *
 * Each entry becomes a definition of the game's settings catalog, with the game's own row: key actions
 * at the end of CONTROLS, options in ADVANCED, a mod's together under a header (`OptionsMenu`). The game then does the
 * rest: its menu, its reset, and its rule that a key is one action's, the game's own included. A value
 * is the mod's all along, kept in its data folder; the game reads and writes it through the entry's
 * binding.
 */
@:allow(mods.api)
class Options {
	static inline final OPTIONS_CATEGORY = "advanced";

	static inline final KEYS_CATEGORY = "controls";

	/** The game's settings menu and its reset confirmation, where a key pressed is one being picked. */
	static inline final MENU_LAYER = "SETTINGS_MENU";

	static inline final RESET_LAYER = "SETTINGS_RESET_CONFIRM_POPUP";

	/** In the order the mods declared first, which is their load order. */
	static var mods:Array<ModOptions> = [];

	/** The game's settings, null before `ready`. */
	static var model:Null<SettingsModel>;

	static var keysHooked:Bool = false;

	static var shiftDown:Bool = false;

	static var ctrlDown:Bool = false;

	static var altDown:Bool = false;

	/** The keys held now, by key code. */
	static var held:Map<Int, Bool> = new Map();

	static function of(core:ModContext):ModOptions {
		for (mod in mods)
			if (mod.core == core)
				return mod;
		var mod = new ModOptions(core);
		mods.push(mod);
		return mod;
	}

	/** A declared entry is in: in the menu at once when the game has its settings, at `ready` otherwise. */
	static function declared(entry:Entry):Void {
		if (entry.kind == Entry.KEY && !keysHooked && Hub.core != null) {
			keysHooked = true;
			Hub.core.onKeyDown(keyDown);
		}
		if (model != null)
			show(entry);
	}

	/** The game exists: its settings take every entry declared so far, and the keyboard is watched. */
	static function ready():Void {
		var facade = Hub.facade();
		if (facade == null)
			return;
		try {
			model = facade.settingsModel;
			for (mod in mods)
				for (entry in mod.entries)
					show(entry);
		} catch (e:Dynamic) {
			model = null;
			Hub.log("settings: the game's menu does not take the mods' options: " + Std.string(e));
		}
		// Before the core's own listener (1000), which calls `keyDown`.
		facade.stageRef.addEventListener(KeyboardEvent.KEY_DOWN, stageKeyDown, false, 1001);
		facade.stageRef.addEventListener(KeyboardEvent.KEY_UP, stageKeyUp, false, 1001);
		facade.stageRef.addEventListener(Event.DEACTIVATE, deactivated);
		OptionsMenu.start();
	}

	static function stageKeyDown(event:KeyboardEvent):Void {
		modifiers(event);
		held.set(event.keyCode, true);
	}

	static function stageKeyUp(event:KeyboardEvent):Void {
		modifiers(event);
		held.remove(event.keyCode);
	}

	static function modifiers(event:KeyboardEvent):Void {
		shiftDown = event.shiftKey;
		ctrlDown = event.ctrlKey;
		altDown = event.altKey;
	}

	static function deactivated(event:Event):Void {
		shiftDown = ctrlDown = altDown = false;
		held = new Map();
	}

	/** The entry's definition, placed in the game's catalog after its mod's others of the same tab. */
	static function show(entry:Entry):Void {
		if (model == null || entry.definition != null || !entry.owner.core.alive)
			return;
		var isKey = entry.kind == Entry.KEY;
		var builder = new SettingBuilder(entry.gameId(), isKey ? KEYS_CATEGORY : OPTIONS_CATEGORY).literalText(title(entry, OptionsMenu.failed), entry.description)
			.boundTo(new EntryBinding(entry));
		if (isKey) {
			unbindTaken(entry);
			// A key left to its holder is not this action's default either: the row's own reset would
			// take it back from the holder, one of the game's keys for instance.
			builder.defaultsTo(KeyBindingValue.make(entry.yielded == entry.defaultKey ? 0 : entry.defaultKey, 0)).keyBinding(entry.gameId());
		} else if (entry.kind == Entry.CHOICE) {
			// The game shows a choice's value itself when it has no text key: the label is that value.
			builder.defaultsTo(entry.labelOf(entry.defaultValue));
			for (label in entry.labels)
				builder.choice(label, "");
		} else if (entry.kind == Entry.SLIDER) {
			builder.defaultsTo(entry.defaultValue).range(entry.minimum, entry.maximum, entry.step).displayedAs(1, entry.decimals);
		} else {
			builder.defaultsTo(entry.defaultValue == true);
		}
		var definition = builder.build();
		if (definition.choices != null)
			for (i in 0...definition.choices.length)
				definition.choices[i].labelKey = null;

		var catalog = model.catalog;
		var definitions:Vector<SettingDefinition> = @:privateAccess catalog.mDefinitions;
		var prefix = "mods." + entry.owner.id + ".";
		var after = -1;
		for (i in 0...definitions.length)
			if (definitions[i].category == definition.category && StringTools.startsWith(definitions[i].id, prefix))
				after = i;
		if (after < 0 || after == definitions.length - 1)
			definitions.push(definition);
		else
			definitions.insertAt(after + 1, definition);
		dictionary("setIn", [@:privateAccess catalog.mDefinitionsById, definition.id, definition]);
		entry.definition = definition;
		var value:Dynamic = modelValue(entry);
		Reflect.setField(@:privateAccess model.mValues, definition.id, value);
		Reflect.setField(@:privateAccess model.mLoadedValues, definition.id, value);
	}

	/** What an entry's row is called: its label, after its mod's name when the menu shows no header for it. */
	static function title(entry:Entry, named:Bool):String {
		var title = ((named ? entry.owner.name + ": " : "") + entry.label).toUpperCase();
		if (entry.kind == Entry.KEY && (entry.shift || entry.ctrl || entry.alt))
			title += " (" + modifiersLabel(entry) + ")";
		return title;
	}

	/** Without headers, each row says whose it is. */
	static function nameRows():Void {
		for (mod in mods)
			for (entry in mod.entries)
				if (entry.definition != null)
					entry.definition.labelText = title(entry, true);
	}

	/** The entry a definition of the game's catalog stands for, null for one of the game's own. */
	static function entryOf(definition:Null<SettingDefinition>):Null<Entry> {
		if (definition == null)
			return null;
		for (mod in mods)
			for (entry in mod.entries)
				if (entry.definition == definition)
					return entry;
		return null;
	}

	/** Takes a mod's entries out of the menu, once it failed. */
	static function hideFailed():Void {
		if (model == null)
			return;
		for (mod in mods) {
			if (mod.core.alive)
				continue;
			for (entry in mod.entries)
				hide(entry);
		}
	}

	static function hide(entry:Entry):Void {
		var definition = entry.definition;
		if (definition == null || model == null)
			return;
		entry.definition = null;
		var catalog = model.catalog;
		var definitions:Vector<SettingDefinition> = @:privateAccess catalog.mDefinitions;
		var at = definitions.indexOf(definition);
		if (at >= 0)
			definitions.splice(at, 1);
		dictionary("removeIn", [@:privateAccess catalog.mDefinitionsById, definition.id]);
	}

	/**
	 * The catalog's dictionary keeps a text key apart from the others, through functions of its own that
	 * a mod can only reach by name.
	 */
	static function dictionary(name:String, arguments:Array<Dynamic>):Dynamic {
		var type:Dynamic = Type.resolveClass("_ASDictionary.ASDictionary_Impl_");
		return Reflect.callMethod(type, Reflect.field(type, name), arguments);
	}

	/** A key another action holds, the game's or a mod's shown before, is not this entry's as well. */
	static function unbindTaken(entry:Entry):Void {
		if (entry.key != 0 && holder(entry.key, null) != null) {
			entry.owner.core.log("key " + KeyNames.displayName(entry.key) + " of " + entry.id + " is taken: left unassigned");
			entry.yielded = entry.key;
			entry.key = 0;
		}
		if (entry.alternate != 0 && holder(entry.alternate, null) != null)
			entry.alternate = 0;
	}

	/** The id of a key action other than `except` that holds the key, in the game's settings. */
	static function holder(key:Int, except:Null<SettingDefinition>):Null<String> {
		var definitions:Vector<SettingDefinition> = @:privateAccess model.catalog.mDefinitions;
		var values:Dynamic = @:privateAccess model.mValues;
		for (i in 0...definitions.length) {
			var definition = definitions[i];
			if (definition == except || !definition.isKeyBinding)
				continue;
			var value:Dynamic = Reflect.field(values, definition.id);
			if (value != null && (KeyBindingValue.primary(value) == key || KeyBindingValue.alternate(value) == key))
				return definition.id;
		}
		return null;
	}

	/** An entry's value as the game's settings hold it. */
	static function modelValue(entry:Entry):Dynamic {
		if (entry.kind == Entry.KEY)
			return KeyBindingValue.make(entry.key, entry.alternate);
		if (entry.kind == Entry.CHOICE)
			return entry.labelOf(entry.value);
		return entry.value;
	}

	/** The game's settings gave an entry a value: the player in the menu, its reset, or `set`. */
	static function fromModel(entry:Entry, value:Dynamic):Void {
		if (entry.kind == Entry.KEY) {
			var key = KeyBindingValue.primary(value);
			var alternate = KeyBindingValue.alternate(value);
			// Assigning a key in the menu takes it from its holder first. A key someone still holds was
			// given another way, the reset to every default: it stays the holder's.
			if (model != null && entry.definition != null) {
				var freed = value;
				var left = 0;
				if (key != 0 && holder(key, entry.definition) != null) {
					freed = KeyBindingValue.withSlot(freed, KeyBindingValue.PRIMARY, 0);
					left = key;
				}
				if (alternate != 0 && holder(alternate, entry.definition) != null)
					freed = KeyBindingValue.withSlot(freed, KeyBindingValue.ALTERNATE, 0);
				if (!KeyBindingValue.equals(freed, value)) {
					model.setValue(entry.definition.id, freed);
					if (left != 0 && entry.key == 0) {
						entry.yielded = left;
						entry.owner.save();
					}
					return;
				}
			}
			if (key == entry.key && alternate == entry.alternate)
				return;
			entry.key = key;
			entry.alternate = alternate;
			entry.yielded = 0;
			entry.owner.save();
			return;
		}
		var changed:Dynamic = value;
		if (entry.kind == Entry.CHOICE) {
			var index = entry.labels.indexOf(Std.string(value));
			changed = index < 0 ? entry.defaultValue : entry.values[index];
		} else if (entry.kind == Entry.SLIDER) {
			var number:Float = value;
			changed = Math.isNaN(number) ? entry.defaultValue : number;
		} else {
			changed = value == true;
		}
		if (changed == entry.value)
			return;
		entry.value = changed;
		entry.owner.save();
		Hub.emit(entry.event, changed);
	}

	/** A mod sets its own option: through the game's settings when the entry is in, so the menu shows it. */
	static function set(entry:Entry, value:Dynamic):Void {
		if (value == entry.value)
			return;
		if (model != null && entry.definition != null) {
			var previous:Dynamic = entry.value;
			entry.value = value;
			var shown:Dynamic = modelValue(entry);
			entry.value = previous;
			model.setValue(entry.definition.id, shown);
			return;
		}
		entry.value = value;
		entry.owner.save();
		Hub.emit(entry.event, value);
	}

	/** A key went down: the actions bound to it are pressed, unless the settings menu is taking it. */
	static function keyDown(code:UInt):Bool {
		hideFailed();
		var key:Int = code;
		if (key == 0 || picking())
			return false;
		var kept = false;
		for (mod in mods) {
			if (!mod.core.alive)
				continue;
			for (entry in mod.entries) {
				if (entry.kind != Entry.KEY || (entry.key != key && entry.alternate != key) || !modifiersHeld(entry))
					continue;
				if (listened(entry.event)) {
					kept = true;
					Hub.emit(entry.event, null);
				}
			}
		}
		return kept;
	}

	static function listened(event:String):Bool {
		var list = Hub.listeners.get(event);
		if (list == null)
			return false;
		for (subscription in list)
			if (subscription.active)
				return true;
		return false;
	}

	static function picking():Bool {
		var facade = Hub.facade();
		if (facade == null || facade.menuNavigationController == null)
			return false;
		var layer = facade.menuNavigationController.getTopUILayer();
		return layer == MENU_LAYER || layer == RESET_LAYER;
	}

	static function modifiersHeld(entry:Entry):Bool {
		return (!entry.shift || shiftDown) && (!entry.ctrl || ctrlDown) && (!entry.alt || altDown);
	}

	static function isHeld(entry:Entry):Bool {
		if (!entry.owner.core.alive || !modifiersHeld(entry))
			return false;
		return (entry.key != 0 && held.exists(entry.key)) || (entry.alternate != 0 && held.exists(entry.alternate));
	}

	static function modifiersLabel(entry:Entry):String {
		return (entry.ctrl ? "CTRL+" : "") + (entry.alt ? "ALT+" : "") + (entry.shift ? "SHIFT+" : "");
	}

	/** What is bound, as the menu names keys: "SHIFT+R", empty when nothing is. */
	static function keyLabel(entry:Entry):String {
		var key = entry.key != 0 ? entry.key : entry.alternate;
		return key == 0 ? "" : modifiersLabel(entry) + KeyNames.displayName(key);
	}
}
