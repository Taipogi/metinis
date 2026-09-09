class_name RoomGeneration
extends Node2D
@export var map_size : int = 7
@export var rooms_to_generate : int = 12
var room_count : int = 0
var map : Array[bool]
var rooms : Array[Room]
var room_pos_offset : float = 280
var first_room_x : int = 3
var first_room_y : int = 3
var first_room : Room
var room_scene : PackedScene = preload ("res://scenes/ROOMS/room_template.tscn")
@export var player : CharacterBody2D

func _ready ():
    _generate()
    
func _generate ():
    room_count = 0
    map.resize(map_size * map_size)
    
    _check_room(first_room_x, first_room_y, Vector2.ZERO, true)
    _instantiate_rooms()
    
    _start_level_complete_timer()

func _start_level_complete_timer():
    var timer := Timer.new()
    timer.wait_time = 5.0
    timer.one_shot = true
    add_child(timer)
    timer.timeout.connect(_on_level_complete_timer_timeout)
    timer.start()

func _on_level_complete_timer_timeout():
    for room in rooms:
        room.level_complete = true

func _check_room (x : int, y : int, desired_direction : Vector2, is_first_room : bool = false):
    if room_count >= rooms_to_generate:
        return
        
    if x < 0 or x > map_size - 1 or y < 0 or y > map_size -1:
        return
    
    if _get_map (x, y) == true:
        return
    
    room_count += 1
    _set_map(x, y, true)
    
    var go_north : bool = randf() > (0.2 if desired_direction == Vector2.UP else 0.8)
    var go_south : bool = randf() > (0.2 if desired_direction == Vector2.DOWN else 0.8)
    var go_east : bool = randf () > (0.2 if desired_direction == Vector2.RIGHT else 0.8)
    var go_west : bool = randf () > (0.2 if desired_direction == Vector2.LEFT else 0.8)
    
    if go_north or is_first_room:
        _check_room(x, y - 1, Vector2.UP if is_first_room else desired_direction)
    if go_south or is_first_room:
        _check_room(x, y + 1, Vector2.DOWN if is_first_room else desired_direction)
    if go_east or is_first_room:
        _check_room(x + 1, y, Vector2.RIGHT if is_first_room else desired_direction)	
    if go_west or is_first_room:
        _check_room(x - 1, y, Vector2.LEFT if is_first_room else desired_direction)
        
        
func _instantiate_rooms():
    for x in range(map_size):
        for y in range(map_size):
            if _get_map(x, y) == false:
                continue
            
            var room : Room = room_scene.instantiate()
            get_tree().root.add_child.call_deferred(room)
            rooms.append(room)
            
            room.global_position = Vector2(x - first_room_x, y - first_room_y) * room_pos_offset
            
            room.has_neighbor = {
                "north": _room_exists(x, y - 1),
                "south": _room_exists(x, y + 1),
                "east":  _room_exists(x + 1, y),
                "west":  _room_exists(x - 1, y),
            }
            room.setup_doors.call_deferred()

func _room_exists(x : int, y : int) -> bool:
    if x < 0 or x > map_size - 1 or y < 0 or y > map_size - 1:
        return false
    return _get_map(x, y)

func _get_map (x : int, y : int) -> bool:
    return map[x + y * map_size]
func _set_map (x : int, y : int, value : bool):
    map[x + y * map_size] = value
