#include <amxmodx>
#include <amxmisc>
#include <zombieswarm>

#define TASKID 72
new killcount[33];

new const KILL_MARKS[][] = {
	"zswarm/kill_1.wav",
	"zswarm/kill_2.wav",
	"zswarm/kill_3.wav",
	"zswarm/kill_4.wav",
	"zswarm/kill_5.wav",
	"zswarm/kill_6.wav",
	"zswarm/kill_7.wav",
	"zswarm/kill_8.wav",
	"zswarm/kill_9.wav",
	"zswarm/kill_10.wav",
	"zswarm/kill_11.wav"
}

new const HEADSHOOT[] = "zswarm/kill_headshot.wav"
new const OHNO[] = "zswarm/kill_ohno.wav"

public plugin_init() {
	register_plugin("[ZS] Addon: Kill Counter", "v2.53.6", "--chcode");
	register_event("DeathMsg", "player_death", "a");
}

public plugin_precache() {
	for(new i = 0; i < sizeof(KILL_MARKS); i++) {
		precache_sound(KILL_MARKS[i]);
	}
	
	precache_sound(HEADSHOOT);
	precache_sound(OHNO);
}

public client_connect(id) {
	killcount[id] = 0;
}

public player_death() {
	new id = read_data(1);
	new iv = read_data(2);
	new head = read_data(3);
	
	killcount[iv] = 0;
	
	new hud[128];
	
	if(!iv || !id || id == iv || zs_get_user_zombie(id)) {
		return;
	}
	
	if(killcount[id] < sizeof(KILL_MARKS)) {
		client_cmd(id, "spk sound/%s", KILL_MARKS[killcount[id]]);
	} else {
		client_cmd(id, "spk sound/%s", KILL_MARKS[charsmax(KILL_MARKS)]);
	}
	
	killcount[id]++;
	
	if(killcount[id] == 1) {
		formatex(hud, charsmax(hud), "First Kill");
	} else if(killcount[id] > 1) {
		formatex(hud, charsmax(hud), "Kill Streak's: %d", killcount[id]);
	}

	client_print(id, print_center, hud);
	remove_task(id + TASKID); remove_task(id);
	set_task(5.0, "reset_kills", id + TASKID);
	
	if(head) {
		set_task(1.45, "headshot", id);
	}
	
	if(!zs_get_user_zombie(iv) && killcount[iv] > 4) {
		client_cmd(iv, "spk sound/%s", OHNO);
		formatex(hud, charsmax(hud), "Oh no, your kill score was good");
		client_print(iv, print_center, hud);
	}
}

public headshot(id) {
	new hud[128];
	formatex(hud, charsmax(hud), "!HEADSHOOT!");
	client_print(id, print_center, hud);
	client_cmd(id, "spk sound/%s", HEADSHOOT);
}

public reset_kills(task) {
	new id = task - TASKID;
	killcount[id] = 0;
}