extends CharacterBody3D

@export var speed = 5.0
@export var acceleration = 15.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Matches your screenshot names exactly
@onready var cam_pivot = $Node3D 
@onready var spring_arm = $Node3D/SpringArm3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Prevents the camera from jittering when hitting the knight
	spring_arm.add_excluded_object(get_rid())

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Horizontal rotation (Body)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical rotation (Pivot)
		cam_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-70), deg_to_rad(70))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get movement using the actions we just created
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
