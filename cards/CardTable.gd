extends Spatial

const TABLE_COLLIDER_MASK = 1<<2
const CARD_CORE_LAYER_MASK = 1<<3
const DRAG_CAMERA = 1
const DRAG_CARD = 2
const CARD_SNAP_SIZE = Vector2(0.6*2, 0.8*2) / 3

var dragging_item
var dragging_shadow
var drag_mode = null
var drag_initial_rotation

var drag_start_world_coords:Vector3 # world space position of the mouse on the surface of the table when dragging started
var dragging_item_initial_position:Vector3 # world space position of the item being dragged, in case we need to put it back where it came from
var dragging_item_pickup_offset:Vector3 # difference between the start position and the mouse cursor, so we can offset the item and its shadow while dragging
var last_drag_pixel # screen position of the last time we checked dragging physics - if it hasn't changed, no need to do anything else
var last_drag_pixel_update_count = 0

var tile_try_list = [Vector3(0,0,0)]

func _ready():
	EventBus.connect("start_drag", self, "start_drag")
	EventBus.connect("stop_drag", self, "stop_drag")
	for dist in range(1, 10):
		for y in range(-dist, dist+1):
			for x in range(-dist, dist+1):
				var steps_away = abs(y) + abs(x)
				if steps_away != dist:
					continue
				tile_try_list.append(Vector3(x, 0, y))

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
		dragging_item.drag_started()
		print("Pickup offset: ", dragging_item_pickup_offset)
		last_drag_pixel = null
		call_deferred("update_drag")
	print("drag start at ", drag_start_world_coords)


func stop_drag():
	if drag_mode == DRAG_CARD:
		dragging_item.rotation_degrees = drag_initial_rotation
		if dragging_shadow:
			dragging_item.global_transform.origin = dragging_shadow.global_transform.origin
		else:
			dragging_item.global_transform.origin = dragging_item_initial_position
		dragging_item.drag_stopped()
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
	var cur_drag_pixel = $Camera.get_viewport().get_mouse_position()
	if last_drag_pixel == cur_drag_pixel:
		last_drag_pixel_update_count += 1
		if last_drag_pixel_update_count > 2:
			return
	last_drag_pixel_update_count = 0
	last_drag_pixel = cur_drag_pixel
	update_drag()

func update_drag():
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
		dragging_item.drag_sway(world_dist_moved.length() + dragging_item.global_transform.origin.length())
		if dragging_shadow:
			var overlapping_cards = dragging_shadow.get_overlapping_cards()
			overlapping_cards.erase(dragging_item)
			var highest = 0
			for card in overlapping_cards:
				if card.global_transform.origin.y > highest:
					highest = card.global_transform.origin.y
			#print("Shadow at ", highest + Card.CARD_Y_OFFSET_INCREMENT)
			dragging_shadow.global_transform.origin = closest_unoccupied_tile(dragging_item.global_transform.origin)
			dragging_shadow.global_transform.origin.y = highest + Card.CARD_Y_OFFSET_INCREMENT
			#Vector3(round(dragging_item.global_transform.origin.x/CARD_SNAP_SIZE.x)*CARD_SNAP_SIZE.x, highest + Card.CARD_Y_OFFSET_INCREMENT, round(dragging_item.global_transform.origin.z/CARD_SNAP_SIZE.y)*CARD_SNAP_SIZE.y)

func closest_unoccupied_tile(position):
	var center_tile = Vector3(round(position.x/CARD_SNAP_SIZE.x), 0, round(position.z/CARD_SNAP_SIZE.y))
	for tile_try in tile_try_list:
		var cur_tile = Vector3((center_tile.x + tile_try.x)*CARD_SNAP_SIZE.x, 0, (center_tile.z + tile_try.z)*CARD_SNAP_SIZE.y)
		#print("Trying tile: ", cur_tile)
		var intersect = Util.raycast_from_point(self, cur_tile+Vector3.DOWN*3, Vector3.UP*6, CARD_CORE_LAYER_MASK, [dragging_item.find_node("CoreDetector")])
		if !intersect:
			#print("Good tile: ", cur_tile)
			return cur_tile
		else:
			#print("Possibly bad tile: ", cur_tile)
			if tile_try == Vector3.ZERO:
				var intersecting_item = intersect["collider"].owner
				if intersecting_item.has_method("can_merge_with"):
					if intersecting_item.can_merge_with(dragging_item):
						dragging_item.potentially_merge_with_item(intersecting_item)
						return cur_tile


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
