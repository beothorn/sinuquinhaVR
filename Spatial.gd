extends Spatial


var perform_runtime_config = false


onready var ovr_init_config_pre = preload("res://addons/godot_ovrmobile/OvrInitConfig.gdns")
onready var ovr_performance_pre = preload("res://addons/godot_ovrmobile/OvrPerformance.gdns")
onready var playerCam = $ARVROrigin/ARVRCamera

export(bool) var debug = true

func _ready():
	if not debug:
		var ovr_init_config = ovr_init_config_pre.new()
		var ovr_performance = ovr_performance_pre.new()
		var interface = ARVRServer.find_interface("OVRMobile")
		if interface:
			ovr_init_config.set_render_target_size_multiplier(1)

			if interface.initialize():
				get_viewport().arvr = true

	
