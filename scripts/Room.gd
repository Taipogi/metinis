class_name Room
extends Node2D

signal player_exited(direction : String, room : Room)

var grid_pos : Vector2i = Vector2i.ZERO

@export var level_complete : bool = false:
	set(value):
		level_complete = value
		if is_node_ready():
			setup_doors()

var has_neighbor : Dictionary = {
	"north": true,
	"south": true,
	"east": true,
	"west": true,
}

@onready var entrances : Dictionary = {
	"north": $ENTRANCE_NORTH,
	"south": $ENTRANCE_SOUTH,
	"east": $ENTRANCE_EAST,
	"west": $ENTRANCE_WEST,
}

func _ready():
	_connect_exit_triggers()

func _connect_exit_triggers():
	for dir in entrances.keys():
		var entrance : Node2D = entrances.get(dir)
		if entrance == null:
			continue
		var door_node : Node = entrance.get_node_or_null("DOOR")
		var exit_trigger : Node = door_node.get_node_or_null("EXIT_TRIGGER") if door_node else null
		if exit_trigger:
			exit_trigger.body_entered.connect(_on_exit_trigger_body_entered.bind(dir))

func _on_exit_trigger_body_entered(body : Node, dir : String):
	if body.is_in_group("player"):
		player_exited.emit(dir, self)

func _get_collision_children(body: Node) -> Array:
	var result : Array = []
	if body == null:
		return result
	for child in body.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			result.append(child)
	return result

func setup_doors():
	for dir in has_neighbor.keys():
		var entrance : Node2D = entrances.get(dir)
		if entrance == null:
			push_warning("Room missing entrance node for direction: " + dir)
			continue
		var door_node : Node = entrance.get_node_or_null("DOOR")
		var door_shut : Node = door_node.get_node_or_null("DOOR_SHUT") if door_node else null
		var tunnel : Node = door_node.get_node_or_null("TUNNEL") if door_node else null
		var barrier : Node = entrance.get_node_or_null("BARRIER")
		var neighbor_exists : bool = has_neighbor[dir]
		var door_should_be_active : bool = neighbor_exists and not level_complete

		if global_position == Vector2.ZERO:
			print(dir, " neighbor=", neighbor_exists, " door_active=", door_should_be_active, " door_shut_found=", door_shut != null)

		if door_shut:
			door_shut.visible = door_should_be_active
			for door_col in _get_collision_children(door_shut):
				door_col.set_deferred("disabled", not door_should_be_active)

		if tunnel:
			tunnel.visible = neighbor_exists

		if barrier:
			barrier.visible = not neighbor_exists
			for barrier_col in _get_collision_children(barrier):
				barrier_col.set_deferred("disabled", neighbor_exists)
