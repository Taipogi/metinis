class_name Room
extends Node2D

signal player_exited(direction : String, room : Room)

var grid_pos : Vector2i = Vector2i.ZERO
var enemy_count := 0

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
		var door_should_be_active : bool = neighbor_exists and not level_complete and not forced_open[dir]

		print(name, " [", dir, "] neighbor=", neighbor_exists, " level_complete=", level_complete, " forced_open=", forced_open[dir], " door_active(shut)=", door_should_be_active)

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

func register_room_enemies():
	for child in get_children():
		if child.has_method("take_damage") and child.is_in_group("enemy"):
			register_enemy(child)
	
	if enemy_count == 0:
		level_complete = true
		_notify_neighbors()

func register_enemy(enemy):
	var enemy_health : Health = enemy.get_node_or_null("Health")
	if enemy_health == null:
		push_warning("Enemy " + enemy.name + " has no Health node, not counting it")
		return
	enemy_count += 1
	enemy_health.died.connect(_on_enemy_died)

var neighbors : Dictionary = {
	"north": null,
	"south": null,
	"east": null,
	"west": null,
}

var forced_open : Dictionary = {
	"north": false,
	"south": false,
	"east": false,
	"west": false,
}

const OPPOSITE = {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east",
}

func unlock_entrance(dir : String):
	print(name, " received unlock_entrance for: ", dir)
	forced_open[dir] = true
	setup_doors()


func _on_enemy_died():
	enemy_count -= 1
	if enemy_count <= 0:
		level_complete = true
		_notify_neighbors()


func _notify_neighbors():
	print(name, " notifying neighbors. neighbors dict: ", neighbors)
	for dir in neighbors.keys():
		var neighbor : Room = neighbors[dir]
		if neighbor:
			print(name, " -> unlocking ", OPPOSITE[dir], " on ", neighbor.name)
			neighbor.unlock_entrance(OPPOSITE[dir])
		else:
			print(name, " has no neighbor in direction: ", dir)



@export var enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/ROOMS/DIAGONALENEMY.tscn"),
]
@export var enemies_per_room := 2

@onready var spawn_points: Node = $SpawnPoints

var is_start_room := false
var spawned := false


func spawn_enemies():
	if spawned:
		return
	spawned = true

	if is_start_room or enemy_scenes.is_empty():
		level_complete = true
		_notify_neighbors()
		return

	var points := spawn_points.get_children()
	points.shuffle()
	var count : int = min(enemies_per_room, points.size())

	for i in count:
		var enemy = enemy_scenes.pick_random().instantiate()
		add_child(enemy)
		enemy.global_position = points[i].global_position
		register_enemy(enemy)

	if enemy_count == 0:
		level_complete = true
		_notify_neighbors()
