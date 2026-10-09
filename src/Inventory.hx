package mods.api;

import account.DBInventoryInfo;
import account.ItemInfo;
import account.PetInfo;
import account.StackableInfo;

/**
 * What the account owns, read live from `ready`. Each list is a copy, in no particular order; what is
 * equipped is on its hero in `heroes`. Coins, gems and trophies are on `Account`.
 */
class Inventory {
	/** Weapons in storage, not equipped. Their `slot` is -1. */
	public var weapons(get, never):Array<Weapon>;

	/** Size of the weapon storage. Unopened chests take room in it too. */
	public var weaponLimit(get, never):UInt;

	/** The account's heroes, with what each has equipped. */
	public var heroes(get, never):Array<OwnedHero>;

	/** Pets in storage, not equipped. */
	public var pets(get, never):Array<Pet>;

	/** Consumables in storage, not equipped: potions and bombs for the dungeon. Coin and XP boosters are not listed. */
	public var consumables(get, never):Array<Stack>;

	@:allow(mods.api.Account)
	function new() {}

	function inventory():Null<DBInventoryInfo> {
		var facade = Hub.facade();
		var account = facade == null ? null : facade.dbAccountInfo;
		return account == null ? null : account.inventoryInfo;
	}

	function get_weapons():Array<Weapon> {
		var out:Array<Weapon> = [];
		var inventory = inventory();
		if (inventory != null)
			for (value in inventory.items.toArray()) {
				var item:ItemInfo = cast value;
				if (item.avatarId == 0)
					out.push(weapon(item, -1));
			}
		return out;
	}

	function get_weaponLimit():UInt {
		var inventory = inventory();
		return inventory == null ? 0 : inventory.storageLimitWeapon;
	}

	function get_heroes():Array<OwnedHero> {
		var out:Array<OwnedHero> = [];
		var inventory = inventory();
		if (inventory != null)
			for (value in inventory.avatars.toArray())
				out.push(new OwnedHero(cast value, inventory));
		return out;
	}

	function get_pets():Array<Pet> {
		var out:Array<Pet> = [];
		var inventory = inventory();
		if (inventory != null)
			for (value in inventory.pets.toArray()) {
				var info:PetInfo = cast value;
				if (info.EquippedHero == 0)
					out.push(pet(info));
			}
		return out;
	}

	function get_consumables():Array<Stack> {
		var out:Array<Stack> = [];
		var inventory = inventory();
		if (inventory != null)
			for (value in inventory.stackables.toArray()) {
				var info:StackableInfo = cast value;
				if (info.gmStackable != null && !info.gmStackable.AccountBooster)
					out.push(stack(info));
			}
		return out;
	}

	@:allow(mods.api.OwnedHero)
	static function weapon(item:ItemInfo, slot:Int):Weapon {
		var rarity = item.rarity;
		var modifiers = item.modifiers;
		return Weapon.read(slot, item.gmId, item.power, item.requiredLevel, rarity == null ? 0 : rarity.Id,
			modifiers.length > 0 ? modifiers[0].Id : 0, modifiers.length > 1 ? modifiers[1].Id : 0, item.legendaryModifier);
	}

	@:allow(mods.api.OwnedHero)
	static function pet(info:PetInfo):Pet {
		var npc = info.gmNpc;
		return npc == null ? new Pet(info.PetType, "", 0, 0, 0) : new Pet(info.PetType, npc.Name == null ? "" : npc.Name, npc.AttackRating,
			npc.DefenseRating, npc.SpeedRating);
	}

	@:allow(mods.api.OwnedHero)
	static function stack(info:StackableInfo):Stack {
		var gm = info.gmStackable;
		return new Stack(info.gmId, gm == null || gm.Name == null ? "" : gm.Name, info.count);
	}
}
