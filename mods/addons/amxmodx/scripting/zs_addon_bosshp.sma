#include <amxmodx>
#include <zombieswarm>

public plugin_init() {
	register_plugin("[ZS] Addon: Boss Health", "v2.36.08", "--chcode");
	set_task(0.25, "show_bosshp", 0, _, _, "b");
}

public show_bosshp(id) {
	new boss;
	new bosshp;
	new bossname[64];
	new i;
	
	for(i = 0; i < get_maxplayers(); i++) {
		if(is_user_alive(i) && is_user_connected(i)) {
			if(zs_get_user_boss(i)) {
				boss = i;
				break;
			}
		}
	}
	
	if(boss) {
		bosshp = get_user_health(boss);
		get_user_name(boss, bossname, charsmax(bossname)); remove_color(bossname, charsmax(bossname));
		set_hudmessage(180, 80, 80, -1.0, 0.02, 1, 0.0, 2.0, 0.0, 0.0, 3);
		show_hudmessage(id, "Boss Round^n[ %s   =|=   %d ]", bossname, bosshp);
	}
}