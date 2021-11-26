extends StaticBody

onready var gui: Viewport = $HUD/GUI
onready var cursor: Sprite = $HUD/GUI/Cursor

func _get_pos_2d(pos3: Vector3):
	var relative_pos3: Vector3 = global_transform.origin - pos3 
	# goes from -1 to 1
	if relative_pos3.z < -1 or relative_pos3.z > 1 or relative_pos3.y < -1 or relative_pos3.y > 1:
		return null
	var projected_ray_pos = Vector2((relative_pos3.z + 1)/2, (relative_pos3.y + 1)/ 2) # x is z because panel is rotated 90
	return projected_ray_pos * gui.size

func hide_cursor():
	cursor.visible = false

func mouse_at(pos3: Vector3):
	var mouse_position: InputEventMouseMotion  = InputEventMouseMotion.new()
	var new_mouse_pos = _get_pos_2d(pos3)
	if new_mouse_pos:
		mouse_position.position = new_mouse_pos
		gui.input(mouse_position)
		cursor.visible = true
		cursor.position = mouse_position.position
	else:
		cursor.visible = false

func mouse_press_at(pos3: Vector3):
	var mouse_position: InputEventMouseButton  = InputEventMouseButton.new()
	mouse_position.position = _get_pos_2d(pos3)
	mouse_position.pressed = true
	mouse_position.button_mask = BUTTON_LEFT
	mouse_position.button_index = BUTTON_LEFT
	gui.input(mouse_position)

func mouse_release_at(pos3: Vector3):
	var mouse_position: InputEventMouseButton  = InputEventMouseButton.new()
	var new_mouse_pos = _get_pos_2d(pos3)
	if new_mouse_pos:
		mouse_position.position = new_mouse_pos
	mouse_position.pressed = false
	mouse_position.button_mask = BUTTON_LEFT
	mouse_position.button_index = BUTTON_LEFT
	gui.input(mouse_position)
