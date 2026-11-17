extends CharacterBody2D

@export var attack_scene: PackedScene = preload("res://scenes/EnemyAttack.tscn")
@export var attack_cooldown := 2.0
@export var speed := 20
@export var attack_range := 40.0
@export var hit_frame := 2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_sprite: AnimatedSprite2D = $Attacksprite
@onready var health: Health = $Health

const CARDINAL_DIRECTIONS = [
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(0, 1),
	Vector2(0, -1),
]

var player: Node2D = null
var can_attack := true
var hit_this_swing := false


func _ready():
	add_to_group("enemy")
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_sprite.visible = false
	attack_sprite.animation_finished.connect(_on_attack_sprite_animation_finished)
	attack_sprite.frame_changed.connect(_on_attack_sprite_frame_changed)
	health.died.connect(_on_died)


func _physics_process(_delta):
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player = player.global_position - global_position

	if to_player.length() > 30:
		velocity = to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	play_walk_anim(to_player)

	if can_attack and to_player.length() < attack_range:
		attack_toward_player(to_player.normalized())


func play_walk_anim(direction: Vector2):
	if abs(direction.x) > abs(direction.y):
		sprite.play("WALK_RIGHT" if direction.x > 0 else "WALK_LEFT")
	else:
		sprite.play("WALK_DOWN" if direction.y > 0 else "WALK_UP")


func attack_toward_player(direction: Vector2):
	if player == null:
		return

	can_attack = false
	hit_this_swing = false
	play_attack_anim(get_closest_direction(direction, CARDINAL_DIRECTIONS))

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func play_attack_anim(dir: Vector2):
	attack_sprite.visible = true
	attack_sprite.position = dir * 24
	attack_sprite.flip_h = false
	attack_sprite.flip_v = false

	if dir == Vector2(1, 0):
		attack_sprite.rotation_degrees = 180
		attack_sprite.play("Attack_Right")
	elif dir == Vector2(-1, 0):
		attack_sprite.rotation_degrees = 0
		attack_sprite.play("Attack_Left")
	elif dir == Vector2(0, 1):
		attack_sprite.rotation_degrees = -90
		attack_sprite.play("Attack_Down")
	else:
		attack_sprite.rotation_degrees = 90
		attack_sprite.play("Attack_Up")


func _on_attack_sprite_frame_changed():
	if attack_sprite.frame != hit_frame or hit_this_swing:
		return
	if player == null or global_position.distance_to(player.global_position) >= attack_range:
		return

	hit_this_swing = true
	var dir = get_closest_direction(
		(player.global_position - global_position).normalized(),
		CARDINAL_DIRECTIONS
	)
	play_attack_anim(dir)
	spawn_hitbox(dir)


func spawn_hitbox(dir: Vector2):
	var attack = attack_scene.instantiate()
	attack.source = self
	get_parent().add_child(attack)
	attack.global_position = global_position + dir * 16
	attack.rotation = dir.angle()


func get_closest_direction(target_dir: Vector2, directions: Array) -> Vector2:
	var best_dir = directions[0]
	var best_dot = -INF
	for dir in directions:
		var dot = target_dir.dot(dir)
		if dot > best_dot:
			best_dot = dot
			best_dir = dir
	return best_dir


func take_damage(amount):
	health.take_damage(amount)


func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body


func _on_detection_area_body_exited(body):
	if body == player:
		player = null


func _on_attack_sprite_animation_finished():
	attack_sprite.visible = false


func _on_died():
	queue_free()
