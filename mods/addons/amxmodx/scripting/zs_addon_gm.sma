#include <amxmodx>
#include <amxmisc>
#include <cstrike>

native zs_get_user_money(id);
native zs_set_user_money(id, amount);

new ei_name[128][128];
new ei_cost[128];
new ei_count;
new ei_itemselect;
new ei_dummyresult;

public plugin_init() {
	register_plugin("[ZS] Game Menu", "v2.53.6", "--chcode");
	register_clcmd("chooseteam", "pl_gamemenu");
	register_clcmd("say /gamemenu", "pl_gamemenu");
	
	ei_itemselect = CreateMultiForward("zs_item_selected", ET_IGNORE, FP_CELL, FP_CELL)
}

public plugin_natives() {
	register_native("zs_register_item", "native_zs_register_item", 1);
	register_native("zs_get_item_id", "native_zs_get_item_id", 1);
	register_native("zs_get_item_cost", "native_zs_get_item_cost", 1);
	register_native("zs_set_item_return", "native_zs_set_item_return", 1);
}

public native_zs_register_item(name[], cost) {
	param_convert(1);
	
	formatex(ei_name[ei_count], charsmax(ei_name), "%s", name);
	ei_cost[ei_count] = cost;
	
	ei_count++;
	return ei_count - 1;
}

public native_zs_get_item_id(name[]) {
	new itemid;
	
	param_convert(1);
	for(new i = 0; i < ei_count; i++) {
		if(containi(name, ei_name[i]) != -1) {
			itemid = i;
			break;
		}
	}
	
	return itemid;
}

public native_zs_get_item_cost(id) {
	return ei_cost[id];
}

public native_zs_set_item_return(id, itemid) {
	zs_set_user_money(id, zs_get_user_money(id) + ei_cost[itemid]);
}

public pl_gamemenu(id) {
	if(get_user_team(id) == 2 && is_user_alive(id)) {
		GameMenu(id);
		return PLUGIN_HANDLED;
	}
}

public GameMenu(id) { 
    new menu = menu_create("\y[ZombieSwarm] ^^0- \wGame Menu", "GameHandle")
    
    menu_additem(menu, "^^1 - \wSelect Weapon", "1", 0);
    menu_additem(menu, "^^1 - \wExtra Items", "2", 0);
    menu_additem(menu, "^^1 - \wUpgrade Stats", "3", 0);
    menu_additem(menu, "^^1 - \wSwitch Spectator", "4", 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
    
    return PLUGIN_HANDLED;
}

public GameHandle(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[6], iName[64], access, callback;
    menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);

    new key = str_to_num(data);
    
    if(key == 1) {
    	client_cmd(id, "say /guns");
    }
    if(key == 2) {
    	ExtraItem(id);
    }
    if(key == 3) {
    	client_cmd(id, "say /upgrade");
    }
    if(key == 4) {
    	cs_set_user_team(id, CS_TEAM_SPECTATOR);
  	  user_kill(id);
    }
    
    menu_destroy(menu);
    
    return PLUGIN_HANDLED;
} 

public ExtraItem(id) { 
	if(get_user_team(id) != 2 || !is_user_alive(id)) {
		if(get_user_team(id) != 2) {
			client_print(id, print_chat, "^^3[ZS] ^^7You are not human");
		}
		else if(!is_user_alive(id)) {
			client_print(id, print_chat, "^^3[ZS] ^^7You are not alive");
		}
		return PLUGIN_HANDLED;
	}
	
	if(!ei_count) {
		client_print(id, print_chat, "^^3[ZS] ^^7No have any extra items.");
		return PLUGIN_HANDLED;
	}
	
    new menu = menu_create("\y[ZombieSwarm] ^^0- \wExtra Items", "ExtraItemHandle")
    new menu_items;
    new menu_items_string[18];
    new menu_items_name[128];
    
    for(new i = 0; i < ei_count; i++) {
    	menu_items++;
    	formatex(menu_items_string, charsmax(menu_items_string), "%d", menu_items);
    	formatex(menu_items_name, charsmax(menu_items_name), "^^1 - \w%s ^^0[$ %d]", ei_name[i], ei_cost[i]);
    	menu_additem(menu, menu_items_name, menu_items_string, 0);
    }
    
    menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    menu_display(id, menu, 0);
    
    return PLUGIN_HANDLED;
}

public ExtraItemHandle(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    if(!is_user_alive(id) || get_user_team(id) != 2) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[6], iName[64], access, callback;
    menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);

    new key = str_to_num(data);
    new itemid = key - 1;
    new money = zs_get_user_money(id);
	
	if(money < ei_cost[itemid]) {
		client_print(id, print_chat, "^^3[ZS] ^^7You can not purchase this item %s", ei_name[itemid]);
		client_print(id, print_chat, "^^3[ZS] ^^7You need for purchase ^^2$ %d", ei_cost[itemid] - money);
		
		menu_destroy(menu);
   	 return PLUGIN_HANDLED;
	}
	
	zs_set_user_money(id, money - ei_cost[itemid]);
	ExecuteForward(ei_itemselect, ei_dummyresult, id, itemid);
	
    menu_destroy(menu);
    return PLUGIN_HANDLED;
} 