extends Node

const CUE_MIN_DISTANCE = 0.3

var aiming

func init():
	print("PrepaingToPlay")
	aiming = load("res://src/GameScene/Game/Aiming.gd")
	
func physics_process(game, delta: float):
	
	var time_start = OS.get_unix_time()
	
	# Move player
	game.vr_player.move_and_rotate(delta, game.left_controller.get_movement_vector(), game.right_controller.get_x_axis())
	
	# Move stick to joy position
	game.cueStick.global_transform = game.cuestick_pos.global_transform
	var should_fix_axis = !game.left_controller.is_trigger_pressed()
	if should_fix_axis: 
		game.cueStick.global_transform = game.cueStick.global_transform.looking_at(game.white_ball.global_transform.origin, Vector3.UP)
		game.cueStick.rotate_object_local(Vector3.RIGHT, PI/2)
		game.cueStick.rotate_object_local(Vector3.BACK, PI)
	
		
	# If stick is intersecting other balls or table
	if game.cueStick.is_intersecting_other_bodies():
		game.target.visible = false
		game.cueStick.set_transparent(true)
		return self
	
	var cuestick_raycast = game.get_world().direct_space_state.intersect_ray(
		game.cueStick.global_transform.origin,
		game.cueStick.global_transform.origin + (game.cueStick.global_transform.basis.y.normalized() * 6),
		[],
		4 # white ball layer
	)
	
	# If stick is not aiming at white ball
	if cuestick_raycast.size() == 0:
		game.target.visible = false
		game.cueStick.set_transparent(true)
		return self
	
	# If distance to white ball is not close enough to shoot
	var dist = game.cueStick.global_transform.origin.distance_to(cuestick_raycast.position)
	if dist > CUE_MIN_DISTANCE:
		game.target.visible = false
		game.cueStick.set_transparent(true)
		return self
	
	game.target.global_transform.origin = cuestick_raycast.position
	game.target.global_transform.basis = game.cueStick.global_transform.basis
	
	game.target.visible = true
	game.cueStick.set_transparent(false)
	
	# TODO: Here if axis is fixed we need to lock the stick
	# TODO: fixed_axis = left_controller.is_trigger_pressed()
	# If should not switch to aim mode (right trigger)
	if !game.right_controller.is_trigger_pressed():
		return self
	
	var next_state = aiming.new()
	next_state.init(game)
	return next_state
