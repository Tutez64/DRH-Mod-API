package mods.api;

import modding.ModContext;
import mods.api._internal.Hub;
import mods.api.dungeon.Floor;
import mods.api.dungeon.Hero;
import openfl.display.Sprite;

/**
 * What a mod receives in `init` and `ready`.
 *
 * Subscribe from `init` for `onTablesLoaded` (it fires before `ready`) and for anything that can happen
 * as the world appears. Each `on*` returns the subscription to cancel. A mod that fails stops receiving
 * events, and a handler's throw is only logged, under its mod.
 */
class Context {
	/** This mod's layer of the overlay, above the letterbox and stacked in load order. Removed if the mod fails. */
	public var overlay(get, never):Sprite;

	/**
	 * This mod's `Resources/` folder, absolute and without a trailing slash, where it reads its own
	 * files, such as `BitmapData.fromFile(resources + "/icon.png")`; the only ones its release holds
	 * besides its code. They never replace the game's.
	 */
	public var resources(get, never):String;

	/**
	 * This mod's folder to write in, such as its settings, absolute and without a trailing slash:
	 * `data/<id>/` in the mods folder, created on first read. Kept when the mod is updated or
	 * uninstalled, unlike its own folder.
	 */
	public var data(get, never):String;

	/** The live window: account, floor, heroes, players. Shared by every mod. */
	public var state(get, never):State;

	/** Size of the game's view in overlay coordinates. 0 before `ready`. */
	public var viewWidth(get, never):Float;

	public var viewHeight(get, never):Float;

	/** The core this context wraps. Using it is `extends`: it is not covered by the `api` version. */
	public var core(default, null):ModContext;

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

	public function log(message:String):Void {
		core.log(message);
	}

	/** A hero, local or remote, is on a dungeon floor and initialised. Not town. Always after that floor's `onFloorEnter`. */
	public function onHeroSpawned(handler:Hero->Void):Subscription {
		return Hub.listen(core, Hub.HERO_SPAWNED, handler);
	}

	/** A hero leaves the floor. Its wrapper still reads it in the handlers, empty after them; its player stays. */
	public function onHeroDespawned(handler:Hero->Void):Subscription {
		return Hub.listen(core, Hub.HERO_DESPAWNED, handler);
	}

	/** A dungeon floor starts: its grid is built and its map node set. Art may still be loading. */
	public function onFloorEnter(handler:Floor->Void):Subscription {
		return Hub.listen(core, Hub.FLOOR_ENTER, handler);
	}

	public function onFloorExit(handler:Floor->Void):Subscription {
		return Hub.listen(core, Hub.FLOOR_EXIT, handler);
	}

	/** Tables are in, the account is not parsed against them yet. Fires before `ready`. */
	public function onTablesLoaded(handler:Void->Void):Subscription {
		return Hub.listen(core, Hub.TABLES_LOADED, handler == null ? null : function(_:Dynamic) handler());
	}

	/** Town entered, including a return from a dungeon. */
	public function onTownEnter(handler:Void->Void):Subscription {
		return Hub.listen(core, Hub.TOWN_ENTER, handler == null ? null : function(_:Dynamic) handler());
	}

	public function onTownExit(handler:Void->Void):Subscription {
		return Hub.listen(core, Hub.TOWN_EXIT, handler == null ? null : function(_:Dynamic) handler());
	}

	/**
	 * A key goes down, with its key code: once per press, not for a held key's repeats, and not while a
	 * text field such as the chat has focus.
	 * Return true to keep the key: the game never sees that press, neither its own shortcuts (Enter
	 * opening the chat) nor OpenFL's (Tab moving the focus), nor its repeats and release.
	 */
	public function onKeyDown(handler:UInt->Bool):Subscription {
		return Hub.listen(core, Hub.KEY_DOWN, handler);
	}
}
