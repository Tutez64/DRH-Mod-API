package mods.api._internal;

import distributedObjects.DistributedDungeonFloor;
import distributedObjects.HeroGameObject;
import distributedObjects.HeroGameObjectOwner;
import facade.DBFacade;
import modding.ModContext;
import mods.api.account.Account;
import mods.api.dungeon.Floor;
import mods.api.dungeon.Hero;
import mods.api.dungeon.Player;
import mods.api.State;
import mods.api.Subscription;
import openfl.display.DisplayObjectContainer;

/**
 * The `api` mod's shared side: the live state, the game's facade, and every mod's subscriptions. Not
 * for mods: they go through `Context`.
 */
@:allow(mods.api)
class Hub {
	static inline final HERO_SPAWNED = "heroSpawned";

	static inline final HERO_DESPAWNED = "heroDespawned";

	static inline final FLOOR_ENTER = "floorEnter";

	static inline final FLOOR_EXIT = "floorExit";

	static inline final TABLES_LOADED = "tablesLoaded";

	static inline final TOWN_ENTER = "townEnter";

	static inline final TOWN_EXIT = "townExit";

	static inline final KEY_DOWN = "keyDown";

	/** The `api` mod's own core context. */
	static var core:Null<ModContext>;

	static var state:State = new State();

	static var listeners:Map<String, Array<Subscription>> = new Map();

	static var keysHooked:Bool = false;

	/** Heroes on a floor now, by object id. */
	static var heroes:Map<String, Hero> = new Map();

	/** Players met in the dungeon in progress, by account. Emptied on the return to town. */
	static var players:Map<String, Player> = new Map();

	static var floors:Map<String, Floor> = new Map();

	static function start(ctx:ModContext):Void {
		core = ctx;
		ctx.onHeroSpawned(heroSpawned);
		ctx.onHeroDespawned(heroDespawned);
		ctx.onFloorEnter(floorEnter);
		ctx.onFloorExit(floorExit);
		ctx.onTablesLoaded(function() emit(TABLES_LOADED, null));
		ctx.onTownEnter(townEnter);
		ctx.onTownExit(function() emit(TOWN_EXIT, null));
	}

	static function ready():Void {
		state.setAccount(Account.from(facade()));
	}

	/** The game's facade, null before `ready`. */
	static function facade():Null<DBFacade> {
		return core == null ? null : core.facade;
	}

	/** The overlay's root, above every mod's own layer. */
	static function top():Null<DisplayObjectContainer> {
		return core == null || core.overlay == null ? null : core.overlay.parent;
	}

	/** Runs a mod's callback from game code, which must not see its error. */
	static function safely(handler:Null<Void->Void>):Void {
		if (handler == null)
			return;
		try {
			handler();
		} catch (e:Dynamic) {
			log("callback: " + Std.string(e));
		}
	}

	static function log(message:String):Void {
		if (core != null)
			core.log(message);
	}

	static function listen(owner:ModContext, event:String, handler:Dynamic):Subscription {
		if (handler == null)
			throw event + ": handler is null";
		// The core only routes keys while someone listens, so the api mod listens on the first request.
		if (event == KEY_DOWN && !keysHooked && core != null) {
			keysHooked = true;
			core.onKeyDown(keyDown);
		}
		var list = listeners.get(event);
		if (list == null) {
			list = [];
			listeners.set(event, list);
		}
		var subscription = new Subscription(owner, event, handler);
		list.push(subscription);
		return subscription;
	}

	static function unlisten(subscription:Subscription):Void {
		var list = listeners.get(subscription.event);
		if (list != null)
			list.remove(subscription);
	}

	/** Calls every live handler of an event; a throw is logged under the mod that subscribed. */
	static function emit(event:String, payload:Dynamic):Void {
		var list = listeners.get(event);
		if (list == null)
			return;
		for (subscription in list.copy()) {
			if (!subscription.active)
				continue;
			try {
				subscription.call(payload);
			} catch (e:Dynamic) {
				subscription.owner.log(event + ": " + Std.string(e));
			}
		}
	}

	/** The key is kept when any handler keeps it. */
	static function keyDown(key:UInt):Bool {
		var list = listeners.get(KEY_DOWN);
		if (list == null)
			return false;
		var kept = false;
		for (subscription in list.copy()) {
			if (!subscription.active)
				continue;
			try {
				if (subscription.call(key) == true)
					kept = true;
			} catch (e:Dynamic) {
				subscription.owner.log(KEY_DOWN + ": " + Std.string(e));
			}
		}
		return kept;
	}

	static function heroSpawned(object:HeroGameObject):Void {
		var key = Std.string(object.id);
		if (heroes.exists(key))
			return;
		var local = Std.isOfType(object, HeroGameObjectOwner);
		var account:UInt = object.playerID;
		var player:Null<Player> = null;
		if (account != 0) {
			player = players.get(Std.string(account));
			if (player == null) {
				player = new Player(account, local);
				players.set(Std.string(account), player);
				state.addPlayer(player);
			}
		}
		var hero = new Hero(object, local, player);
		if (player != null)
			player.setHero(hero);
		heroes.set(key, hero);
		state.addHero(hero);
		emit(HERO_SPAWNED, hero);
	}

	static function heroDespawned(object:HeroGameObject):Void {
		var key = Std.string(object.id);
		var hero = heroes.get(key);
		if (hero == null)
			return;
		hero.leave();
		heroes.remove(key);
		state.removeHero(hero);
		emit(HERO_DESPAWNED, hero);
		hero.detach();
	}

	static function floorEnter(object:DistributedDungeonFloor):Void {
		var floor = new Floor(object);
		floors.set(Std.string(object.id), floor);
		state.setFloor(floor);
		emit(FLOOR_ENTER, floor);
	}

	static function floorExit(object:DistributedDungeonFloor):Void {
		var key = Std.string(object.id);
		var floor = floors.get(key);
		if (floor == null)
			return;
		floors.remove(key);
		if (state.floor == floor) {
			var next:Null<Floor> = null;
			for (other in floors)
				next = other;
			state.setFloor(next);
		}
		emit(FLOOR_EXIT, floor);
	}

	static function townEnter():Void {
		players = new Map();
		state.clearPlayers();
		emit(TOWN_ENTER, null);
	}
}
