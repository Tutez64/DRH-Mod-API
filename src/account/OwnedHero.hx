package mods.api.account;

import account.AvatarInfo;
import account.DBInventoryInfo;

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
}
