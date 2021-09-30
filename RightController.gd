extends ARVRController

const CONTROLLER_DEADZONE = 0.65
const MOVEMENT_SPEED = 1.5

const x_axis = 0
const y_axis = 1
const trigger = 2

var aiming_mode = false
var cue_stick_pos
var cue_stick_axis

var cam: ARVRCamera

func _ready():
	cam = get_parent().get_node("ARVRCamera")

func _physics_process(delta):
	var was_aiming_mode = aiming_mode
	aiming_mode = get_joystick_axis(trigger) > CONTROLLER_DEADZONE
	$cueStick.visible = aiming_mode
	if aiming_mode:
		if not was_aiming_mode:
			cue_stick_pos = $cueStick.translation
			cue_stick_axis = $cueStick.transform.basis.y.normalized()
		
		$cueStick.translation = cue_stick_pos + (cue_stick_axis * get_joystick_axis(y_axis))
	else:
		if was_aiming_mode:
			$cueStick.translation = cue_stick_pos
		_physics_process_directional_movement(delta)

func _physics_process_directional_movement(delta):
	var joystick_vector = Vector2(-get_joystick_axis(y_axis), get_joystick_axis(x_axis))

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
