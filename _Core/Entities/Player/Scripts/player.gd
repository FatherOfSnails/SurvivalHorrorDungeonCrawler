extends CharacterBody3D


@export_range(0.1, 10.0, 0.1) var mouse_sensitivity: float = 1.0
var _mouse_motion: Vector2

@export var move_speed: float = 5.0
var gravity = 9.8


@onready var player_camera: Camera3D = $Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	_mouse_motion.y = clamp(_mouse_motion.y, -1560, 1560)
	transform.basis = Basis.from_euler(Vector3(0, _mouse_motion.x * -0.001, 0))
	player_camera.transform.basis = Basis.from_euler(Vector3(_mouse_motion.y * -0.001, 0, 0))
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = 4.5
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	transform = transform.orthonormalized()
	
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_mouse_motion += event.relative * mouse_sensitivity
	
