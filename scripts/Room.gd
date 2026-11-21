class_name Room
extends Node2D

signal player_exited(direction : String, room : Room)
signal cleared(room : Room)

var grid_pos : Vector2i = Vector2i.ZERO
var is_start_room := false
var is_boss_room := false

@export var enemy_scenes: Array[PackedScene] = []
@export var boss_scene: PackedScene
@export var enemies_per_room := 2
@onready var spawn_points: Node = $SpawnPoints
var spawned := false
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

		# true = the shut-door graphic and collision are on (door closed)
		var door_closed : bool = neighbor_exists and not level_complete and not forced_open[dir]

		if door_shut:
			door_shut.visible = door_closed
			for door_col in _get_collision_children(door_shut):
				door_col.set_deferred("disabled", not door_closed)

		if tunnel:
			tunnel.visible = neighbor_exists

		if barrier:
			barrier.visible = not neighbor_exists
			for barrier_col in _get_collision_children(barrier):
				barrier_col.set_deferred("disabled", neighbor_exists)



func spawn_enemies():
	if spawned:
		return
	spawned = true

	var points : Array = []
	for p in spawn_points.get_children():
		if p.name != "ArcherSpawn":
			points.append(p)
	points.shuffle()

	print(name, " spawn check | start=", is_start_room, " boss=", is_boss_room,
		" points=", points.size(), " enemy_scenes=", enemy_scenes.size())

	if is_start_room or points.is_empty() or enemy_scenes.is_empty():
		level_complete = true
		_notify_neighbors()
		return

	if is_boss_room:
		for p in points:
			_spawn_enemy(enemy_scenes.pick_random(), p.global_position)

		var boss_spawn = find_child("ArcherSpawn", true, false)
		if boss_scene == null:
			push_warning("Boss Scene is empty on this room template")
		elif boss_spawn == null:
			push_warning("No node named ArcherSpawn found in this room")
		else:
			_spawn_enemy(boss_scene, boss_spawn.global_position)
	else:
		var count : int = min(enemies_per_room, points.size())
		for i in count:
			_spawn_enemy(enemy_scenes.pick_random(), points[i].global_position)

	if enemy_count == 0:
		level_complete = true
		_notify_neighbors()

func _spawn_enemy(scene: PackedScene, pos: Vector2):
	var enemy = scene.instantiate()
	print(name, " spawning: ", scene.resource_path)
	add_child(enemy)
	enemy.global_position = pos
	register_enemy(enemy)


func register_enemy(enemy):
	var enemy_health : Health = enemy.get_node_or_null("Health")
	if enemy_health == null:
		push_warning("Enemy " + enemy.name + " has no Health node, not counting it")
		return
	enemy_count += 1
	enemy_health.died.connect(_on_enemy_died)


func _on_enemy_died():
	enemy_count -= 1
	if enemy_count <= 0:
		level_complete = true
		_notify_neighbors()
		cleared.emit(self)



func unlock_entrance(dir : String):
	forced_open[dir] = true
	if is_node_ready():
		setup_doors()


func _notify_neighbors():
	for dir in neighbors.keys():
		var neighbor : Room = neighbors[dir]
		if neighbor:
			neighbor.unlock_entrance(OPPOSITE[dir])
