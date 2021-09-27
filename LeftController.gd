extends ARVRController

const debounce_rotation = 0.33
var deboucing_time = debounce_rotation

const CONTROLLER_DEADZONE = 0.65
const MOVEMENT_SPEED = 1.5

var cam: ARVRCamera

func _ready():
	cam = get_parent().get_node("ARVRCamera")

func _physics_process(delta):	
	_physics_process_directional_movement(delta)
	
	var joystick_vector = Vector2(-get_joystick_axis(1), get_joystick_axis(0))
	var x = -get_joystick_axis(0) * delta
	
	if(deboucing_time < debounce_rotation):
		deboucing_time += delta
		return
	if(x > 0.01):
		get_parent().rotate_y(0.52)
		deboucing_time = 0
	if(x < -0.01):
		get_parent().rotate_y(-0.52)
		deboucing_time = 0

func _physics_process_directional_movement(delta):
	var joystick_vector = Vector2(-get_joystick_axis(1), get_joystick_axis(0))

	if joystick_vector.length() < CONTROLLER_DEADZONE:
		joystick_vector = Vector2(0,0)
	else:
		joystick_vector = joystick_vector.normalized() * ((joystick_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))

	var forward_direction = cam.global_transform.basis.z.normalized()
	var right_direction = cam.global_transform.basis.x.normalized()

	var movement_vector = joystick_vector.normalized()

	var movement_forward = forward_direction * movement_vector.x * delta * MOVEMENT_SPEED
	var movement_right = right_direction * movement_vector.y * delta * MOVEMENT_SPEED

	movement_forward.y = 0
	movement_right.y = 0

	if movement_right.length() > 0 or movement_forward.length() > 0:
		get_parent().global_translate(movement_right + movement_forward)
