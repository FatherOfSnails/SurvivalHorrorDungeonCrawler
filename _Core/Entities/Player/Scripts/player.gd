extends CharacterBody3D


@export_range(0.001, 0.01, 0.001) var mouse_sensitivity: float = 0.001

@export var move_speed: float = 5.0


@onready var player_camera: Camera3D = $Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
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
	
	
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_object_local(Vector3.UP, -event.relative.x * mouse_sensitivity)
		player_camera.rotate_object_local(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)
		#I HATE LEONHARD EULER
	
