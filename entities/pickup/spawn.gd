extends Node3D

func _setup(out):
	get_tree().current_scene.add_child(out)
	out.global_position = global_position
	out.global_rotation.y = randf() * PI * 2

func _ready():
	var id = Network.pop_spawn()
	if id and Network.pickups.has(id):
		var obj: PackedScene = Network.pickups[id]
		var out: Pickup = obj.instantiate()
		_setup.call_deferred(out)
	
