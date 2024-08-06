/* 
	Plugin by Doomsday
	ICQ: 692561
*/

#include <amxmodx>
#include <amxmisc>

#include <fakemeta_util>
#include <zombieswarm>
#include <hamsandwich>
#include <fakemeta>
#include <engine>

#include <fun>

#include <cstrike>
#include <zswarm_rpg>

#include <roundev>

#define PLUGIN "[ZS] Addon: Kill Rewards"
#define VERSION "1.0"
#define AUTHOR "Doomsday"

enum ammoboxs {
	GET = 0,
	TIC,
	TAC,
	DESTROY
}

new g_sprite_index[3];
new const g_sprite_string[][] = {
	"sprites/zswarm/rebox_drop.spr",
	"sprites/zswarm/rebox_destroy.spr",
	"sprites/zswarm/rebox_get.spr"
}

new const item_class_name[] = "ammo"
new const item_class_name_boss[] = "boss_ammo"
new g_model[] = "models/zswarm/rebox.mdl"
new g_model_boss[] = "models/zswarm/rebox_boss.mdl"
new sound[][] = {
	"zswarm/rebox_get.wav",
	"zswarm/rebox_tic.wav",
	"zswarm/rebox_tac.wav",
	"zswarm/rebox_destroy.wav"
}

public plugin_precache()
{
	precache_model(g_model);
	precache_model(g_model_boss);
	
	for(new i = 0; i < sizeof g_sprite_string; i++) {
		g_sprite_index[i] = precache_model(g_sprite_string[i]);
	}
	
	for(new i = 0; i < sizeof sound; i++) {
		precache_sound(sound[i]);
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_forward(FM_Touch, "fwd_Touch");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	register_round(ROUND_END, "EVENT_round_end");
}

public EVENT_round_end()
{
	set_task(0.5, "deleteAllItems", 9320);
}

public deleteAllItems()
{
	new Float: origin[3];
	new ent = FM_NULLENT;
	static string_class[] = "classname";
	
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, string_class, item_class_name))) {
		pev(ent, pev_origin, origin);
		emit_sound(ent, CHAN_AUTO, sound[DESTROY], 1.0, ATTN_NORM, 0, PITCH_NORM);
		sprite_index(g_sprite_index[1], 0, 0, 20, 7, origin);
		set_pev(ent, pev_flags, FL_KILLME);
	}
	
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, string_class, item_class_name_boss))) {
		pev(ent, pev_origin, origin);
		emit_sound(ent, CHAN_AUTO, sound[DESTROY], 1.0, ATTN_NORM, 0, PITCH_NORM);
		sprite_index(g_sprite_index[1], 0, 0, 20, 7, origin);
		set_pev(ent, pev_flags, FL_KILLME);
	}
}

public addItem(origin[3], id)
{
	new ent = fm_create_entity("info_target")
	
	if(!zs_get_user_boss(id)) {
		set_pev(ent, pev_classname, item_class_name)
		engfunc(EngFunc_SetModel,ent, g_model)
	} else {
		set_pev(ent, pev_classname, item_class_name_boss)
		engfunc(EngFunc_SetModel,ent, g_model_boss)
	}

	set_pev(ent,pev_mins,Float:{-10.0,-10.0,0.0})
	set_pev(ent,pev_maxs,Float:{10.0,10.0,25.0})
	set_pev(ent,pev_size,Float:{-10.0,-10.0,0.0,10.0,10.0,25.0})
	engfunc(EngFunc_SetSize,ent,Float:{-10.0,-10.0,0.0},Float:{10.0,10.0,25.0})

	set_pev(ent,pev_solid,SOLID_BBOX)
	set_pev(ent,pev_movetype,MOVETYPE_TOSS)
	/* set_pev(ent,pev_owner,id) */
	
	new Float:fOrigin[3]
	IVecFVec(origin, fOrigin)
	set_pev(ent, pev_origin, fOrigin)
	
	new Float:velocity[3];
	pev(ent,pev_velocity,velocity);
	velocity[2] = random_float(10.0,12.0);
	set_pev(ent,pev_velocity,velocity)
	
	new Float: origin[3];
	pev(ent, pev_origin, origin);
	sprite_index(g_sprite_index[0], 0, 0, 0, 3, origin);
	
	set_task(5.0, "glow_flow_r", ent);
	set_task(10.0, "delete_ent", ent);
}

public glow_flow_r(entity) {
	if(pev_valid(entity)) {
		emit_sound(entity, CHAN_AUTO, sound[TAC], 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_task(0.5, "glow_flow_null", entity);
		fm_set_rendering(entity, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16)
	} else {
		remove_task(entity);
		return PLUGIN_HANDLED;
	}
}

public glow_flow_null(entity) {
	if(pev_valid(entity)) {
		emit_sound(entity, CHAN_AUTO, sound[TIC], 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_task(0.5, "glow_flow_r", entity);
		fm_set_rendering(entity, kRenderFxNone, 0, 0, 0, kRenderNormal, 16)
	} else {
		remove_task(entity);
		return PLUGIN_HANDLED;
	}
}

public delete_ent(entity) {
	if(pev_valid(entity)) {
		new Float: origin[3];
		pev(entity, pev_origin, origin);
		sprite_index(g_sprite_index[1], 0, 0, 20, 7, origin);
	
		emit_sound(entity, CHAN_AUTO, sound[DESTROY], 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_pev(entity, pev_flags, FL_KILLME);
	} else {
		return PLUGIN_HANDLED;
	}
}

public fwd_Touch(toucher, touched)
{
	if (!is_user_alive(toucher) || !pev_valid(touched) || zs_get_user_zombie(toucher))
		return FMRES_IGNORED;
	
	new classname[32];
	pev(touched, pev_classname, classname, 31);

	/* new owner = pev(touched, pev_owner);
	server_print("Owner: { %d } | Entity: { %d }", owner, touched);
	
	if(owner != toucher) {
		return FMRES_IGNORED;
	} */
	
	new random_item = random(5);
	new health = get_user_health(toucher);
	new maxhealth = 100 + (5 * zs_rpg_get_health(toucher));
	
	if (equal(classname, item_class_name)) {
		switch(random_item) {
			case 0: {
				zs_set_user_money(toucher, zs_get_user_money(toucher) + 500);
			}
		
			case 1: {
				zs_rpg_set_points(toucher, zs_rpg_get_points(toucher) + 1);
			}
		
			case 2: {
				const health_reward = 25;
			
				if(health + health_reward > maxhealth) {
					fm_set_user_health(toucher, maxhealth);
				} else {
					fm_set_user_health(toucher, health + health_reward);
				}
			}
		
			case 3: {
				new hg = cs_get_user_bpammo(toucher, CSW_HEGRENADE);
			
				if(!hg) {
					give_item(toucher, "weapon_hegrenade");
				} else if(hg < 3) {
					cs_set_user_bpammo(toucher, CSW_HEGRENADE, hg + 1);
				}
			}
		
			case 4: {
				zs_rpg_set_exp(toucher, zs_rpg_get_exp(toucher) + 5);
			}
		}
	
		new name[64];
		get_user_name(toucher, name, charsmax(name));
		remove_color(name, charsmax(name));
	
		switch(random_item) {
			case 0: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 500 money out of the box", name);
			case 1: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 1 point out of the box", name);
			case 2: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 25 health out of the box", name);
			case 3: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 1 grenade out of the box", name);
			case 4: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 5 exp out of the box", name);
		}
	}
	
	if (equal(classname, item_class_name_boss)) {
		random_item = random(7);
		switch(random_item) {
			case 0: {
				zs_set_user_money(toucher, zs_get_user_money(toucher) + 10000);
			}
		
			case 1: {
				zs_rpg_set_points(toucher, zs_rpg_get_points(toucher) + 20);
			}
		
			case 2: {
				zs_rpg_set_health(toucher, zs_rpg_get_health(toucher) + 5);
			}
		
			case 3: {
				zs_rpg_set_attack(toucher, zs_rpg_get_attack(toucher) + 5);
			}
		
			case 4: {
				zs_rpg_set_speed(toucher, zs_rpg_get_speed(toucher) + 5);
			}
			
			case 5: {
				zs_rpg_set_deffence(toucher, zs_rpg_get_deffence(toucher) + 5);
			}
			
			case 6: {
				zs_rpg_set_moneygain(toucher, zs_rpg_get_moneygain(toucher) + 5);
			}
		}
	
		new name[64];
		get_user_name(toucher, name, charsmax(name));
		remove_color(name, charsmax(name));
	
		switch(random_item) {
			case 0: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 10000 money out of the box", name);
			case 1: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 20 point out of the box", name);
			case 2: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 5 health sp out of the box", name);
			case 3: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 5 attack sp out of the box", name);
			case 4: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 5 speed sp of the box", name);
			case 5: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 5 deffence sp of the box", name);
			case 6: client_print(0, print_chat, "^^3[ZS]^^7 %s he took 5 money gain sp of the box", name);
		}
	}
	
	if (equal(classname, item_class_name) || equal(classname, item_class_name_boss)) {
		new Float: origin[3];
		pev(touched, pev_origin, origin);
		sprite_index(g_sprite_index[2], 0, 0, 20, 10, origin);
	
   	 emit_sound(toucher, CHAN_AUTO, sound[GET], 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_pev(touched, pev_flags, FL_KILLME);
	
		remove_task(touched);
		return FMRES_IGNORED;
	}
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(!attacker || !victim || attacker == victim || !zs_get_user_zombie(victim)) {
		return;
	}
	
	new Float: origin[3];
    get_user_origin(victim , origin);
	
	if(zs_get_user_boss(victim)) {
		addItem(origin, victim);
	} else if(random(6) == 0) {
		addItem(origin, victim);
	}
}

public sprite_index(sprite, x, y, z, scale, Float: origin[3]) {
	for(new i = 0; i < 3; i++) {
		origin[i] = floatround(origin[i], floatround_tozero);
	}
	
	server_print("%d, %d, %d", origin[0], origin[1], origin[2]);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_SPRITE); // TE id
	write_coord(origin[0] + x); // x
	write_coord(origin[1] + y); // y
	write_coord(origin[2] + z); // z
	write_short(sprite); // sprite
	write_byte(scale); // scale
	write_byte(255); // brightness
	message_end();
}