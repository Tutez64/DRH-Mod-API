package mods.api.account;

import account.AvatarInfo;
import account.DBInventoryInfo;
import account.PetInfo;
import brain.jsonRPC.JSONRPCService;
import facade.DBFacade;
import flash.errors.Error;
import mods.api._internal.Hub;

/**
 * A hero of the account, copied when read, with what it carries into a dungeon. Not a hero on a
 * floor: that is `Hero`.
 */
class OwnedHero {
	/** The account's id for this hero, as in `Account.activeAvatarId`. */
	public var id(default, null):UInt;

	/** GameMaster hero class id, as `Hero.classId`. */
	public var classId(default, null):UInt;

	/** Name of the hero class, as the game shows it. */
	public var className(default, null):String;

	public var level(default, null):UInt;

	/** GameMaster skin id. */
	public var skinId(default, null):UInt;

	/** Equipped weapons by slot, empty slots left out. */
	public var weapons(default, null):Array<Weapon> = [];

	/** Equipped pets. */
	public var pets(default, null):Array<Pet> = [];

	/** Equipped consumables by slot, empty slots left out. */
	public var consumables(default, null):Array<Stack> = [];

	/** A pet move in progress, of any mod: one at a time. */
	static var moving:Bool = false;

	@:allow(mods.api.account.Inventory)
	function new(avatar:AvatarInfo, inventory:DBInventoryInfo) {
		id = avatar.id;
		classId = avatar.avatarType;
		var gm = avatar.gmHero;
		className = gm == null || gm.Name == null ? "" : gm.Name;
		level = avatar.level;
		skinId = avatar.skinId;
		for (item in inventory.getEquipedItemsOnAvatar(id))
			weapons.push(Inventory.weapon(item, item.avatarSlot));
		weapons.sort((a, b) -> a.slot - b.slot);
		for (pet in inventory.getEquipedPetsOnAvatar(id))
			pets.push(Inventory.pet(pet));
		for (stack in inventory.getEquipedConsumablesOnAvatar(avatar))
			consumables.push(Inventory.stack(stack));
	}

	/**
	 * Equips `pet` on this hero, in town, as the inventory does but without its popup: the pet this hero
	 * carries goes back to storage, and `pet` leaves the hero carrying it. `done` runs once: true once the
	 * server accepted, false on an error, which the game shows. Returns false when there is nothing to do:
	 * out of town, `pet` already on this hero or not the account's, or a move still in progress.
	 */
	public function equipPet(pet:Pet, ?done:Bool->Void):Bool {
		var facade = Hub.facade();
		var account = facade == null ? null : facade.dbAccountInfo;
		var inventory = account == null ? null : account.inventoryInfo;
		if (!Hub.inTown || moving || pet == null || inventory == null || inventory.getAvatarInfoForAvatarInstanceId(id) == null)
			return false;
		var moved = petInfo(inventory, pet.uid);
		if (moved == null || moved.EquippedHero == id)
			return false;
		moving = true;
		var hero = id;
		var uid = pet.uid;
		// The game's answer to a change of hero holds the whole account: read after ours, it would put the pet back.
		Hub.whenSaved(() -> move(facade, hero, uid, done));
		return true;
	}

	static function petInfo(inventory:DBInventoryInfo, uid:UInt):Null<PetInfo> {
		for (value in inventory.pets.toArray()) {
			var info:PetInfo = cast value;
			if (info.databaseId == uid)
				return info;
		}
		return null;
	}

	/**
	 * Takes the pets off at once, then equips. Each answer holds the whole account: only the last is
	 * read, as the game would, but without refreshing the screens on the world map, which reloads then.
	 */
	static function move(facade:DBFacade, hero:UInt, uid:UInt, done:Null<Bool->Void>):Void {
		var account = facade.dbAccountInfo;
		var inventory = account.inventoryInfo;
		var last:Dynamic = null;
		function finish(ok:Bool):Void {
			moving = false;
			if (last != null)
				account.parseResponse(last, !Hub.onMap);
			Hub.safely(done == null ? null : () -> done(ok));
		}
		var moved = petInfo(inventory, uid);
		if (moved == null) {
			finish(false);
			return;
		}
		var off = [for (carried in inventory.getEquipedPetsOnAvatar(hero)) carried.databaseId];
		if (moved.EquippedHero == hero) {
			finish(true);
			return;
		}
		if (moved.isEquipped)
			off.push(uid);
		var service = facade.rpcRoot + "avatarmanager";
		var failed = false;
		function fail(error:Dynamic):Void {
			failed = true;
			// The game's error popup.
			@:privateAccess account.parseError(Std.isOfType(error, Error) ? error : new Error(Std.string(error)));
		}
		function equip():Void {
			if (failed) {
				finish(false);
				return;
			}
			var rpc = JSONRPCService.getFunction("equipPetOnAvatar", service);
			rpc(account.id, hero, uid, facade.validationToken, function(result:Dynamic) {
				if (result != null)
					last = result;
				finish(true);
			}, function(error:Dynamic) {
				fail(error);
				finish(false);
			});
		}
		var waiting = off.length;
		if (waiting == 0)
			equip();
		for (pet in off) {
			var rpc = JSONRPCService.getFunction("unEquipPet", service);
			rpc(account.id, pet, facade.validationToken, function(result:Dynamic) {
				if (result != null)
					last = result;
				if (--waiting == 0)
					equip();
			}, function(error:Dynamic) {
				fail(error);
				if (--waiting == 0)
					equip();
			});
		}
	}
}
