extends CharacterBody2D

# Top-down 8-direction player. The walk is procedural (bob + wiggle + flip) since
# the character tile is a single frame — swap _update_procedural_animation's body
# for a real sprite-sheet AnimationPlayer later without touching movement or the
# set_animation_intent / face_toward seam other code calls into.

const MOVE_SPEED := 70.0
const BOB_HEIGHT := 2.0
const BOB_CYCLES_PER_SECOND := 4.0
const WALK_WIGGLE_DEGREES := 3.0
const IDLE_BREATHE_HEIGHT := 0.6
const IDLE_BREATHE_CYCLES_PER_SECOND := 1.0

@onready var sprite: Sprite2D = $Sprite2D

var _animation_intent := "idle"
var _animation_time := 0.0
var _base_sprite_position: Vector2


func _ready() -> void:
	_base_sprite_position = sprite.position


func _physics_process(delta: float) -> void:
	var input_direction := _read_input_direction()
	if input_direction != Vector2.ZERO:
		velocity = input_direction * MOVE_SPEED
		face_toward(input_direction)
		set_animation_intent("walk")
	else:
		velocity = Vector2.ZERO
		set_animation_intent("idle")
	move_and_slide()
	_update_procedural_animation(delta)


func _read_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return direction.normalized() if direction != Vector2.ZERO else direction


# Public seam: point the visual at a direction. Horizontal-only flip today;
# a 4-direction sheet would swap frames here instead.
func face_toward(direction: Vector2) -> void:
	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0


# Public seam: name the current animation intent. Today this just drives the
# procedural bob below; a real sprite sheet would play a matching clip instead.
func set_animation_intent(intent_name: String) -> void:
	if _animation_intent == intent_name:
		return
	_animation_intent = intent_name
	_animation_time = 0.0


func _update_procedural_animation(delta: float) -> void:
	_animation_time += delta
	if _animation_intent == "walk":
		var cycle := sin(_animation_time * BOB_CYCLES_PER_SECOND * TAU)
		sprite.position = _base_sprite_position + Vector2(0.0, -absf(cycle) * BOB_HEIGHT)
		sprite.rotation_degrees = cycle * WALK_WIGGLE_DEGREES
	else:
		var breathe := sin(_animation_time * IDLE_BREATHE_CYCLES_PER_SECOND * TAU)
		sprite.position = _base_sprite_position + Vector2(0.0, -absf(breathe) * IDLE_BREATHE_HEIGHT)
		sprite.rotation_degrees = 0.0
