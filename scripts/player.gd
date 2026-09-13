extends CharacterBody2D

var mspeed = 100
# mspeed yra max_speed
var lastdir := Vector2(1, 0)

@onready var health: Health = $Health
@onready var health_bar: ProgressBar = $HealthBar


func _ready():
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health
	
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


func walk_anim(direction):
	if direction.x > 0:
		$AnimatedSprite2D.play("walk_right")
	elif direction.x < 0:
		$AnimatedSprite2D.play("walk_left")
	elif direction.y > 0:
		$AnimatedSprite2D.play("walk_down")
	elif direction.y < 0:
		$AnimatedSprite2D.play("walk_up")


func idle_anim(direction):
	if direction.x > 0:
		$AnimatedSprite2D.play("idle_right")
	elif direction.x < 0:
		$AnimatedSprite2D.play("idle_left")
	elif direction.y > 0:
		$AnimatedSprite2D.play("idle_down")
	elif direction.y < 0:
		$AnimatedSprite2D.play("idle_up")


func _on_died():
	print("PLAYER DIED")


func _on_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health


func _input(event):
	if event.is_action_pressed("ui_accept"):
		health.take_damage(10)
