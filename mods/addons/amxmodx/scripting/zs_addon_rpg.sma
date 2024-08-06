#pragma tabsize 0

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieswarm>
#include <nvault>
#include <roundev>

new const round_event[][] = {
	"Zombie Health",
	"Zombie Damage",
	"Zombie Guard",
	"Human Gain Money",
	"Human Damage",
	"Human Unlimited Clip",
	"Human Regeneration",
	"Waiting Round Start.."
}

new database;
new cdata_level[33];
new cdata_exp[33];
new cdata_nexp[33];
new cdata_health[33];
new cdata_attack[33];
new cdata_speed[33];
new cdata_deffence[33];
new cdata_moneygain[33];
new cdata_points[33];

new bool: canmove;

native zs_get_round_event()

public plugin_init() {
	register_plugin("[ZS] RPG System", "v2.53.6", "--chcode");
	register_clcmd("say /upgrade", "Menu");
	register_concmd("set_rpg", "set_user_rpg");
	
	register_forward(FM_PlayerPreThink, "pl_prethink");
	register_event("DeathMsg", "pl_death", "a");
	
	register_round(ROUND_NEW, "player_cantmove");
	register_round(ROUND_START, "player_canmove");
	
	canmove = true;
	
	RegisterHam(Ham_Spawn, "player", "pl_spawn");
	RegisterHam(Ham_TakeDamage, "player", "pl_damage");
	
	database = nvault_open("rpg_cdata");
}

public set_user_rpg(id) {
	new args[4][128];
	read_argv(1, args[0], charsmax(args));
	read_argv(2, args[1], charsmax(args));
	read_argv(3, args[2], charsmax(args));
	read_argv(4, args[3], charsmax(args));
	
	if(get_user_flags(id) & ADMIN_KICK) {
		if(!strlen(args[0])) {
			client_print(id, print_console, "[RPG System]: Type username");
			client_print(id, print_console, "[RPG System]: Truth Usage: *<userid> *<rpg_ability> *<amount> <method:+/->");
			return PLUGIN_HANDLED;
		}
		
		if(!strlen(args[1])) {
			client_print(id, print_console, "[RPG System]: Type ability");
			client_print(id, print_console, "[RPG System]: Truth Usage: *<userid> *<rpg_ability> *<amount> <method:+/->");
			return PLUGIN_HANDLED;
		}
		
		if(strlen(args[3]) > 1 && !(equali(args[3], "+")) && !(equali(args[3], "-"))) {
			client_print(id, print_console, "[RPG System]: Wrong type's");
			client_print(id, print_console, "[RPG System]: Truth Usage: *<userid> *<rpg_ability> *<amount> <method:+/->");
			return PLUGIN_HANDLED;
		}
		
		new target = cmd_target(id, args[0], 0);
		
		if(!target) {
			client_print(id, print_console, "[RPG System]: User not found");
			client_print(id, print_console, "[RPG System]: Truth Usage: *<userid> *<rpg_ability> *<amount> <method:+/->");
			return PLUGIN_HANDLED;
		}
		
		new const abilitys[][] = {
			"atk", "hp", "spd", "def", "mg"
		}
		
		new avail;
		
		for(new i = 0; i < sizeof(abilitys); i++) {
			if(equali(args[1], abilitys[i])) {
				avail = 1;
				break;
			}
		}
		
		if(!avail) {
			client_print(id, print_console, "[RPG System]: Wrong ability: %s", args[1]);
			client_print(id, print_console, "[RPG System]: Truth Usage: *<userid> *<rpg_ability> *<amount> <method:+/->");
			return PLUGIN_HANDLED;
		}
		
		new amount = str_to_num(args[2]);
		
		if(!amount) {
			client_print(id, print_console, "[RPG System]: Wrong amount");
			client_print(id, print_console, "[RPG System]: Truth Usage: *<userid> *<rpg_ability> *<amount> <method:+/->");
			return PLUGIN_HANDLED;
		}
		
		new adminname[64]; get_user_name(id, adminname, 63);
		new targetname[64]; get_user_name(target, targetname, 63);
		
		new ability_index;
		if(equali(args[1], "atk")) { ability_index = 1; }
		if(equali(args[1], "hp")) { ability_index = 2; }
		if(equali(args[1], "spd")) { ability_index = 3; }
		if(equali(args[1], "def")) { ability_index = 4; }
		if(equali(args[1], "mg")) { ability_index = 5; }
		
		switch(ability_index) {
			case 1: {
				if(equali(args[3], "+")) {
					cdata_attack[target] += amount;
				} else if(equali(args[3], "-")) {
					cdata_attack[target] -= amount;
				} else {
					cdata_attack[target] = amount;
				}
				
				if(cdata_attack[target] <= 0) {
					cdata_attack[target] = 0;
				}
				
				client_print(0, print_chat, "[RPG System]: ADMIN %s^^7 changed %s^^7 user %s ability: %d%s, current: %d", adminname, targetname, args[1], amount, args[3], cdata_attack[target]);
			}
			
			case 2: {
				if(equali(args[3], "+")) {
					cdata_health[target] += amount;
				} else if(equali(args[3], "-")) {
					cdata_health[target] -= amount;
				} else {
					cdata_health[target] = amount;
				}
				
				if(cdata_health[target] <= 0) {
					cdata_health[target] = 0;
				}
				
				client_print(0, print_chat, "[RPG System]: ADMIN %s^^7 changed %s^^7 user %s ability: %d%s, current: %d", adminname, targetname, args[1], amount, args[3], cdata_health[target]);
			}
			
			case 3: {
				if(equali(args[3], "+")) {
					cdata_speed[target] += amount;
				} else if(equali(args[3], "-")) {
					cdata_speed[target] -= amount;
				} else {
					cdata_speed[target] = amount;
				}
				
				if(cdata_speed[target] <= 0) {
					cdata_speed[target] = 0;
				}
				
				if(cdata_speed[target] >= 50) {
					cdata_speed[target] = 50;
				}
				
				client_print(0, print_chat, "[RPG System]: ADMIN %s^^7 changed %s^^7 user %s ability: %d%s, current: %d", adminname, targetname, args[1], amount, args[3], cdata_speed[target]);
			}
			
			case 4: {
				if(equali(args[3], "+")) {
					cdata_deffence[target] += amount;
				} else if(equali(args[3], "-")) {
					cdata_deffence[target] -= amount;
				} else {
					cdata_deffence[target] = amount;
				}
				
				if(cdata_deffence[target] <= 0) {
					cdata_deffence[target] = 0;
				}
				
				client_print(0, print_chat, "[RPG System]: ADMIN %s^^7 changed %s^^7 user %s ability: %d%s, current: %d", adminname, targetname, args[1], amount, args[3], cdata_deffence[target]);
			}
			
			case 5: {
				if(equali(args[3], "+")) {
					cdata_moneygain[target] += amount;
				} else if(equali(args[3], "-")) {
					cdata_moneygain[target] -= amount;
				} else {
					cdata_moneygain[target] = amount;
				}
				
				if(cdata_moneygain[target] <= 0) {
					cdata_moneygain[target] = 0;
				}
				
				if(cdata_moneygain[target] >= 50) {
					cdata_moneygain[target] = 50;
				}
				
				client_print(0, print_chat, "[RPG System]: ADMIN %s^^7 changed %s^^7 user %s ability: %d%s, current: %d", adminname, targetname, args[1], amount, args[3], cdata_deffence[target]);
			}
		}
		
	} else {
		client_print(id, print_console, "[RPG System]: You can't use this rpg command");
	}
	
	return PLUGIN_HANDLED;
}

public player_cantmove() {
	canmove = false;
}

public player_canmove() {
	canmove = true;
}

public plugin_natives() {
	register_native("zs_rpg_set_level", "native_zs_rpg_set_level", 1);
	register_native("zs_rpg_set_exp", "native_zs_rpg_set_exp", 1);
	register_native("zs_rpg_set_health", "native_zs_rpg_set_health", 1);
	register_native("zs_rpg_set_attack", "native_zs_rpg_set_attack", 1);
	register_native("zs_rpg_set_speed", "native_zs_rpg_set_speed", 1);
	register_native("zs_rpg_set_deffence", "native_zs_rpg_set_deffence", 1);
	register_native("zs_rpg_set_moneygain", "native_zs_rpg_set_moneygain", 1);
	register_native("zs_rpg_set_points", "native_zs_rpg_set_points", 1);
	
	register_native("zs_rpg_get_level", "native_zs_rpg_get_level", 1);
	register_native("zs_rpg_get_exp", "native_zs_rpg_get_exp", 1);
	register_native("zs_rpg_get_health", "native_zs_rpg_get_health", 1);
	register_native("zs_rpg_get_attack", "native_zs_rpg_get_attack", 1);
	register_native("zs_rpg_get_speed", "native_zs_rpg_get_speed", 1);
	register_native("zs_rpg_get_deffence", "native_zs_rpg_get_deffence", 1);
	register_native("zs_rpg_get_moneygain", "native_zs_rpg_get_moneygain", 1);
	register_native("zs_rpg_get_points", "native_zs_rpg_get_points", 1);
}

public native_zs_rpg_set_level(id, amount) {
	cdata_level[id] = amount;
	
	if(cdata_level[id] <= 0) {
		cdata_level[id] = 0;
	}
}

public native_zs_rpg_set_exp(id, amount) {
	cdata_exp[id] = amount;
	
	if(cdata_exp[id] <= 0) {
		cdata_exp[id] = 0;
	}
}

public native_zs_rpg_set_health(id, amount) {
	cdata_health[id] = amount;
	
	if(cdata_health[id] <= 0) {
		cdata_health[id] = 0;
	}
	
	if(cdata_health[id] >= 250) {
		cdata_health[id] = 250;
	}
}

public native_zs_rpg_set_attack(id, amount) {
	cdata_attack[id] = amount;
	
	if(cdata_attack[id] <= 0) {
		cdata_attack[id] = 0;
	}
	
	if(cdata_attack[id] >= 125) {
		cdata_attack[id] = 125;
	}
}

public native_zs_rpg_set_speed(id, amount) {
	cdata_speed[id] = amount;
	
	if(cdata_speed[id] >= 50) {
		cdata_speed[id] = 50;
	}
	
	if(cdata_speed[id] <= 0) {
		cdata_speed[id] = 0;
	}
}

public native_zs_rpg_set_deffence(id, amount) {
	cdata_deffence[id] = amount;
	
	if(cdata_deffence[id] <= 0) {
		cdata_deffence[id] = 0;
	}
	
	if(cdata_deffence[id] >= 100) {
		cdata_deffence[id] = 100;
	}
}

public native_zs_rpg_set_moneygain(id, amount) {
	cdata_moneygain[id] = amount;
	
	if(cdata_moneygain[id] <= 0) {
		cdata_moneygain[id] = 0;
	}
	
	if(cdata_moneygain[id] >= 50) {
		cdata_moneygain[id] = 50;
	}
}

public native_zs_rpg_set_points(id, amount) {
	cdata_points[id] = amount;
	
	if(cdata_points[id] <= 0) {
		cdata_points[id] = 0;
	}
}

public native_zs_rpg_get_level(id) {
	return cdata_level[id];
}

public native_zs_rpg_get_exp(id) {
	return cdata_exp[id];
}

public native_zs_rpg_get_health(id) {
	return cdata_health[id];
}

public native_zs_rpg_get_attack(id) {
	return cdata_attack[id];
}

public native_zs_rpg_get_speed(id) {
	return cdata_speed[id];
}

public native_zs_rpg_get_deffence(id) {
	return cdata_deffence[id];
}

public native_zs_rpg_get_moneygain(id) {
	return cdata_moneygain[id];
}

public native_zs_rpg_get_points(id) {
	return cdata_points[id];
}

public plugin_cfg() {
	for(new i = 0; i < get_maxplayers(); i++) {
		cdata_nexp[i] = 25;
	}
}

public pl_death() {
	new killer = read_data(1);
	new victim = read_data(2);
	
	if(!killer || !victim || killer == victim) {
		return;
	}
	
	if(!zs_get_user_zombie(killer) && zs_get_user_zombie(victim)) {
		cdata_exp[killer] += random_num(1, 3);
		
		if(zs_get_user_boss(victim)) {
			new name[64];
			get_user_info(killer, "name", name, charsmax(name));
			set_hudmessage(255, 120, 120, -1.0, 0.2, 0, 0.0, 0.1, 0.0, 2.0, 1);
			show_hudmessage(0, "! BOSS KILLER !^n%s", name);
			cdata_exp[killer] += random_num(45, 80);
		}
	}
}

public pl_prethink(id) {
	if(id == 0) {
		return;
	}
	
	if(!is_user_connected(id)) {
		return;
	}
	
	if(is_user_alive(id) && !zs_get_user_zombie(id)) {
		if(canmove) {
			fm_set_user_maxspeed(id, 250.0 + (cdata_speed[id] * 1));
		}
		
		if(cdata_exp[id] >= cdata_nexp[id]) {
			cdata_level[id]++;
			cdata_exp[id] -= cdata_nexp[id];
			cdata_nexp[id] += 30;
			cdata_points[id] += 1;
			
			new name[64];
			get_user_info(id, "name", name, charsmax(name));
			
			client_print(0, print_chat, "^^3[ZS] LVL UP! ^^2[%d] ^^7%s", cdata_level[id], name);
		}
	}
}

public pl_spawn(id) {
	if(is_user_connected(id)) {
		if(!zs_get_user_zombie(id)) {
			set_task(1.0, "set_health", id); set_task(1.1, "set_health", id);
			set_task(1.2, "set_health", id); set_task(1.3, "set_health", id);
		}
	}
}

public pl_damage(victim, inflictor, attacker, Float:damage, damage_bits) {
	if(!victim || !attacker || attacker == victim || !is_user_alive(attacker) || !is_user_alive(victim)) {
		return PLUGIN_HANDLED;
	}
	
	if(!zs_get_user_zombie(attacker) && zs_get_user_zombie(victim)) {
		zs_set_user_money(attacker, zs_get_user_money(attacker) + 2 + (cdata_moneygain[attacker] * 3));
	}
	
	if(!zs_get_user_zombie(attacker) && zs_get_user_zombie(victim)) {
		SetHamParamFloat(4, damage * (1.0 + (cdata_attack[attacker] * 0.025)));
		return HAM_HANDLED;
	}
	
	if(zs_get_user_zombie(attacker) && !zs_get_user_zombie(victim)) {
		SetHamParamFloat(4, floatround(damage, floatround_tozero) / ( 1.0 + (cdata_deffence[victim] * 0.015)));
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public set_health(id) {
	if(is_user_alive(id)) {
		fm_set_user_health(id, 100 + (cdata_health[id] * 5));
	}
}

public client_putinserver(id) {
	set_task(0.150, "pl_showhud", id, _, _, "b");
}

public client_connect(id) {
	database_load(id);
}

public pl_showhud(id) {
	new spec = pev(id, pev_iuser2);
	
	if(is_user_alive(id)) {
		new name[64];
		get_user_info(id, "name", name, charsmax(name));
		remove_color(name, charsmax(name));
		set_hudmessage(255, 210, 100, -1.0, 0.85, 0, 0.0, 2.30, 0.0, 0.0, 2);
		show_hudmessage(id, "Player: %s | Money: $ %d^nHP: %d | ATK: %d | SPD: %d | DEF: %d | MG: %d | P: %d^nLVL: %d | EXP: %d/%d | Round: %s", name, zs_get_user_money(id), cdata_health[id], cdata_attack[id], cdata_speed[id], cdata_deffence[id], cdata_moneygain[id], cdata_points[id], cdata_level[id], cdata_exp[id], cdata_nexp[id], round_event[zs_get_round_event()]);
	} else if(spec && is_user_alive(spec) && !is_user_bot(spec)) {
		new name[64];
		get_user_info(spec, "name", name, charsmax(name));
		remove_color(name, charsmax(name));
		set_hudmessage(255, 220, 180, -1.0, 0.85, 0, 0.0, 2.30, 0.0, 0.0, 2);
		show_hudmessage(id, "Player: %s | Money: $ %d^nHP: %d | ATK: %d | SPD: %d | DEF: %d | MG: %d | P: %d^nLVL: %d | EXP: %d/%d | Round: %s", name, zs_get_user_money(spec), cdata_health[spec], cdata_attack[spec], cdata_speed[spec], cdata_deffence[spec], cdata_moneygain[spec], cdata_points[spec], cdata_level[spec], cdata_exp[spec], cdata_nexp[spec], round_event[zs_get_round_event()]);
	}
}

public client_disconnected(id) {
	database_save(id);
}

public database_save(id) {
	new szAuth[33]; get_user_authid(id , szAuth , charsmax(szAuth));
	new szKey[64]; formatex(szKey , 63 , "%s ==> " , szAuth);
	new szData[256]; formatex(szData , 255, "%d#%d#%d#%d#%d#%d#%d#%d#%d#", cdata_health[id], cdata_attack[id], cdata_speed[id], cdata_points[id], cdata_level[id], cdata_exp[id], cdata_nexp[id], cdata_deffence[id], cdata_moneygain[id]);
	
	nvault_pset(database , szKey , szData);
	
	reset_datas(id);
}

public database_load(id) {
	new szAuth[33]; get_user_authid(id , szAuth , charsmax(szAuth));
	new szKey[40]; formatex(szKey , 63 , "%s ==> " , szAuth);
	new szData[256]; formatex(szData , 255, "%d#%d#%d#%d#%d#%d#%d#%d#%d#", cdata_health[id], cdata_attack[id], cdata_speed[id], cdata_points[id], cdata_level[id], cdata_exp[id], cdata_nexp[id], cdata_deffence[id], cdata_moneygain[id]);
	
	nvault_get(database, szKey, szData, 255);
	replace_all(szData , 255, "#", " ");
	
	new data_health[128];
	new data_attack[128];
	new data_speed[128];
	new data_point[128];
	new data_level[128];
	new data_exp[128];
	new data_nexp[128];
	new data_deffence[128];
	new data_moneygain[128];
	parse(szData, data_health, 127, data_attack, 127, data_speed, 127, data_point, 127, data_level, 127, data_exp, 127, data_nexp, 127, data_deffence, 127, data_moneygain, 127);
	
	cdata_health[id] = str_to_num(data_health);
	cdata_attack[id] = str_to_num(data_attack);
	cdata_speed[id] = str_to_num(data_speed);
	cdata_points[id] = str_to_num(data_point);
	cdata_level[id] = str_to_num(data_level);
	cdata_exp[id] = str_to_num(data_exp);
	cdata_nexp[id] = str_to_num(data_nexp);
	cdata_deffence[id] = str_to_num(data_deffence);
	cdata_moneygain[id] = str_to_num(data_moneygain);
	
	if(cdata_nexp[id] == 0) {
		cdata_nexp[id] = 30;
	}
	
	if(cdata_level[id] == 0) {
		cdata_level[id] = 1;
	}
}

public reset_datas(id) {
	cdata_health[id] = 0;
	cdata_attack[id] = 0;
	cdata_speed[id] = 0;
	cdata_points[id] = 0;
	cdata_level[id] = 0;
	cdata_exp[id] = 0;
	cdata_nexp[id] = 0;
	cdata_deffence[id] = 0;
	cdata_moneygain[id] = 0;
}

public Menu(id) { 
	new menutitle[256];
	formatex(menutitle, charsmax(menutitle), "\y[ZombieSwarm] \wUpgrade Menu^n\yPoints: \w%d", cdata_points[id]);
    new menu = menu_create(menutitle, "Handle")
    
    new menuitem_health[128]; formatex(menuitem_health, charsmax(menuitem_health), "^^5%d-P - \wHealth Point: ^^3lv.%d ^^2(%d)", 1 + (cdata_health[id] / 5), cdata_health[id], 100 + (cdata_health[id] * 2));
    new menuitem_attack[128]; formatex(menuitem_attack, charsmax(menuitem_attack), "^^5%d-P - \wAttack Point: ^^3lv.%d ^^2(%0.2f)", 1 + (cdata_attack[id] / 5), cdata_attack[id], 1.0 + (cdata_attack[id] * 0.025));
    new menuitem_speed[128]; formatex(menuitem_speed, charsmax(menuitem_speed), "^^5%d-P - \wSpeed Point: ^^3lv.%d ^^2(%d)", 1 + (cdata_speed[id] / 5), cdata_speed[id], 250 + (cdata_speed[id] * 1));
    new menuitem_deffence[128]; formatex(menuitem_deffence, charsmax(menuitem_deffence), "^^5%d-P - \wDeffence Point: ^^3lv.%d ^^2(%0.2f)", 1 + (cdata_deffence[id] / 5), cdata_deffence[id], 0.00 + (cdata_deffence[id] * 0.015));
    new menuitem_moneygain[128]; formatex(menuitem_moneygain, charsmax(menuitem_moneygain), "^^5%d-P - \wMoneyGain Point: ^^3lv.%d ^^2(%d)", 1 + (cdata_moneygain[id] / 5), cdata_moneygain[id], 3 + (cdata_moneygain[id] * 3));
    new menuitem_reset[128]; formatex(menuitem_reset, charsmax(menuitem_reset), "Reset Points: ^^0[$ 7500]");
    
    menu_additem(menu, menuitem_health, "1", 0);
    menu_additem(menu, menuitem_attack, "2", 0);
    menu_additem(menu, menuitem_speed, "3", 0);
    menu_additem(menu, menuitem_deffence, "4", 0);
    menu_additem(menu, menuitem_moneygain, "5", 0);
    menu_additem(menu, menuitem_reset, "6", 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
    
    return PLUGIN_HANDLED;
}

public Handle(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[6], iName[64], access, callback;
    menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);
    new key = str_to_num(data);
    new cost;
    
    if(key==1) { cost = 1 + (cdata_health[id] / 5); }
    if(key==2) { cost = 1 + (cdata_attack[id] / 5); }
    if(key==3) { cost = 1 + (cdata_speed[id] / 5); }
    if(key==4) { cost = 1 + (cdata_deffence[id] / 5); }
    if(key==5) { cost = 1 + (cdata_moneygain[id] / 5); }
    
    if(key != 6 && cdata_points[id] < cost) {
    	menu_destroy(menu);
    	Menu(id); client_print(id, print_chat, "^^3[ZS] ^^7we need %d more point.", cost - cdata_points[id]);
        return PLUGIN_HANDLED;
    }
	
	if(key == 1) {
		if(cdata_health[id] >= 250) {
			client_print(id, print_chat, "^^3[ZS] ^^7You can't more upgrade this ability");
			Menu(id);
			return PLUGIN_HANDLED;
		}
		
		cdata_health[id]++;
	}
	
	if(key == 2) {
		if(cdata_attack[id] >= 125) {
			client_print(id, print_chat, "^^3[ZS] ^^7You can't more upgrade this ability");
			Menu(id);
			return PLUGIN_HANDLED;
		}
		
		cdata_attack[id]++;
	}
	
	if(key == 3) {
		if(cdata_speed[id] >= 50) {
			client_print(id, print_chat, "^^3[ZS] ^^7You can't more upgrade this ability");
			Menu(id);
			return PLUGIN_HANDLED;
		}
		
		cdata_speed[id]++;
	}
	
	if(key == 4) {
		if(cdata_deffence[id] >= 100) {
			client_print(id, print_chat, "^^3[ZS] ^^7You can't more upgrade this ability");
			Menu(id);
			return PLUGIN_HANDLED;
		}
		
		cdata_deffence[id]++;
	}
	
	if(key == 5) {
		if(cdata_moneygain[id] >= 50) {
			client_print(id, print_chat, "^^3[ZS] ^^7You can't more upgrade this ability");
			Menu(id);
			return PLUGIN_HANDLED;
		}
		
		cdata_moneygain[id]++;
	}
	
	if(key == 6) {
		reset_points(id);
	}
	
	if(key != 6) {
		cdata_points[id] -= cost;
	}
	
    menu_destroy(menu);
    Menu(id);
    return PLUGIN_HANDLED;
} 

public reset_points(id) {
	new cost = 7500;
	new total_point = 0;
	
	total_point += cdata_attack[id];
	total_point += cdata_health[id];
	total_point += cdata_speed[id];
	total_point += cdata_deffence[id];
	total_point += cdata_moneygain[id];
	
	if(!total_point) {
		client_print(id, print_chat, "^^3[ZS] ^^7You don't have the skills to reset.");
		return;
	}
	
	if(zs_get_user_money(id) < cost) {
		client_print(id, print_chat, "^^3[ZS] ^^7You can not purchase this item Reset Points");
		client_print(id, print_chat, "^^3[ZS] ^^7You need for purchase ^^2$ %d", cost - zs_get_user_money(id));
	} else if(total_point) {
		client_print(id, print_chat, "^^3[ZS] ^^7Your skill points have been reset");
		zs_set_user_money(id, zs_get_user_money(id) - cost);
		cdata_points[id] += total_point;
		
		cdata_attack[id] = 0;
		cdata_health[id] = 0;
		cdata_speed[id] = 0;
		cdata_deffence[id] = 0;
		cdata_moneygain[id] = 0;
	}
}