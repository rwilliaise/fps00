extends Node

var current_elevator: Elevator = null
var current_sector = "main"
var current_sector_data = null

var from_elevator = false

var section_datas = {}
var sections = {
	main = {
		scene = "res://scenes/main.tscn",
		help = "Reclaimed sector. Connection to radar system fully severed. Biosphere exterminated.",
		spawns = []
	},
	c04 = {
		scene = "res://scenes/c04.tscn",
		help = "Houses small radar system. Biosphere of unknown size.",
		spawns = ["flashlight"]
	},
}

var pickups = {
	flashlight = preload("res://entities/pickup/flashlight.tscn")
}
var player = {
	holding = null
}

func route(new_target):
	if is_instance_valid(current_elevator):
		current_elevator.open(new_target)

func pop_spawn():
	if current_sector_data and current_sector_data.has("spawns") and not current_sector_data.spawns.is_empty():
		return current_sector_data.spawns.pop_at(randi() % current_sector_data.spawns.size())
	return null

func _setup_pickup(out):
	get_tree().current_scene.add_child(out)
	out.global_position = out.data.position
	out.global_rotation = out.data.rotation

func _load_pickups():
	for object in current_sector_data.objects:
		if "id" in object and pickups.has(object.id):
			var obj: PackedScene = pickups[object.id]
			var out: Pickup = obj.instantiate()
			out.data = object
			_setup_pickup.call_deferred(out)
	current_sector_data.objects.clear()

func load_section(section):
	get_tree().change_scene_to_file(sections[section].scene)
	var section_data
	if not section_datas.has(section):
		section_datas[section] = {
			objects = []
		}
		section_datas[section].spawns = sections[section].spawns.duplicate()
	section_data = section_datas[section]
	current_sector = section
	current_sector_data = section_data
	_load_pickups.call_deferred()

func _ready():
	Save.contribute_dictionary("sector_data", section_datas)
	Save.contribute_dictionary("player_data", player)

