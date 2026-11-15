package mods.api.dungeon;

import distributedObjects.DistributedDungeonFloor;
import mods.api._internal.Foe;
import mods.api._internal.Hub;

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

	/** The tiles once read whole, which a floor keeps as they are: each read copies them. */
	var laid:Null<Array<Tile>>;

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
		if (usages == null)
			return out;
		var count:Int = usages.length;
		if (laid == null || laid.length != count)
			laid = count == 0 ? null : readTiles(usages, count, true);
		var known:Array<Tile> = laid == null ? readTiles(usages, count, false) : laid;
		for (i in 0...known.length) {
			var tile:Tile = known[i];
			out.push(new Tile(tile.x, tile.y, tile.id, tile.category, tile.exits.copy()));
		}
		return out;
	}

	/** The floor's tiles read from the game; with `whole`, null while the library cannot say what one of them is. */
	function readTiles(usages:Dynamic, count:Int, whole:Bool):Null<Array<Tile>> {
		var out:Array<Tile> = [];
		var factory = floor.dungeonFloorFactory == null ? null : floor.dungeonFloorFactory.tileFactory;
		var library = factory == null ? null : @:privateAccess factory.mTileMap;
		for (i in 0...count) {
			var usage = usages[i];
			var json:Dynamic = library == null ? null : library.itemFor(usage.tileId);
			if (json == null && whole)
				return null;
			var category:Null<String> = json == null ? null : json.category;
			var sides:Dynamic = json == null ? null : json.exits;
			var exits = [for (side in 0...4) sides != null && side < sides.length && sides[side] != null && sides[side] != 0];
			out.push(new Tile(usage.x, usage.y, usage.tileId == null ? "" : usage.tileId, category == null ? "" : category, exits));
		}
		return out;
	}

	function get_monsters():Array<Monster> {
		var out:Array<Monster> = [];
		if (floor == null || floor.isDestroyed)
			return out;
		var known:Null<Array<Foe>> = Hub.foes.get(Std.string(id));
		if (known == null)
			return out;
		// Those the mods were told of and not told gone: the events and this list are one account.
		for (i in 0...known.length) {
			var foe:Foe = known[i];
			if (foe.told && !foe.left)
				out.push(foe.copy());
		}
		return out;
	}
}
