#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <fun>
#include <engine>
#include <roundev>
#include <zombieswarm>
#include <zswarm_rpg>
#include <hamsandwich>

enum Round_Events {
	RE_EXTRA_ZOMBIE_HEALTH = 0,
	RE_EXTRA_ZOMBIE_DMG,
	RE_EXTRA_ZOMBIE_GUARD,
	RE_EXTRA_HUMAN_COIN,
	RE_EXTRA_HUMAN_DMG,
	RE_EXTRA_HUMAN_UNCLIP,
	RE_EXTRA_HUMAN_REGENERATION
}

new const CURRENT_REMSG[][] = {
	"Zombie Health",
	"Zombie Damage",
	"Zombie Guard",
	"Human Gain Money",
	"Human Damage",
	"Human Unlimited Clip",
	"Human Regeneration",
	"Waiting Round Start.."
}

new current_re
new Float: nextPreThink[33];

new const clips[] = 
{
	0,
	13,	//CSW_P228
	0,
	10,	//CSW_SCOUT
	1,	//CSW_HEGRENADE
	8,	//CSW_XM1014
	1,	//CSW_C4
	30,	//CSW_MAC10
	30,	//CSW_AUG
	1,	//CSW_SMOKEGRENADE
	30,	//CSW_ELITE
	20,	//CSW_FIVESEVEN
	30,	//CSW_UMP45
	30,	//CSW_SG550
	30,	//CSW_GALIL
	30,	//CSW_FAMAS
	12,	//CSW_USP
	20,	//CSW_GLOCK18
	10,	//CSW_AWP
	30,	//CSW_MP5NAVY
	100,	//CSW_M249
	8,	//CSW_M3
	30,	//CSW_M4A1
	30,	//CSW_TMP
	20,	//CSW_G3SG1
	2,	//CSW_FLASHBANG
	7,	//CSW_DEAGLE
	30,	//CSW_SG552
	30,	//CSW_AK47
	0,	//CSW_KNIFE
	50	//CSW_P90
};

public plugin_init() {
	register_plugin("[ZS] Addon: Round Event", "v2.53.6", "--chcode");
	register_round(ROUND_START, "round_start");
	register_round(ROUND_NEW, "round_new");
	register_forward(FM_PlayerPreThink, "player_prethink");
	RegisterHam(Ham_TakeDamage, "player", "player_takedamage");
	RegisterHam(Ham_Spawn, "player", "player_spawn");
}

public plugin_natives() {
	register_native("zs_get_round_event", "native_zs_get_round_event", 1);
}

public native_zs_get_round_event() {
	return current_re;
}

public round_start() {
	current_re = random(7);
	client_print(0, print_center, "[ Round Event ]^n%s", CURRENT_REMSG[current_re]);
	
	for(new id = 0; id < get_maxplayers(); id++) {
		if(current_re == RE_EXTRA_ZOMBIE_HEALTH && zs_get_user_zombie(id) && is_user_alive(id)) {
			fm_set_user_health(id, get_user_health(id) * 2);
		}
	}
}

public round_new() {
	current_re = 7;
}

public player_spawn(id) {
	set_task(0.2, "player_set_health", id);
}

public player_set_health(id) {
	remove_task(id);
	
	if(!is_user_alive(id)) {
		return;
	}
	
	if(!zs_get_user_zombie(id)) {
		return;
	}
	
	if(id == 0) {
		return;
	}
	
	if(current_re == RE_EXTRA_ZOMBIE_HEALTH) {
		fm_set_user_health(id, get_user_health(id) * 2);
	}
}

public player_takedamage(victim, inflictor, attacker, Float: damage, damage_bits) {
	if(!attacker || !victim || victim == attacker || !is_user_alive(attacker) || !is_user_alive(victim)) {
		return;
	}
	
	if(current_re == RE_EXTRA_ZOMBIE_DMG) {
		if(zs_get_user_zombie(attacker) && !zs_get_user_zombie(victim)) {
			SetHamParamFloat(4, damage * 3.00);
		}
	}
	
	if(current_re == RE_EXTRA_ZOMBIE_GUARD) {
		if(!zs_get_user_zombie(attacker) && zs_get_user_zombie(victim)) {
			SetHamParamFloat(4, damage / 3.50);
		}
	}
	
	if(current_re == RE_EXTRA_HUMAN_DMG) {
		if(!zs_get_user_zombie(attacker) && zs_get_user_zombie(victim)) {
			SetHamParamFloat(4, damage * 1.50);
		}
	}
	
	if(current_re == RE_EXTRA_HUMAN_COIN) {
		if(!zs_get_user_zombie(attacker) && zs_get_user_zombie(victim)) {
			zs_set_user_money(attacker, zs_get_user_money(attacker) + (floatround(damage, floatround_tozero) / 4));
		}
	}
	
	if(current_re == RE_EXTRA_HUMAN_REGENERATION) {
		if(zs_get_user_zombie(attacker) && !zs_get_user_zombie(victim)) {
			remove_task(victim + 100);
			set_task(0.8, "player_regeneration", victim + 100, _, _, "b");
		}
	}
}

public player_regeneration(taskid) {
	new id = taskid - 100;
	new maxhealth = 100 + (zs_rpg_get_health(id) * 5);
	
	if(!is_user_alive(id) || !is_user_connected(id)) {
		remove_task(taskid);
		return;
	}
	
	if(cs_get_user_armor(id) > 0) {
		remove_task(taskid);
		return;
	}
	
	if(is_user_alive(id) && is_user_connected(id) && current_re == RE_EXTRA_HUMAN_REGENERATION && get_user_health(id) < maxhealth) {
		fm_set_user_health(id, get_user_health(id) + 1);
	}
	
	if(get_user_health(id) >= maxhealth) {
		fm_set_user_health(id, maxhealth);
		remove_task(taskid);
	}
}

public player_prethink(id) {
	if(id == 0 || !is_user_alive(id) || !is_user_connected(id) || zs_get_user_zombie(id)) {
		return;
	}
	
	if(current_re != RE_EXTRA_HUMAN_UNCLIP) {
		return;
	}
	
	new weapon = get_user_weapon(id);
	new clip, ammo;
	new weaponname[44];
	
	if(weapon == 0 || weapon == CSW_KNIFE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_HEGRENADE || weapon == CSW_C4) {
		return;
	}
	
	get_user_ammo(id, weapon, clip, ammo);
	get_weaponname(weapon, weaponname, charsmax(weaponname));
	
	if(clip < clips[weapon]) {
		give_clip(id, clips[weapon], weaponname);
	}
	
	nextPreThink[id] = get_gametime() + 0.15;
}

stock give_clip(id, clip, weapon_name[])
{
	new ent = find_ent_by_owner(-1, weapon_name, id)
	set_pdata_int(ent, 51, clip, 4);
}