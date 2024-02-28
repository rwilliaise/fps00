extends TextureRect


var open = false

func get_action_strength(action: StringName):
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE: return 0
	return Input.get_action_strength(action)

func is_action_just_pressed(action: StringName):
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE: return false
	return Input.is_action_just_pressed(action)

func is_action_just_released(action: StringName):
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE: return false
	return Input.is_action_just_released(action)

func _ready():
	Hud.set_default(self)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if not open:
			Hud.open_default()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if open:
		var target
		var cam = Hud.current_camera
		if not cam:
			return
		for node in get_tree().get_nodes_in_group("selectable"):
			if node.has_method("_is_held") and node._is_held():
				continue

			var visual_target = node.visual_cursor_target if "visual_cursor_target" in node else node

			if visual_target == null: continue
			if node.has_method("_test_crosshair"):
				if node._test_crosshair():
					target = node
					break
				else:
					continue

			var difference = visual_target.global_position - cam.global_position
			var length = difference.length()

			if length > 3:
				continue

			var direction = difference / length
			var similarity = direction.dot(-cam.global_transform.basis.z)
			if similarity < 0.95:
				continue
			
			var query = PhysicsRayQueryParameters3D.create(cam.global_position, visual_target.global_position)
			query.collide_with_areas = false
			query.exclude = [Hud.current_player, node.visual_cursor_exclude if "visual_cursor_exclude" in node else node]

			var space_state = visual_target.get_world_3d().direct_space_state
			var result = space_state.intersect_ray(query)

			if result.size() > 0:
				continue

			target = node
			break
		
		var target_position = get_viewport_rect().size / 2 - size / 2
		$Label.visible = false
		if is_instance_valid(target):
			var visual_target = target.visual_cursor_target if "visual_cursor_target" in target else target
			target_position = target_position.lerp(
				cam.unproject_position(visual_target.global_position),
				0.2
			)

			if target.has_method("_interact"):
				$Label.visible = true
				if is_action_just_pressed("interact"):
					target._interact()


		position = position.lerp(target_position, delta * 8)


func _input(event):
	if open and event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ui_open():
	position = get_viewport_rect().size / 2 - size / 2
	open = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ui_close():
	open = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

