#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <nvault>
#include <zombieswarm>

new database;
new cdata_money[33]

public plugin_init() {
	register_plugin("[ZS] Money Save", "v2.53.6", "--chcode");
	register_forward(FM_PlayerPreThink, "pl_prethink");
	RegisterHam(Ham_TakeDamage, "player", "pl_damage");
	database = nvault_open("money_cdata");
	
	register_message(get_user_msgid("Money"), "message_money")
}

public plugin_natives() {
	register_native("zs_get_user_money", "native_zs_get_user_money", 1);
	register_native("zs_set_user_money", "native_zs_set_user_money", 1);
}

public native_zs_get_user_money(id) {
	return cdata_money[id];
}

public native_zs_set_user_money(id, amount) {
	cdata_money[id] = amount;
}

public message_money(msg_id, msg_dest, msg_entity) {
	if(is_user_connected(msg_entity) && is_user_alive(msg_entity)) {
		cs_set_user_money(msg_entity, 0);
	}
	
	return PLUGIN_HANDLED;
}

public hide_money(id) {
	id -= 6333;
	
	if(!is_user_alive(id)) {
		return;
	}
	
	// Hide money
	message_begin(MSG_ONE, get_user_msgid("HideWeapon"), _, id)
	write_byte((1<<5)) // what to hide bitsum
	message_end()
	
	// Hide the HL crosshair that's drawn
	message_begin(MSG_ONE, get_user_msgid("Crosshair"), _, id)
	write_byte(0) // toggle
	message_end()
}


public pl_damage(victim, inflictor, attacker, Float:damage, damagebits) {
	if(!attacker || !victim || attacker == victim) {
		return;
	}
	
	if(zs_get_user_zombie(victim) && !zs_get_user_zombie(attacker)) {
		cdata_money[attacker] += (floatround(damage) / 4);
	}
}

public client_putinserver(id) { 
	set_task(0.4, "hide_money", id + 6333, _, _, "b");
}

public client_connect(id) {
	database_load(id);
}

public client_disconnected(id) { 
	database_save(id); 
}

public database_save(id) {
	new szAuth[33]; get_user_authid(id , szAuth , charsmax(szAuth));
	new szKey[64]; formatex(szKey , 63 , "%s ==> " , szAuth);
	new szData[256]; formatex(szData , 255 , "%d" , cdata_money[id]);
	
	nvault_pset(database , szKey , szData);
	
	cdata_money[id] = 0;
}

public database_load(id) {
	new szAuth[33]; get_user_authid(id , szAuth , charsmax(szAuth));
	new szKey[40]; formatex(szKey , 63 , "%s ==> " , szAuth);
	new szData[256]; formatex(szData , 255, "%d", cdata_money[id]);
	
	nvault_get(database, szKey, szData, 255);
	replace_all(szData , 255, "#", " ");
	
	new data[128]; parse(szData, data, 127);
	
	cdata_money[id] = str_to_num(data);
}