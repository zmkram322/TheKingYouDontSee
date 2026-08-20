extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 7

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	# PitchPivot's rest pose now carries the 20 deg downward tilt that used
	# to be baked into TwistPivot's basis (see tutorial_player.tscn), so
	# the old +/-30 deg clamp (measured from a 0 rest) is shifted by that
	# same 20 deg to preserve the original look range: -10 deg .. 50 deg.
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		deg_to_rad(-10),
		deg_to_rad(50)
	)

	# Consume this frame's mouse-look delta and zero it. _unhandled_input
	# only fires while the mouse is actually moving, so without this reset
	# the pivots keep rotating every frame at the last delta forever — this
	# was the runaway-rotation bug.
	twist_input = 0.0
	pitch_input = 0.0


func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_jump") and is_on_floor():
		print('action just pressed: ui_jump')
		velocity.y = JUMP_VELOCITY
			#velocity.y = velocity.y * JUMP_VELOCITY
	if Input.is_action_pressed('ui_jump'):
		print('is_action_pressed: ui_jump')
		velocity.y += JUMP_VELOCITY * delta
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	velocity = twist_pivot.basis * velocity
	print("velocity.y=",velocity.y)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		# Mouse capture was only ever released (ui_cancel), never
		# recaptured — clicking back into the view now recaptures it.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
