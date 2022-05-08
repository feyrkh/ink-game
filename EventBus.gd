extends Node

signal start_drag(item, pickup_offset)
signal stop_drag()

signal show_card_info(item)
signal hide_card_info()

signal change_address(new_address) # called to trigger an address change

signal pre_load_address(old_address, new_address) # called just before a new address is loaded
signal load_address(old_address, new_address) # called to load entities for a new address
signal post_load_address(old_address, new_address) # called just after a new address is loaded

signal register_entity(address, entity_name, entity_node) # called to register a new entity in the tree. If the address is invalid, a placeholder entity will be created and may later be overridden
signal place_entity(entity_view_node, initial_coords) # called to place an entity on the map, hopefully respecting other entities nearby...

func try_disconnect(signal_name, obj, method):
	if is_connected(signal_name, obj, method):
		disconnect(signal_name, obj, method)
