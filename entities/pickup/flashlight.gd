extends Pickup

var id = "flashlight"

func _use():
	$SpotLight3D.visible = not $SpotLight3D.visible
