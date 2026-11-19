extends CharacterBody2D

@export var attack_scene: PackedScene = preload("res://scenes/EnemyAttack.tscn")
@export var attack_cooldown := 2.0
@export var speed := 20
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_sprite: AnimatedSprite2D = $Attacksprite
@onready var health: Health = $Health

var DIAGONAL_DIRECTIONS = [
	Vector2(1, 1).normalized(),
	Vector2(-1, 1).normalized(),
	Vector2(1, -1).normalized(),
	Vector2(-1, -1).normalized(),
]

var player: Node2D = null
var can_attack := true
var pending_dir := Vector2.ZERO


func _ready():
	add_to_group("enemy")
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_sprite.visible = false
	attack_sprite.animation_finished.connect(_on_attack_sprite_animation_finished)
	attack_sprite.frame_changed.connect(_on_attack_sprite_frame_changed)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	var p = get_tree().get_first_node_in_group("player")
	if p:
		add_collision_exception_with(p)
		p.add_collision_exception_with(self)


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

	if can_attack and to_player.length() < 40:
		attack_toward_player(to_player.normalized())
	if to_player.length() > 30:
		velocity = to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO

	velocity += get_soft_push()
	velocity = velocity.limit_length(speed * 1.5)
	move_and_slide()

func play_walk_anim(direction: Vector2):
	if direction.length() == 0:
		return
	if abs(direction.x) > abs(direction.y):
		sprite.play("WALK_RIGHT" if direction.x > 0 else "WALK_LEFT")
	else:
		sprite.play("WALK_DOWN" if direction.y > 0 else "WALK_UP")


func attack_toward_player(direction: Vector2):
	if player == null or global_position.distance_to(player.global_position) >= 40:
		return

	can_attack = false
	pending_dir = get_closest_direction(direction, DIAGONAL_DIRECTIONS)
	play_attack_anim(pending_dir)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func play_attack_anim(dir: Vector2):
	attack_sprite.visible = true
	attack_sprite.position = dir * 24

	if dir.x > 0 and dir.y > 0:
		attack_sprite.play("Attack_DownRight")
	elif dir.x < 0 and dir.y > 0:
		attack_sprite.play("Attack_DownLeft")
	elif dir.x > 0 and dir.y < 0:
		attack_sprite.play("Attack_UpRight")
	else:
		attack_sprite.play("Attack_UpLeft")


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


func _on_health_changed(current_health, max_health):
	print("ENEMY (", self.name, ") health: ", current_health, "/", max_health)


func _on_attack_sprite_frame_changed():
	if attack_sprite.frame == 2:
		if player != null and global_position.distance_to(player.global_position) < 40:
			var current_dir = get_closest_direction(
				(player.global_position - global_position).normalized(),
				DIAGONAL_DIRECTIONS
			)
			play_attack_anim(current_dir)
			spawn_hitbox(current_dir)


func spawn_hitbox(dir: Vector2):
	var attack = attack_scene.instantiate()
	attack.source = self
	get_parent().add_child(attack)
	attack.global_position = global_position + dir * 16
	attack.rotation = dir.angle()


@export var push_radius := 22.0     # how close before the pushing starts
@export var push_strength := 35.0   # how hard it pushes


func get_soft_push() -> Vector2:
	var push := Vector2.ZERO
	var others := get_tree().get_nodes_in_group("enemy")
	if player != null:
		others.append(player)

	for other in others:
		if other == self or not (other is Node2D):
			continue
		var offset : Vector2 = global_position - other.global_position
		var dist := offset.length()
		if dist >= push_radius:
			continue
		if dist < 0.01:
			offset = Vector2.from_angle(randf() * TAU)   # exactly on top: pick a random direction
			dist = 0.01
		push += offset.normalized() * (1.0 - dist / push_radius)

	return push * push_strength
