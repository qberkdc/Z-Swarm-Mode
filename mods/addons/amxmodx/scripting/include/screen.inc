#define FFADE_OUT 0x0000 // Just here so we don't pass 0 into the function
#define FFADE_IN 0x0001 // Fade out (not in)
#define FFADE_MODULATE 0x0002 // Modulate (don't blend)
#define FFADE_STAYOUT 0x0004 // ignores the duration, stays faded out until //new ScreenFade message received

stock screenfade(id, red, green, blue, alpha, type, durabilty, Float:seconds)
{
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id)
    write_short((1<<12)*durabilty)
    write_short(floatround((1<<12)*seconds))
    write_short(type)
    write_byte (red)
    write_byte (green)
    write_byte (blue)
    write_byte (alpha)
    message_end()
} 

stock screenshake(id)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0,0,0}, id)
	write_short(255<< 14 ) //ammount
	write_short(10 << 14) //lasts this long
	write_short(255<< 14) //frequency
	message_end()
}

stock screenfog(const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false)
{    
	static msgFog;

	if (msgFog || (msgFog = get_user_msgid("Fog")))    
	{        
		new density = _:floatclamp(density_f, 0.0001, 0.25) * _:!clear;                
		message_begin(index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgFog, .player = index);        
		write_byte(clamp(red, 0, 255));        
		write_byte(clamp(green, 0, 255));        
		write_byte(clamp(blue , 0, 255));        
		write_byte((density & 0xFF));        
		write_byte((density >>  8) & 0xFF);        
		write_byte((density >> 16) & 0xFF);        
		write_byte((density >> 24) & 0xFF);        
		message_end();    
	}
}