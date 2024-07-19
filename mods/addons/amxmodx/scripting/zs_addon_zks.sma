#include <amxmodx>
#include <amxmisc>
#include <zombieswarm>

#define  	PLUGIN  "[ZS] Kill Effect"
#define  	VERSION "1.0"
#define 	 AUTHOR  "Berk , byoreo"

new sprite_ind;

//	Options for Oreo
enum _:{
	X = 0,
	Y = 0,
	Z = 6,
	SCALE = 5,
	BRIGHTNESS = 255,
	FX_TIME = 2.840
}

public plugin_init() {
	register_plugin(PLUGIN, 	VERSION, 	AUTHOR);
	register_event("DeathMsg", 	"fw_DeathMsg", 	"a");
}

public plugin_precache() {
	sprite_ind = precache_model("sprites/killsprite/killhand.spr");
}

public fw_DeathMsg() {
	new victim = read_data(2);
	if(zs_get_user_zombie(victim)) {
		set_task(FX_TIME, "sprite_index", victim);
	}
}

public sprite_index(id) {
	
	// Sprite Effect
	static origin[3];
	get_user_origin(id, origin);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_SPRITE); // TE id
	write_coord(origin[0]+X); // x
	write_coord(origin[1]+Y); // y
	write_coord(origin[2]+Z); // z
	write_short(sprite_ind) // sprite
	write_byte(SCALE); // scale
	write_byte(BRIGHTNESS); // brightness
	message_end();
}