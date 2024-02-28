extends Node

@export var logic_table := {}

const INPUT_PREFIX = "__INPUT__"
const OUTPUT_PREFIX = "__OUTPUT__"

func _ready():
	Save.contribute_dictionary("logic_table", logic_table)

func safe_call(target, calling_method, perpetrator):
	var methods = target.get_method_list()
	var method
	for target_method in methods:
		if target_method.name == calling_method:
			method = target_method
			break
	if not method: return
	if method.args.size() > 0:
		target[calling_method].call_deferred(perpetrator)
	else:
		target[calling_method].call_deferred()

func set_state(target : Node, value, perpetrator : Node = null):
	if perpetrator == target: return
	if value and target.has_method("_enable"):
		safe_call(target, "_enable", perpetrator)
	if not value and target.has_method("_disable"):
		safe_call(target, "_disable", perpetrator)
	if target.has_method("_state_changed"):
		target._state_changed.call_deferred(value, perpetrator)
		
func broadcast_state(perpetrator : Node, value, kill = true):
	if "target" in perpetrator:
		for target in get_targets(perpetrator.target):
			set_state(target, value, perpetrator)
	if kill and "killtarget" in perpetrator:
		for target in get_targets(perpetrator.killtarget):
			set_state(target, value, perpetrator)

func offer_input(object : Node):
	if "targetname" in object and not object.targetname.is_empty():
		object.add_to_group(INPUT_PREFIX + object.targetname)
		if object.has_method("_ready_logic") and not object.has_meta("logic_ready"):
			object._ready_logic.call_deferred()
			object.set_meta("logic_ready", true)

func offer_output(object : Node):
	if "target" in object and not object.target.is_empty():
		object.add_to_group(OUTPUT_PREFIX + object.target)
		if object.has_method("_ready_logic") and not object.has_meta("logic_ready"):
			object._ready_logic.call_deferred()
			object.set_meta("logic_ready", true)
	if "killtarget" in object and not object.killtarget.is_empty():
		object.add_to_group(OUTPUT_PREFIX + object.killtarget)
		if object.has_method("_ready_logic") and not object.has_meta("logic_ready"):
			object._ready_logic.call_deferred()
			object.set_meta("logic_ready", true)


func get_targets(targetname):
	return get_tree().get_nodes_in_group(INPUT_PREFIX + targetname)

func get_outputs(targetname):
	return get_tree().get_nodes_in_group(OUTPUT_PREFIX + targetname)
