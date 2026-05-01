extends CharacterBody3D

@export_category("Mouse Settings")
@export_range(0.001, 0.01, 0.001) var mouse_sensitivity: float = 0.001
@export_range(0.1, 1.0, 0.1) var mouse_friction: float = 0.4

@export_category("Gamepad Settings")
@export_range(0.001, 0.1, 0.01) var controller_look_sensitivity: float = 0.09
var current_target_look: Vector2

@export_category("Player Settings")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 7.0
@export var ground_accel: float = 15.0
@export var ground_decel: float = 10.0
@export var ground_friction: float = 5.0
@export var jump_velocity: float = 5.0

@export var auto_bhop: bool = false

@export var air_cap: float = 0.85
@export var air_accel: float = 800.0
@export var air_move_speed: float = 500.0



const HEADBOB_AMOUNT: float = 0.03
const HEADBOB_FREQUENCY: float = 2.5
var headbob_time: float = 0.0

var direction: Vector3 = Vector3.ZERO
var gravity = 12

@onready var player_pov: Node3D = $PlayerPOV
@onready var camera_3d: Camera3D = $PlayerPOV/Camera3D
@onready var world_model: Node3D = $WorldModel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	for child in world_model.get_children():
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_handle_controller_look_input(delta)
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			player_pov.rotate_x(-event.relative.y * mouse_sensitivity)
			player_pov.rotation.x = clamp(player_pov.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _handle_controller_look_input(delta: float) -> void:
	var target_look = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	
	if target_look.length() < current_target_look.length():
		current_target_look = target_look
	else:
		current_target_look = current_target_look.lerp(target_look, 5.0 * delta)
	
	rotate_y(-current_target_look.x * controller_look_sensitivity)
	player_pov.rotate_x(current_target_look.y * controller_look_sensitivity)
	player_pov.rotation.x = clamp(player_pov.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func headbob_effect(delta):
	if direction:
		headbob_time += delta * self.velocity.length()
		camera_3d.transform.origin = Vector3(
			0,
			sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_AMOUNT,
			0
		)
	else:
		camera_3d.transform.origin = lerp(camera_3d.transform.origin, Vector3.ZERO, 0.1)
		headbob_time = 0.0


var audio_played = false
func handle_footstep_sounds(audio: AudioStreamPlayer3D):
	if camera_3d.transform.origin.y < 0 and audio_played == false:
		audio.play()
		audio_played = true
	
	if camera_3d.transform.origin.y > 0:
		audio_played = false


func clip_velocity(normal: Vector3, overbounce: float) -> void:
	var backoff := self.velocity.dot(normal) * overbounce
	if backoff >= 0: return
	
	var change := normal * backoff
	self.velocity -= change
	
	var adjust := self.velocity.dot(normal)
	if adjust < 0.0:
		self.velocity -= normal * adjust


func check_surface_angle(normal: Vector3) -> bool:
	var max_slope_ang_dot = Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), self.floor_max_angle).dot(Vector3(0, 1, 0))
	if normal.dot(Vector3(0, 1, 0)) < max_slope_ang_dot:
		return true
	else:
		return false


func handle_air_physics(delta) -> void:
	self.velocity.y -= gravity * delta
	
	var current_speed_in_direction = self.velocity.dot(direction)
	var capped_speed = min((air_move_speed * direction).length(), air_cap)
	var added_speed = capped_speed - current_speed_in_direction
	if added_speed > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, added_speed)
		self.velocity += accel_speed * direction
	
	if is_on_wall():
		#if check_surface_angle(get_floor_normal()):
			#self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		#else:
			#self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1)


func handle_ground_physics(delta) -> void:
	var current_speed_in_direction = self.velocity.dot(direction)
	var added_speed = get_move_speed() - current_speed_in_direction
	if added_speed > 0:
		var accel_speed = ground_accel * delta * get_move_speed()
		accel_speed = min(accel_speed, added_speed)
		self.velocity += accel_speed * direction
		
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	headbob_effect(delta)


func get_move_speed() -> float:
	return sprint_speed if Input.is_action_pressed("sprint") else walk_speed


func _physics_process(delta: float) -> void:
	if is_on_floor():
		handle_ground_physics(delta)
		handle_footstep_sounds(audio_stream_player_3d)
	else:
		handle_air_physics(delta)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	transform = transform.orthonormalized()
	
	move_and_slide()
