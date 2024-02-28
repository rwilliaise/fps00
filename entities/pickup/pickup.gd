extends RigidBody3D 
class_name Pickup

var data = null

func _ready():
	add_to_group("selectable")
	if not "id" in self: return

func _exit_tree():
	if freeze:
		return
	data = {
		id = self.id,
		position = global_position,
		rotation = global_rotation,
	}
	Network.current_sector_data.objects.push_back(data)
	Save.save()

func _is_held():
	return freeze

func _pickup():
	freeze = true

func _drop():
	freeze = false
	set_sleeping.call_deferred(false)

func _interact():
	Hud.current_player.pick_up(self)
