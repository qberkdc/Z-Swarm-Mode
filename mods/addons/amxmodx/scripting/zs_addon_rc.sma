#include <amxmodx>
#include <amxmisc>

new Float:fstart_time_round, Float:ftime_round, time_round;

public plugin_init() {
	register_plugin("[ZS] Round Controller", "v2.53.6", "--chcode");
	register_logevent("sv_roundstart", 2, "1=Round_Start" );
	time_round = get_cvar_pointer("mp_roundtime");
}

public sv_roundstart() {
	ftime_round = floatmul(get_pcvar_float(time_round), 60.0) - 1.0;
    fstart_time_round = get_gametime();
    
    remove_task(101010); set_task(0.1, "fw_roundtime", 101010, _, _, "b");
}

public fw_roundtime() {
    static szTime[6]; format_time(szTime, 5, "%M:%S", floatround(ftime_round - (get_gametime() - fstart_time_round), floatround_ceil));
    if(equal(szTime, "00:00")) {
		for(new i = 0; i < get_maxplayers(); i++) {
			if(is_user_alive(i) && get_user_team(i) == 1) {
				user_silentkill(i);
			}
		}
    }
} 
