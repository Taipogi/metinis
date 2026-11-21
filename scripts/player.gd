extends CharacterBody2D

var mspeed = 100
var lastdir := Vector2(1, 0)

@onready var health: Health = $Health
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_point: Marker2D = $Attackpoint
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sprite: AnimatedSprite2D = $AttackSprite
@export var attack_scene: PackedScene = preload("res://scenes/Attack.tscn")

var is_attacking := false


func _ready():
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	
	health_bar.max_value = health.max_health
	health_bar.value = health.current_health
	
	attack_sprite.visible = false
	print("attack_sprite ready check: ", attack_sprite)


func take_damage(amount):
	if invincible:
		return
	health.take_damage(amount)
	if iframe_time > 0.0 and health.current_health > 0:
		invincible = true
		sprite.modulate.a = 0.5
		await get_tree().create_timer(iframe_time).timeout
		if not is_inside_tree():
			return
		invincible = false
		sprite.modulate.a = 1.0


func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * mspeed * move_speed_mult + get_enemy_push()
	move_and_slide()
	
	if direction.length() > 0:
		lastdir = direction
		walk_anim(direction)
	else:
		idle_anim(lastdir)


func _process(delta):
	if Input.is_action_just_pressed("Attack_melee") and not is_attacking:
		start_attack()

	if regen_per_sec > 0.0 and health.current_health > 0:
		_regen_buffer += regen_per_sec * delta
		if _regen_buffer >= 1.0:
			var whole := int(_regen_buffer)
			_regen_buffer -= whole
			health.heal(whole)


func start_attack():
	is_attacking = true
	attack_sprite.speed_scale = attack_speed_mult
	attack_sprite.scale = Vector2.ONE * hitbox_scale
	attack_sprite.visible = true
	attack_anim(lastdir)

func attack_anim(direction):
	current_attack_anim = get_attack_anim(direction)
	attack_sprite.position = ATTACK_OFFSETS[current_attack_anim] * hitbox_scale
	attack_sprite.play(current_attack_anim)

func walk_anim(direction):
	if direction.x > 0:
		sprite.play("walk_right")
	elif direction.x < 0:
		sprite.play("walk_left")
	elif direction.y > 0:
		sprite.play("walk_down")
	elif direction.y < 0:
		sprite.play("walk_up")


func idle_anim(direction):
	if direction.x > 0:
		sprite.play("idle_right")
	elif direction.x < 0:
		sprite.play("idle_left")
	elif direction.y > 0:
		sprite.play("idle_down")
	elif direction.y < 0:
		sprite.play("idle_up")


func _on_attack_sprite_animation_finished():
	is_attacking = false
	attack_sprite.visible = false


func _on_attack_sprite_frame_changed():
	if attack_sprite.frame == 2:
		spawn_hitbox()

func spawn_hitbox():
	_strike()
	if attack_twice:
		await get_tree().create_timer(0.2 / attack_speed_mult).timeout
		if is_inside_tree():
			_strike()

func _on_died():
	get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn")


func _on_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health
	print("PLAYER (", self.name, ") health: ", current_health, "/", max_health)

@export var projectile_scene: PackedScene
@export var arrow_damage := 6

var damage_mult := 1.0
var attack_speed_mult := 1.0
var move_speed_mult := 1.0
var hitbox_scale := 1.0
var regen_per_sec := 0.0
var iframe_time := 0.0
var heal_on_clear := 0
var thorns_damage := 0
var extra_arrows := 0
var attack_twice := false
var lifesteal := 0.0

var invincible := false
var _regen_buffer := 0.0


func _strike():
	_make_hitbox()
	_fire_arrows()


func _make_hitbox():
	var attack = attack_scene.instantiate()
	attack.source = self
	attack.scale = Vector2.ONE * hitbox_scale
	attack.damage = int(round(attack.damage * damage_mult))
	get_parent().add_child(attack)
	attack.global_position = global_position + ATTACK_OFFSETS[current_attack_anim] * hitbox_scale

func _fire_arrows():
	if extra_arrows <= 0 or projectile_scene == null:
		return
	var base_dir = lastdir.normalized()
	for i in extra_arrows:
		var angle := 0.0
		if extra_arrows > 1:
			angle = lerpf(-15.0, 15.0, float(i) / (extra_arrows - 1))
		var arrow = projectile_scene.instantiate()
		arrow.source = self
		arrow.direction = base_dir.rotated(deg_to_rad(angle))
		arrow.damage = int(round(arrow_damage * damage_mult))
		get_parent().add_child(arrow)
		arrow.global_position = global_position + base_dir * 16

func on_hit_dealt(_target, dmg):
	if lifesteal > 0.0:
		health.heal(maxi(1, int(round(dmg * lifesteal))))


func on_hurt_by(attacker):
	if thorns_damage > 0 and is_instance_valid(attacker) and attacker.has_method("take_damage"):
		attacker.take_damage(thorns_damage)


func on_room_cleared():
	if heal_on_clear > 0:
		health.heal(heal_on_clear)


const ATTACK_OFFSETS := {
	"attack_right": Vector2(20, 0),
	"attack_left": Vector2(-20, 0),
	"attack_down": Vector2(0, 16),
	"attack_up": Vector2(0, -16),
}

var current_attack_anim := "attack_right"


func get_attack_anim(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		return "attack_right" if direction.x > 0 else "attack_left"
	return "attack_down" if direction.y > 0 else "attack_up"
func get_enemy_push() -> Vector2:
	var push := Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var offset : Vector2 = global_position - enemy.global_position
		var dist := offset.length()
		if dist < 22.0 and dist > 0.01:
			push += offset.normalized() * (1.0 - dist / 22.0)
	return push * 30.0
