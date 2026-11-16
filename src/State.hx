package mods.api;

import mods.api._internal.Hub;
import mods.api.account.Account;
import mods.api.dungeon.Floor;
import mods.api.dungeon.Hero;
import mods.api.dungeon.Player;

/**
 * The live game, read now: `context.state`, shared by every mod.
 *
 * A hero and its player are two objects: a `Hero` is what a player plays on one floor, and each floor
 * gives a new one; its `Player` is the account behind it, the same from its first hero to the end of
 * the dungeon.
 *
 * @since 1.0
 */
class State {
	/** The account, null until `ready`. */
	public var account(default, null):Null<Account>;

	/**
	 * Whether the game is in town: true from `onTownEnter` to `onTownExit`.
	 * @since 1.2
	 */
	public var inTown(get, never):Bool;

	/** The dungeon floor in progress; null in town. */
	public var floor(default, null):Null<Floor>;

	/** The heroes on the floor, local and remote. A copy. */
	public var heroes(get, never):Array<Hero>;

	/**
	 * The players met in the dungeon in progress, in order of arrival, those who left included; emptied
	 * when it is left, for the town (before `onTownEnter`) or for another dungeon. A copy.
	 */
	public var players(get, never):Array<Player>;

	var heroList:Array<Hero> = [];

	var playerList:Array<Player> = [];

	@:allow(mods.api._internal.Hub)
	function new() {}

	function get_inTown():Bool {
		return Hub.inTown;
	}

	function get_heroes():Array<Hero> {
		return heroList.copy();
	}

	function get_players():Array<Player> {
		return playerList.copy();
	}

	@:allow(mods.api._internal.Hub)
	function setAccount(value:Null<Account>):Void {
		account = value;
	}

	@:allow(mods.api._internal.Hub)
	function setFloor(value:Null<Floor>):Void {
		floor = value;
	}

	@:allow(mods.api._internal.Hub)
	function addHero(hero:Hero):Void {
		heroList.push(hero);
	}

	@:allow(mods.api._internal.Hub)
	function removeHero(hero:Hero):Void {
		heroList.remove(hero);
	}

	@:allow(mods.api._internal.Hub)
	function addPlayer(player:Player):Void {
		playerList.push(player);
	}

	@:allow(mods.api._internal.Hub)
	function clearPlayers():Void {
		playerList = [];
	}
}
