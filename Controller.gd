extends ARVRController

class_name QuestContorller

const CONTROLLER_VECTOR_DEADZONE = 0.65
const CONTROLLER_AXIS_DEADZONE = 0.3
const TRIGGER_AXIS_DEADZONE = 0.2
const X_AXIS = 0
const Y_AXIS = 1
const TRIGGER = 2

func is_trigger_pressed() -> bool:
	return get_joystick_axis(TRIGGER) > TRIGGER_AXIS_DEADZONE

func get_x_axis(sensitivity = CONTROLLER_AXIS_DEADZONE) -> float:
	return  _get_axis(X_AXIS, sensitivity)

func get_y_axis(sensitivity = CONTROLLER_AXIS_DEADZONE) -> float:
	return  _get_axis(Y_AXIS, sensitivity)

func get_raw_y_axis() -> float:
	return  get_joystick_axis(Y_AXIS)

func get_controller_vector() -> Vector2:
	return Vector2(get_x_axis(), get_y_axis())

func get_movement_vector() -> Vector2:
	var controller_vector: Vector2 = Vector2(-get_joystick_axis(Y_AXIS), get_joystick_axis(X_AXIS))

	if controller_vector.length() < CONTROLLER_VECTOR_DEADZONE:
		controller_vector = Vector2(0,0)
	else:
		controller_vector = controller_vector.normalized() * ((controller_vector.length() - CONTROLLER_VECTOR_DEADZONE) / (1 - CONTROLLER_VECTOR_DEADZONE))
	return controller_vector.normalized()

func _get_axis(axis, sensitivity):
	var raw_axis = get_joystick_axis(axis)
	if raw_axis < sensitivity and raw_axis > -sensitivity:
		return 0.0
	return raw_axis
