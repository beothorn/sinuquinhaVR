extends Spatial

class_name Game


const DEBOUNCE_ROTATION_TIME = 0.33
const PLAYER_ROTATION_ANGLE = 0.53 # App. 30'
const MOVEMENT_SPEED = 1.5
const CUE_STICK_BACK_SIZE = 0.3 # How much can you pull the stick back
const CUE_STICK_RELEASE_POINT = -0.0001 # Joystick axis point where if joy goes to zero, it will throw

onready var vr_player = $VRPlayer
onready var vr_camera = $VRPlayer/VRCamera
onready var left_controller: QuestContorller = $VRPlayer/LeftController
onready var right_controller: QuestContorller = $VRPlayer/RightController
onready var cueStick: RigidBody = $CueStick
onready var displayCueStick: Spatial = $VRPlayer/RightController/CueStickModel
onready var displayCueStickHitterPositon: CSGCylinder = $VRPlayer/RightController/hitterPosition

export(bool) var debug = false

var aiming_mode = false
var after_hit = false
var after_throw = false # TODO: This should be aiming mode
var pulled_down = false
var deboucing_rotation_time_counter = DEBOUNCE_ROTATION_TIME
var cue_stick_pos: Transform
var last_joy_axis_measurement = 99
var last_joy_axis_speed = 0

func _ready():
	_initialize_vr()

func _initialize_vr():
	if not debug:
		var ovr_init_config_pre = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns")
		var ovr_performance_pre = preload("res://addons/godot_ovrmobile/OvrPerformance.gdns")
		
		var ovr_init_config = ovr_init_config_pre.new()
		var ovr_performance = ovr_performance_pre.new()
		var interface = ARVRServer.find_interface("OVRMobile")
		if interface:
			ovr_init_config.set_render_target_size_multiplier(1)
			if interface.initialize():
				get_viewport().arvr = true

func _physics_process(delta: float):
	_process_left_controller_input(delta)
	_process_right_controller_input(delta)

func _process_left_controller_input(delta: float):
	_move_player(delta, left_controller.get_movement_vector())
	
func _process_right_controller_input(delta: float):
	var was_aiming_mode = aiming_mode
	aiming_mode =  right_controller.is_trigger_pressed() 
	if after_hit:
		if not aiming_mode:
			after_hit = false
		else:
			return
	cueStick.visible = aiming_mode
	displayCueStick.visible = ! aiming_mode
	var current_y_axis = right_controller.get_y_axis()
	if aiming_mode and not was_aiming_mode:
		after_throw = false
		_move_real_stick_to_joystick_pos()
	if not aiming_mode and was_aiming_mode:
		cueStick.sleeping = true
	
	if aiming_mode:
		_aim(right_controller.get_raw_y_axis(), delta)
		
	if(deboucing_rotation_time_counter < DEBOUNCE_ROTATION_TIME):
		deboucing_rotation_time_counter += delta
	else:
		var x = right_controller.get_x_axis()
		
		if(x > 0.0):
			vr_player.rotate_y(-PLAYER_ROTATION_ANGLE)
			deboucing_rotation_time_counter = 0
			
		if(x < 0.0):
			vr_player.rotate_y(PLAYER_ROTATION_ANGLE)
			deboucing_rotation_time_counter = 0

func _aim(current_joy_axis: float, delta: float):
	if after_throw:
		return
	var cue_stick_y_axis = cueStick.transform.basis.y.normalized()
	print("================")
	print(pulled_down)
	print(current_joy_axis)
	print("================")
	if current_joy_axis < CUE_STICK_RELEASE_POINT:
		pulled_down = true
	if current_joy_axis >= -0.000001 :
		if pulled_down:
			var current_speed = (current_joy_axis - last_joy_axis_measurement) / delta
			# line from (last_joy_axis_measurement, last_joy_axis_speed) to (current_joy_axis, current_speed)
			# need to find where it intersects CUE_STICK_RELEASE_POINT
			
			# x is y_axis (joystick y position ranging from -1 to 1)
			# y is speed (joystick change per time)
			# y = a*x + b
			# a is the slope
			# a = ((y2-y1)/(x2-x1))
			var a = ((current_speed - last_joy_axis_speed)/(current_joy_axis - last_joy_axis_measurement))
					
			
			# y = ((y2-y1)/(x2-x1))*x + b
			# -b + y = ax
			# b - y = -ax
			# b = -ax + y
			# b = y - ax
			var b = current_speed - ( a * current_joy_axis )
			
			# y = ax + b
			var release_speed = (a * CUE_STICK_RELEASE_POINT) + b
			
			var max_joy_speed = 56
			if release_speed > max_joy_speed:
				release_speed = max_joy_speed
			
			var cue_stick_max_impulse = 20
			
			var impulse_factor = (release_speed / max_joy_speed)
			# we want weak to e very weak and strong to be very strong, it is not a linear relation
			var impulse_with_ease = ease(impulse_factor, -1.8) # see https://github.com/godotengine/godot/issues/10572
			var impulse_to_apply = (impulse_with_ease * cue_stick_max_impulse)
			var apply_force = cue_stick_y_axis * impulse_to_apply
			#print("================")
			#print(release_speed)
			#print(impulse_factor)
			#print(impulse_with_ease)
			#print(impulse_to_apply)
			#print(apply_force)
			#print("================")
			cueStick.apply_central_impulse( apply_force )
			after_throw = true
			pulled_down = false
	else:
		cueStick.global_transform.origin = cue_stick_pos.origin + ( cue_stick_y_axis * current_joy_axis * CUE_STICK_BACK_SIZE )
		cueStick.sleeping = true
	last_joy_axis_speed = (current_joy_axis - last_joy_axis_measurement) / delta
	last_joy_axis_measurement = current_joy_axis

func _move_player(delta: float, movement_vector: Vector2):
	var forward_direction = vr_camera.global_transform.basis.z.normalized()
	var right_direction = vr_camera.global_transform.basis.x.normalized()

	var movement_forward = forward_direction * movement_vector.x * delta * MOVEMENT_SPEED
	var movement_right = right_direction * movement_vector.y * delta * MOVEMENT_SPEED

	movement_forward.y = 0
	movement_right.y = 0

	if movement_right.length() > 0 or movement_forward.length() > 0:
		vr_player.global_translate(movement_right + movement_forward)

func _move_real_stick_to_joystick_pos():
	cue_stick_pos = displayCueStickHitterPositon.global_transform
	cueStick.global_transform = displayCueStickHitterPositon.global_transform


func _on_CueStick_body_entered(body):
	after_hit = true
	cueStick.visible = false
	cueStick.sleeping = true
