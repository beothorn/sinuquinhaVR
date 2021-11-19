extends Spatial

class_name Game

const WORLD_SCALE = 1.39

const BALLS_Y = 1.024

onready var preparing_to_play = load("res://src/GameScene/Game/PreparingToPlay.gd")

onready var vr_player = $VRPlayer
onready var left_controller: QuestController = $VRPlayer/LeftController
onready var left_controller_joy: Spatial = $VRPlayer/LeftController/leftJoy
onready var right_controller: QuestController = $VRPlayer/RightController
onready var right_controller_joy: Spatial = $VRPlayer/RightController/rightJoy
onready var debug_label: Label = $VRPlayer/LeftController/MeshInstance/Debug/Label
onready var target: CSGSphere = $Target
onready var label: Label = $HUD/GUI/Label
onready var cueStickCollisionDetector: Area = $CueStick/Area
onready var cueStick: Spatial = $CueStick
onready var cuestick_pos = $VRPlayer/RightController/CueStick
onready var white_ball_node = $WhiteBall
onready var balls_node = $Balls
onready var white_ball_center = $WhiteBallCenter
onready var HUD = $HUD

onready var white_ball_gen = preload("res://src/GameScene/Game/Balls/WhiteBallRigidBody.tscn")
onready var ball_gen = preload("res://src/GameScene/Game/Balls/BallRigidBody.tscn")

export(bool) var debug = true

var saved_table
var table_initial_setup

var white_ball: RigidBody
var balls: Array

var game_state

func _ready():
	_initialize_vr()
	white_ball = $WhiteBall/WhiteBall
	save_table()
	table_initial_setup = saved_table
	_reset_table()
	

func _initialize_vr():
	if not debug:
		var ovr_init_config_pre = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns")
		
		var ovr_init_config = ovr_init_config_pre.new()
		var interface = ARVRServer.find_interface("OVRMobile")
		ARVRServer.world_scale = WORLD_SCALE
		left_controller_joy.scale = Vector3(WORLD_SCALE, WORLD_SCALE, WORLD_SCALE)
		right_controller_joy.scale = Vector3(WORLD_SCALE, WORLD_SCALE, WORLD_SCALE)
		if interface:
			ovr_init_config.set_render_target_size_multiplier(1)
			if interface.initialize():
				get_viewport().arvr = true
		
		right_controller.connect("on_by_pressed", self, "_reset_table")
		left_controller.connect("on_ax_pressed", self, "save_table")
		left_controller.connect("on_by_pressed", self, "load_saved_table")


var pressed = false
func _physics_process(delta: float):
	game_state = game_state.physics_process(self, delta)
	
	var cuestick_raycast = get_world().direct_space_state.intersect_ray(
		right_controller_joy.global_transform.origin,
		right_controller_joy.global_transform.origin + (right_controller_joy.global_transform.basis.z.normalized() * 6),
		[],
		16 # HUD layer
	)
	
	if cuestick_raycast.size() > 0:
		$MouseCursor.global_transform.origin = cuestick_raycast.position
		HUD.mouse_at(cuestick_raycast.position)
		if right_controller.is_trigger_pressed():
			if not pressed:
				pressed = true
				print("WILL CLICK")
				HUD.mouse_press_at(cuestick_raycast.position)
		else:
			HUD.mouse_release_at(cuestick_raycast.position)
			pressed = false

func _readd_white_ball(pos: Vector3 = Vector3(-0.676, 1.024, 0.008)):
	white_ball = white_ball_gen.instance()
	white_ball_node.add_child(white_ball)
	white_ball.connect("body_entered", self, "_on_CueStick_body_entered")
	white_ball.transform.origin = pos
	
func _add_ball(pos: Vector3, rot: Vector3, ball_number: int):
	var ball = ball_gen.instance()
	ball.change_ball(ball_number)
	balls_node.add_child(ball)
	ball.transform.origin = pos
	ball.set_rotation_degrees(rot)
	balls.append(ball)

func _load_table_state(table_state):
	for ball in balls_node.get_children():
		ball.queue_free()
	for ball in white_ball_node.get_children():
		ball.queue_free()
	_readd_white_ball(Vector3(table_state.white_ball.orig_x, BALLS_Y, table_state.white_ball.orig_z))
	balls.clear()
	for ball_data in table_state.balls:
		_add_ball(
			Vector3(ball_data.transform.orig_x, BALLS_Y, ball_data.transform.orig_z), 
			Vector3(ball_data.transform.rot_x, ball_data.transform.rot_y, ball_data.transform.rot_z), 
			ball_data.number
		)
	white_ball_center.global_transform.origin = white_ball.global_transform.origin
	white_ball_center.visible = true

func _reset_table():
	_load_table_state(table_initial_setup)
	game_state = preparing_to_play.new()
	game_state.init()

func save_table():
	var new_saved_state = {
		"white_ball": {
			"orig_x": white_ball.transform.origin.x,
			"orig_z": white_ball.transform.origin.z
		},
		"balls": []
	}
	for ball in balls_node.get_children():
		new_saved_state.balls.append({
			"number": ball.get_ball_number(),
			"transform": {
				"orig_x": ball.transform.origin.x,
				"orig_z": ball.transform.origin.z,
				"rot_x": ball.get_rotation_degrees().x,
				"rot_y": ball.get_rotation_degrees().y,
				"rot_z": ball.get_rotation_degrees().z,
			}
		})
	saved_table = new_saved_state
	

func load_saved_table():
	_load_table_state(saved_table)

func _on_Ground_body_entered(body):
	if balls.find(body) != -1:
		balls.remove(balls.find(body))
		body.queue_free()
	if body == white_ball:
		_readd_white_ball()

func _on_LeftController_on_menu_pressed():
	get_tree().quit()

func _on_ToolButton_pressed():
	print("CLICK")
	get_tree().quit()
