extends Node

const CUE_STICK_BACK_SIZE = 0.3 # How much can you pull the stick back

var preparing_to_play
var waiting_play_to_end

var cue_stick_pos: Vector3

var last_joy_axis_measurement = 99
var last_joy_axis_speed = 0

func init(game):
	print("Aiming")
	cue_stick_pos = game.cueStick.global_transform.origin
	preparing_to_play = load("res://src/GameScene/Game/PreparingToPlay.gd")
	waiting_play_to_end = load("res://src/GameScene/Game/WaitingPlayToEnd.gd")

func physics_process(game, delta: float):
	
	# Move player
	game.vr_player.move_and_rotate(delta, game.left_controller.get_movement_vector(), game.right_controller.get_x_axis())
	
	if !game.right_controller.is_trigger_pressed():
		var next = preparing_to_play.new()
		next.init()
		return next
	
	var impulse_offset = game.target.global_transform.origin
	var current_joy_axis = game.right_controller.get_raw_y_axis()

	var cue_stick_y_axis = game.cueStick.global_transform.basis.y.normalized()
	var joy_to_physical_size_conversion = current_joy_axis * CUE_STICK_BACK_SIZE
	var stick_offset = cue_stick_y_axis * joy_to_physical_size_conversion
	game.cueStick.global_transform.origin = cue_stick_pos + stick_offset
	
	var cue_stick_original_to_current = cue_stick_pos.distance_to(game.cueStick.global_transform.origin)
	var cue_stick_original_to_target = cue_stick_pos.distance_to(game.target.global_transform.origin)
	var cue_stick_to_target = game.cueStick.global_transform.origin.distance_to(game.target.global_transform.origin)
		
	var speed = (current_joy_axis - last_joy_axis_measurement) / delta
	print("not (cue_stick_original_to_current["+str(cue_stick_original_to_current)+"] >= cue_stick_original_to_target["+str(cue_stick_original_to_target)+"] and cue_stick_to_target["+str(cue_stick_to_target)+"] <= cue_stick_original_to_target["+str(cue_stick_original_to_target)+"])")
	# not (cue_stick_original_to_current[0.298819] >= cue_stick_original_to_target[0.108277] and cue_stick_to_target[0.190542] <= cue_stick_original_to_target[0.108277])

	if (cue_stick_original_to_current >= cue_stick_original_to_target) and (cue_stick_to_target <= cue_stick_original_to_current):
		var speed_adjusted = ease(speed * 0.005, -2) # see https://github.com/godotengine/godot/issues/10572
				
		var apply_force = cue_stick_y_axis * speed_adjusted
		game.white_ball.apply_impulse(impulse_offset, apply_force)
		game.cueStick.visible = false
		game.target.visible = false
		game.white_ball_center.visible = false
		print("speed = "+str(current_joy_axis)+" - "+str(last_joy_axis_measurement)+" / "+str(delta))
		print("Applied force:")
		print(str(apply_force))
		print("At point:")
		print(str(impulse_offset))
		
		var next = waiting_play_to_end.new()
		next.init()
		return next
		
	last_joy_axis_speed = speed
	last_joy_axis_measurement = current_joy_axis
	return self
