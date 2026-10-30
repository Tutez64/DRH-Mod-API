package mods.api.dungeon;

import dBGlobals.DBGlobal;
import distributedObjects.DistributedDungeonFloor;
import distributedObjects.NPCGameObject;

/** The dungeon floor in progress. Not town. */
class Floor {
	public var id(default, null):UInt;

	/** 1-based index of the floor inside its dungeon. */
	public var number(get, never):Int;

	/** GameMaster map-node constant, empty when the floor is already gone. */
	public var map(get, never):String;

	/**
	 * The floor's tiles as the server laid them out, read now: a copy. Filler the server sends is in it,
	 * not the filler the game adds on its own around the floor. Empty once the floor is gone.
	 */
	public var tiles(get, never):Array<Tile>;

	/**
	 * The heroes' living enemies the game knows on the floor, read now: a copy. Rooms not reached yet
	 * are in it, monsters a generator spawns later too, and anything of the foes' team, such as the
	 * Cracked Walls guarding the Golem in Twisted Jungle Boss or the Barrel Monsters of Knight Fortress
	 * Boss; not breakable props, nor traps that hurt everyone. None yet at `onFloorEnter`; empty once the
	 * floor is gone.
	 */
	public var monsters(get, never):Array<Monster>;

	var floor:DistributedDungeonFloor;

	@:allow(mods.api._internal.Hub)
	function new(floor:DistributedDungeonFloor) {
		this.floor = floor;
		id = floor.id;
	}

	function get_number():Int {
		if (floor == null || floor.isDestroyed)
			return 0;
		return (floor.getCurrentFloorNum() : Int);
	}

	function get_map():String {
		if (floor == null || floor.isDestroyed)
			return "";
		var node = floor.gmMapNode;
		if (node == null || node.Constant == null)
			return "";
		return node.Constant;
	}

	function get_tiles():Array<Tile> {
		var out:Array<Tile> = [];
		if (floor == null || floor.isDestroyed)
			return out;
		var usages = @:privateAccess floor.mTileNetworkComponents;
		var factory = floor.dungeonFloorFactory == null ? null : floor.dungeonFloorFactory.tileFactory;
		var library = factory == null ? null : @:privateAccess factory.mTileMap;
		if (usages == null)
			return out;
		for (i in 0...usages.length) {
			var usage = usages[i];
			var json:Dynamic = library == null ? null : library.itemFor(usage.tileId);
			var category:Null<String> = json == null ? null : json.category;
			var sides:Dynamic = json == null ? null : json.exits;
			var exits = [for (side in 0...4) sides != null && side < sides.length && sides[side] != null && sides[side] != 0];
			out.push(new Tile(usage.x, usage.y, usage.tileId == null ? "" : usage.tileId, category == null ? "" : category, exits));
		}
		return out;
	}

	function get_monsters():Array<Monster> {
		var out:Array<Monster> = [];
		if (floor == null || floor.isDestroyed || floor.remoteActors == null)
			return out;
		var avatar = floor.activeOwnerAvatar;
		var heroes:Int = avatar == null ? (DBGlobal.TEAM_1 : Int) : avatar.team;
		for (actor in floor.remoteActors.toArray()) {
			if (!Std.isOfType(actor, NPCGameObject))
				continue;
			var npc:NPCGameObject = cast actor;
			if (npc.isDestroyed || npc.isDead())
				continue;
			// Teams besides the heroes': props (environment), and traps that hurt everyone (the third team).
			var team = npc.team;
			if (team == heroes || team == (DBGlobal.TEAM_ENVIRONMENT : Int) || team == (DBGlobal.TEAM_3 : Int))
				continue;
			var position = npc.position;
			var gm = npc.gmNpc;
			out.push(new Monster(npc.id, gm == null || gm.Name == null ? "" : gm.Name, position == null ? 0 : position.x,
				position == null ? 0 : position.y, gm != null && gm.HasHealthbar));
		}
		return out;
	}
}
