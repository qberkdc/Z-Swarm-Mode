#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zswarm_rpg>
#include <zombieswarm>

public plugin_init() {
	register_plugin("[ZS] Addon: Health Percentage", "v2.53.6", "--chcode");
	RegisterHam(Ham_TakeDamage, "player", "player_damage");
	register_message(get_user_msgid("Health"), "Message_Health")
}

public player_damage(victim, inflictor, attacker, Float: damage, damagebits) {
	if(!victim || !attacker || !is_user_alive(victim) || !is_user_alive(attacker)) {
		return;
	}
	
	if(!zs_get_user_zombie(victim)) {
		fm_set_user_health(victim, get_user_health(victim));
	}
}

public Message_Health(msg_id, msg_dest, id) {
	
	if(zs_get_user_zombie(id) || !is_user_alive(id)) {
		return;
	}
	
	// Get player's health
	new health = get_user_health(id);
	
	// Don't bother
	if(health < 1) 
		return;
		
	new maxhealth = 100 + (zs_rpg_get_health(id) * 5);
	new percent = 100 * health / maxhealth;
	
	set_msg_arg_int(1, get_msg_argtype(1), percent);
}
