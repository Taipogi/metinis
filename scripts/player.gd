extends CharacterBody2D

var mspeed = 100
#mspeed yra max_speed
var lastdir := Vector2(1,0)

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction*mspeed
	move_and_slide()
	
	if direction.length() > 0:
		lastdir = direction
		walk_anim(direction)
		print(direction)
	else:
		idle_anim(lastdir)
		print(direction)
		
func walk_anim(direction):
	if direction.x > 0:
		$AnimatedSprite2D.play("walk_right")
	elif direction.x <0:
		$AnimatedSprite2D.play("walk_left")
	elif direction.y >0:
		$AnimatedSprite2D.play("walk_down")
	elif direction.y <0:
		$AnimatedSprite2D.play("walk_up")

func idle_anim(direction):
	if direction.x > 0:
		$AnimatedSprite2D.play("idle_right")
	elif direction.x <0:
		$AnimatedSprite2D.play("idle_left")
	elif direction.y >0:
		$AnimatedSprite2D.play("idle_down")
	elif direction.y <0:
		$AnimatedSprite2D.play("idle_up")
