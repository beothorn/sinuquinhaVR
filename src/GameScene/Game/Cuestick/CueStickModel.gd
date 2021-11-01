extends Spatial

func get_stick_size():
	return $CueStickModel.transform.origin.y * -1

func set_transparent(value: bool):
	visible = true
	if value:
		$CueStickModel.visible = false
		$CueStickModelTransparent.visible = true
	else:
		$CueStickModel.visible = true
		$CueStickModelTransparent.visible = false
