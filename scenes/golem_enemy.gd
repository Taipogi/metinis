extends CharacterBody2D

@export var speed := 45
@export var contact_damage := 10
@export var contact_cooldown := 1.0
@export var push_radius := 22.0   
@export var push_strength := 75.0 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var contact_area: Area2D = $ContactArea
@onready var health: Health = $Health

var player: Node2D = null
var contact_timer := 0.0


func _ready():
	add_to_group("enemy")
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	health.died.connect(_on_died)


func _physics_process(delta):
	if contact_timer > 0.0:
		contact_timer -= delta

	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player = player.global_position - global_position
	velocity = to_player.normalized() * speed
	velocity += get_soft_push()
	velocity = velocity.limit_length(speed * 1.5)
	move_and_slide()

	play_walk_anim(to_player)
	_check_contact()


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
			offset = Vector2.from_angle(randf() * TAU)
			dist = 0.01
		push += offset.normalized() * (1.0 - dist / push_radius)

	return push * push_strength


func _check_contact():
	if contact_timer > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(contact_damage)
			if body.has_method("on_hurt_by"):
				body.on_hurt_by(self)
			contact_timer = contact_cooldown
			return


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
