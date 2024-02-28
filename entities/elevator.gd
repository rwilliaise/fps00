extends StaticBody3D
class_name Elevator

@onready var player_spawn = $PlayerSpawn

var target = null
var closing = false
var opened = false

func _ready():
	Network.current_elevator = self

func _teleport():
	if target:
		Network.from_elevator = true
		Network.load_section(target)

func _start_teleport(body):
	if closing: return
	if target and body == Hud.current_player:
		closing = true
		$AnimationPlayer.play("close")
		$close.play()
		$Teleport.start()

func open_doors():
	if not opened:
		$AnimationPlayer.play("open")
		opened = true

func open(new_target):
	open_doors()
	$ding.play()
	target = new_target

