extends ARVRController

const debounce_rotation = 0.33
var deboucing_time = debounce_rotation

func _physics_process(delta):
	var y = get_joystick_axis(1) * delta
	var x = -get_joystick_axis(0) * delta
	get_parent().translate(Vector3(0,y,0))
	if(deboucing_time < debounce_rotation):
		deboucing_time += delta
		return
	if(x > 0.005):
		get_parent().rotate_y(0.52)
		deboucing_time = 0
	if(x < -0.005):
		get_parent().rotate_y(-0.52)
		deboucing_time = 0
