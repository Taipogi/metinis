extends CharacterBody2D

@export var projectile_scene: PackedScene = preload("res://scenes/ROOMS/ARROW.tscn")
@export var charge_time := 0.6
@export var attack_cooldown := 2.0

@export var barrage_chance := 0.4

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var health: Health = $Health

var player: Node2D = null
var busy := false


func _ready():
	add_to_group("enemy")
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	health.died.connect(queue_free)
	sprite.play("Idle_Down")

func _physics_process(_delta):
	if player != null:
		aim_bow()
		face_player()

	if player == null or busy:
		return
	busy = true
	if randf() < barrage_chance:
		await barrage()
	else:
		await single_shot()
	await get_tree().create_timer(attack_cooldown).timeout
	busy = false


func single_shot():
	bow_sprite.speed_scale = 1.0
	bow_sprite.play("SingleDraw")
	await bow_sprite.animation_finished
	if player == null:
		bow_sprite.play("Idle")
		return
	fire_arrow(aim_direction())
	play_release()
	await bow_sprite.animation_finished
	bow_sprite.play("Idle")


func barrage():
	bow_sprite.speed_scale = barrage_draw_speed
	bow_sprite.play("TripleDraw")
	await bow_sprite.animation_finished
	bow_sprite.speed_scale = 1.0

	for volley in 3:
		if player == null:
			break
		var base = aim_direction()
		for angle in [-15, 0, 15]:
			fire_arrow(base.rotated(deg_to_rad(angle)))
		play_release()
		await get_tree().create_timer(volley_gap).timeout

	await bow_sprite.animation_finished
	bow_sprite.play("Idle")


func play_release():
	bow_sprite.stop()
	bow_sprite.play("Release")

func aim_direction() -> Vector2:
	return (player.global_position - global_position).normalized()


func fire_arrow(dir: Vector2):
	var arrow = projectile_scene.instantiate()
	arrow.source = self      
	arrow.direction = dir    
	get_parent().add_child(arrow)
	arrow.global_position = global_position + dir * 16


func take_damage(amount):
	health.take_damage(amount)


func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body



func _on_detection_body_exited(body):
	if body == player:
		player = null
		bow_sprite.play("Idle")

@onready var bow_pivot: Node2D = $BowPivot
@onready var bow_sprite: AnimatedSprite2D = $BowPivot/BowSprite

@export var bow_art_angle_degrees := 0.0  

@export var barrage_draw_speed := 0.6  
@export var volley_gap := 0.25



func aim_bow():
	var dir = aim_direction()
	bow_pivot.rotation = dir.angle() - deg_to_rad(bow_art_angle_degrees)

	bow_sprite.flip_v = dir.x < 0

var facing := "Down"


func face_player():
	var dir = aim_direction()
	if abs(dir.x) > abs(dir.y):
		facing = "Right" if dir.x > 0 else "Left"
	else:
		facing = "Down" if dir.y > 0 else "Up"
	sprite.play("Idle_" + facing)
