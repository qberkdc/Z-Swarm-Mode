#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

public plugin_init() {
	register_plugin("[ZS] Team Balance", "v2.53.6", "--chcode");
	RegisterHam(Ham_Spawn, "player", "pl_spawn");
}

public pl_spawn(id) {
	set_task(0.1234, "pl_swap", id);
}

public pl_swap(id) {
	if(is_user_alive(id)) {
		remove_task(id);
		
		if(is_user_bot(id)) {
			if(cs_get_user_team(id) == CS_TEAM_CT) {
				cs_set_user_team(id, CS_TEAM_T);
				ExecuteHamB(Ham_CS_RoundRespawn, id)
			}
		} else {
			if(cs_get_user_team(id) == CS_TEAM_T) {
				cs_set_user_team(id, CS_TEAM_CT);
				ExecuteHamB(Ham_CS_RoundRespawn, id)
			}
		}
	}
}