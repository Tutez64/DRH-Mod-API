package mods.api;

/**
 * Live window handed to every mod.
 *
 * Account is filled at `ready`. Hero and floor wrappers stay absent until the
 * matching event. Adding a field later is a minor version of `api`.
 */
class State {
	/** Account-level reading. Null until `ready`. */
	public var account(default, null):Null<Account>;

	/** Dungeon floor in progress. Null in town and until `floorEnter`. */
	public var floor(default, null):Null<Floor>;

	/** Heroes currently on a dungeon floor, local and remote. A copy: changing it changes nothing. */
	public var heroes(get, never):Array<Hero>;

	/**
	 * Players met in the dungeon in progress, in order of arrival, those who left included. Emptied on
	 * `townEnter`. A copy.
	 */
	public var players(get, never):Array<Player>;

	var heroList:Array<Hero> = [];

	var playerList:Array<Player> = [];

	public function new() {}

	function get_heroes():Array<Hero> {
		return heroList.copy();
	}

	function get_players():Array<Player> {
		return playerList.copy();
	}

	@:allow(mods.api.Hub)
	function setAccount(value:Null<Account>):Void {
		account = value;
	}

	@:allow(mods.api.Hub)
	function setFloor(value:Null<Floor>):Void {
		floor = value;
	}

	@:allow(mods.api.Hub)
	function addHero(hero:Hero):Void {
		heroList.push(hero);
	}

	@:allow(mods.api.Hub)
	function removeHero(hero:Hero):Void {
		heroList.remove(hero);
	}

	@:allow(mods.api.Hub)
	function addPlayer(player:Player):Void {
		playerList.push(player);
	}

	@:allow(mods.api.Hub)
	function clearPlayers():Void {
		playerList = [];
	}
}
