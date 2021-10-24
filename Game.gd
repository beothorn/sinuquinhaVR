extends Spatial

class_name Game

const WORLD_SCALE = 1.39

const DEBOUNCE_ROTATION_TIME = 0.33
const PLAYER_ROTATION_ANGLE = 0.53 # App. 30'
const MOVEMENT_SPEED = 1.5
const CUE_STICK_BACK_SIZE = 0.3 # How much can you pull the stick back
const CUE_STICK_RELEASE_POINT = -0.0001 # Joystick axis point where if joy goes to zero, it will throw
const CUE_STICK_MAX_IMPULSE = 0.7

const BALLS_Y = 1.024
const TABLE_INITIAL_SETUP = {
	"white_ball": {
		"x": -0.676,
		"z": 0.008
	},
	"balls": [
		{
			"number": 1,
			"pos": {
				"x": -2.448,
				"z": 0.008	
			}
		},
		{
			"number": 2,
			"pos": {
				"x": 0.868,
				"z": 0.687
			}
		},
		{
			"number": 11,
			"pos": {
				"x": 0.665,
				"z": -0.083
			}
		},
		{
			"number": 15,
			"pos": {
				"x": 2.414,
				"z": 1.143
			}
		}
	]
}

var current_white_ball
var saved_table = TABLE_INITIAL_SETUP

onready var vr_player = $VRPlayer
onready var vr_camera = $VRPlayer/VRCamera
onready var left_controller: QuestContorller = $VRPlayer/LeftController
onready var right_controller: QuestContorller = $VRPlayer/RightController
onready var displayCueStick: Spatial = $VRPlayer/RightController/CueStickModel
onready var displayCueStickTransparent: Spatial = $VRPlayer/RightController/CueStickModelTransparent
onready var displayCueStickHitterPositon: Spatial = $VRPlayer/RightController/hitterPosition

onready var cue_stick_rigid_body = preload("res://CueStickRigidBody.tscn")
onready var white_ball_gen = preload("res://WhiteBallRigidBody.tscn")
onready var ball_gen = preload("res://BallRigidBody.tscn")
onready var cue_stick_model = preload("res://assets/cueStick/cueStick.fbx")

onready var cueStickCollisionDetector: Area = $VRPlayer/RightController/CueStickCollisionDetector

export(bool) var debug = false

var aiming_mode = false
var after_hit = false
var after_throw = false
var pulled_joystick_down = false
var waiting_balls_to_stop = false
var deboucing_rotation_time_counter = DEBOUNCE_ROTATION_TIME
var cue_stick_pos: Transform
var last_joy_axis_measurement = 99
var last_joy_axis_speed = 0
var current_cue_stick_rigid_body: RigidBody
var cueStick: Spatial

var auto_shoot_count = 0

func _ready():
	_initialize_vr()
	_reset_table()

func _initialize_vr():
	if not debug:
		var ovr_init_config_pre = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns")
		var ovr_performance_pre = preload("res://addons/godot_ovrmobile/OvrPerformance.gdns")
		
		var ovr_init_config = ovr_init_config_pre.new()
		var ovr_performance = ovr_performance_pre.new()
		var interface = ARVRServer.find_interface("OVRMobile")
		ARVRServer.world_scale = WORLD_SCALE
		$VRPlayer/LeftController/leftJoy.scale = Vector3(WORLD_SCALE, WORLD_SCALE, WORLD_SCALE)
		$VRPlayer/RightController/rightJoy.scale = Vector3(WORLD_SCALE, WORLD_SCALE, WORLD_SCALE)
		if interface:
			ovr_init_config.set_render_target_size_multiplier(1)
			if interface.initialize():
				get_viewport().arvr = true
		
		$VRPlayer/RightController.connect("on_by_pressed", self, "_reset_table")
		$VRPlayer/LeftController.connect("on_ax_pressed", self, "_save_table")
		$VRPlayer/LeftController.connect("on_by_pressed", self, "_load_saved_table")

func _physics_process(delta: float):
	var balls_velocity = 0
	for ball in $Balls.get_children():
		balls_velocity = balls_velocity + ball.linear_velocity.length()
	balls_velocity = balls_velocity / $Balls.get_children().size()
	
	for ball in $WhiteBall.get_children():
		balls_velocity = balls_velocity + ball.linear_velocity.length()
	balls_velocity = balls_velocity / $WhiteBall.get_children().size()
	
	if balls_velocity <= 0.1 and waiting_balls_to_stop:
		_save_table()
		_load_saved_table()
		waiting_balls_to_stop = false
		print(balls_velocity)
	
	_process_left_controller_input(delta)
	_process_right_controller_input(delta)

func _process_left_controller_input(delta: float):
	_move_player(delta, left_controller.get_movement_vector())
	
func _process_right_controller_input(delta: float):
	_rotate_camera(right_controller.get_x_axis(), delta)
	
	var bodiesCollidingWithCuestick: Array = cueStickCollisionDetector.get_overlapping_bodies()
	if bodiesCollidingWithCuestick.size() > 0 and not aiming_mode:
		displayCueStickTransparent.visible = true
		displayCueStick.visible = false
		return
	
	displayCueStickTransparent.visible = false
	
	var was_aiming_mode = aiming_mode
	aiming_mode =  right_controller.is_trigger_pressed() 
	if after_hit:
		if aiming_mode:
			return
		else:
			after_hit = false
	displayCueStick.visible = ! aiming_mode
	var current_y_axis = right_controller.get_y_axis()
	if aiming_mode and not was_aiming_mode:
		after_throw = false
		_move_real_stick_to_joystick_pos()
	if not aiming_mode and was_aiming_mode:
		_remove_aiming_cuestick()
	
	if aiming_mode:
		_aim(right_controller.get_raw_y_axis(), delta)

func _rotate_camera(axis: float, delta: float):
	if(deboucing_rotation_time_counter < DEBOUNCE_ROTATION_TIME):
		deboucing_rotation_time_counter += delta
	else:
		if(axis > 0.0):
			vr_player.rotate_y(-PLAYER_ROTATION_ANGLE)
			deboucing_rotation_time_counter = 0
			
		if(axis < 0.0):
			vr_player.rotate_y(PLAYER_ROTATION_ANGLE)
			deboucing_rotation_time_counter = 0

func _aim(current_joy_axis: float, delta: float):
	if after_throw:
		return
	var cue_stick_y_axis = current_cue_stick_rigid_body.transform.basis.y.normalized()
	cueStick.global_transform.origin = cue_stick_pos.origin + ( cue_stick_y_axis * current_joy_axis * CUE_STICK_BACK_SIZE )
	if current_joy_axis < CUE_STICK_RELEASE_POINT:
		pulled_joystick_down = true
	if current_joy_axis >= -0.000001 :
		if pulled_joystick_down:
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
			
			
			
			var impulse_factor = (release_speed / max_joy_speed)
			# we want weak to e very weak and strong to be very strong, it is not a linear relation
			var impulse_with_ease = ease(impulse_factor, -1.8) # see https://github.com/godotengine/godot/issues/10572
			var impulse_to_apply = (impulse_with_ease * CUE_STICK_MAX_IMPULSE)
			var apply_force = cue_stick_y_axis * impulse_to_apply
			#print("================")
			#print(release_speed)
			#print(impulse_factor)
			#print(impulse_with_ease)
			#print(impulse_to_apply)
			#print(apply_force)
			#print("================")
			current_cue_stick_rigid_body.apply_central_impulse( apply_force )
			after_throw = true
			pulled_joystick_down = false
		
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
	var new_cue_stick_rigid_body: RigidBody = cue_stick_rigid_body.instance()
	
	new_cue_stick_rigid_body = cue_stick_rigid_body.instance()
	new_cue_stick_rigid_body.global_transform = displayCueStickHitterPositon.global_transform
	add_child(new_cue_stick_rigid_body)
	new_cue_stick_rigid_body.connect("body_entered", self, " _on_CueStick_body_entered")
	current_cue_stick_rigid_body = new_cue_stick_rigid_body
	
	cueStick = cue_stick_model.instance()
	cueStick.global_transform = displayCueStick.global_transform
	cue_stick_pos = displayCueStick.global_transform
	add_child(cueStick)
	
func _on_CueStick_body_entered(body):	
	print("HIT")
	after_hit = true
	waiting_balls_to_stop = true
	_remove_aiming_cuestick()

func _remove_aiming_cuestick():
	current_cue_stick_rigid_body.queue_free()
	cueStick.queue_free()

func _readd_white_ball(pos: Vector3 = Vector3(-0.676, 1.024, 0.008)):
	current_white_ball = white_ball_gen.instance()
	$WhiteBall.add_child(current_white_ball)
	current_white_ball.transform.origin = pos
	
func _add_ball(pos: Vector3, ball_number: int):
	var ball = ball_gen.instance()
	ball.change_ball(ball_number)
	$Balls.add_child(ball)
	ball.transform.origin = pos

func _load_table_state(table_state):
	for ball in $Balls.get_children():
		ball.queue_free()
	for ball in $WhiteBall.get_children():
		ball.queue_free()
	_readd_white_ball(Vector3(table_state.white_ball.x, BALLS_Y, table_state.white_ball.z))
	for ball_data in table_state.balls:
		_add_ball(Vector3(ball_data.pos.x, BALLS_Y, ball_data.pos.z), ball_data.number)

func _reset_table():
	_load_table_state(TABLE_INITIAL_SETUP)

func _save_table():
	var new_saved_state = {
		"white_ball": {
			"x": current_white_ball.transform.origin.x,
			"z": current_white_ball.transform.origin.z
		},
		"balls": []
	}
	for ball in $Balls.get_children():
		new_saved_state.balls.append({
			"number": ball.get_ball_number(),
			"pos": {
				"x": ball.transform.origin.x,
				"z": ball.transform.origin.z
			}
		})
	saved_table = new_saved_state
	

func _load_saved_table():
	_load_table_state(saved_table)

func _on_Ground_body_entered(body):
	_readd_white_ball()
