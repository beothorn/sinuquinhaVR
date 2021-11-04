extends Node

const MINIMUN_BALL_TOTAL_SPEED = 0.005

var preparing_to_play

var previous_speed = 0

func init():
	print("WaitingPlayToEnd")
	preparing_to_play = load("res://src/GameScene/Game/PreparingToPlay.gd")

func physics_process(game, delta: float):
	# Move player
	game.vr_player.move_and_rotate(delta, game.left_controller.get_movement_vector(), game.right_controller.get_x_axis())
	
	var balls_velocity = 0
	for ball in game.balls:
		balls_velocity = balls_velocity + ball.linear_velocity.length()
	balls_velocity = balls_velocity / game.balls.size()
	
	balls_velocity = (balls_velocity + game.white_ball.linear_velocity.length()) / 2
	
	if balls_velocity <= MINIMUN_BALL_TOTAL_SPEED and previous_speed > MINIMUN_BALL_TOTAL_SPEED:
		game.save_table()
		game.load_saved_table()
		game.cueStick.visible = true
		var next = preparing_to_play.new()
		next.init()
		return next
	
	previous_speed = balls_velocity
	return self
