extends Area2D

@export var damage := 10
@export var lifetime := 0.2
var source: Node = null

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	print("Attack hit: ", body.name, " | source: ", source.name if source else "NULL")
	if body == source:
		print("-> skipped, is source")
		return
	if body.has_method("take_damage"):
		print("-> damaging: ", body.name)
		body.take_damage(damage)
