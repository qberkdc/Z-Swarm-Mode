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

// Forwardings
forward zs_item_select(id, item);
forward zs_zombie_spawn(id);