extends ARVROrigin

class_name ARVROriginMovable

export(float) var speed = 1.5
export(float) var debounce_rotation_time = 0.33
export(float) var player_rotation_angle = 0.33 # App. 30'

onready var vr_camera: ARVRCamera = $VRCamera

var deboucing_rotation_time_counter: float = debounce_rotation_time

func move_and_rotate(delta: float, movement_vector: Vector2, axis: float):
	var forward_direction = vr_camera.global_transform.basis.z.normalized()
	var right_direction = vr_camera.global_transform.basis.x.normalized()

	var movement_forward = forward_direction * movement_vector.x * delta * speed
	var movement_right = right_direction * movement_vector.y * delta * speed

	movement_forward.y = 0
	movement_right.y = 0

	if movement_right.length() > 0 or movement_forward.length() > 0:
		global_translate(movement_right + movement_forward)
	
	if(deboucing_rotation_time_counter < debounce_rotation_time):
		deboucing_rotation_time_counter += delta
	else:
		if(axis > 0.0):
			rotate_y(-player_rotation_angle)
			deboucing_rotation_time_counter = 0
			
		if(axis < 0.0):
			rotate_y(player_rotation_angle)
			deboucing_rotation_time_counter = 0	

