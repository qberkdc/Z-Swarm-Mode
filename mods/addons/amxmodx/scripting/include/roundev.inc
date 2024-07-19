// 	Round Events Include
#define ROUND_START 1
#define ROUND_END 2
#define ROUND_RESTART 3
#define ROUND_NEW 4

// 	Round Events Names
new const evnames[][] = {
	"",
	"Start Event",
	"End Event",
	"Restart Event",
	"New Event"
}

public register_round(round, function[]) {
	if(round == ROUND_START) {
		register_logevent(function, 2, "1=Round_Start");
	}
	
	if(round == ROUND_END) {
		register_logevent(function, 2, "1=Round_End");
	}
	
	if(round == ROUND_RESTART) {
		register_event("TextMsg", function, "a", "2&#Game_C", "2&#Game_w");
	}
	
	if(round == ROUND_NEW) {
		register_event("HLTV", function, "a", "1=0", "2=0");
	}
	
	server_print("Register Round Event: %d/%s/%s", round, evnames[round], function);
}