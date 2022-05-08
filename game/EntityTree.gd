extends Node

var cur_address = "__NO_ADDRESS__"

func _ready():
	EventBus.connect("register_entity", self, "register_entity")
	EventBus.connect("change_address", self, "change_address")

func change_address(new_address):
	if new_address == cur_address:
		return
	var old_address = cur_address
	EventBus.emit_signal("pre_load_address", old_address, new_address)
	cur_address = new_address
	EventBus.emit_signal("load_address", old_address, new_address)
	EventBus.emit_signal("post_load_address", old_address, new_address)

func register_entity(address, entity_name, entity_node):
	var chunks:PoolStringArray = address.split("/", false)
	var name_chunks:PoolStringArray = entity_name.split("/", false)
	if name_chunks.size() > 1:
		entity_name = name_chunks[-1]
		name_chunks.resize(name_chunks.size()-1)
		chunks.append_array(name_chunks)
	var parent_entity = self
	var parent_address = ""
	for address_chunk in chunks:
		var next_parent = parent_entity.get_node(address_chunk)
		if !next_parent:
			next_parent = create_placeholder_entity(address_chunk, parent_address)
			add_child(next_parent)
		parent_entity = next_parent
	parent_entity.add_child(entity_node)
	entity_node.enter_entity_tree()

func create_placeholder_entity(entity_name, parent_address):
	var entity = preload("res://game/Entity.tscn").instance()
	entity.set_script(preload("res://game/PlaceholderEntity.gd"))
	entity.name = entity_name
	entity.view_node_address = parent_address
	return entity
