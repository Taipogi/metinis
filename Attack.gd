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
	if is_instance_valid(source) and source.is_in_group("enemy") and body.is_in_group("enemy"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if is_instance_valid(source) and source.has_method("on_hit_dealt"):
			source.on_hit_dealt(body, damage)
		if body.has_method("on_hurt_by"):
			body.on_hurt_by(source)
