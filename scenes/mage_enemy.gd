extends CharacterBody2D

@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
@export var speed := 40
@export var preferred_range := 140.0    
@export var range_tolerance := 30.0     
@export var shoot_range := 220.0
@export var attack_cooldown := 2.0
@export var windup_time := 0.4
@export var push_radius := 22.0
@export var push_strength := 35.0
@export var probe_distance := 28.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var health: Health = $Health
func is_blocked(dir: Vector2) -> bool:
	return test_move(global_transform, dir * probe_distance)


func steer(desired: Vector2) -> Vector2:
	if desired == Vector2.ZERO:
		return Vector2.ZERO
	if not is_blocked(desired):
		return desired
	for angle in [30, 60, 90, 120]:
		var a := deg_to_rad(angle) * strafe_dir
		var alt = desired.rotated(a)
		if not is_blocked(alt):
			return alt
		alt = desired.rotated(-a)
		if not is_blocked(alt):
			return alt
	return Vector2.ZERO

var player: Node2D = null
var can_attack := true
var winding_up := false
var strafe_dir := 1.0
var strafe_timer := 0.0


func _ready():
	add_to_group("enemy")
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	health.died.connect(_on_died)
	strafe_dir = 1.0 if randf() < 0.5 else -1.0


func _physics_process(delta):
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var dir = to_player.normalized()

	var move := Vector2.ZERO
	if not winding_up:
		if dist > preferred_range + range_tolerance:
			move = dir                      
		elif dist < preferred_range - range_tolerance:
			move = -dir           
			if is_on_wall():    
				move = dir.orthogonal() * strafe_dir
		else:
			strafe_timer -= delta
			if strafe_timer <= 0.0:
				strafe_dir = -strafe_dir
				strafe_timer = randf_range(1.0, 2.5)
			move = dir.orthogonal() * strafe_dir * 0.6

	velocity = move * speed + get_soft_push()
	velocity = velocity.limit_length(speed * 1.5)
	move_and_slide()

	play_walk_anim(to_player)

	if can_attack and dist <= shoot_range:
		shoot()


func shoot():
	can_attack = false
	winding_up = true
	sprite.modulate = Color(1.6, 1.6, 2.0)
	await get_tree().create_timer(windup_time).timeout
	if not is_inside_tree():
		return
	sprite.modulate = Color.WHITE
	winding_up = false

	if player != null:
		var dir = (player.global_position - global_position).normalized()
		var proj = projectile_scene.instantiate()
		proj.source = self
		proj.direction = dir
		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 16

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func get_soft_push() -> Vector2:
	var push := Vector2.ZERO
	var others := get_tree().get_nodes_in_group("enemy")
	if player != null:
		others.append(player)
	for other in others:
		if other == self or not (other is Node2D):
			continue
		var offset : Vector2 = global_position - other.global_position
		var d := offset.length()
		if d >= push_radius:
			continue
		if d < 0.01:
			offset = Vector2.from_angle(randf() * TAU)
			d = 0.01
		push += offset.normalized() * (1.0 - d / push_radius)
	return push * push_strength


func play_walk_anim(direction: Vector2):
	if abs(direction.x) > abs(direction.y):
		sprite.play("WALK_RIGHT" if direction.x > 0 else "WALK_LEFT")
	else:
		sprite.play("WALK_DOWN" if direction.y > 0 else "WALK_UP")


func take_damage(amount):
	health.take_damage(amount)


func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		add_collision_exception_with(body)
		body.add_collision_exception_with(self)


func _on_detection_area_body_exited(body):
	if body == player:
		player = null


func _on_died():
	queue_free()
