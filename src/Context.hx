package mods.api;

import modding.ModContext;
import mods.api._internal.Hub;
import mods.api.dungeon.Floor;
import mods.api.dungeon.Hero;
import mods.api.dungeon.Monster;
import mods.api.settings.Keys;
import mods.api.settings.Settings;
import openfl.display.Sprite;

/**
 * What `init` and `ready` receive.
 *
 * Each `on...` subscribes a handler to an event and returns its `Subscription`. A null handler is refused.
 *
 * Order: `init`, `onTablesLoaded`, `ready`, then everything else. A hero and a monster always come
 * after their floor. Town has neither. A monster's events hand it copied at that moment: tell one from
 * another by its `id`.
 *
 * @since 1.0
 */
class Context {
	/**
	 * This mod's layer, an OpenFL `Sprite` above the game and its letterbox, stacked in load order.
	 * Removed if the mod fails.
	 */
	public var overlay(get, never):Sprite;

	/**
	 * This mod's `Resources/` folder, absolute and without a trailing slash: its own files, such as
	 * `BitmapData.fromFile(resources + "/icon.png")`, the only ones its release holds besides its code.
	 * They never replace the game's.
	 */
	public var resources(get, never):String;

	/**
	 * This mod's folder to write in, absolute and without a trailing slash, created on first read:
	 * anything it keeps. Kept when the mod is updated or uninstalled. Its `settings.json` is the
	 * `api`'s, for `Settings` and `Keys`.
	 */
	public var data(get, never):String;

	/** The live game, shared by every mod. */
	public var state(get, never):State;

	/** Size of the game's view in overlay coordinates; 0 before `ready`. */
	public var viewWidth(get, never):Float;
	public var viewHeight(get, never):Float;

	/**
	 * This mod's options, shown in the game's settings menu.
	 * @since 1.3
	 */
	public var settings(get, never):Settings;

	/**
	 * This mod's key actions, which the player rebinds.
	 * @since 1.3
	 */
	public var keys(get, never):Keys;

	/** The core this context wraps: [beyond the `api`](#beyond-the-api). */
	public var core(default, null):ModContext;

	var heldSettings:Null<Settings>;

	var heldKeys:Null<Keys>;

	@:allow(mods.api.Mod)
	function new(core:ModContext) {
		this.core = core;
	}

	function get_overlay():Sprite {
		return core.overlay;
	}

	function get_resources():String {
		return core.resources;
	}

	function get_data():String {
		return core.data;
	}

	function get_state():State {
		return Hub.state;
	}

	function get_viewWidth():Float {
		return core.viewWidth;
	}

	function get_viewHeight():Float {
		return core.viewHeight;
	}

	function get_settings():Settings {
		if (heldSettings == null)
			heldSettings = new Settings(core);
		return heldSettings;
	}

	function get_keys():Keys {
		if (heldKeys == null)
			heldKeys = new Keys(core);
		return heldKeys;
	}

	/** Writes `mod <id>: <message>` to the game's log, and to the output of `--run-mod`. */
	public function log(message:String):Void {
		core.log(message);
	}

	/**
	 * Whether the mod of that id runs: enabled, started, and not failed since. Ask from `ready` on: in
	 * `init`, a mod that starts after this one is not there yet.
	 * @since 1.5
	 */
	public function isActive(id:String):Bool {
		return Hub.active(id);
	}

	/**
	 * The game's tables are in, the account is not read against them yet. Before `ready`, so subscribe
	 * in `init`.
	 */
	public function onTablesLoaded(handler:Void->Void):Subscription {
		return Hub.listen(core, Hub.TABLES_LOADED, handler == null ? null : function(_:Dynamic) handler());
	}

	/** Town entered, including a return from a dungeon. */
	public function onTownEnter(handler:Void->Void):Subscription {
		return Hub.listen(core, Hub.TOWN_ENTER, handler == null ? null : function(_:Dynamic) handler());
	}

	/** Town left. */
	public function onTownExit(handler:Void->Void):Subscription {
		return Hub.listen(core, Hub.TOWN_EXIT, handler == null ? null : function(_:Dynamic) handler());
	}

	/** A dungeon floor starts, its grid built and its `map` set (its art may still be loading). */
	public function onFloorEnter(handler:Floor->Void):Subscription {
		return Hub.listen(core, Hub.FLOOR_ENTER, handler);
	}

	/** A dungeon floor ends. */
	public function onFloorExit(handler:Floor->Void):Subscription {
		return Hub.listen(core, Hub.FLOOR_EXIT, handler);
	}

	/**
	 * A hero, local or of another player, is on a dungeon floor and ready. Always after its floor's
	 * `onFloorEnter`.
	 */
	public function onHeroSpawned(handler:Hero->Void):Subscription {
		return Hub.listen(core, Hub.HERO_SPAWNED, handler);
	}

	/** A hero leaves the floor. It still reads in the handlers, empty after them. */
	public function onHeroDespawned(handler:Hero->Void):Subscription {
		return Hub.listen(core, Hub.HERO_DESPAWNED, handler);
	}

	/**
	 * An enemy of the heroes, as `Floor.monsters` lists them, is ready on the floor. Always after its
	 * floor's `onFloorEnter`.
	 * @since 1.5
	 */
	public function onMonsterSpawned(handler:Monster->Void):Subscription {
		return Hub.listen(core, Hub.MONSTER_SPAWNED, handler);
	}

	/**
	 * The hit points of a monster told as spawned changed, down or up.
	 * @since 1.5
	 */
	public function onMonsterHurt(handler:Monster->Void):Subscription {
		return Hub.listen(core, Hub.MONSTER_HURT, handler);
	}

	/**
	 * A monster told as spawned died or left, or its floor ends: once for each, before its floor's
	 * `onFloorExit`.
	 * @since 1.5
	 */
	public function onMonsterDespawned(handler:Monster->Void):Subscription {
		return Hub.listen(core, Hub.MONSTER_DESPAWNED, handler);
	}

	/**
	 * A key goes down, with its OpenFL key code: once per press, not for a held key's repeats, not while
	 * a text field such as the chat has focus. Return true to keep the key: the game never sees that
	 * press, neither its own shortcuts (Enter opening the chat) nor OpenFL's (Tab moving the focus), nor
	 * its repeats and release. For the keys of a mod's own window while it is open, such as Enter and
	 * Escape: a shortcut is a key action of `Keys`.
	 */
	public function onKeyDown(handler:UInt->Bool):Subscription {
		return Hub.listen(core, Hub.KEY_DOWN, handler);
	}
}
