extends Spatial
class_name Card

const CARD_LAYER_MASK = 1<<0
const CARD_Y_OFFSET_INCREMENT = 0.03
const HILITE_COLOR = Color("fdffbd")
const SHADOW_CARD = preload("res://cards/ShadowCard.tscn")

onready var CardContents = find_node("CardContents")

export(String) var card_name
var nearby_cards_moved = false
var dragging = false
var entity

func set_entity(entity_data):
	entity = entity_data

func _ready():
	$CardImage.mesh.material = $CardImage.mesh.material.duplicate()

func get_card_info():
	return CardContents.get_card_info()

func _process(delta):
	if nearby_cards_moved:
		nearby_cards_moved = false
		sink_down()

func get_drag_shadow():
	var shadow = SHADOW_CARD.instance()
	#var shadow = Sprite3D.new()
	#shadow.texture = texture
	#shadow.material = shadow.material.duplicate()
	#shadow.material.albedo_color = Color(0.1, 0.1, 0.1, 0.4)
	#shadow.pixel_size = pixel_size
	#shadow.axis = axis
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
			#print("Mouse click at: ", event.global_position, " shape:", self)
			var pickup_offset = Util.project_point_from_mouse(get_viewport().get_camera(), CARD_LAYER_MASK)
			bring_to_top()
			EventBus.emit_signal("start_drag", self, pickup_offset)
			unhighlight()
		elif event.pressed == false:
			print("Mouse release at: ", event.global_position, " shape:", self)
			EventBus.emit_signal("stop_drag")

func drag_started():
	$CardImage.scale = Vector3(0.6, 0.6, 0.6)
	dragging = true

func drag_stopped():
	$CardImage.scale = Vector3.ONE
	dragging = false

func _on_StaticBody_mouse_entered() -> void:
	pass #highlight()

func highlight():
	if !dragging:
		$CardImage.mesh.material.albedo_color = HILITE_COLOR
	else:
		$CardImage.mesh.material.albedo_color = Color.white

func _on_StaticBody_mouse_exited() -> void:
	pass#unhighlight()

func unhighlight():
	$CardImage.mesh.material.albedo_color = Color.white

func get_overlapping_cards():
	var overlapping_areas = $OverlapDetector.get_overlapping_areas()
	var overlapping_cards = []
	for area in overlapping_areas:
		overlapping_cards.append(area.owner)
	#print("Overlapping cards: ", overlapping_cards)
	return overlapping_cards

func bring_to_top():
	var overlapping_cards = get_overlapping_cards()
	var higher_cards = [self]
	for card in overlapping_cards:
		if card.transform.origin.y > self.transform.origin.y:
			higher_cards.append(card)
			card.nearby_cards_moved = true

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

	print(self, " sinking down from ", transform.origin.y, ", has ", overlapping_cards.size(), " overlapping cards")
	for card in overlapping_cards:
		#card.nearby_cards_moved = true
		if card.transform.origin.y < transform.origin.y and card.transform.origin.y > highest_height_below_me:
			highest_height_below_me = card.transform.origin.y
	if highest_height_below_me + CARD_Y_OFFSET_INCREMENT < transform.origin.y:
		transform.origin.y = highest_height_below_me + CARD_Y_OFFSET_INCREMENT
		#print(self, " sank down to ", transform.origin.y)
		for card in overlapping_cards:
			if card.has_method("queue_height_update"):
				card.queue_height_update()
			#print("asked ", card, " to sink down as well")

func queue_height_update():
	nearby_cards_moved = true

func sort_by_height(a, b):
	return a.transform.origin.y < b.transform.origin.y


func _on_Timer_timeout() -> void:
	unhighlight()
