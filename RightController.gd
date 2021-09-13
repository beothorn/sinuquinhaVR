extends ARVRController

const CONTROLLER_DEADZONE = 0.65

const MOVEMENT_SPEED = 1.5

func _physics_process(delta):
	var x = get_joystick_axis(0) * delta
	var z = get_joystick_axis(1) * delta
	get_parent().translate(Vector3(x,0,z))
	
