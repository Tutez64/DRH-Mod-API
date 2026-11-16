package mods.api.account;

import facade.GameMasterLocale;
import flash.display.Sprite;
import gameMasterDictionary.GMRarity;
import gameMasterDictionary.GMWeaponItem;
import mods.api._internal.Art;
import mods.api._internal.Hub;

/**
 * A weapon, copied when read: it does not follow later changes.
 *
 * @since 1.0
 */
class Weapon {
	/** 0-based slot on the hero carrying it, -1 in storage. */
	public var slot(default, null):Int;

	/** The game's item id, and its name as the inventory shows it, without its modifiers. */
	public var id(default, null):UInt;
	public var name(default, null):String;

	public var power(default, null):UInt;
	public var requiredLevel(default, null):UInt;

	/**
	 * The game's rarity constant (empty when unknown), the text color it uses for it, and whether it is
	 * legendary.
	 */
	public var rarity(default, null):String;
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
	 * The game's icon on its rarity background, centred in a `size` square; hovering it shows the game's
	 * tooltip. Empty before `ready`.
	 */
	public function createIcon(size:Float):Sprite {
		return Art.weaponIcon(id, power, requiredLevel, rarityId, modifier1, modifier2, legendaryModifier, size);
	}
}
