# Copyright (c) 2022 Mohammad Rezai.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# https://github.com/elvisish/GodotStairs

extends CharacterBody3D
class_name Player

const SPEED_DEFAULT := 5.0
const SPEED_CROUCH := 3.0
const SPEED_AIR := 1.0
const FRICTION := 5
const MAX_ACCELERATION := 7 * SPEED_DEFAULT
const JUMP_IMPULSE := sqrt(2 * GRAVITY)
const GRAVITY := 19.6
const STOP_SPEED := 2

const WALL_MARGIN := 0.001
const STEP_HEIGHT_DEFAULT := Vector3(0, 0.6, 0)
const STEP_MAX_SLOPE_DEGREE := 0.0
const STEP_CHECK_COUNT := 2
const STAIRS_FEEL_COEFFICIENT := 2
const FOOTSTEP_TIMER := 35

var walk_speed: float = SPEED_DEFAULT
var next_footstep := FOOTSTEP_TIMER

var was_on_floor = true
var mouse_sense: float = 0.1
var snap: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO

@onready var body = $Body
@onready var head = $Body/Head
@onready var camera = $Body/Head/Camera
@onready var head_position: Vector3 = head.position
@onready var body_euler_y = body.global_transform.basis.get_euler().y

var head_offset: Vector3 = Vector3.ZERO
var is_step: bool = false
var step_check_height: Vector3 = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
var camera_target_position : Vector3 = Vector3()
var camera_coefficient: float = 1.0
var time_in_air: float = 0.0

var held_item: Pickup = null
var crouching = false

func drop_item():
	held_item._drop()
	var pos = held_item.global_position
	$Body/Head/Camera/Hand.remove_child(held_item)
	get_tree().current_scene.add_child(held_item)
	held_item.global_position = pos
	held_item = null
	Network.player.holding = null 
	Save.save()

func pick_up(item):
	if held_item:
		drop_item()
	held_item = item
	held_item._pickup()
	held_item.get_parent().remove_child(held_item)
	$Body/Head/Camera/Hand.add_child(held_item)
	held_item.position = Vector3.ZERO
	held_item.rotation = Vector3.ZERO
	if "id" in held_item:
		Network.player.holding = held_item.id
		Save.save()

func _unhide():
	global_position = Network.current_elevator.player_spawn.global_position
	body.global_rotation.y = Network.current_elevator.player_spawn.global_rotation.y
	Network.current_elevator.open_doors()
	$AnimationPlayer.play("reveal")

func _ready():
	if Network.from_elevator:
		$Hide.visible = true
		_unhide.call_deferred()

	var id = Network.player.holding
	if id and Network.pickups.has(id):
		var obj: PackedScene = Network.pickups[id]
		var out: Pickup = obj.instantiate()
		var pick = func():
			get_tree().current_scene.add_child(out)
			pick_up(out)
		pick.call_deferred()

	Hud.current_camera = camera
	Hud.current_player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	camera_target_position = camera.global_transform.origin
	camera.set_as_top_level(true)

func _exit_tree():
	if held_item and "id" in held_item:
		Network.player.holding = held_item.id

func _process(delta: float) -> void:
	# Find the current interpolated transform of the target
	var head_transform: Transform3D = head.get_global_transform()

	# Provide some delayed smoothed lerping towards the target position 
	camera_target_position = lerp(camera_target_position, head_transform.origin, delta * walk_speed * STAIRS_FEEL_COEFFICIENT * camera_coefficient)
	camera.position.x = camera_target_position.x

	if is_on_floor():
		time_in_air = 0.0
		camera_coefficient = 1.0
		camera.position.y = camera_target_position.y
	else:
		time_in_air += delta
		if time_in_air > 1.0:
			camera_coefficient += delta
			camera_coefficient = clamp(camera_coefficient, 2.0, 4.0)
		else: 
			camera_coefficient = 2.0
			
		camera.position.y = camera_target_position.y

	if held_item and held_item.has_method("_use") and Cursor.is_action_just_pressed("use"):
		held_item._use()
	if held_item and Cursor.is_action_just_pressed("drop"):
		drop_item()

	if not crouching and Cursor.is_action_just_pressed("crouch"):
		$AnimationPlayer.play("crouch")
		walk_speed = SPEED_CROUCH
		crouching = true
	if crouching and not Input.is_action_pressed("crouch") and not $Body/Head/RayCast3D.is_colliding():
		$AnimationPlayer.play("uncrouch")
		walk_speed = SPEED_DEFAULT
		crouching = false

	camera.position.z = camera_target_position.z
	camera.rotation.x = head.rotation.x
	camera.rotation.y = body.rotation.y + body_euler_y

func _input(event):
	# get mouse input for camera rotation
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		body.rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func params(transform3d, motion):
	var out := PhysicsTestMotionParameters3D.new()
	out.from = transform3d
	out.motion = motion
	out.recovery_as_collision = true
	return out 

func accelerate(max_velocity, max_acceleration, delta):
	var current_speed = velocity.dot(direction)
	var add_speed = clamp(max_velocity - current_speed, 0, max_acceleration * delta)
	return velocity + add_speed * direction

func accelerate_ground(delta):
	var speed = velocity.length()

	if speed != 0:
		var control = max(STOP_SPEED, speed)
		var drop = control * FRICTION * delta
		velocity *= max(speed - drop, 0) / speed
	return accelerate(walk_speed, MAX_ACCELERATION, delta)

func accelerate_air(delta):
	return accelerate(SPEED_AIR, MAX_ACCELERATION * 100, delta)

func _physics_process(delta):
	is_step = false
	
	# get keyboard input
	direction = Vector3.ZERO
	var h_rot: float = body.global_transform.basis.get_euler().y
	var f_input: float = Cursor.get_action_strength("move_backward") - Cursor.get_action_strength("move_forward")
	var h_input: float = Cursor.get_action_strength("strafe_right") - Cursor.get_action_strength("strafe_left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()

	# make it move
	if is_on_floor():
		if Cursor.is_action_just_pressed("move_jump"):
			snap = Vector3.ZERO
			velocity.y = JUMP_IMPULSE
			velocity = accelerate_air(delta)
		else:
			snap = -get_floor_normal()
			velocity = accelerate_ground(delta)
		if not was_on_floor:
			$Footstep.play()
			next_footstep = FOOTSTEP_TIMER
		else:
			next_footstep -= velocity.length_squared() * delta
			if next_footstep <= 0:
				$Footstep.play()
				next_footstep = FOOTSTEP_TIMER
		was_on_floor = true		
	else:
		next_footstep = FOOTSTEP_TIMER
		velocity.y -= GRAVITY * delta
		velocity = accelerate_air(delta)
		snap = Vector3.DOWN
		was_on_floor = false
	
	if is_on_floor():
		for i in range(STEP_CHECK_COUNT):
			var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
			
			var step_height: Vector3 = STEP_HEIGHT_DEFAULT - i * step_check_height
			var transform3d: Transform3D = global_transform
			var motion: Vector3 = step_height
			
			var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
			
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y < 0:
				continue
				
			if not is_player_collided:
				transform3d.origin += step_height
				motion = velocity * delta
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
							head_offset = -test_motion_result.get_remainder()
							is_step = true
							global_transform.origin += -test_motion_result.get_remainder()
							break
				else:
					var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)

					transform3d.origin += test_motion_result.get_collision_normal(0) * WALL_MARGIN
					motion = (velocity * delta).slide(wall_collision_normal)
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								global_transform.origin += -test_motion_result.get_remainder()
								break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * WALL_MARGIN
				motion = step_height
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += step_height
					motion = (velocity * delta).slide(wall_collision_normal)
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								global_transform.origin += -test_motion_result.get_remainder()
								break

	var is_falling: bool = false
	
	if not is_step and is_on_floor():
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var step_height: Vector3 = STEP_HEIGHT_DEFAULT
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = velocity * delta
		var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
		
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
			if is_player_collided:
				if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
					head_offset = test_motion_result.get_travel()
					is_step = true
					global_transform.origin += test_motion_result.get_travel()
			else:
				is_falling = true
		else:
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y == 0:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * WALL_MARGIN
				motion = (velocity * delta).slide(wall_collision_normal)
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
							head_offset = test_motion_result.get_travel()
							is_step = true
							global_transform.origin += test_motion_result.get_travel()
					else:
						is_falling = true
		
	if not is_step:
		head_offset = head_offset.lerp(Vector3.ZERO, delta * walk_speed * STAIRS_FEEL_COEFFICIENT)
		
	if is_falling:
		snap = Vector3.ZERO
		
	move_and_slide()

	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse((col.get_position() - global_position).normalized() * col.get_depth() * 50)
