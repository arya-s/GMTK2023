extends CharacterBody3D

const pixelToMeters = 12.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var AIR_MULTIPLIER: float = 0.65
@export var GRAVITY: int = -900 / pixelToMeters
@export var HALF_GRAVITY_THRESHOLD: int = 120 / pixelToMeters
@export var RUN_ACCELERATION = 1000 / pixelToMeters
@export var RUN_FRICTION = 400 / pixelToMeters
@export var RUN_MAX_SPEED = 90 / pixelToMeters
@export var DUCK_FRICTION = 500 / pixelToMeters
@export var JUMP_FORCE = 105 / pixelToMeters
@export var JUMP_HORIZONTAL_BOOST = 40 / pixelToMeters
@export var WALL_JUMP_HORIZONTAL_BOOST = RUN_MAX_SPEED + JUMP_HORIZONTAL_BOOST
@export var WALL_SLIDE_START_MAX = 20
@export var WALL_CHECK_DISTANCE = 3
@export var FALL_MAX_SPEED = 160 / pixelToMeters
@export var FALL_MAX_ACCELERATION = 300 / pixelToMeters
@export var AUTO_JUMP_TIMER = 0.1
@export var UPWARD_CORNER_CORRECTION = 4
@export var CEILING_VARIABLE_JUMP = 0.05
@export var FAST_FALL_MAX_SPEED = 240 / pixelToMeters
@export var FAST_FALL_MAX_ACCELERATION = 300 / pixelToMeters

var max_fall = FALL_MAX_SPEED
var variable_jump_speed = 0
var mouse_sensitivity = 0.05
var min_look_angle = deg_to_rad(-20.0)
var max_look_angle = deg_to_rad(20.0)

@onready var model = $Visuals
@onready var spring_arm = $CameraMount/SpringArm
@onready var variable_jump_timer = $VariableJumpTimer
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var coyote_jump_timer = $CoyoteJumpTimer
@onready var camera_mount = $CameraMount


	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		# player model should not rotate with mouse
		model.rotate_y(deg_to_rad(event.relative.x * mouse_sensitivity))
		
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, min_look_angle, max_look_angle)
		

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
#	var input_vector := Vector3.ZERO
#	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
#	input_vector.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
#	input_vector = input_vector.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	handle_joystick_look(delta)
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		model.look_at(position + direction)
	
	# apply horizontal force
	var run_multiplier = 1.0 if is_on_floor() else AIR_MULTIPLIER
	if abs(velocity.x) > RUN_MAX_SPEED and sign(velocity.x) == direction.x:
		velocity.x = move_toward(velocity.x, direction.x * RUN_MAX_SPEED, RUN_FRICTION * run_multiplier * delta)
	else:
		velocity.x = move_toward(velocity.x, direction.x * RUN_MAX_SPEED, RUN_ACCELERATION * run_multiplier * delta)
		
	if abs(velocity.z) > RUN_MAX_SPEED and sign(velocity.z) == direction.z:
		velocity.z = move_toward(velocity.z, direction.z * RUN_MAX_SPEED, RUN_FRICTION * run_multiplier * delta)
	else:
		velocity.z = move_toward(velocity.z, direction.z * RUN_MAX_SPEED, RUN_ACCELERATION * run_multiplier * delta)
	
	# apply vertical force
	var fm = FALL_MAX_SPEED
	max_fall = move_toward(max_fall, fm, FAST_FALL_MAX_ACCELERATION * delta)
	
	if not is_on_floor():
		var fall_multiplier = 0.5 if abs(velocity.y) < HALF_GRAVITY_THRESHOLD and Input.is_action_pressed("jump") else 1.0
		velocity.y = move_toward(velocity.y, max_fall, GRAVITY * fall_multiplier * delta)
		
	if variable_jump_timer.time_left > 0:
		if Input.is_action_pressed("jump"):
			velocity.y = min(velocity.y, variable_jump_speed)
		else:
			variable_jump_timer.stop()
			
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_jump_timer.time_left > 0:
			jump(direction)
		else:
			jump_buffer_timer.start()

	move_and_slide()

func handle_joystick_look(delta):
	var input_dir = Input.get_vector("ui_look_left", "ui_look_right", "ui_look_up", "ui_look_down")
	
	if input_dir:
		rotate_y(deg_to_rad(-input_dir.x * 4))
		model.rotate_y(deg_to_rad(input_dir.x * 4))
		
		camera_mount.rotate_x(deg_to_rad(-input_dir.y * 4))
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, min_look_angle, max_look_angle)
		
func jump(input_vector: Vector3):
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	velocity.y = JUMP_FORCE
	variable_jump_speed = velocity.y
