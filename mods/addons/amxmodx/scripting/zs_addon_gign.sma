#include <amxmodx>
#include <zombieswarm>

public plugin_init() {
	register_plugin("[ZS] Addon Human: Gign", "v2.53.6", "--chcode");
	zs_add_human("gign", MALE);
}