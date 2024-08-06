#include <amxmodx>
#include <cstrike>
#include <fun>
#include <zombieswarm>

new itemid;

public plugin_init() {
	register_plugin("[ZS] Extra: Grenade Pack", "v2.53.6", "--chcode");
	itemid = zs_register_item("HE Grenade", 200);
}

public zs_item_select(id, item) {
	if(itemid == item) {
		new hg = cs_get_user_bpammo(id, CSW_HEGRENADE);
		if(hg >= 3) {
			client_print(id, print_chat, "^^3[ZS] ^^7You can't carry more");
			zs_set_item_return(id, item);
		} else {
			if(hg < 1) {
				give_item(id, "weapon_hegrenade");
			} else {
				cs_set_user_bpammo(id, CSW_HEGRENADE, hg + 1)
			}
		}
	}
}