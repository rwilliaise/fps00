extends ColorRect

func _timeout():
	$TextureRect.visible = true
	$AudioStreamPlayer.play()


func _main_timeout():
	Music.restart_random()
	Network.load_section("main")
