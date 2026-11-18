class_name Health
extends Node

@export var max_health: int = 100

var current_health: int

signal health_changed(current_health, max_health)
signal died


func _ready():
	current_health = max_health


func take_damage(amount: int):
	if current_health <= 0:
		return
	current_health -= amount
	current_health = max(current_health, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)

	health_changed.emit(current_health, max_health)

func increase_max(amount: int):
	max_health += amount
	current_health += amount
	health_changed.emit(current_health, max_health)


func scale_max(factor: float):
	var ratio := float(current_health) / float(max_health)
	max_health = maxi(1, int(round(max_health * factor)))
	current_health = clampi(int(round(max_health * ratio)), 1, max_health)
	health_changed.emit(current_health, max_health)
