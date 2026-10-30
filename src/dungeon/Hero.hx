package mods.api.dungeon;

import distributedObjects.HeroGameObject;
import mods.api.account.Weapon;

/**
 * One hero on a dungeon floor: what a player plays there. Each floor gives a new one. Fields read
 * the live object and go empty after the `heroDespawned` handlers; the player behind it stays in `player`.
 */
class Hero {
	/** The hero's object id on the floor, not an account: see `player`. */
	public var id(default, null):UInt;

	/** True for the local player's hero. */
	public var local(default, null):Bool;

	/** The player playing this hero. Null only if the game sent no account for it. */
	public var player(default, null):Null<Player>;

	/** GameMaster hero class id, 0 once the hero is gone. */
	public var classId(get, never):UInt;

	/** Name of the hero class, as the game shows it. Empty once the hero is gone. */
	public var className(get, never):String;

	public var level(get, never):UInt;

	/** World position; 0 once the hero is gone. */
	public var x(get, never):Float;

	public var y(get, never):Float;

	/** Equipped weapons by slot, empty slots left out. A copy. */
	public var weapons(get, never):Array<Weapon>;

	var hero:HeroGameObject;

	@:allow(mods.api._internal.Hub)
	function new(hero:HeroGameObject, local:Bool, player:Null<Player>) {
		this.hero = hero;
		this.local = local;
		this.player = player;
		id = hero.id;
	}

	/** At `heroDespawned`, before its handlers: the player keeps what was last read and is no longer on it. */
	@:allow(mods.api._internal.Hub)
	function leave():Void {
		if (player != null && player.hero == this)
			player.setHero(null);
	}

	/** After the `heroDespawned` handlers: fields read empty from there on. */
	@:allow(mods.api._internal.Hub)
	function detach():Void {
		hero = null;
	}

	/** The game object while it is still there. */
	function live():Null<HeroGameObject> {
		return hero != null && !hero.isDestroyed ? hero : null;
	}

	function get_classId():UInt {
		var live = live();
		return live == null ? 0 : live.type;
	}

	function get_className():String {
		var live = live();
		var gm = live == null ? null : live.gMHero;
		return gm == null || gm.Name == null ? "" : gm.Name;
	}

	function get_level():UInt {
		var live = live();
		return live == null ? 0 : live.level;
	}

	function get_x():Float {
		var live = live();
		return live == null ? 0 : live.position.x;
	}

	function get_y():Float {
		var live = live();
		return live == null ? 0 : live.position.y;
	}

	function get_weapons():Array<Weapon> {
		var out:Array<Weapon> = [];
		var live = live();
		var details = live == null ? null : @:privateAccess live.mWeaponDetails;
		if (details == null)
			return out;
		for (slot in 0...details.length) {
			var detail = details[slot];
			if (detail == null || detail.type == 0)
				continue;
			out.push(Weapon.read(slot, detail.type, detail.power, detail.requiredlevel, detail.rarity, detail.modifier1, detail.modifier2,
				detail.legendarymodifier));
		}
		return out;
	}
}
