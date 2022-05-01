extends Sprite3D
class_name Card

const CARD_LAYER_MASK = 1<<0
const CARD_Y_OFFSET_INCREMENT = 0.03
const HILITE_COLOR = Color("fdffbd")

export(String) var card_name
var nearby_cards_moved = false
var dragging = false

func _ready():
	material_override = material_override.duplicate()

func _process(delta):
	if nearby_cards_moved:
		nearby_cards_moved = false
		sink_down()
		set_process(false)

func get_drag_shadow():
	var shadow = Sprite3D.new()
	shadow.texture = texture
	shadow.material_override = material_override.duplicate()
	shadow.material_override.albedo_color = Color(0.1, 0.1, 0.1, 0.4)
	shadow.pixel_size = pixel_size
	shadow.axis = axis
	return shadow

func drag_sway(drag_amt):
	rotation_degrees.x = sin(drag_amt*-3) * 3
	rotation_degrees.y = sin(drag_amt*2) * 3
	rotation_degrees.z = sin(drag_amt*1) * 3

func _on_StaticBody_input_event(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.doubleclick:
			print("Mouse doubleclick on ", self)
		elif event.pressed and event.button_index == BUTTON_LEFT:
			dragging = true
			#print("Mouse click at: ", event.global_position, " shape:", self)
			var pickup_offset = Util.project_point_from_mouse(get_viewport().get_camera(), CARD_LAYER_MASK)
			bring_to_top()
			EventBus.emit_signal("start_drag", self, pickup_offset)
			unhighlight()
		elif event.pressed == false:
			dragging = false
			print("Mouse release at: ", event.global_position, " shape:", self)
			EventBus.emit_signal("stop_drag")

func _on_StaticBody_mouse_entered() -> void:
	highlight()

func highlight():
	if !dragging:
		material_override.albedo_color = HILITE_COLOR
	else:
		material_override.albedo_color = Color.white

func _on_StaticBody_mouse_exited() -> void:
	unhighlight()

func unhighlight():
	material_override.albedo_color = Color.white

func get_overlapping_cards():
	var overlapping_areas = $OverlapDetector.get_overlapping_areas()
	var overlapping_cards = []
	for area in overlapping_areas:
		overlapping_cards.append(area.owner)
	return overlapping_cards

func bring_to_top():
	var overlapping_cards = get_overlapping_cards()
	var higher_cards = [self]
	for card in overlapping_cards:
		if card.transform.origin.y > self.transform.origin.y:
			higher_cards.append(card)
			card.nearby_cards_moved = true
			card.set_process(true)

	higher_cards.sort_custom(self, "sort_by_height")
	var highest_card_y = higher_cards[-1].transform.origin.y
	for i in range(higher_cards.size()-1, 0, -1):
		var card = higher_cards[i]
		var prev_card = higher_cards[i-1]
		#print('moving ', card.card_name, ' to height ', prev_card.transform.origin.y)
		#card.transform.origin.y = prev_card.transform.origin.y
	transform.origin.y = highest_card_y

func sink_down():
	if dragging:
		return
	var highest_height_below_me = 0
	var overlapping_cards = get_overlapping_cards()

	#print(self, "sinking down from ", transform.origin.y, ", has ", overlapping_cards.size(), " overlapping cards")
	for card in overlapping_cards:
		if card.transform.origin.y < transform.origin.y and card.transform.origin.y > highest_height_below_me:
			highest_height_below_me = card.transform.origin.y
	if highest_height_below_me + CARD_Y_OFFSET_INCREMENT < transform.origin.y:
		transform.origin.y = highest_height_below_me + CARD_Y_OFFSET_INCREMENT
		#print(self, " sank down to ", transform.origin.y)
		for card in overlapping_cards:
			card.nearby_cards_moved = true
			card.set_process(true)
			#print("asked ", card, " to sink down as well")

func sort_by_height(a, b):
	return a.transform.origin.y < b.transform.origin.y


func _on_Timer_timeout() -> void:
	unhighlight()
