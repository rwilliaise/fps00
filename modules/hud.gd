extends Node

var default: Control = null
var open: Control = null

var current_camera: Camera3D = null
var current_player: Player = null

func set_default(ui: Control):
	default = ui
	open_ui(default)

func open_ui(ui: Control):
	if open:
		open.visible = false
		if open.has_method("_ui_close"):
			open._ui_close()

	open = ui
	open.visible = true
	if open.has_method("_ui_open"):
		open._ui_open()

func open_default():
	open_ui(default)

