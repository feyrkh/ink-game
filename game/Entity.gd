extends Node
class_name Entity

var view_node # Node representing the graphical view of this entity in the world - created and destroyed as needed
var view_node_coords # World space coordinates of the view, when the view is created it moves here, when the view is moved this is updated
var view_node_address # The game world is divided into nested views that can go as deep as needed; special address of "hand" means the card is held by the player
var data = {}

func enter_entity_tree():
	EventBus.connect("pre_load_address", self, "pre_load_address")

func create_view():
	printerr("Must subclass Entity and override create_view to create the right kind of physical representation")
	return null

func destroy_view():
	if view_node:
		view_node.queue_free()
		view_node = null

func pre_load_address(old_address, new_address):
	if view_node_address == old_address:
		destroy_view()
		EventBus.try_disconnect("load_address", self, "load_address")
		EventBus.try_disconnect("post_load_address", self, "post_load_address")

	if view_node_address == new_address:
		destroy_view()
		view_node = create_view()
		view_node.set_entity(self)
		EventBus.connect("load_address", self, "load_address")

func load_address(old_address, new_address):
	if view_node_address == new_address:
		EventBus.emit_signal("place_entity", view_node, view_node_coords)
