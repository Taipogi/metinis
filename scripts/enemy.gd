extends CharacterBody2D

var mspeed = 60

var damage_per_second = 10
var attack_timer = 0.0

@onready var player = get_tree().get_first_node_in_group("player")

@onready var health = $Health
@onready var health_bar = $HealthBar
@onready var attack_area = $AttackArea


func _ready():
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	health_bar.max_value = health.max_health
	health_bar.value = health.current_health


func _physics_process(delta):
	if player == null:
		return

	# Check whether the player is inside the attack range
	var player_in_range = attack_area.overlaps_body(player)

	if player_in_range:
		# Stop moving and attack
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")

		attack_timer -= delta

		if attack_timer <= 0:
			player.take_damage(damage_per_second)
			attack_timer = 1.0

	else:
		# Chase the player
		var direction = global_position.direction_to(player.global_position)

		velocity = direction * mspeed
		move_and_slide()

		$AnimatedSprite2D.play("walk")


func _on_died():
	print("ENEMY DIED")
	queue_free()


func _on_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health
