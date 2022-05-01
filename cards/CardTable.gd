extends Spatial

const TABLE_COLLIDER_MASK = 1<<2
const DRAG_CAMERA = 1
const DRAG_CARD = 2
const CARD_SNAP_SIZE = Vector2(0.45*2, 0.66*2) / 3

var dragging_item
var dragging_shadow
var drag_mode = null
var drag_initial_rotation

var drag_start_world_coords:Vector3 # world space position of the mouse on the surface of the table when dragging started
var dragging_item_initial_position:Vector3 # world space position of the item being dragged, in case we need to put it back where it came from
var dragging_item_pickup_offset:Vector3 # difference between the start position and the mouse cursor, so we can offset the item and its shadow while dragging

func _ready():
	EventBus.connect("start_drag", self, "start_drag")
	EventBus.connect("stop_drag", self, "stop_drag")

func start_drag(item:Node, pickup_offset:Vector3):
	clear_shadow()
	var camera = $Camera
	var result = Util.project_point_from_mouse(camera, 1<<2)
	drag_start_world_coords = Vector3(result.x, 0, result.z)

	if item == self:
		drag_mode = DRAG_CAMERA
	else:
		drag_mode = DRAG_CARD
		dragging_item = item
		dragging_shadow = null
		drag_initial_rotation = dragging_item.rotation_degrees
		if dragging_item.has_method("get_drag_shadow"):
			dragging_shadow = dragging_item.get_drag_shadow()
			if dragging_shadow:
				add_child(dragging_shadow)
		dragging_item_initial_position = dragging_item.global_transform.origin
		dragging_item_pickup_offset =  dragging_item_initial_position
		dragging_item_pickup_offset.y = 0
		print("Pickup offset: ", dragging_item_pickup_offset)
	print("drag start at ", drag_start_world_coords)


func stop_drag():
	if drag_mode == DRAG_CARD:
		dragging_item.rotation_degrees = drag_initial_rotation
		if dragging_shadow:
			dragging_item.global_transform.origin = dragging_shadow.global_transform.origin
		else:
			dragging_item.global_transform.origin = dragging_item_initial_position
	clear_shadow()
	drag_mode = null

func clear_shadow():
	if dragging_shadow:
		dragging_shadow.queue_free()
		dragging_shadow = null

func _physics_process(delta: float) -> void:
	if drag_mode != null && !Input.is_action_pressed("mouse_drag"):
		stop_drag()
		return
	if drag_mode == DRAG_CAMERA:
		var camera = $Camera
		var new_mouse_world_pos = Util.project_point_from_mouse(camera, TABLE_COLLIDER_MASK)
		if !new_mouse_world_pos:
			return
		var world_dist_moved = new_mouse_world_pos - Vector3(drag_start_world_coords.x, 0, drag_start_world_coords.z)
		camera.global_transform.origin.x -= world_dist_moved.x
		camera.global_transform.origin.z -= world_dist_moved.z
	elif drag_mode == DRAG_CARD:
		var camera = $Camera
		var world_dist_moved = Util.project_point_from_mouse(camera, TABLE_COLLIDER_MASK) - Vector3(drag_start_world_coords.x, -0.75, drag_start_world_coords.z)
		#print("world_dist_moved: ", world_dist_moved)
		dragging_item.global_transform.origin = dragging_item_initial_position + world_dist_moved
		dragging_item.drag_sway(world_dist_moved.length())
		if dragging_shadow:
			var overlapping_cards = dragging_item.get_overlapping_cards()
			var highest = 0
			for card in overlapping_cards:
				if card.global_transform.origin.y > highest:
					highest = card.global_transform.origin.y
					card.material_override.albedo_color = Color.green
			print("Shadow at ", highest + Card.CARD_Y_OFFSET_INCREMENT)
			dragging_shadow.global_transform.origin = Vector3(round(dragging_item.global_transform.origin.x/CARD_SNAP_SIZE.x)*CARD_SNAP_SIZE.x, highest + Card.CARD_Y_OFFSET_INCREMENT, round(dragging_item.global_transform.origin.z/CARD_SNAP_SIZE.y)*CARD_SNAP_SIZE.y)

func _on_TabletopCollider_input_event(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.doubleclick:
			print("Mouse doubleclick on ", self)
		elif event.pressed and event.button_index == BUTTON_LEFT:
			print("Mouse click at: ", event.global_position, " shape:", self)
			EventBus.emit_signal("start_drag", self, Vector3.ZERO)
		elif event.pressed == false:
			print("Mouse release at: ", event.global_position, " shape:", self)
			EventBus.emit_signal("stop_drag")
