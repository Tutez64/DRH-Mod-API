package mods.api._internal;

import haxe.Json;
import modding.ModContext;
import sys.FileSystem;
import sys.io.File;

/**
 * One mod's options and key actions, and the file that keeps them: `settings.json` in its data folder,
 * `options` by id and `keys` by id, each a key, its alternate and its modifiers. The file is written
 * whole, on the first change: nothing else stays in it.
 */
class ModOptions {
	static inline final FILE = "settings.json";

	public var core:ModContext;

	public var id:String;

	/** The mod's name as its `mod.json` gives it, its id without one. */
	public var name:String;

	public var entries:Array<Entry> = [];

	/** The file's two parts, read on the first declaration: an entry no longer declared stays in them. */
	var options:Dynamic;

	var keys:Dynamic;

	public function new(core:ModContext) {
		this.core = core;
		id = @:privateAccess core.id;
		name = id;
		try {
			var manifest:Dynamic = Json.parse(File.getContent(haxe.io.Path.directory(core.resources) + "/mod.json"));
			if (manifest != null && Std.isOfType(manifest.name, String) && manifest.name != "")
				name = manifest.name;
		} catch (e:Dynamic) {}
	}

	public function find(kind:Int, id:String):Null<Entry> {
		for (entry in entries)
			if (entry.id == id && (entry.kind == Entry.KEY) == (kind == Entry.KEY))
				return entry;
		return null;
	}

	/** A new entry, refused without an id or with one the mod already declared. */
	public function add(kind:Int, id:String, label:String, description:String):Entry {
		var what = kind == Entry.KEY ? "key action" : "option";
		if (id == null || id == "")
			throw what + ": id is empty";
		if (find(kind, id) != null)
			throw what + " " + id + ": declared twice";
		var entry = new Entry(this, kind, id, label == null || label == "" ? id : label, description == null ? "" : description);
		entries.push(entry);
		return entry;
	}

	/** What the file holds for an option, null for nothing. */
	public function storedOption(id:String):Dynamic {
		load();
		return Reflect.field(options, id);
	}

	public function storedKey(id:String):Dynamic {
		load();
		return Reflect.field(keys, id);
	}

	/** Reads the file's two parts once; anything else it holds is not kept. */
	function load():Void {
		if (options != null)
			return;
		options = {};
		keys = {};
		try {
			var path = core.data + "/" + FILE;
			if (!FileSystem.exists(path))
				return;
			var held:Dynamic = Json.parse(File.getContent(path));
			if (isObject(held)) {
				if (isObject(held.options))
					options = held.options;
				if (isObject(held.keys))
					keys = held.keys;
			}
		} catch (e:Dynamic) {
			core.log("settings: could not read " + FILE + ", the defaults apply: " + Std.string(e));
		}
	}

	static function isObject(held:Dynamic):Bool {
		return held != null && Reflect.isObject(held) && !Std.isOfType(held, String) && !Std.isOfType(held, Array);
	}

	/** Writes the file whole: every declared entry, over what it held for it. */
	public function save():Void {
		load();
		for (entry in entries) {
			if (entry.kind == Entry.KEY)
				Reflect.setField(keys, entry.id, {
					key: entry.key != 0 ? entry.key : entry.yielded,
					alternate: entry.alternate,
					shift: entry.shift,
					ctrl: entry.ctrl,
					alt: entry.alt
				});
			else
				Reflect.setField(options, entry.id, entry.value);
		}
		try {
			File.saveContent(core.data + "/" + FILE, Json.stringify({options: options, keys: keys}, null, "\t"));
		} catch (e:Dynamic) {
			core.log("settings: could not write " + FILE + ": " + Std.string(e));
		}
	}
}
