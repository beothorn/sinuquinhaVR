extends ARVRController

class_name QuestContorller

signal on_ax_pressed
signal on_by_pressed

const CONTROLLER_VECTOR_DEADZONE = 0.65
const CONTROLLER_AXIS_DEADZONE = 0.3
const TRIGGER_AXIS_DEADZONE = 0.2

func _ready():
	connect("button_pressed", self, "_on_button_pressed")

func _on_button_pressed(button):
	if button == JOY_OCULUS_AX:
		emit_signal("on_ax_pressed")
	if button == JOY_OCULUS_BY:
		emit_signal("on_by_pressed")

func is_trigger_pressed() -> bool:
	return get_joystick_axis(JOY_VR_ANALOG_TRIGGER) > TRIGGER_AXIS_DEADZONE

func get_x_axis(sensitivity = CONTROLLER_AXIS_DEADZONE) -> float:
	return  _get_axis(JOY_OPENVR_TOUCHPADX, sensitivity)

func get_y_axis(sensitivity = CONTROLLER_AXIS_DEADZONE) -> float:
	return  _get_axis(JOY_OPENVR_TOUCHPADY, sensitivity)

func get_raw_y_axis() -> float:
	return  get_joystick_axis(JOY_OPENVR_TOUCHPADY)

func get_controller_vector() -> Vector2:
	return Vector2(get_x_axis(), get_y_axis())

func get_movement_vector() -> Vector2:
	var controller_vector: Vector2 = Vector2(-get_joystick_axis(JOY_OPENVR_TOUCHPADY), get_joystick_axis(JOY_OPENVR_TOUCHPADX))

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
