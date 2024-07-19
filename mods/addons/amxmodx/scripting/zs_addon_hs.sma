#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define STEP_DELAY 0.310
 
new Float:g_fNextStep[33];

new const cpack_walk[][] = {
    "zswarm/pl_step1.wav",
    "zswarm/pl_step2.wav",
    "zswarm/pl_step3.wav",
    "zswarm/pl_step4.wav"
}

/*
new const cpack_hurt[][] = {
    "common/null.wav"
}
*/

new const cpack_died[][] = {
    "zswarm/pl_die1.wav"
}

public plugin_init() {
    register_plugin("[ZS] Human Sounds", "v2.53.6", "--chcode");
    register_forward(FM_EmitSound, "Forward_EmitSound");
    register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink");
}

public plugin_precache() {
	for(new i = 0; i < sizeof(cpack_walk); i++) {
		precache_sound(cpack_walk[i]); 
	}
    
    /*
	for(new i = 0; i < sizeof(cpack_hurt); i++) {
        precache_sound(cpack_hurt[i]);
	}
	*/
    
	for(new i = 0; i < sizeof(cpack_died); i++) {
		precache_sound(cpack_died[i]);
	}
}

public fwd_PlayerPreThink(id) {
	if(!is_user_alive(id))
		return FMRES_IGNORED;
 
	set_pev(id, pev_flTimeStepSound, 999);
	
	new speed = floatround(fm_get_ent_speed(id));
	new flags = pev(id, pev_flags);
	
	if(g_fNextStep[id] < get_gametime() && !ntv_zs_get_user_zombie(id) && flags & FL_ONGROUND && speed > 134) {
		emit_sound(id, CHAN_AUTO, cpack_walk[random(sizeof(cpack_walk))], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		g_fNextStep[id] = get_gametime() + STEP_DELAY;
	}
	
	return FMRES_IGNORED;
}
 
stock Float:fm_get_ent_speed(id) {
	if(!pev_valid(id))
		return 0.0;
 
	static Float:vVelocity[3];
	pev(id, pev_velocity, vVelocity);
	vVelocity[2] = 0.0;
	
	return vector_length(vVelocity);
}

public Forward_EmitSound(id, channel, const sound[], Float:volume, Float:attn, flag, pitch) {
    if(is_user_connected(id) && !ntv_zs_get_user_zombie(id)) {
		new dummy[128];
    	new file[128];
    	new data[128];
		formatex(file, 127, "%s", sound);
    	replace_all(file, 127, "/", " ");
    	parse(file, dummy, 127, data, 127);
		replace_all(data, 127, ".wav", "");
    
		/*
		if(containi(data, "pain") != -1 || containi(data, "bhit_flesh") != -1) {
			emit_sound(id, CHAN_AUTO, cpack_hurt[random(sizeof(cpack_hurt))], volume, attn, flag, pitch);
			return FMRES_SUPERCEDE;
		}
		*/
        
		if(containi(data, "die") != -1 || containi(data, "death") != -1) {
			emit_sound(id, CHAN_AUTO, cpack_died[random(sizeof(cpack_died))], volume, attn, flag, pitch);
			return FMRES_SUPERCEDE;
		}
    }
    
    return FMRES_IGNORED;
}

stock ntv_zs_get_user_zombie(id) {
	new CsTeams: team = cs_get_user_team(id);
	if(team == CS_TEAM_T) {
		return 1;
	} else {
		return 0;
	}
}