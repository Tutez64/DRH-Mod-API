package mods.api.account;

import facade.GameMasterLocale;
import flash.display.Sprite;
import gameMasterDictionary.GMRarity;
import gameMasterDictionary.GMWeaponItem;
import mods.api._internal.Art;
import mods.api._internal.Hub;

/** One weapon, copied when read: it does not follow later changes. */
class Weapon {
	/** 0-based slot on the hero carrying it, -1 in storage. */
	public var slot(default, null):Int;

	/** GameMaster weapon item id. */
	public var id(default, null):UInt;

	/** Display name, as the inventory shows it, without its modifiers. */
	public var name(default, null):String;

	public var power(default, null):UInt;

	public var requiredLevel(default, null):UInt;

	/** GameMaster rarity constant, empty when unknown. */
	public var rarity(default, null):String;

	/** Text color the game uses for this rarity. */
	public var rarityColor(default, null):UInt;

	public var legendary(default, null):Bool;

	var rarityId:UInt;

	var modifier1:UInt;

	var modifier2:UInt;

	var legendaryModifier:UInt;

	/** Names and rarity from the GameMaster, read now. */
	@:allow(mods.api.dungeon.Hero, mods.api.account.Inventory, mods.api.account.OwnedHero)
	static function read(slot:Int, id:UInt, power:UInt, requiredLevel:UInt, rarityId:UInt, modifier1:UInt, modifier2:UInt,
			legendaryModifier:UInt):Weapon {
		var facade = Hub.facade();
		var gameMaster = facade == null ? null : facade.gameMaster;
		var name = "";
		var rarity:GMRarity = null;
		if (gameMaster != null) {
			var item:GMWeaponItem = cast gameMaster.weaponItemById.itemFor(id);
			if (item != null) {
				var aesthetic = item.getWeaponAesthetic(requiredLevel, legendaryModifier > 0);
				name = aesthetic != null ? GameMasterLocale.getGameMasterSubString("WEAPON_AESTHETIC_NAME", aesthetic.Constant) : item.Name;
			}
			rarity = cast gameMaster.rarityById.itemFor(rarityId);
		}
		var color:UInt = rarity != null && rarity.TextColor != 0 ? rarity.TextColor : 15463921;
		return new Weapon(slot, id, name == null ? "" : name, power, requiredLevel, rarity == null || rarity.Constant == null ? "" : rarity.Constant,
			color, rarityId, modifier1, modifier2, legendaryModifier);
	}

	function new(slot:Int, id:UInt, name:String, power:UInt, requiredLevel:UInt, rarity:String, rarityColor:UInt, rarityId:UInt, modifier1:UInt,
			modifier2:UInt, legendaryModifier:UInt) {
		this.slot = slot;
		this.id = id;
		this.name = name;
		this.power = power;
		this.requiredLevel = requiredLevel;
		this.rarity = rarity;
		this.rarityColor = rarityColor;
		this.rarityId = rarityId;
		this.modifier1 = modifier1;
		this.modifier2 = modifier2;
		this.legendaryModifier = legendaryModifier;
		legendary = legendaryModifier > 0;
	}

	/**
	 * The game's icon for this weapon on its rarity background, centred in a `size` square. Hovering
	 * it shows the game's weapon tooltip. The art appears once loaded, and is released when the sprite
	 * is removed from its parent. Empty before `ready`.
	 */
	public function createIcon(size:Float):Sprite {
		return Art.weaponIcon(id, power, requiredLevel, rarityId, modifier1, modifier2, legendaryModifier, size);
	}
}
