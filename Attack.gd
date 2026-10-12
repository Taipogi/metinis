extends Area2D

@export var damage := 10
@export var lifetime := 0.2
var source: Node = null

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body == source:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
