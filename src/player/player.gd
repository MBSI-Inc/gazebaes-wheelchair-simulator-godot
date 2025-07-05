extends CharacterBody3D
class_name Player

@export var use_keyboard: bool = false
@export var turn_rate: float = 25.0
@export var connections_handler: Node # TODO
@export var target_speed: float = 10.0
@export var stop_when_turning: bool = false

var current_speed: float = 0.0
var is_moving: bool = false
var direction: float = 0.0
var obstacle_bump_count: int = 0
var spawn: Vector3

func _ready():
	spawn = global_position

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		set_direction(-turn_rate)
	elif Input.is_action_pressed("ui_left"):
		set_direction(turn_rate)
	else:
		set_direction(0)

	if not use_keyboard and connections_handler:
		is_moving = connections_handler.get_latest_movement()
		if is_moving:
			set_direction(connections_handler.get_latest_direction())
			set_target_speed(connections_handler.get_latest_target_speed())
			velocity = Vector3.FORWARD * current_speed
	else:
		velocity = Vector3.FORWARD * current_speed

	rotate_y(deg_to_rad(direction * delta))

	if Input.is_key_pressed(KEY_SPACE):
		is_moving = not is_moving
		current_speed = target_speed if is_moving else 0.0

	if Input.is_key_pressed(KEY_R):
		global_position = spawn
		rotation_degrees.y = 90.0

	if Input.is_key_pressed(KEY_M):
		connections_handler.is_moving = not connections_handler.is_moving

	move_and_slide()
	

func set_direction(new_dir: float) -> void:
	direction = new_dir
	current_speed = target_speed
	if stop_when_turning and new_dir != 0.0:
		current_speed = 0.0

func set_target_speed(_target_speed: float) -> void:
	target_speed = _target_speed

func _on_body_entered(body: Node) -> void:
	if body.get_collision_layer_value(6):
		obstacle_bump_count += 1
