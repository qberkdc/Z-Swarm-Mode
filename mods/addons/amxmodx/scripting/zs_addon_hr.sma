#include <amxmodx>
#include <cstrike>
#include <screen>
#include <hamsandwich>
#include <zombieswarm>

new respawnable;
new countdown[33];
new deathcount[33];

public plugin_init() {
	register_plugin("[ZS] Human Respawn", "v2.53.6", "--chcode");
	register_logevent("sv_roundstart", 2, "1=Round_Start");
    register_logevent("sv_roundend", 2, "1=Round_End");
    register_event("DeathMsg", "pl_death", "a");
}

public sv_roundstart() {
	respawnable = 1;
}

public sv_roundend() {
	for(new i = 0; i < get_maxplayers(); i++) {
		remove_task(i + 820);
		respawnable = 0;
		deathcount[i] = 0;
	}
}

public client_putinserver(id) {
	remove_task(id + 820);
	deathcount[id] = 0;
	countdown[id] = 5;
	set_task(1.0, "pl_respawn", id + 820, _, _, "b");
}

public client_disconnected(id) {
	remove_task(id + 820);
}

public pl_death() {
	new id = read_data(2);
	
	if(is_user_bot(id)) {
		return;
	}
	
	deathcount[id]++;
	countdown[id] = 0 + (deathcount[id] * 5);
	
	remove_task(id + 820); set_task(1.0, "pl_respawn", id + 820, _, _, "b");
}

public pl_respawn(id) {
	id -= 820;
	
	if(!is_user_connected(id)) {
		remove_task(id + 820);
		return;
	}
	
	if(!respawnable) {
		remove_task(id + 820);
		return;
	}
	
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR || cs_get_user_team(id) == CS_TEAM_UNASSIGNED) {
		countdown[id] = 0 + (deathcount[id] * 5);
		return;
	}
	
	if(countdown[id] > 0) {
		set_hudmessage(70, 255, 70, -1.0, 0.7, 0, 0.0, 0.2, 0.0, 0.72, 1);
		show_hudmessage(id, "You will respawn %d second after", countdown[id]);
		countdown[id]--;
	} else {
		screenfade(id, 255, 255, 255, 255, FFADE_IN, 2, 0.6);
		set_task(1.8, "setspawn", id);
		remove_task(id + 820);
	}
}

public setspawn(id) {
	if(!is_user_alive(id) && is_user_connected(id)) {
		cs_set_user_team(id, CS_TEAM_CT);
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
}