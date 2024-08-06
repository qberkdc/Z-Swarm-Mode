#include <amxmodx>
#include <amxmisc>
#include <zombieswarm>
#include <nvault>

#define Plugin "[ZS] Addon: Daily Money"
#define Version "v1.00"
#define Author "--chcode"

new database;
new daily[33];

public plugin_init() {
	register_plugin(Plugin, Version, Author);
	register_clcmd("say /daily", "get_daily_money");
	register_clcmd("say /testtime", "get_next_time");
	database = nvault_open("daily_cdata");
}

public get_next_time(id) {
	server_print("%d", get_nexttime());
}

public client_connect(id) {
	database_load(id);
}

public client_disconnected(id) {
	database_save(id);
}

public get_daily_money(id) {
	new daily_reward;
	new time[4]; time_format(daily[id] - get_systime(), time);
	new timex[128];
	new times[4][128];
	new const time_fmt[][] = {
		"D ", "H ", "M ", "S"
	}
	
	format(times[0], charsmax(times), "%d", time[0]);
	format(times[1], charsmax(times), "%d", time[1]);
	format(times[2], charsmax(times), "%d", time[2]);
	format(times[3], charsmax(times), "%d", time[3]);
	
	format(timex, charsmax(timex), "%s%s%s", timex, time[3] <= 0 ? "" : times[3], time[3] <= 0 ? "" : time_fmt[0]);
	format(timex, charsmax(timex), "%s%s%s", timex, time[2] <= 0 ? "" : times[2], time[2] <= 0 ? "" : time_fmt[1]);
	format(timex, charsmax(timex), "%s%s%s", timex, time[1] <= 0 ? "" : times[1], time[1] <= 0 ? "" : time_fmt[2]);
	format(timex, charsmax(timex), "%s%s%s", timex, time[0] <= 0 ? "" : times[0], time[0] <= 0 ? "" : time_fmt[3]);
	
	if(daily[id] > get_systime()) {
		client_print(id, print_chat, "^^3[ZS]^^7 You have more time for next daily, %s", timex);
	}
	else {
		if((get_user_flags(id) & ADMIN_LEVEL_F)) {
			daily_reward = 15000;
			client_print(id, print_chat, "^^3[ZS]^^7 You got your daily %d money, goodbye, spend it", daily_reward);
		}
		else {
			daily_reward = 5000;
			client_print(id, print_chat, "^^3[ZS]^^7 You got your daily %d money, goodbye, spend it", daily_reward);
		}
		
		daily[id] = get_systime() + get_nexttime();
		zs_set_user_money(id, zs_get_user_money(id) + daily_reward);
	}
	
	return PLUGIN_HANDLED;
}

public get_nexttime() {
	new timeous[3][128];
	new timeou[3];
	
	get_time("%H", timeous[0], charsmax(timeous))
	get_time("%M", timeous[1], charsmax(timeous))
	get_time("%S", timeous[2], charsmax(timeous))
	
	timeou[0] = str_to_num(timeous[0]) + 3;
	timeou[1] = str_to_num(timeous[1]);
	timeou[2] = str_to_num(timeous[2]);
	
	if(timeou[0] >= 24) {
		timeou[0] -= 24;
	}
	
	new c;
	
	for(new i = 0; i < 24; i++) {
		if(timeou[0] + i < 24) {
			c++;
		}
	}
	
	new h; h = (c - 1) * 3600;
	new m; m = (60 - timeou[1]) * 60;
	new s; s = h + m + timeou[2];
	
	server_print("%d", s)
	return s;
}

public database_save(id) {
	new szAuth[33]; get_user_authid(id , szAuth , charsmax(szAuth));
	new szKey[64]; formatex(szKey , 63 , "%s ==> " , szAuth);
	new szData[256]; formatex(szData , 255 , "%d" , daily[id]);
	
	nvault_pset(database , szKey , szData);
}

public database_load(id) {
	new szAuth[33]; get_user_authid(id , szAuth , charsmax(szAuth));
	new szKey[40]; formatex(szKey , 63 , "%s ==> " , szAuth);
	new szData[256]; formatex(szData , 255, "%d", daily[id]);
	
	nvault_get(database, szKey, szData, 255);
	replace_all(szData , 255, "#", " ");
	
	new data[128]; parse(szData, data, 127);
	daily[id] = str_to_num(data);
}

stock time_format(time, time_array[]) {
	enum {
		SEC = 0,
		MIN,
		HOUR,
		DAY
	}

	for(new i = 0; i < 86400; i++) {
		if(time > 0) {
			time -= 1;
			time_array[SEC] += 1;
		}
	}
	
	for(new i = 0; i < 1440; i++) {
		if(time_array[SEC] >= 60) {
			time_array[SEC] -= 60;
			time_array[MIN]++;
		}
	}
	
	for(new i = 0; i < 24; i++) {
		if(time_array[MIN] >= 60) {
			time_array[MIN] -= 60;
			time_array[HOUR]++;
		}
	}
	
	for(new i = 0; i < 1; i++) {
		if(time_array[HOUR] >= 24) {
			time_array[HOUR] -= 24;
			time_array[DAY]++;
		}
	}
}