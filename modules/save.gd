extends Node

const SAVE_LOCATION = "user://save.hh"
const SAVE_PASSWORD = "hh_fps00"

@onready var save_file = ConfigFile.new()
var operators: Dictionary = {}

signal file_loaded()

func contribute_dictionary(key, dict: Dictionary):
	operators[key] = dict

func save():
	for key in operators.keys():
		var value = operators[key]
		if save_file.has_section(key):
			save_file.erase_section(key)
		for val_key in value.keys():
			save_file.set_value(key, val_key, value[val_key])
	save_file.save(SAVE_LOCATION)
	# save_file.save_encrypted_pass(SAVE_LOCATION, SAVE_PASSWORD)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()

func _load():
	save_file.load(SAVE_LOCATION)
	# save_file.load_encrypted_pass(SAVE_LOCATION, SAVE_PASSWORD)
	for key in operators.keys():
		var value = operators[key]
		if save_file.has_section(key):
			for val_key in save_file.get_section_keys(key):
				value[val_key] = save_file.get_value(key, val_key)
	file_loaded.emit()

func _ready():
	_load.call_deferred()

