extends Camera

const PAN_SPEED = 5
const ZOOM_SPEED = 1

func _process(delta):
	if Input.is_action_pressed("camera_forward"):
		transform.origin += Vector3.FORWARD * PAN_SPEED * delta
	if Input.is_action_pressed("camera_back"):
		transform.origin += Vector3.BACK * PAN_SPEED * delta
	if Input.is_action_pressed("camera_left"):
		transform.origin += Vector3.LEFT * PAN_SPEED * delta
	if Input.is_action_pressed("camera_right"):
		transform.origin += Vector3.RIGHT * PAN_SPEED * delta

	if Input.is_action_just_pressed("camera_zoom_out"):
		transform.origin += Vector3.UP * ZOOM_SPEED
	if Input.is_action_just_pressed("camera_zoom_in"):
		transform.origin += Vector3.DOWN * ZOOM_SPEED

