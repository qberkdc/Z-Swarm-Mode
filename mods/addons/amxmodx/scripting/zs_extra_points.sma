#include <amxmodx>
#include <zombieswarm>
#include <zswarm_rpg>

#define NAME "Points"
#define COST 3000

new itemid;

public plugin_init() {
	register_plugin("[ZS] Extra: Points", "v2.53.6", "--chcode");
	itemid = zs_register_item(NAME, COST);
}

public zs_item_select(id, item) {
	if(itemid == item) {
		zs_rpg_set_points(id, zs_rpg_get_points(id) + 1);
	}
}