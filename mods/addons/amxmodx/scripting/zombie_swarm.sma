#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <fun>
#include <screen>
#include <roundev>

#define SURVIVOR_PUNCHANGLE 30.0
#define SURVIVOR_BACKSPEED 1.0

#define ZOMBIE_SLASH_MIN 1.0
#define ZOMBIE_SLASH_MAX 3.0
#define ZOMBIE_STAB_MIN 5.5
#define ZOMBIE_STAB_MAX 8.5

#define BOSS_SLASH_MIN 30.0
#define BOSS_SLASH_MAX 50.0
#define BOSS_STAB_MIN 80.0
#define BOSS_STAB_MAX 100.0

#define ZOMBIE_RADIO_SPEED 50

enum _: {
	MALE = 0,
	FEMALE
};

#pragma semicolon 1

#define Ham_Player_ResetMaxSpeed Ham_Item_PreFrame
#define write_coord_f(%1) engfunc(EngFunc_WriteCoord,%1)

new const m_iId                   = 43;
new const m_flNextPrimaryAttack   = 46;
new const m_flNextSecondaryAttack = 47;
new const m_pActiveItem           = 373;

enum (+= 1000)
{
	TASKID_MODEL = 1000,
	TASKID_STRIP,
	TASKID_NVG,
	TASKID_HEALTH,
	TASKID_ROUND
}

enum (<<= 1)
{
	MOD_SCOUT = 1,	//a.
	MOD_XM1014,		//b...
	MOD_MAC10,
	MOD_AUG,
	MOD_UMP45,
	MOD_SG550,
	MOD_GALIL,
	MOD_FAMAS,
	MOD_AWP,
	MOD_MP5NAVY,
	MOD_M249,
	MOD_M3,
	MOD_M4A1,
	MOD_TMP,
	MOD_G3SG1,
	MOD_SG552,
	MOD_AK47,
	MOD_P90,
	MOD_P228,
	MOD_ELITE,
	MOD_FIVESEVEN,
	MOD_USP,
	MOD_GLOCK18,
	MOD_DEAGLE,
	MOD_VEST,
	MOD_VESTHELM
};

new const weapon_names[26][16] =
{
	"Scout",
	"XM1014",
	"Mac10",
	"Aug",
	"UMP",
	"SG550",
	"Galil",
	"Famas",
	"AWP",
	"MP5Navy",
	"M249",
	"M3",
	"M4A1",
	"TMP",
	"G3SG1",
	"SG552",
	"AK47",
	"P90",
	"P228",
	"Elite",
	"Fiveseven",
	"USP",
	"Glock18",
	"Deagle",
	"VEST",
	"VESTHELM"
};

new const g_MaxBPAmmo[] = 
{
	0,
	52,	//CSW_P228
	0,
	90,	//CSW_SCOUT
	1,	//CSW_HEGRENADE
	32,	//CSW_XM1014
	1,	//CSW_C4
	100,//CSW_MAC10
	90,	//CSW_AUG
	1,	//CSW_SMOKEGRENADE
	120,//CSW_ELITE
	100,//CSW_FIVESEVEN
	100,//CSW_UMP45
	90,	//CSW_SG550
	90,	//CSW_GALIL
	90,	//CSW_FAMAS
	100,//CSW_USP
	120,//CSW_GLOCK18
	30,	//CSW_AWP
	120,//CSW_MP5NAVY
	200,//CSW_M249
	32,	//CSW_M3
	90,	//CSW_M4A1
	120,//CSW_TMP
	90,	//CSW_G3SG1
	2,	//CSW_FLASHBANG
	35,	//CSW_DEAGLE
	90,	//CSW_SG552
	90,	//CSW_AK47
	0,	//CSW_KNIFE
	100//CSW_P90
};

new g_bBoss[33];
new rounds;
new boss_rounds;
new g_RoundStatus;
new g_ZombieModelIndex[33];

new bool: g_ShowMenu[33];
new bool: g_ShowMenuFirstTime[33];
new g_PickedWeapons[2][33];
new g_CurOffset[33];
new g_OptionsOnMenu[8][33];
new g_ForwardZombieSpawn;
new g_ForwardDummy;

new const g_Menu_WeaponID[] = "Menu_WeaponID";
new const g_Menu_PrimaryID[]  = "Menu_PrimaryID";
new const g_Menu_SecID[] = "Menu_SecondaryID";

new const g_szClass_flesh[] = "flesh throw";

new const g_MapEntities[][] =
{
	"info_map_parameters",
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone"
};

new const g_TouchBlockEnts[][] =
{
	"armoury_entity",
	"weaponbox",
	"weapon_shield"
};

new const g_SendAudio_RoundStart[][] =
{
	"%!MRAD_LETSGO",
	"%!MRAD_MOVEOUT",
	"%!MRAD_LOCKNLOAD"
};

new const g_SendAudio_Radio[][] =
{
	"%!MRAD_COVERME",
	"%!MRAD_TAKEPOINT",
	"%!MRAD_POSITION",
	"%!MRAD_REGROUP",
	"%!MRAD_FOLLOWME",
	"%!MRAD_HITASSIST",
	"%!MRAD_GO",				//Conflicts with round start audio
	"%!MRAD_FALLBACK",
	"%!MRAD_STICKTOG",
	"%!MRAD_GETINPOS",
	"%!MRAD_STORMFRONT",
	"%!MRAD_REPORTIN",
	"%!MRAD_AFFIRM",
	"%!MRAD_ROGER",
	"%!MRAD_ENEMYSPOT",
	"%!MRAD_BACKUP",
	"%!MRAD_CLEAR",
	"%!MRAD_INPOS",
	"%!MRAD_REPRTINGIN",
	"%!MRAD_BLOW",
	"%!MRAD_NEGATIVE",
	"%!MRAD_ENEMYDOWN"
};

new const g_BossWarning[] = "zswarm/boss_warn.wav";
new const g_BossStart[] = "zswarm/boss_start.wav";
new const g_sound_roundstart[] = "zswarm/start.wav";
new const g_sound_roundstats[] = "zswarm/round.wav";
new const g_sound_zombiewin[] = "zswarm/win_zombie.wav";
new const g_sound_humanwin[] = "zswarm/win_human.wav";

new const g_sound_miss[][] =
{
	"zswarm/cso_slash1.wav",
	"zswarm/cso_slash2.wav",
	"zswarm/cso_slash3.wav"
};

new const g_sound_hit[][] =
{
	"zswarm/cso_attack1.wav",
	"zswarm/cso_attack2.wav",
	"zswarm/cso_attack3.wav"
};

new const g_sound_pain[][] =
{
	"zswarm/cso_hurt1.wav",
	"zswarm/cso_hurt2.wav"
};

new const g_sound_female_pain[][] =
{
	"zswarm/light_hurt1.wav"
};

new const g_sound_die[][] =
{
	"zswarm/cso_death1.wav",
	"zswarm/cso_death2.wav"
};

new const g_sound_female_die[][] =
{
	"zswarm/light_death1.wav"
};

new const g_sound_boss_pain[][] =
{
	"zswarm/cso_boss_hurt1.wav",
	"zswarm/cso_boss_hurt2.wav"
};

new const g_sound_boss_die[][] =
{
	"zswarm/cso_boss_death1.wav",
	"zswarm/cso_boss_death2.wav"
};

new const g_SoundBuild[][] =
{
	"buttons/spark1.wav",
	"buttons/spark2.wav",
	"buttons/spark3.wav",
	"buttons/spark4.wav",
	"buttons/spark5.wav",
	"buttons/spark6.wav"

};

new const g_SoundComplete[][] = 
{
	"buttons/button1.wav",
	"buttons/button3.wav",
	"buttons/button4.wav",
	"buttons/button5.wav",
	"buttons/button6.wav",
	"buttons/button9.wav"
};

new Float:g_flDisplayDamage[33];

new bool: g_bZombie[33];

new bool: g_bHeadshot[33][33];
new bool: g_bModel[33];
new g_CurrentModel[33][32];

new Float: g_LastLeap[33];
new Float: g_LastFthrow[33];

new bool: g_bDeadNvg[2][33];
new g_bCustomNvg[33];

new g_EntIndex[256];
new g_EntCount;
new bool: g_EntActive[256];
	
new g_WeaponIndex[33];
new g_WeaponId[33];

new const g_RandomModel[][] =
{
	"terror",
	"leet",
	"arctic",
	"guerilla",
	"urban",
	"gsg9",
	"sas",
	"gign"
};

new const g_ZombiePlayerModels[][] = {
	"cso_zombie",
	"cso_light"
};

new const g_ZombieClaws[][] = { 
	"models/zswarm/v_zombie_knife.mdl",
	"models/zswarm/v_light_knife.mdl"
};

new const g_ZombieModelGender[] = {
	MALE,
	FEMALE
};

new const g_BossPlayerModels[] = "cso_boss";
new const g_BossClaws[] = "models/zswarm/v_boss_knife.mdl";
new const g_ZombieFleshThrow[] = "models/hgibs.mdl";	//11 Submodels

new g_MaxPlayers;
new g_RoundCounter;
new bool: g_bTimerStart;
new bool: g_bFreezeTime;
new g_bFFire;

new g_ForwardSpawn;

new g_bIsAlive[33], g_bIsBot[33];

new g_MsgID_Health, g_MsgID_ScreenFade, g_MsgID_SetFov, g_MsgID_NVGToggle;

new cvar_Swith, cvar_Health, cvar_Armour, cvar_Gravity, cvar_Footsteps, cvar_Speed,
cvar_AutoNvg, cvar_Round, cvar_Teams, cvar_Blocknvg, cvar_Lights,
cvar_Leap, cvar_LeapCooldown, cvar_LeapForce, cvar_LeapHeight,
cvar_FleshThrow, cvar_FleshForce, cvar_FleshDmg, cvar_FleshSelfDmg, cvar_FleshBreakEnts,
cvar_Skyname, cvar_EndRound,
cvar_GunMenu, cvar_Weapons, cvar_Equip;

#define PLUGIN "Zombie Swarm"
#define VERSION "3.1"
#define AUTHOR "--chcode & MMidget"

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar(PLUGIN, VERSION, FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string(PLUGIN, VERSION);
	register_dictionary("zombie_swarm.txt");

	register_concmd("zombie_swarm", "concmd_zombieswarm", ADMIN_BAN, "<0/1> Disable/Enable Zombie Swarm");

	cvar_Swith = register_cvar("zswarm_enable", "1");

	if(!get_pcvar_num(cvar_Swith))
		return;
		
	new sz_Model[256];

	for(new i = 0 ; i < sizeof g_ZombiePlayerModels ; i++)
	{
		format(sz_Model, charsmax(sz_Model), "models/player/%s/%s.mdl", g_ZombiePlayerModels[i], g_ZombiePlayerModels[i]);
		precache_model(sz_Model);
	}
	
	format(sz_Model, charsmax(sz_Model), "models/player/%s/%s.mdl", g_BossPlayerModels, g_BossPlayerModels);
	precache_model(sz_Model);
	
	for(new i = 0; i < sizeof(g_RandomModel); i++) {
		format(sz_Model, charsmax(sz_Model), "models/player/%s/%s.mdl", g_RandomModel[i], g_RandomModel[i]);
		precache_model(sz_Model);
	}
	
	for(new i = 0; i < sizeof(g_ZombieClaws); i++) {
		precache_model(g_ZombieClaws[i]);
	}
	
	precache_model(g_BossClaws);

	new iNum;
	for (iNum = 0; iNum < sizeof g_sound_miss; iNum++)
		precache_sound(g_sound_miss[iNum]);
	for (iNum = 0; iNum < sizeof g_sound_hit; iNum++)
		precache_sound(g_sound_hit[iNum]);
	for (iNum = 0; iNum < sizeof g_sound_pain; iNum++)
		precache_sound(g_sound_pain[iNum]);
	for (iNum = 0; iNum < sizeof g_sound_die; iNum++)
		precache_sound(g_sound_die[iNum]);
	for (iNum = 0; iNum < sizeof g_sound_female_pain; iNum++)
		precache_sound(g_sound_female_pain[iNum]);
	for (iNum = 0; iNum < sizeof g_sound_female_die; iNum++)
		precache_sound(g_sound_female_die[iNum]);
	for (iNum = 0; iNum < sizeof g_sound_boss_pain; iNum++)
		precache_sound(g_sound_boss_pain[iNum]);
	for (iNum = 0; iNum < sizeof g_sound_boss_die; iNum++)
		precache_sound(g_sound_boss_die[iNum]);
	
	for (iNum = 0; iNum < sizeof g_SoundBuild; iNum++)
		precache_sound(g_SoundBuild[iNum]);
	
	for (iNum = 0; iNum < sizeof g_SoundComplete; iNum++)
		precache_sound(g_SoundComplete[iNum]);
		
	precache_sound(g_BossStart);
	precache_sound(g_BossWarning);
	precache_sound(g_sound_zombiewin);
	precache_sound(g_sound_humanwin);
	precache_sound(g_sound_roundstart);
	precache_sound(g_sound_roundstats);
	
	new iEnt = create_entity("info_map_parameters");
	DispatchKeyValue(iEnt, "buying", "1");
	DispatchSpawn(iEnt);

	g_ForwardSpawn = register_forward(FM_Spawn, "Forward_Spawn");
}

public plugin_natives() {
	register_native("zs_get_user_zombie", "native_zs_get_user_zombie", 1);
	register_native("zs_get_user_boss", "native_zs_get_user_boss", 1);
}

public native_zs_get_user_zombie(id) {
	return g_bZombie[id];
}

public native_zs_get_user_boss(id) {
	return g_bBoss[id];
}

public plugin_init()
{
	if(!get_pcvar_num(cvar_Swith))
		return;

	register_cvar("zswarm_fog_enable", "1");
	register_cvar("zswarm_fog_color", "255 255 255");
	register_cvar("zswarm_fog_density", "0.0014");
	register_cvar("zswarm_boss_health", "10000");
	register_cvar("zswarm_zombie_xdmg", "4");
	register_cvar("zswarm_zombie_xhp", "65");
	register_cvar("zswarm_boss_xdmg", "8");
	register_cvar("zswarm_boss_xhp", "1500");
	register_cvar("zswarm_fog_enable", "1");
	cvar_Health	 = register_cvar("zswarm_health", "80");
	cvar_Armour	 = register_cvar("zswarm_armour", "100");
	cvar_Gravity = register_cvar("zswarm_gravity", "600");
	cvar_Footsteps = register_cvar("zswarm_footsteps", "1");
	cvar_Speed = register_cvar("zswarm_speed", "148");
	cvar_AutoNvg = register_cvar("zswarm_autonvg", "1");
	cvar_Round = register_cvar("zswarm_rounds", "999");
	cvar_Teams = register_cvar("zswarm_blockteams", "0");
	cvar_Blocknvg = register_cvar("zswarm_blocknvg", "0");
	cvar_Lights = register_cvar("zswarm_lights", "f");
	cvar_Leap = register_cvar("zswarm_leap", "1");
	cvar_LeapCooldown = register_cvar("zswarm_cooldown", "10.0");
	cvar_LeapForce = register_cvar("zswarm_lforce", "400");
	cvar_LeapHeight = register_cvar("zswarm_lheight", "260");
	cvar_FleshThrow = register_cvar("zswarm_fleshthrow", "1");
	cvar_FleshForce = register_cvar("zswarm_fforce", "500");
	cvar_FleshDmg = register_cvar("zswarm_fleshdmg", "5");
	cvar_FleshSelfDmg = register_cvar("zswarm_fselfdmg", "250");
	cvar_FleshBreakEnts = register_cvar("zswarm_fleshents", "1");
	cvar_Skyname = register_cvar("zswarm_skyname", "night");
	cvar_EndRound = register_cvar("zswarm_endround", "1");
	cvar_GunMenu = register_cvar("zswarm_gunmenu", "1");
	cvar_Weapons = register_cvar("zswarm_weapons", "abcdefghijklmnopqrstuvwxyz");
	cvar_Equip = register_cvar("zswarm_equip", "hhhn");

	g_MsgID_Health = get_user_msgid("Health");
	g_MsgID_ScreenFade = get_user_msgid("ScreenFade");
	g_MsgID_SetFov = get_user_msgid("SetFOV");
	g_MsgID_NVGToggle = get_user_msgid("NVGToggle");
	
	RegisterHam(Ham_Spawn, "player", "Bacon_Spawn_Post", 1);
	RegisterHam(Ham_TraceAttack, "player", "Bacon_TraceAttack_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "Bacon_TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "Bacon_TakeDamage_Post" , 1);
	RegisterHam(Ham_Killed, "player", "Bacon_Killed_Post", 1);
	for(new i = 0 ; i < sizeof g_TouchBlockEnts ; i++)
		RegisterHam(Ham_Touch,	g_TouchBlockEnts[i], "Bacon_Touch");
	RegisterHam(Ham_Player_ResetMaxSpeed, "player",	"Bacon_ResetMaxSpeed", 1);

	register_logevent("Logevent_RoundStart", 2,	"1=Round_Start");
	register_logevent("Logevent_RoundEnd" , 2, "1=Round_End");

	register_event("TextMsg", "Event_TextMsg", "a", "2&#Game_C", "2&#Game_w" );
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");
	register_event("CurWeapon", "Event_CurWeapon" , "be", "1=1");

	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon");
	register_message(g_MsgID_Health, "Message_Health");
	register_message(get_user_msgid("Battery"), "Message_Battery");
	register_message(get_user_msgid("TextMsg"),	"Message_TextMessage");
	register_message(get_user_msgid("RoundTime"), "Message_RoundTimer");
	register_message(g_MsgID_NVGToggle, "Message_NVGToggle");
	register_message(get_user_msgid("SendAudio"), "Message_SendAudio");

	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET);

	register_menucmd(register_menuid(g_Menu_WeaponID), MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_0,"MenuID_Weapon");
	register_menucmd(register_menuid(g_Menu_PrimaryID), MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4| MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0, "MenuID_Primary");
	register_menucmd(register_menuid(g_Menu_SecID), MENU_KEY_1| MENU_KEY_2| MENU_KEY_3| MENU_KEY_4| MENU_KEY_5| MENU_KEY_6| MENU_KEY_7| MENU_KEY_8, "MenuID_Secondary");

	register_clcmd("chooseteam", "ClCmd_teams");
	register_clcmd("nightvision", "ClCmd_nvg");
	register_clcmd("say guns", "ClCmd_guns");
	register_clcmd("say_team guns", "ClCmd_guns");
	register_clcmd("say /guns", "ClCmd_nextguns");
	register_clcmd("say_team /guns", "ClCmd_nextguns");
	
	register_round(ROUND_START, "sv_round_start");
	register_round(ROUND_RESTART, "sv_round_restart");
	register_round(ROUND_NEW, "sv_round_new");
	
	register_concmd("zswarm_menu_AddWeap", "ConCmd_addweap", ADMIN_BAN, "<Weapon> Un-Restricts a weapon from the weapons menu.");
	register_concmd("zswarm_menu_DelWeap", "ConCmd_delweap", ADMIN_BAN, "<Weapon> Restricts a weapon from the weapons menu.");

	register_forward(FM_PlayerPreThink, "pl_prethink");

	if(g_ForwardSpawn > 0)
		unregister_forward(FM_Spawn, g_ForwardSpawn);

	register_forward(FM_CmdStart, "Forward_CmdStart");
	register_forward(FM_EmitSound, "Forward_EmitSound");
	register_forward(FM_Touch, "Forward_Touch");
	register_forward(FM_TraceLine, "Forward_TraceLine_Post", 1);
	register_forward(FM_AddToFullPack, "Forward_AddToFullPack_Post", 1);
	register_think(g_szClass_flesh, "Forward_Think_Flesh");
	
	g_ForwardZombieSpawn = CreateMultiForward("zs_zombie_spawn", ET_IGNORE, FP_CELL);
	
	server_cmd("exec addons/amxmodx/configs/zombie_swarm.cfg");
	
	new sz_Sky[32];
	get_pcvar_string(cvar_Skyname, sz_Sky, charsmax(sz_Sky));

	set_cvar_string("sv_skyname", sz_Sky);
	set_cvar_num("sv_skycolor_r", 0);
	set_cvar_num("sv_skycolor_g", 0);
	set_cvar_num("sv_skycolor_b", 0);
	server_cmd("sv_maxspeed 2000");

	g_MaxPlayers = get_maxplayers();
	g_bFFire = get_cvar_pointer("mp_friendlyfire");
	
	set_task(0.25, "Forward_Think_Weather", _, _, _, "b" );
}

public pl_prethink(id) {
	if(is_user_alive(id)) {
		new weapon = get_user_weapon(id);
		if(weapon != 0 && weapon != CSW_KNIFE && weapon != CSW_FLASHBANG && weapon != CSW_SMOKEGRENADE && weapon != CSW_HEGRENADE) {
			
			new clip, ammo;
			get_user_ammo(id, weapon, clip, ammo);
			
			if(ammo < g_MaxBPAmmo[weapon]) {
				cs_set_user_bpammo(id, weapon, g_MaxBPAmmo[weapon]);
			}
		}
	}
}

public select_boss() {
	new players[33];
	new counts;
	
	for(new i = 0; i < get_maxplayers(); i++) {
		if(is_user_alive(i)) {
			new CsTeams: team = cs_get_user_team(i);
			if(team == CS_TEAM_T) {
				players[counts] = i;
				counts++;
			}
		}
	}
	
	new id = players[random(counts)];
	
	g_bBoss[id] = 1;
	cs_set_user_model(id, g_BossPlayerModels);
	fm_set_user_health(id, get_cvar_num("zswarm_boss_health") + (rounds * get_cvar_num("zswarm_boss_xhp")));
	
	new name[64];
	get_user_info(id, "name", name, charsmax(name));
	set_hudmessage(255, 120, 120, -1.0, 0.2, 0, 0.0, 0.1, 0.0, 2.0, 1);
	show_hudmessage(0, "| BOSS ARRIVED |^n%s", name);
	
	Task_Strip(id + TASKID_STRIP);
}

public sv_round_new() {
	for(new i = 0; i < get_maxplayers(); i++) {
		g_bBoss[i] = 0;
	}
}
	
public sv_round_start() {
	for(new i = 0; i < get_maxplayers(); i++) {
		g_bBoss[i] = 0;
	}
	
	rounds++;
	boss_rounds--;
	
	if(boss_rounds==0) {
		boss_rounds = 5;
		set_hudmessage(255, 120, 120, -1.0, 0.2, 0, 0.0, 0.1, 0.0, 1.5, 1);
		show_hudmessage(0, "| BOSS ROUND |^nRound: %d", rounds);
		set_task(2.0, "select_boss", 0);
		screenfade(0, 255, 0, 0, 100, FFADE_OUT, 2, 1.5);
		client_cmd(0, "spk sound/%s", g_BossStart);
	} else if(boss_rounds>1) {
		set_hudmessage(255, 255, 255, -1.0, 0.2, 0, 0.0, 0.1, 0.0, 4.5, 1);
		show_hudmessage(0, "Round: %d", rounds);
		sound_play(2);
	} else if(boss_rounds==1) {
		set_hudmessage(255, 150, 150, -1.0, 0.2, 0, 0.0, 0.1, 0.0, 4.5, 1);
		show_hudmessage(0, "| THE BOSS WILL COME |^nRound: %d", rounds);
		client_cmd(0, "spk sound/%s", g_BossWarning);
	}
	
	set_task(4.85, "round_stats", 0);
	
}

public round_stats() {
	new rs_health = get_pcvar_num(cvar_Health) + (rounds * get_cvar_num("zswarm_zombie_xhp"));
	new rs_health_boss = get_cvar_num("zswarm_boss_health") + (rounds * get_cvar_num("zswarm_boss_xhp"));
	new Float: rs_dmg_zombie = ZOMBIE_SLASH_MAX + (rounds * get_cvar_num("zswarm_zombie_xdmg"));
	new Float: rs_dmg_boss = BOSS_SLASH_MAX + (rounds * get_cvar_num("zswarm_boss_xdmg"));
	
	set_hudmessage(255, 255, 190, -1.0, 0.2, 0, 0.0, 0.1, 0.0, 4.5, 1);
	show_hudmessage(0, "| ROUND STATS |^nHealth: %d | %d^nDamage: %0.2f | %0.2f", rs_health, rs_health_boss, rs_dmg_zombie, rs_dmg_boss);
	
	sound_play(3);
}

public sv_round_restart() {
	rounds = 0;
	boss_rounds = 5;
}

public plugin_cfg()
{
	if(!get_pcvar_num(cvar_Swith))
		return;
	
	boss_rounds = 5;
	rounds = 1;
	
	g_RoundStatus = 1;
}
	
public client_putinserver(id)
{
	g_ShowMenu[id] = true;
	g_ShowMenuFirstTime[id] = true;
	
	if(is_user_bot(id))
		g_bIsBot[id] = true;
}

public client_disconnected(id)
{
	g_bIsAlive[id] = false;
	g_bIsBot[id] = false;
}

public concmd_zombieswarm(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	new sz_Args[8];
	read_argv(id, sz_Args, charsmax(sz_Args));

	if ( equali(sz_Args, "1") || equali(sz_Args, "on") || equali(sz_Args, "enable") )
	{
		set_task(5.0, "Task_Restart");
		set_pcvar_num(cvar_Swith, 1);

		set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 1.0, 5.0, 0.1, 0.2, -1);
		show_hudmessage(0, "%L", LANG_PLAYER, "PLUGIN_HON_MSG", PLUGIN);

		console_print(0, "%L", LANG_PLAYER, "PLUGIN_TON_MSG", PLUGIN);
		for(new i = 1; i < 6; i++)
			client_print(0, print_chat, "%L", LANG_PLAYER, "PLUGIN_TON_MSG", PLUGIN);

		return PLUGIN_HANDLED;
	}
	else if ( equali(sz_Args, "0") || equali(sz_Args, "off") || equali(sz_Args, "disable") )
	{

		set_task(5.0, "Task_Restart");
		set_pcvar_num(cvar_Swith, 0);

		set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 1.0, 5.0, 0.1, 0.2, -1);
		show_hudmessage(0, "%L", LANG_PLAYER, "PLUGIN_HOFF_MSG", PLUGIN);

		console_print(0, "%L", LANG_PLAYER, "PLUGIN_TOFF_MSG", PLUGIN);
		for(new i = 1; i < 6; i++)
			client_print(0, print_chat, "%L", LANG_PLAYER, "PLUGIN_TOFF_MSG", PLUGIN);

		return PLUGIN_HANDLED;
	}

	console_print(id,  "Invalid argument!");

	return PLUGIN_HANDLED;
}

public Forward_Spawn(iEnt)
{
	if(!pev_valid(iEnt))
		return FMRES_IGNORED;

	static className[32];
	pev(iEnt, pev_classname, className, charsmax(className));

	for(new i = 0; i < sizeof g_MapEntities; ++i)
	{
		if(equal(className, g_MapEntities[i]))
		{
			remove_entity(iEnt);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public Bacon_Spawn_Post(id)
{
	set_task(0.18, "Task_Model", id + TASKID_MODEL);
	
	if(!is_user_alive(id))
		return;

	g_bIsAlive[id] = true;
	
	new CsTeams: team = cs_get_user_team(id);
	new sz_CurrentModel[32];

	if(team == CS_TEAM_T)
	{
		new Health, Armour, Float: Gravity, FootSteps;
		Health = get_pcvar_num(cvar_Health) + (rounds * get_cvar_num("zswarm_zombie_xhp"));
		Armour = get_pcvar_num(cvar_Armour);
		Gravity = get_pcvar_float(cvar_Gravity) / 800;
		FootSteps = get_pcvar_num(cvar_Footsteps);

		set_pev(id, pev_max_health, float(Health));
		set_user_health(id, Health);
		// cs_set_user_armor(id, Armour, CS_ARMOR_VESTHELM);
		set_user_gravity(id, Gravity);
		set_user_footsteps(id, FootSteps);

		if(!g_bZombie[id])
		{
			g_bZombie[id] = true;
			fm_reset_user_model(id);
		}
		
		new modelindex = random(sizeof g_ZombiePlayerModels);
		copy(g_CurrentModel[id], charsmax(g_CurrentModel[]), g_ZombiePlayerModels[modelindex]);

		fm_get_user_model(id, sz_CurrentModel, charsmax(sz_CurrentModel) );

		if(!cs_get_user_nvg(id))
			cs_set_user_nvg(id);

		if(get_pcvar_num(cvar_AutoNvg))
			set_task(0.2, "Task_NVG", TASKID_NVG + id);

	}
	else if(team == CS_TEAM_CT)
	{
		g_ShowMenuFirstTime[id] = true;
		g_ShowMenu[id] = false;
		
		new he, flash, smoke;
		new weapon[32];
		get_pcvar_string(cvar_Equip, weapon, charsmax(weapon));
		
		for(new i = 0 ; i < strlen(weapon) ; i++)
		{
			switch(weapon[i])
			{
				case 'h': he++;
				case 'f': flash++;
				case 's': smoke++;
				case 'n': cs_set_user_nvg(id);
			}
		}

		if(he) give_item(id, "weapon_hegrenade"), cs_set_user_bpammo(id, CSW_HEGRENADE, he);
		if(flash) give_item(id, "weapon_flashbang"), cs_set_user_bpammo(id, CSW_FLASHBANG, flash);
		if(smoke) give_item(id, "weapon_smokegrenade"), cs_set_user_bpammo(id, CSW_SMOKEGRENADE, smoke);
	
		set_pev(id, pev_max_health, 100.0);
		set_user_footsteps(id, false);
		if(g_bZombie[id])
		{
			g_bZombie[id] = false;
			fm_reset_user_model(id);
		}

		copy(g_CurrentModel[id], charsmax(g_CurrentModel[]), g_RandomModel[random(sizeof g_RandomModel)]);

		fm_get_user_model(id, sz_CurrentModel, charsmax(sz_CurrentModel) );

		set_task(0.1, "Task_Health", TASKID_HEALTH + id);
		
		if(get_pcvar_num(cvar_GunMenu))
			Main_Weapon_Menu(id);
	}
	
	for(new i = 0; i < 10; i++)
		client_cmd(id, "-nvgadjust");
	g_bDeadNvg[0][id] = false;
	
		
}

public Bacon_TraceAttack_Post(iVictim, iAttacker, Float: flDamage, Float: flDirection[3], trace_handle, iDamageType)
{
	if(!g_bIsAlive[iVictim] || !is_user_connected(iAttacker))
		return HAM_IGNORED;
		
	g_bHeadshot[iAttacker][iVictim] = bool:( get_tr2(trace_handle, TR_iHitgroup) == HIT_HEAD );
	
	return HAM_IGNORED;
}		

public Bacon_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageType)
{
	if (!is_user_alive(iAttacker) || !is_user_connected(iAttacker))
		return HAM_IGNORED;
		
	new weapon = get_user_weapon(iAttacker);
	if(weapon == CSW_KNIFE && !g_bZombie[iVictim])
	{
		new button = get_user_button(iAttacker);

		if (button & IN_ATTACK) {
			flDamage = random_float(ZOMBIE_SLASH_MIN + (rounds * get_cvar_num("zswarm_zombie_xdmg")), ZOMBIE_SLASH_MAX + (rounds * get_cvar_num("zswarm_zombie_xdmg")));
			if(g_bBoss[iAttacker])
				flDamage = random_float(BOSS_SLASH_MIN + (rounds * get_cvar_num("zswarm_boss_xdmg")), BOSS_SLASH_MAX + (rounds * get_cvar_num("zswarm_boss_xdmg")));
		} else if (button & IN_ATTACK2) {
			flDamage = random_float(ZOMBIE_STAB_MIN + (rounds * get_cvar_num("zswarm_zombie_xdmg")), ZOMBIE_STAB_MAX + (rounds * get_cvar_num("zswarm_zombie_xdmg")));
			if(g_bBoss[iAttacker])
				flDamage = random_float(BOSS_STAB_MIN + (rounds * get_cvar_num("zswarm_boss_xdmg")), BOSS_STAB_MAX + (rounds * get_cvar_num("zswarm_boss_xdmg")));
		}

		SetHamParamFloat(4, flDamage);
		return HAM_HANDLED;
	}

	return HAM_IGNORED;
}

public Bacon_TakeDamage_Post(iVictim, inflictor, iAttacker, Float:flDamage, iDamageType)
{
	if(g_bBoss[iVictim] == 1) {
		set_pdata_float(iVictim, 108, 1.0, 5);
	}
	
    if (g_flDisplayDamage[iVictim])
    {
        set_pev(iVictim, pev_dmg_take, g_flDisplayDamage[iVictim]);
        g_flDisplayDamage[iVictim] = 0.0;
    }

	else if (g_bIsAlive[iVictim] || is_user_connected(iAttacker))
	{
		if(g_bZombie[iAttacker] && !g_bZombie[iVictim])
		{
			if(flDamage >= SURVIVOR_PUNCHANGLE)
			{
				new Float: fl_Angle[3];
				for(new i = 0 ; i < 3 ; i++)
					fl_Angle[i] = random_float(-75.0, 75.0);

				entity_set_vector(iVictim, EV_VEC_punchangle, fl_Angle);
			}
		}
	}
}

public Bacon_Zombie_Spawn(id) {
	id -= 100;
	
	if(g_bZombie[id] && g_RoundStatus && !is_user_alive(id)) {
		ExecuteHamB(Ham_CS_RoundRespawn, id);
		ExecuteForward(g_ForwardZombieSpawn, g_ForwardDummy, id);
	}
}

public Bacon_Killed_Post(id, iKiller)
{
	g_bIsAlive[id] = false;
	g_bDeadNvg[0][id] = true;
	
	if(g_bZombie[id])
	{
		if(g_bBoss[id] == 0)
			set_task(5.5, "Bacon_Zombie_Spawn", id + 100);
	}
}

public Bacon_Touch(ent, id)
{
	if (is_user_alive(id) && g_bZombie[id])
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public Bacon_ResetMaxSpeed(id)
{
	if(!g_bZombie[id])
		return;

	static Float: maxspeed; maxspeed = get_pcvar_float(cvar_Speed);

	if(get_user_maxspeed(id) != 1.0) {
		if(g_bBoss[id] == 0) {
			set_user_maxspeed(id, maxspeed + (25 + (rounds * 4)));
		} else {
			set_user_maxspeed(id, maxspeed + (rounds * 2));
		}
	}

}

public Logevent_RoundStart()
{
	g_bTimerStart = true;
	g_bFreezeTime = false;
}

public Logevent_RoundEnd()
{
	if(get_pcvar_num(cvar_EndRound))
		remove_task(TASKID_ROUND);
		
	for(new i = 0; i < get_maxplayers(); i++) {
		remove_task(i + 9526735);
	}
		
	g_RoundStatus = 0;
	fn_Rounds();
}

public Event_TextMsg()
{
	if(get_pcvar_num(cvar_EndRound))
		remove_task(TASKID_ROUND);

	g_RoundCounter = 0;
}

public Event_NewRound()
{
	g_bFreezeTime = true;
	g_RoundStatus = 1;
}

public Event_CurWeapon(id)
{
	if(!g_bIsAlive[id] || !g_bZombie[id])
		return;

	if(read_data(2) != CSW_KNIFE)
	{
		engclient_cmd(id, "weapon_knife");
		if(g_bBoss[id] == 0) {
			UTIL_SetModel(id, g_BossClaws, "");
		} else {
			UTIL_SetModel(id, g_ZombieClaws[g_ZombieModelIndex[id]], "");
		}
	}
}

public Message_StatusIcon(msg_id, msg_dest, id)
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;

	new sz_Icon[4];
	get_msg_arg_string(2, sz_Icon, charsmax(sz_Icon));


	if(equali(sz_Icon, "buy"))
	{
		if (!get_pcvar_num(cvar_GunMenu) && !g_bZombie[id])
			return PLUGIN_CONTINUE;
		
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Message_Health(msg_id, msg_dest, id)
{
	if(!g_bIsAlive[id] || !g_bZombie[id])
		return;

	static CurrentHealth ; CurrentHealth = get_user_health(id);
	static Float: MaxHealth ; MaxHealth = get_pcvar_float(cvar_Health);

	//Must use 'clamp' to fix '0' hud bug
	set_msg_arg_int(1, ARG_BYTE, clamp(floatround((CurrentHealth / MaxHealth) * 100.0), 1, 100));	
}

public Message_Battery(msg_id, msg_dest, id)
{
	if(!g_bIsAlive[id] || !g_bZombie[id])
		return;

	static CurrentArmour ; CurrentArmour = get_user_armor(id);
	static Float: MaxArmour ; MaxArmour = get_pcvar_float(cvar_Armour);

	set_msg_arg_int(1, ARG_SHORT, floatround((CurrentArmour / MaxArmour) * 100.0));
}

public Message_TextMessage(msg_id, msg_dest, id)
{
	if(get_msg_arg_int(1) != 4)
		return PLUGIN_CONTINUE;

	new sz_TextMsg[25], sz_WinMsg[32];
	get_msg_arg_string(2, sz_TextMsg, charsmax(sz_TextMsg));

	if(equal(sz_TextMsg[1], "Game_bomb_drop") || equal(sz_TextMsg[1], "Terrorist_cant_buy") || (equal(sz_TextMsg[1], "CT_cant_buy")))
		return PLUGIN_HANDLED;

	else if(equal(sz_TextMsg[1], "Terrorists_Win"))
	{
		formatex(sz_WinMsg, charsmax(sz_WinMsg), "%L", LANG_SERVER, "WIN_ZOMBIE");
		set_msg_arg_string(2, sz_WinMsg);
		sound_play(0);
	}
	else if(equal(sz_TextMsg[1], "Target_Saved") || equal(sz_TextMsg[1], "CTs_Win"))
	{
		formatex(sz_WinMsg, charsmax(sz_WinMsg) , "%L", LANG_SERVER, "WIN_HUMAN");
		set_msg_arg_string(2, sz_WinMsg);
		sound_play(1);
	}
	return PLUGIN_CONTINUE;
}

public sound_play(playid) {
	for(new id = 1; id < get_maxplayers(); id++) { if(is_user_connected(id)) {
			if(playid == 0) {
				client_cmd(id, "spk %s", g_sound_zombiewin);
			}
	
			if(playid == 1) {
				client_cmd(id, "spk %s", g_sound_humanwin);
			}
	
			if(playid == 2) {
				client_cmd(id, "spk %s", g_sound_roundstart);
			}
	
			if(playid == 3) {
				client_cmd(id, "spk %s", g_sound_roundstats);
			}
		}
	}
}

public Message_RoundTimer()
{
	if(get_pcvar_num(cvar_EndRound))
	{
		if(g_bTimerStart)
		{
			g_bTimerStart = false;
			set_task(float(get_msg_arg_int(1)), "Task_RoundEnd", TASKID_ROUND);
		}
	}
}

public Message_NVGToggle(msg_id, msg_dest, id)
{
	static iNvgToggle ; iNvgToggle = get_msg_arg_int(1);
	if(g_bZombie[id] && g_bIsAlive[id] && !g_bIsBot[id])
	{
		g_bCustomNvg[id] = iNvgToggle;
		set_msg_arg_int(1, ARG_BYTE, 0);
		
		if( g_bCustomNvg[id] )
		{
			message_begin( MSG_ONE_UNRELIABLE, g_MsgID_ScreenFade, { 0,0,0 }, id); 
			write_short( 1<<0 ); 
			write_short( 1<<0 ); 
			write_short( 0x0004 ); 
			write_byte( 175 );
			write_byte( 50 );
			write_byte( 25 ); 
			write_byte( 50 ); 
			message_end( );
			
			message_begin(MSG_ONE_UNRELIABLE, g_MsgID_SetFov, {0,0,0}, id);
			write_byte(110);
			message_end();
		}
		else
		{
			message_begin( MSG_ONE_UNRELIABLE, g_MsgID_ScreenFade, { 0,0,0 }, id); 
			write_short( 0 ); 
			write_short( 0 ); 
			write_short( 0x0000 ); 
			write_byte( 0 );
			write_byte( 0 );
			write_byte( 0 ); 
			write_byte( 0 ); 
			message_end( );
			
			message_begin(MSG_ONE_UNRELIABLE, g_MsgID_SetFov, { 0,0,0 }, id);
			write_byte(90);
			message_end();
		}
	}
	else if(!g_bZombie[id] && get_pcvar_num(cvar_Blocknvg))
	{
		if(iNvgToggle)
		{
			client_print(id, print_center, "%L", LANG_PLAYER, "BLOCK_NVG");
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public Message_SendAudio(msg_id, msg_dest, id)
{
	static AudioCode[22];
	get_msg_arg_string(2, AudioCode, charsmax(AudioCode) );

	for(new i = 0 ; i < sizeof g_SendAudio_Radio ; i++)
	{
		if(g_bZombie[id])
		{
			if(equal(AudioCode, g_SendAudio_Radio[i]))
				set_msg_arg_int(3, ARG_SHORT, ZOMBIE_RADIO_SPEED);
		}
	}
	for(new i = 0 ; i < sizeof g_SendAudio_RoundStart ; i++)
	{
		if(equal(AudioCode, g_SendAudio_RoundStart[i])) {
			set_msg_arg_string(2, "common/null.wav");
		}
	}

	if(equal(AudioCode, "%!MRAD_terwin")) {
		set_msg_arg_string(2, "common/null.wav");
	}

	else if(equal(AudioCode, "%!MRAD_ctwin")) {
		set_msg_arg_string(2, "common/null.wav");
	}

	return PLUGIN_CONTINUE;
}

public Main_Weapon_Menu(id)
{
	g_CurOffset[id] = 0;
	
	if(g_PickedWeapons[0][id] == 0 && g_PickedWeapons[1][id] == 0) {
		g_PickedWeapons[0][id] = 24;
		g_PickedWeapons[1][id] = 25;
	}
	
	if(g_bIsBot[id]) {
		give_weapons(id);
	}

	if(!g_ShowMenu[id]) {
		show_menu(id, MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_0, "\yWeapon Selection Method^n^n\r1. \wNew Weapons^n\r2. \wPrevious Setup^n^n\r0. Exit", -1, g_Menu_WeaponID);
	}
}

public MenuID_Weapon(id, key)
{
	switch(key)
	{
		case 0:
		{
			g_ShowMenu[id] = true;
			Primary_Weapon_Menu(id, 0);

		}
		case 1:
		{
			g_ShowMenu[id] = true;
			give_weapons(id);
		}
	}

	return;
}

public Primary_Weapon_Menu(id, offset)
{
	if(offset<0) 
		offset = 0;

	new cvar_value[32];
	get_pcvar_string(cvar_Weapons, cvar_value, charsmax(cvar_value));

	new flags = read_flags(cvar_value);

	new keys, curnum, menu[2048];
	for(new i = offset ; i < 19 ; i++)
	{
		if(i == 18)
		{
			g_OptionsOnMenu[curnum][id] = 24;
			keys += (1<<curnum);
			curnum++;
			format(menu, 2047, "\y%s^n^n\r%d. \wRandom^n", menu, curnum);
			break;
		}
		else if(flags & power(2, i))
		{
			g_OptionsOnMenu[curnum][id] = i;
			keys += (1<<curnum);

			curnum++;
			format(menu,2047, "\y%s^n\r%d. \w%s", menu, curnum, weapon_names[i]);

			if(curnum == 8)
				break;
		}
	}

	format(menu, 2047, "\ySelect Primary Weapon:\w^n%s", menu);
	if(curnum == 8 && offset < 12)
	{
		keys += (1<<8);
		format(menu, 2047, "\y%s^n^n\r9. \wNext", menu);
	}
	if(offset)
	{
		keys += (1<<9);
		format(menu, 2047, "\y%s^n\r0. \wBack", menu);
	}

	g_ShowMenuFirstTime[id] = false;
	show_menu(id, keys, menu, -1, g_Menu_PrimaryID);
}

public MenuID_Primary(id, key)
{
	if(key < 8)
	{
		g_PickedWeapons[0][id] = g_OptionsOnMenu[key][id];
		g_CurOffset[id] = 0;
		Secodary_Weapon_Menu(id,0);
	}
	else
	{
		if(key==8)
			g_CurOffset[id] += 8;
		if(key==9)
			g_CurOffset[id] -= 8;
		Primary_Weapon_Menu(id, g_CurOffset[id]);
	}

	return ;
}

public Secodary_Weapon_Menu(id, offset)
{
	if(offset < 0) 
		offset = 0;

	new cvar_value[32];
	get_pcvar_string(cvar_Weapons, cvar_value, charsmax(cvar_value));

	new flags = read_flags(cvar_value);

	new keys, curnum, menu[2048];
	for(new i = 18 ; i < 24 ; i++)
	{
		if(flags & power(2, i))
		{
			g_OptionsOnMenu[curnum][id] = i;
			keys += (1<<curnum);

			curnum++;
			format(menu, 2047, "\y%s^n\r%d. \w%s", menu, curnum, weapon_names[i]);
		}
	}
	g_OptionsOnMenu[curnum][id] = 25;
	keys += (1<<curnum);
	curnum++;
	format(menu, 2047, "\y%s^n^n\r%d. \wRandom", menu, curnum);

	format(menu, 2047, "\ySelect Secondary Weapon:\w^n%s", menu);

	show_menu(id, keys, menu, -1, g_Menu_SecID);
}

public MenuID_Secondary(id, key)
{
	if(key<8)
	{
		g_PickedWeapons[1][id] = g_OptionsOnMenu[key][id];
	}

	give_weapons(id);

	return;
}

public give_weapons(id)
{
	if(!g_bIsAlive[id] || !is_user_connected(id))
		return;

	strip_user_weapons(id);
	cs_set_user_nvg(id, 0);

	give_item(id, "weapon_knife");

	new weapon[32];
	new csw ;

	csw = csw_contant(g_PickedWeapons[0][id]);
	get_weaponname(csw, weapon, charsmax(weapon));
	give_item(id, weapon);
	cs_set_user_bpammo(id, csw, g_MaxBPAmmo[csw]); 

	csw = csw_contant(g_PickedWeapons[1][id]);
	get_weaponname(csw,weapon, charsmax(weapon));
	give_item(id, weapon);
	cs_set_user_bpammo(id, csw, g_MaxBPAmmo[csw]);

	get_pcvar_string(cvar_Equip,weapon, charsmax(weapon));
	get_pcvar_string(cvar_Weapons, weapon, charsmax(weapon));

	new flags = read_flags(weapon);
	if(flags & MOD_VESTHELM) cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
	else if(flags & MOD_VEST) cs_set_user_armor(id, 100, CS_ARMOR_KEVLAR);
	
	new he, flash, smoke;
	new weaponu[32];
	get_pcvar_string(cvar_Equip, weaponu, charsmax(weaponu));
		
	for(new i = 0 ; i < strlen(weaponu) ; i++)
	{
		switch(weaponu[i])
		{
			case 'h': he++;
			case 'f': flash++;
			case 's': smoke++;
			case 'n': cs_set_user_nvg(id);
		}
	}

	if(he) give_item(id, "weapon_hegrenade"), cs_set_user_bpammo(id, CSW_HEGRENADE, he);
	if(flash) give_item(id, "weapon_flashbang"), cs_set_user_bpammo(id, CSW_FLASHBANG, flash);
	if(smoke) give_item(id, "weapon_smokegrenade"), cs_set_user_bpammo(id, CSW_SMOKEGRENADE, smoke);
	
}

public csw_contant(weapon)
{
	new num = 29;
	switch(weapon)
	{
		case 0: num = 3;
		case 1: num = 5;
		case 2: num = 7;
		case 3: num = 8;
		case 4: num = 12;
		case 5: num = 13;
		case 6: num = 14;
		case 7: num = 15;
		case 8: num = 18;
		case 9: num = 19;
		case 10: num = 20;
		case 11: num = 21;
		case 12: num = 22;
		case 13: num = 23;
		case 14: num = 24;
		case 15: num = 27;
		case 16: num = 28;
		case 17: num = 30;
		case 18: num = 1;
		case 19: num = 10;
		case 20: num = 11;
		case 21: num = 16;
		case 22: num = 17;
		case 23: num = 26;
		case 24:
		{
			new s_weapon[32];
			get_pcvar_string(cvar_Weapons, s_weapon, charsmax(s_weapon));

			new flags = read_flags(s_weapon);
			do
			{
				num = random_num(0, 17);
				if(!(num & flags))
				{
					num = -1;
				}
			}
			while(num==-1);
			num = csw_contant(num);
		}
		case 25:
		{
			new s_weapon[32];
			get_pcvar_string(cvar_Weapons, s_weapon, charsmax(s_weapon));

			new flags = read_flags(s_weapon);
			do
			{
				num = random_num(18, 23);
				if(!(num & flags))
				{
					num = -1;
				}
			}
			while(num==-1);
			num = csw_contant(num);
		}
	}
	return num;
}

public ClCmd_teams(id)
{
	if (!get_pcvar_num(cvar_Teams))
		return PLUGIN_CONTINUE;

	new CsTeams: team = cs_get_user_team(id);
	if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return PLUGIN_CONTINUE;

	client_print(id, print_center, "%L", LANG_PLAYER, "BLOCK_TEAMS");

	return PLUGIN_HANDLED;
}

public ClCmd_nvg(id)
{
	if(!g_bIsAlive[id] && g_bDeadNvg[0][id])
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgID_NVGToggle, _, id);
		write_byte(g_bDeadNvg[1][id] = !g_bDeadNvg[1][id]);
		message_end();
	}
}

public ClCmd_guns(id)
{
	if(!get_pcvar_num(cvar_GunMenu))
	{
		client_print(id, print_chat, "[Zombie Swarm] Gun Menu has been disabled.");
	}
	else
	{
		g_ShowMenu[id] = true;
		client_print(id, print_chat, "[Zombie Swarm] Weapon Selection Menu will show next time you spawn");
	}
}

public ClCmd_nextguns(id)
{
	if(get_pcvar_num(cvar_GunMenu) && g_ShowMenuFirstTime[id])
		Main_Weapon_Menu(id);
		
	return PLUGIN_HANDLED;
}

public ConCmd_addweap(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED;

	new arg[32];
	read_argv(1, arg, charsmax(arg));

	new cvar_value[32];
	get_pcvar_string(cvar_Weapons, cvar_value, charsmax(cvar_value));

	for(new i = 0 ; i < 26 ; i++)
	{
		if(equali(arg, weapon_names[i]))
		{
			new flags = read_flags(cvar_value);
			new add_flag = power(2, i);
			if(!(flags & add_flag))
			{
				console_print(id, "[Zombie Swarm] Adding weapon %s to the choice list.",weapon_names[i]);
				flags += add_flag;
				get_flags(flags, cvar_value, charsmax(cvar_value));
				set_pcvar_string(cvar_Weapons, cvar_value);
			}
			else
			{
				console_print(id, "[Zombie Swarm] Weapon %s is already on choice list.",weapon_names[i]);
			}

			break;
		}
	}

	return PLUGIN_HANDLED;
}

public ConCmd_delweap(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED;

	new arg[32];
	read_argv(1, arg, charsmax(arg));

	new cvar_value[32];
	get_pcvar_string(cvar_Weapons, cvar_value, charsmax(cvar_value));

	new flags = read_flags(cvar_value);
	for(new i = 0 ; i < 26 ; i++)
	{
		if(equali(arg, weapon_names[i]))
		{
			new remove_flag = power(2, i);
			if(flags & remove_flag)
			{
				console_print(id, "[Zombie Swarm] Removing weapon %s from the choice list.", weapon_names[i]);
				flags -= remove_flag;
				get_flags(flags, cvar_value, charsmax(cvar_value));
				set_pcvar_string(cvar_Weapons, cvar_value);
			}
			else
			{
				console_print(id, "[Zombie Swarm] Weapon %s is already off choice list.", weapon_names[i]);
			}
			break;
		}
	}

	return PLUGIN_HANDLED;
}

public Forward_Think_Weather()
{
	if(get_cvar_num("zswarm_fog_enable")) {
		new color[3];
		new cdata_r[20];
		new cdata_g[20];
		new cdata_b[20];
		new colors[128];
		
		get_cvar_string("zswarm_fog_color", colors, charsmax(colors));
		parse(colors, cdata_r, charsmax(cdata_r), cdata_g, charsmax(cdata_g), cdata_b, charsmax(cdata_b));
		
		color[0] = str_to_num(cdata_r);
		color[1] = str_to_num(cdata_g);
		color[2] = str_to_num(cdata_b);
		
		screenfog(0, color[0], color[1], color[2], get_cvar_float("zswarm_fog_density"));
	} else {
		screenfog(0, 0, 0, 0, 0.00001	);
	}
	
	new lift[66];
	get_pcvar_string(cvar_Lights, lift, charsmax(lift));
	
	set_lights(lift);
	return PLUGIN_CONTINUE;
}

public Forward_CmdStart(id, uc_handle, seed)
{
	if(!g_bIsAlive[id])
		return FMRES_IGNORED;

	static Float: flTime ; flTime = get_gametime();
	
	static iButton ; iButton = get_uc(uc_handle, UC_Buttons );
	
	static fViewAngles[3] ; get_uc(uc_handle, UC_ViewAngles, fViewAngles);
	static iImpulse ; iImpulse = get_uc(uc_handle, UC_Impulse);
	
	static iFlag ; iFlag = entity_get_int(id, EV_INT_flags);

	static aim, body, szAimingEnt[32];
	get_user_aiming(id, aim, body, 60);
	entity_get_string(aim, EV_SZ_classname, szAimingEnt, charsmax(szAimingEnt));
	
	if (g_bZombie[id])
	{
		if (!g_bFreezeTime && (iButton & IN_RELOAD) && (iFlag & FL_ONGROUND))
		{
			if (get_pcvar_num(cvar_Leap))
			{
				static Float: fl_CoolDown ; fl_CoolDown = get_pcvar_float(cvar_LeapCooldown);
				{
					if(flTime - fl_CoolDown > g_LastLeap[id])
					{
						clcmd_leap(id);
						g_LastLeap[id] = flTime;
					}
				}
			}
		}
		else if ( (!g_bFreezeTime) && (iButton & IN_ATTACK) && (iButton & IN_ATTACK2))
		{
			if (get_pcvar_num(cvar_FleshThrow))
			{
				if(flTime - 1.1 > g_LastFthrow[id])
				{
					clcmd_throw(id);
					g_LastFthrow[id] = flTime;
				}
			}
		}
		
		else if (iImpulse == 100)
			set_uc(uc_handle, UC_Impulse, 0);
	}
	
	return FMRES_IGNORED;
}

public clcmd_leap(id)
{
	new Float: velocity[3];
	new Float: lheight, lforce;
	lforce = get_pcvar_num(cvar_LeapForce);
	lheight = get_pcvar_float(cvar_LeapHeight);

	velocity_by_aim(id, lforce, velocity);
	velocity[2] = lheight;
	entity_set_vector(id, EV_VEC_velocity, velocity);
	emit_sound(id, CHAN_VOICE, g_sound_pain[random(sizeof g_sound_pain)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public clcmd_throw(id)
{
	new iOrigin[3], Float: flOrigin[3], Float: flVelocity[3];
	get_user_origin(id, iOrigin, 1);
	entity_get_vector(id, EV_VEC_velocity,  flVelocity);

	new Health, flDamage;
	Health = get_user_health(id);
	flDamage = get_pcvar_num(cvar_FleshSelfDmg);

	if (Health > flDamage)
	{
		new iEnt = create_entity("info_target");

		entity_set_string(iEnt, EV_SZ_classname, g_szClass_flesh);
		
		entity_set_model(iEnt, g_ZombieFleshThrow);
		entity_set_int(iEnt, EV_INT_body, random_num(1, 10)); //Submodel 0 is skull/head
		
		new Float: MinBox[3] = { -2.5, -2.5, 0.0 };
		new Float: MaxBox[3] = { 2.5, 2.5, 2.0 };
		entity_set_size(iEnt, MinBox, MaxBox);

		IVecFVec(iOrigin, flOrigin);
		entity_set_vector(iEnt, EV_VEC_origin, flOrigin);
		
		entity_set_int(iEnt, EV_INT_movetype, MOVETYPE_TOSS);
		entity_set_int(iEnt, EV_INT_solid, SOLID_TRIGGER);
		
		entity_set_edict(iEnt, EV_ENT_owner, id); 

		velocity_by_aim(id, get_pcvar_num(cvar_FleshForce), flVelocity);
		entity_set_vector(iEnt, EV_VEC_velocity, flVelocity);

		entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.1);
		 
		emit_sound(id, CHAN_VOICE, g_sound_pain[random(sizeof g_sound_pain)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_user_health(id, Health - flDamage);
	}
	else
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "FLESH_HEALTH");
	}

}

public Forward_EmitSound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED;

	new mi = g_ZombieModelIndex[id];
	new gender = g_ZombieModelGender[mi];
	
	if(g_bZombie[id])
	{
		//KNIFE
		if (sample[0] == 'w' && sample[1] == 'e' && sample[8] == 'k' && sample[9] == 'n')
		{
			switch(sample[17])
			{
				case 'l':
					return FMRES_SUPERCEDE;

				case 's', 'w':
				{
					emit_sound(id, CHAN_WEAPON, g_sound_miss[random(sizeof g_sound_miss)], volume, attn, flag, pitch);
					return FMRES_SUPERCEDE;
				}

				case 'b', '1', '2', '3', '4':
				{
					emit_sound(id, CHAN_WEAPON, g_sound_hit[random(sizeof g_sound_hit)], volume, attn, flag, pitch);
					return FMRES_SUPERCEDE;
				}
			}
		}
		//PAIN
		else if (sample[1] == 'l' && sample[2] == 'a' && sample[3] == 'y' && ( (containi(sample, "bhit") != -1) || (containi(sample, "pain") != -1) || (containi(sample, "shot") != -1)))
		{
			if(g_bBoss[id]) {
				emit_sound(id, CHAN_AUTO, g_sound_boss_pain[random(sizeof g_sound_boss_pain)], volume, attn, flag, pitch);
			} else {
				if(gender == MALE) {
					emit_sound(id, CHAN_AUTO, g_sound_pain[random(sizeof g_sound_pain)], volume, attn, flag, pitch);
				} else if(gender == FEMALE) {
					emit_sound(id, CHAN_AUTO, g_sound_female_pain[random(sizeof g_sound_female_pain)], volume, attn, flag, pitch);
				}
			}
			
			return FMRES_SUPERCEDE;
		}
		//DEATH
		else if (sample[7] == 'd' && (sample[8] == 'i' && sample[9] == 'e' || sample[12] == '6'))
		{
			if(g_bBoss[id]) {
				emit_sound(id, CHAN_AUTO, g_sound_boss_die[random(sizeof g_sound_boss_die)], volume, attn, flag, pitch);
			} else {
				if(gender == MALE) {
					emit_sound(id, CHAN_AUTO, g_sound_die[random(sizeof g_sound_die)], volume, attn, flag, pitch);
				} else if(gender == FEMALE) {
					emit_sound(id, CHAN_AUTO, g_sound_female_die[random(sizeof g_sound_female_die)], volume, attn, flag, pitch);
				}
			}
			
			return FMRES_SUPERCEDE;
		}
		else if (sample[6] == 'n' && sample[7] == 'v' && sample[8] == 'g')
			return FMRES_SUPERCEDE;
	}
	else
	{
		//NVG
		if(get_pcvar_num(cvar_Blocknvg))
			if (sample[6] == 'n' && sample[7] == 'v' && sample[8] == 'g')
				return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public Forward_Touch(pToucher, pTouched)
{
	if ( pev_valid(pToucher))
	{
		static sz_ClassName_Toucher[32], sz_ClassName_Touched[32];
		pev(pToucher, pev_classname, sz_ClassName_Toucher, charsmax(sz_ClassName_Toucher));

		if ( pev_valid(pTouched))
			pev(pTouched, pev_classname, sz_ClassName_Touched, charsmax(sz_ClassName_Touched));

		if ( equal(sz_ClassName_Toucher, g_szClass_flesh))
		{
			static iAttacker ; iAttacker = pev(pToucher, pev_owner);

			if ( pev_valid(pTouched))
			{
				if ( equal(sz_ClassName_Touched, "player") && is_user_connected(pTouched))
				{
					static vOrigin[3], Float: flDamage;
					get_user_origin(pTouched, vOrigin);
					flDamage = get_pcvar_float(cvar_FleshDmg);
					static CsTeams:team[2];
					team[0] = cs_get_user_team(pTouched), team[1] = cs_get_user_team(iAttacker);

					if (iAttacker == pTouched)
						return FMRES_SUPERCEDE;

					if (!get_pcvar_num(g_bFFire) && team[0] == team[1])
						return FMRES_SUPERCEDE;

					message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
					write_byte(TE_BLOOD);
					write_coord(vOrigin[0]);
					write_coord(vOrigin[1]);
					write_coord(vOrigin[2] + 10);
					write_coord(random_num(-360, 360));
					write_coord(random_num(-360, 360));
					write_coord(-10);
					write_byte(70);
					write_byte(random_num(15, 35));
					message_end();
					ExecuteHamB(Ham_TakeDamage, pTouched, pToucher, iAttacker, random_float(flDamage - 5.0, flDamage + 10.0), DMG_BULLET | DMG_NEVERGIB);
				}
				else if ( equal(sz_ClassName_Touched, "func_breakable") && (get_pcvar_num(cvar_FleshBreakEnts)) )
					dllfunc(DLLFunc_Use, pTouched, iAttacker);

				else if ( equal(sz_ClassName_Touched, g_szClass_flesh))
					return FMRES_SUPERCEDE;
			}
			remove_entity(pToucher);
		}
	}

	return FMRES_IGNORED;
}

public Forward_TraceLine_Post(Float:start[3], Float:end[3], nomonsters, id, trace)
{
	if(!is_user_alive(id) || !is_user_bot(id) || !g_bZombie[id] )
		return FMRES_IGNORED;
		
	static Float: gameTime ; gameTime = get_gametime();
	static Float: leapCooldown ; leapCooldown = get_pcvar_float(cvar_LeapCooldown);
	static Float: leapMax ; leapMax = get_pcvar_float(cvar_LeapForce);
	static Float: leapMin ; leapMin = get_pcvar_float(cvar_LeapHeight);
	
	static Float: flshThrowForce ; flshThrowForce = get_pcvar_float(cvar_FleshForce);
	
	static distance;
	static target; target = get_tr2(trace, TR_pHit);
	
	leapMax *= 2.0;
	leapMin *= 1.5;
	
	flshThrowForce /= 2.5;
	
	if(is_user_alive(target) && !g_bZombie[target])
	{
		distance = get_entity_distance(id, target);
		
		if (gameTime - leapCooldown > g_LastLeap[id])
		{
			static chance ; chance = random_num(1, 100);
			
			if (leapMin < distance < leapMax && chance <= 15)
			{
				clcmd_leap(id);
				g_LastLeap[id] = gameTime;
			}
		}
		
		if (gameTime - 1.1 > g_LastFthrow[id])
		{
			static chance ; chance = random_num(1, 100);
			
			if(distance < flshThrowForce && chance <= 10)
			{
				clcmd_throw(id);
				g_LastFthrow[id] = gameTime;
			}
		}
		
	}

	return FMRES_IGNORED;
}
public Forward_AddToFullPack_Post( es_handle, e, ent, host, hostflags, player, pset )
{
	if( player && host == ent && g_bCustomNvg[host] && g_bIsAlive[host] && !g_bIsBot[host])
		set_es( es_handle, ES_Effects, get_es( es_handle, ES_Effects ) | EF_BRIGHTLIGHT ); 
		
	if( player  && g_bCustomNvg[host] && g_bIsAlive[host] && !g_bIsBot[host])
	{
		static RenderColor[3];
		RenderColor[0] = 200;
		RenderColor[1] = 25;
		RenderColor[2] = 25;
		static CsTeams:team[2];
		team[0] = cs_get_user_team(ent), team[1] = cs_get_user_team(host);
		
		set_es(es_handle, ES_RenderMode, kRenderNormal);	
		set_es(es_handle, ES_RenderAmt, 16);	
		
		if(team[0] == team[1])
			RenderColor = {50, 150, 50};
			
		set_es(es_handle, ES_RenderColor, RenderColor);
		set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
	}
}

public Forward_Think_Objective(iEnt)
{
	if(!is_valid_ent(iEnt))
		return;
		
	static Float: flCoords[3];
	
	for (new id = 1 ; id <= g_MaxPlayers ; id++)
	{
		if (!g_bIsAlive[id] || g_bZombie[id]) 
			continue;
		
		for (new i = 0 ; i < g_EntCount ; i++)
		{			
			if(g_EntActive[i])
				continue;
				
			entity_get_vector(g_EntIndex[i], EV_VEC_origin, flCoords);
		
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HostagePos"), {0,0,0}, id);
			write_byte(id);
			write_byte(i);
			write_coord_f(flCoords[0]);
			write_coord_f(flCoords[1]);
			write_coord_f(flCoords[2]);
			message_end();
		
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HostageK"), {0,0,0}, id);
			write_byte(i);
			message_end();
			
		}
	}
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 2.0);
}

public Forward_Think_Flesh(iEnt)
{
	if(!is_valid_ent(iEnt))
		return;
		
	static Float: flAngles[3];
	
	entity_get_vector(iEnt, EV_VEC_angles, flAngles);
	
	for(new i = 0 ; i < 3 ; i++)
		flAngles[i] += 10.0;

	entity_set_vector(iEnt, EV_VEC_angles, flAngles);
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.1);
}

public Task_Restart()
{
	new sz_MapName[32];
	get_mapname(sz_MapName, charsmax(sz_MapName));
	server_cmd("changelevel %s", sz_MapName);
}

public Task_Model(id)
{
	id -= TASKID_MODEL;
	
	if(g_bZombie[id]) {
		Task_Strip(id + TASKID_STRIP);
	}

	if(!is_user_alive(id))
		return;
		
	new CsTeams: team = cs_get_user_team(id);
	new modelindex = random(sizeof g_ZombiePlayerModels);
	g_ZombieModelIndex[id] = modelindex;
	
	if(team == CS_TEAM_T) {
		cs_set_user_model(id, g_ZombiePlayerModels[modelindex]);
	} else {
		cs_set_user_model(id, g_RandomModel[modelindex]);
	}
}

public Task_Strip(id)
{
	id -= TASKID_STRIP;

	if(!g_bIsAlive[id])
		return;
		
	if (cs_get_user_submodel(id))
		cs_set_user_submodel(id, 0);
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	UTIL_SetModel(id, g_ZombieClaws[g_ZombieModelIndex[id]], "");
}

public Task_NVG(id)
{
	id -= TASKID_NVG;

	if(!g_bIsAlive[id])
		return;
		
	engclient_cmd(id, "nightvision");

}

public Task_Health(id)
{
	id -= TASKID_HEALTH;

	if(!g_bIsAlive[id])
		return;
		
	message_begin(MSG_ONE_UNRELIABLE, g_MsgID_Health, _ , id);
	write_byte(100);
	message_end();
}
	
public Task_RoundEnd()
{
	remove_task(TASKID_ROUND);
	fn_Rounds();
}

public fn_Rounds()
{
	new rounds = get_pcvar_num(cvar_Round);

	if(rounds > 0)
	{
		if ( g_RoundCounter >= rounds )
		{
			g_RoundCounter = 0;

			client_print(0, print_chat, "%L", LANG_PLAYER, "ROUND_CHANGE");
			
			for(new i = 1 ; i <= g_MaxPlayers; i++)
			{
				if (!is_user_connected(i) || is_user_bot(i))
					continue;

				switch(cs_get_user_team(i))
				{
					case CS_TEAM_UNASSIGNED, CS_TEAM_SPECTATOR:
						continue;

					case CS_TEAM_T:
					{
							cs_set_user_team(i, CS_TEAM_CT);
							if(g_bIsAlive[i])
								cs_set_user_armor(i, 0, CS_ARMOR_NONE);
					}

					case CS_TEAM_CT:
					{
							cs_set_user_team(i, CS_TEAM_T);
					}

				}
			}
		}
	}
}

stock fm_set_user_model(player, modelname[])
{
	engfunc(EngFunc_SetClientKeyValue, player, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", modelname);

	g_bModel[player] = true;
}

stock fm_get_user_model(player, model[], len)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", model, len);
}

stock fm_reset_user_model(player)
{
	g_bModel[player] = false;

	dllfunc(DLLFunc_ClientUserInfoChanged, player, engfunc(EngFunc_GetInfoKeyBuffer, player));
}


//Arkshine
stock UTIL_SetNextAttack ( const WeapIndex, const Float:Delay )
{
	set_pdata_float( WeapIndex, m_flNextPrimaryAttack, Delay );
	set_pdata_float( WeapIndex, m_flNextSecondaryAttack, Delay );
}

stock UTIL_SetModel ( const PlayerId, const viewModel[], weaponModel[] )
{
	entity_set_string( PlayerId, EV_SZ_viewmodel, viewModel);
	entity_set_string( PlayerId, EV_SZ_weaponmodel, weaponModel);
}
//Arkshine
stock CacheWeaponInfo ( const PlayerId )
{
	g_WeaponIndex[ PlayerId ] = get_pdata_cbase( PlayerId, m_pActiveItem );
	g_WeaponId   [ PlayerId ] = get_pdata_int( g_WeaponIndex[ PlayerId ], m_iId, 4 );
}

stock Is_Ents_Built()
{
	for(new i = 0 ; i < g_EntCount ; i++)
	{
		if(!g_EntActive[i])
			return false;
	}
	return true;
}