extends ARVRController


func _physics_process(delta):
	var y = get_joystick_axis(1) * delta
	var x = -get_joystick_axis(0) * delta
	get_parent().translate(Vector3(0,y,0))
	get_parent().rotate_y(x)
