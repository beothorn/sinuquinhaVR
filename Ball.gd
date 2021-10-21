extends RigidBody

var ballNumber = 0

func change_ball(ball_number: int):
	ballNumber = ball_number
	var image = load("res://resources/balls/" + str(ballNumber) + ".png")	
	var material_one = $Model.get_surface_material(0).duplicate()
	material_one.albedo_texture = image
	$Model.set_surface_material(0, material_one)
