#include <amxmodx>
#include <zombieswarm>

new const zombie_sounds[][] = {
	"zswarm/spawn_1.wav",
	"zswarm/spawn_2.wav"
}

public plugin_init() {
	register_plugin("[ZS] Addon: Zombie Spawn Sound", "v2.53.6", "--chcode");
}

public plugin_precache() {
	new form[76];
	
	for(new i = 0; i < sizeof(zombie_sounds); i++) {
		formatex(form, charsmax(form), "%s", zombie_sounds[i]);
		precache_sound(form);
	}
}

public zs_zombie_spawn(id) {
	client_cmd(0, "spk sound/%s", zombie_sounds[random(sizeof(zombie_sounds))]);
}