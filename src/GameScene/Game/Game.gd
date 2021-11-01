extends Spatial

class_name Game

const WORLD_SCALE = 1.39

const DEBOUNCE_ROTATION_TIME = 0.33
const PLAYER_ROTATION_ANGLE = 0.53 # App. 30'
const MOVEMENT_SPEED = 1.5
const CUE_STICK_BACK_SIZE = 0.3 # How much can you pull the stick back
const CUE_STICK_MAX_IMPULSE = 0.03
const MINIMUN_BALL_TOTAL_SPEED = 0.005
const CUE_MIN_DISTANCE = 1.897

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


var saved_table = TABLE_INITIAL_SETUP

onready var vr_player = $VRPlayer
onready var vr_camera = $VRPlayer/VRCamera
onready var left_controller: QuestController = $VRPlayer/LeftController
onready var right_controller: QuestController = $VRPlayer/RightController
onready var debug_label: Label = $VRPlayer/LeftController/MeshInstance/Debug/Label

onready var target:CSGSphere = $Target

onready var label:Label = $HUD/GUI/Label

onready var white_ball_gen = preload("res://src/GameScene/Game/Balls/WhiteBallRigidBody.tscn")
onready var ball_gen = preload("res://src/GameScene/Game/Balls/BallRigidBody.tscn")

onready var cueStickCollisionDetector: Area = $CueStick/Area
onready var cueStick = $CueStick

#onready var stick_speed = preload("res://StickSpeed.gd")

export(bool) var debug = true

var aiming_mode = false
var after_throw = false
var pulled_joystick_down = false
var waiting_balls_to_stop = false
var deboucing_rotation_time_counter = DEBOUNCE_ROTATION_TIME
var cue_stick_pos: Transform
var last_joy_axis_measurement = 99
var last_joy_axis_speed = 0
var previous_speed = 0

var current_white_ball: RigidBody
var balls: Array

var auto_shoot_count = 0
var fixed_axis = true

func _ready():
	_initialize_vr()
	_reset_table()

func _initialize_vr():
	if not debug:
		var ovr_init_config_pre = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns")
		
		var ovr_init_config = ovr_init_config_pre.new()
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
	for ball in balls:
		balls_velocity = balls_velocity + ball.linear_velocity.length()
	balls_velocity = balls_velocity / balls.size()
	
	balls_velocity = (balls_velocity + current_white_ball.linear_velocity.length()) / 2
	
	label.text = str(balls_velocity)
	if balls_velocity <= MINIMUN_BALL_TOTAL_SPEED and previous_speed > MINIMUN_BALL_TOTAL_SPEED:
		_save_table()
		_load_saved_table()
		cueStick.visible = true
		waiting_balls_to_stop = false
	
	previous_speed = balls_velocity
	
	_process_left_controller_input(delta)
	if balls_velocity <= MINIMUN_BALL_TOTAL_SPEED:
		_process_right_controller_input(delta)

func _process_left_controller_input(delta: float):
	_move_player(delta, left_controller.get_movement_vector())
	
func _process_right_controller_input(delta: float):
	_rotate_camera(right_controller.get_x_axis(), delta)
	
	if not aiming_mode:
		cueStick.global_transform = $VRPlayer/RightController/CueStick.global_transform
	
	var result = get_world().direct_space_state.intersect_ray(
			cueStick.global_transform.origin,
			cueStick.global_transform.origin + (cueStick.global_transform.basis.y.normalized() * 6),
			[],
			4
		)
	
	if not aiming_mode:
		var bodiesCollidingWithCuestick: Array = cueStickCollisionDetector.get_overlapping_bodies()
		if bodiesCollidingWithCuestick.size() > 0 and not aiming_mode:
			target.visible = false
			cueStick.set_transparent(true)
			return
		
		if result:
			var dist = cueStick.global_transform.origin.distance_to(result.position)
			if dist > CUE_MIN_DISTANCE:
				cueStick.set_transparent(true)
				target.visible = false
				return
			else:
				cueStick.set_transparent(false)
				target.visible = true
				target.global_transform.origin = result.position
				target.global_transform.basis = cueStick.global_transform.basis
		else:
			cueStick.set_transparent(true)
			target.visible = false
			return
	
	var was_aiming_mode = aiming_mode
	aiming_mode =  right_controller.is_trigger_pressed()
	
	
	
	if aiming_mode and not was_aiming_mode:
		after_throw = false
		target.visible = true
		cue_stick_pos = cueStick.global_transform
	
	if aiming_mode:
		_aim(target.global_transform.origin, right_controller.get_raw_y_axis(), delta)
		

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

func _aim(impulse_offset: Vector3, current_joy_axis: float, delta: float):
	if after_throw:
		return	
	
	var cue_stick_y_axis = cueStick.global_transform.basis.y.normalized()
	var joy_to_physical_size_conversion = current_joy_axis * CUE_STICK_BACK_SIZE
	var stick_offset = cue_stick_y_axis * joy_to_physical_size_conversion
	cueStick.global_transform.origin = cue_stick_pos.origin + stick_offset
	
	var cue_stick_original_to_current = cue_stick_pos.origin.distance_to(cueStick.global_transform.origin)
	var cue_stick_original_to_target = cue_stick_pos.origin.distance_to(target.global_transform.origin)
	var cue_stick_to_target = cueStick.global_transform.origin.distance_to(target.global_transform.origin)
	
	if cue_stick_original_to_current > cue_stick_original_to_target and cue_stick_to_target < cue_stick_original_to_target:
		var speed = (current_joy_axis - last_joy_axis_measurement) / delta
		var speed_adjusted = ease(speed * 0.005, -2) # see https://github.com/godotengine/godot/issues/10572
		debug_label.text = str(speed_adjusted)
		
		var axis = cue_stick_y_axis
		if fixed_axis:
			var fixed_stick = cueStick.global_transform.origin
			fixed_stick.y = current_white_ball.global_transform.origin.y
			axis = (current_white_ball.global_transform.origin - fixed_stick).normalized()
		
		var apply_force = cue_stick_y_axis * speed_adjusted
		#print("================")
		#print(release_speed)
		#print(impulse_factor)
		#print(impulse_with_ease)
		#print(impulse_to_apply)
		#print(apply_force)
		#print("================")
		current_white_ball.apply_impulse(impulse_offset, apply_force)
		after_throw = true
		pulled_joystick_down = false
		cueStick.visible = false
		target.visible = false
		$WhiteBallCenter.visible = false
			
		
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
	
func _on_CueStick_body_entered(body):
	if body.name == "WhiteBall":
		print("HIT")

func _readd_white_ball(pos: Vector3 = Vector3(-0.676, 1.024, 0.008)):
	current_white_ball = white_ball_gen.instance()
	$WhiteBall.add_child(current_white_ball)
	current_white_ball.connect("body_entered", self, "_on_CueStick_body_entered")
	current_white_ball.transform.origin = pos
	
func _add_ball(pos: Vector3, ball_number: int):
	var ball = ball_gen.instance()
	ball.change_ball(ball_number)
	$Balls.add_child(ball)
	ball.transform.origin = pos
	balls.append(ball)

func _load_table_state(table_state):
	for ball in $Balls.get_children():
		ball.queue_free()
	for ball in $WhiteBall.get_children():
		ball.queue_free()
	_readd_white_ball(Vector3(table_state.white_ball.x, BALLS_Y, table_state.white_ball.z))
	balls.clear()
	for ball_data in table_state.balls:
		_add_ball(Vector3(ball_data.pos.x, BALLS_Y, ball_data.pos.z), ball_data.number)
	$WhiteBallCenter.global_transform.origin = current_white_ball.global_transform.origin
	$WhiteBallCenter.visible = true

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

func _on_Ground_body_entered():
	_readd_white_ball()

