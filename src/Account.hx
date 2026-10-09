package mods.api;

import facade.DBFacade;

/** Account reading available from `ready`. Not a hero and not a floor. Fields read the live account. */
class Account {
	public var id(get, never):UInt;

	/** False when the account has no active avatar. `ready` still runs. */
	public var hasActiveAvatar(get, never):Bool;

	/** The avatar selected in town, 0 when there is none. Follows a change of selection. */
	public var activeAvatarId(get, never):UInt;

	public var coins(get, never):UInt;

	public var gems(get, never):UInt;

	public var trophies(get, never):UInt;

	/** What the account owns. */
	public var inventory(default, null):Inventory = new Inventory();

	var facade:DBFacade;

	function new(facade:DBFacade) {
		this.facade = facade;
	}

	function get_id():UInt {
		var info = facade.dbAccountInfo;
		return info == null ? 0 : info.id;
	}

	function get_hasActiveAvatar():Bool {
		var info = facade.dbAccountInfo;
		return info != null && info.activeAvatarInfo != null;
	}

	function get_activeAvatarId():UInt {
		var info = facade.dbAccountInfo;
		if (info == null)
			return 0;
		var avatar = info.activeAvatarInfo;
		return avatar == null ? 0 : avatar.id;
	}

	function get_coins():UInt {
		var info = facade.dbAccountInfo;
		return info == null ? 0 : info.basicCurrency;
	}

	function get_gems():UInt {
		var info = facade.dbAccountInfo;
		return info == null ? 0 : info.premiumCurrency;
	}

	function get_trophies():UInt {
		var info = facade.dbAccountInfo;
		return info == null ? 0 : info.trophies;
	}

	@:allow(mods.api.Hub)
	static function from(facade:DBFacade):Null<Account> {
		return facade == null || facade.dbAccountInfo == null ? null : new Account(facade);
	}
}
