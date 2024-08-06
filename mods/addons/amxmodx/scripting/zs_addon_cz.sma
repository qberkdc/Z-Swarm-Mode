#include <amxmodx>
#include <zombieswarm>

public plugin_init() {
	register_plugin("[ZS] Addon Zombie: CSO", "v2.53.6", "--chcode");
	zs_add_zombie("cso_zombie", "v_zombie_knife.mdl", MALE);
	zs_add_zombie("cso_light", "v_light_knife.mdl", FEMALE);
	zs_add_zombie("cso_heavy", "v_heavy_knife.mdl", MALE);
}