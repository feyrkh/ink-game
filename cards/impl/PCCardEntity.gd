extends Entity

const CardView:PackedScene = preload("res://cards/Card.tscn")

func setup(address, pos, pc_name):
	data["name"] = pc_name
	view_node_coords = pos
	view_node_address = address

func create_view():
	var view = CardView.instance()
	view.set_script(preload("PCCardView.gd"))
	return view
