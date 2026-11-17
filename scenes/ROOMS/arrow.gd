extends Area2D

@export var damage := 10
@export var speed := 150.0
@export var lifetime := 3.0

var direction := Vector2.RIGHT
var source: Node = null


func _ready():
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta):
	global_position += direction * speed * delta


func _on_body_entered(body):
	if body == source:
		return
	if source and source.is_in_group("enemy") and body.is_in_group("enemy"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free() 
