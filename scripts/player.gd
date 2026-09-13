extends CharacterBody2D

var mspeed = 100
var lastdir := Vector2(1, 0)

@onready var health: Health = $Health
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_point: Marker2D = $Attackpoint
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sprite: AnimatedSprite2D = $AttackSprite
@export var attack_scene: PackedScene = preload("res://scenes/Attack.tscn")

var is_attacking := false


func _ready():
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health
	
	attack_sprite.visible = false
	print("attack_sprite ready check: ", attack_sprite)


func take_damage(amount):
	health.take_damage(amount)


func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * mspeed
	move_and_slide()
	
	if direction.length() > 0:
		lastdir = direction
		walk_anim(direction)
	else:
		idle_anim(lastdir)


func _process(_delta):
	if Input.is_action_just_pressed("Attack_melee") and not is_attacking:
		start_attack()
	if Input.is_action_just_pressed("pause"):
		get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn")


func start_attack():
	is_attacking = true
	attack_sprite.visible = true
	attack_sprite.position = lastdir * 16
	attack_anim(lastdir)


func attack_anim(direction):
	if direction.x > 0:
		attack_sprite.play("attack_right")
	elif direction.x < 0:
		attack_sprite.play("attack_left")
	elif direction.y > 0:
		attack_sprite.play("attack_down")
	else:
		attack_sprite.play("attack_up")


func walk_anim(direction):
	if direction.x > 0:
		sprite.play("walk_right")
	elif direction.x < 0:
		sprite.play("walk_left")
	elif direction.y > 0:
		sprite.play("walk_down")
	elif direction.y < 0:
		sprite.play("walk_up")


func idle_anim(direction):
	if direction.x > 0:
		sprite.play("idle_right")
	elif direction.x < 0:
		sprite.play("idle_left")
	elif direction.y > 0:
		sprite.play("idle_down")
	elif direction.y < 0:
		sprite.play("idle_up")


func _on_attack_sprite_animation_finished():
	is_attacking = false
	attack_sprite.visible = false


func _on_attack_sprite_frame_changed():
	if attack_sprite.frame == 2:
		spawn_hitbox()

func spawn_hitbox():
	attack_point.position = lastdir * 16
	var attack = attack_scene.instantiate()
	get_parent().add_child(attack)
	attack.global_position = attack_point.global_position


func _on_died():
	print("PLAYER DIED")


func _on_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health


func _input(event):
	if event.is_action_pressed("ui_accept"):
		health.take_damage(10)
