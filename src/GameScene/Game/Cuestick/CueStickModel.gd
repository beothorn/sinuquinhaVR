extends Spatial

class_name CluestickModel

onready var cueStickCollisionDetector: Area = $Area

var current_transparent = false

func get_stick_size():
	return $CueStickModel.transform.origin.y * -1

func set_transparent(value: bool):
	if current_transparent == value:
		return
	current_transparent = value
	visible = true
	if value:
		$CueStickModel.visible = false
		$CueStickModelTransparent.visible = true
	else:
		$CueStickModel.visible = true
		$CueStickModelTransparent.visible = false

func is_intersecting_other_bodies():
	var bodiesCollidingWithCuestick: Array = cueStickCollisionDetector.get_overlapping_bodies()
	return bodiesCollidingWithCuestick.size() > 0
