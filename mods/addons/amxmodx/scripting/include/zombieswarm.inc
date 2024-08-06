// * Zombie Swarm Include * //
// * Includes by --chcode & berkch * //

// Natives
native zs_register_item(name[], cost);
native zs_get_item_id(name[]);
native zs_set_item_return(id, itemid);
native zs_get_item_cost(id);
native zs_get_user_zombie(id);
native zs_get_user_boss(id);
native zs_get_user_money(id);
native zs_set_user_money(id, amount);
native zs_get_user_model_gender(id);

// Enums
enum {
	MALE = 0,
	FEMALE
}

native zs_add_human(model[], gender);
native zs_add_zombie(player[], model[], gender);

// Forwardings
forward zs_item_select(id, item);
forward zs_item_return(id, item);
forward zs_zombie_spawn(id);
forward zs_human_respawn(id);