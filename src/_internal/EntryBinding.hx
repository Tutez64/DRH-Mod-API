package mods.api._internal;

import settings.model.bindings.ISettingBinding;

/** What the game's settings read and write an entry through: its value changes here whoever set it. */
class EntryBinding implements ISettingBinding {
	var entry:Entry;

	public function new(entry:Entry) {
		this.entry = entry;
	}

	public function read():Dynamic {
		return Options.modelValue(entry);
	}

	public function write(value:Dynamic):Void {
		Options.fromModel(entry, value);
	}

	public function writeInitial(value:Dynamic):Void {
		Options.fromModel(entry, value);
	}

	public function destroy():Void {}
}
