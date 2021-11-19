extends StaticBody

onready var cueStickCollisionDetector: Label = $HUD/GUI/MarginContainer/VSplitContainer/VSplitContainer2/pos
onready var gui: Viewport = $HUD/GUI

func setPos(p: Vector2):
	cueStickCollisionDetector.text = str(p)

func _get_pos_2d(pos3: Vector3):
	var relative_pos3: Vector3 = global_transform.origin - pos3 
	# goes from -1 to 1
	var projected_ray_pos = Vector2((relative_pos3.z + 1)/2, (relative_pos3.y + 1)/ 2) # x is z because panel is rotated 90
	return projected_ray_pos * gui.size

func mouse_at(pos3: Vector3):
	var mouse_position: InputEventMouseMotion  = InputEventMouseMotion.new()
	mouse_position.position = _get_pos_2d(pos3)
	setPos(mouse_position.position)
	gui.input(mouse_position)

func mouse_press_at(pos3: Vector3):
	var mouse_position: InputEventMouseButton  = InputEventMouseButton.new()
	mouse_position.position = _get_pos_2d(pos3)
	mouse_position.pressed = true
	mouse_position.button_mask = BUTTON_LEFT
	mouse_position.button_index = BUTTON_LEFT
	gui.input(mouse_position)

func mouse_release_at(pos3: Vector3):
	var mouse_position: InputEventMouseButton  = InputEventMouseButton.new()
	mouse_position.position = _get_pos_2d(pos3)
	mouse_position.pressed = false
	mouse_position.button_mask = BUTTON_LEFT
	mouse_position.button_index = BUTTON_LEFT
	gui.input(mouse_position)
