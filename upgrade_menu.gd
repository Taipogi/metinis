class_name UpgradeMenu
extends CanvasLayer

const RARE_CHANCE := 0.25
const COLORS := {
	"common": Color.WHITE,
	"rare": Color(1.0, 0.8, 0.3),
	"special": Color(0.8, 0.5, 1.0),
}

var common_pool := [
	{"id": "aoe", "name": "Wide Swing", "desc": "+15% attack area", "rarity": "common"},
	{"id": "damage", "name": "Sharpened Blade", "desc": "+15% damage", "rarity": "common"},
	{"id": "speed", "name": "Swift Feet", "desc": "+10% move speed", "rarity": "common"},
	{"id": "atk_speed", "name": "Quick Hands", "desc": "+15% attack speed", "rarity": "common"},
	{"id": "health", "name": "Vitality", "desc": "+20 max HP", "rarity": "common"},
	{"id": "regen", "name": "Regeneration", "desc": "+0.5 HP per second", "rarity": "common"},
	{"id": "iframes", "name": "Evasion", "desc": "+0.2s invincibility after a hit", "rarity": "common"},
	{"id": "heal_clear", "name": "Second Wind", "desc": "+8 HP when a room is cleared", "rarity": "common"},
	{"id": "thorns", "name": "Thorns", "desc": "Attackers take 5 damage", "rarity": "common"},
]

var rare_pool := [
	{"id": "r_glass", "name": "Glass Cannon", "desc": "+30% damage\n-40% health", "rarity": "rare"},
	{"id": "r_swift", "name": "Light Footed", "desc": "+25% speed\n-30% health", "rarity": "rare"},
	{"id": "r_tank", "name": "Juggernaut", "desc": "+50% health\n-25% speed", "rarity": "rare"},
	{"id": "r_wide", "name": "Broad Strokes", "desc": "+25% area\n-25% damage", "rarity": "rare"},
	{"id": "r_focus", "name": "Focused Strike", "desc": "+20% damage\n-25% area", "rarity": "rare"},
	{"id": "r_heavy", "name": "Heavy Hitter", "desc": "+25% damage\n-40% attack speed", "rarity": "rare"},
	{"id": "r_gamble", "name": "Gamble", "desc": "2 random buffs", "rarity": "rare"},
]

var special_pool := [
	{"id": "s_arrow", "name": "Extra Arrow", "desc": "Each attack also fires an arrow", "rarity": "special"},
	{"id": "s_double", "name": "Double Strike", "desc": "Attack twice", "rarity": "special"},
	{"id": "s_lifesteal", "name": "Lifesteal", "desc": "Heal 20% of damage dealt", "rarity": "special"},
]

var box : HBoxContainer


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # buttons must work while the game is paused
	layer = 10
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Choose an upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	vbox.add_child(box)


func open_normal():
	var options : Array = []
	var used : Array = []
	for i in 3:
		var pool = rare_pool if randf() < RARE_CHANCE else common_pool
		var pick = _pick(pool, used)
		used.append(pick["id"])
		options.append(pick)
	_show(options)


func open_special():
	_show(special_pool)


func _pick(pool : Array, exclude : Array) -> Dictionary:
	var candidates = pool.filter(func(o): return not exclude.has(o["id"]))
	return candidates.pick_random()


func _show(options : Array):
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	for c in box.get_children():
		c.queue_free()

	for opt in options:
		var b := Button.new()
		b.text = "[" + opt["rarity"].to_upper() + "]\n" + opt["name"] + "\n" + opt["desc"]
		b.custom_minimum_size = Vector2(180, 110)
		var col : Color = COLORS[opt["rarity"]]
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_hover_color", col)
		b.pressed.connect(_choose.bind(opt["id"], player))
		box.add_child(b)

	visible = true
	get_tree().paused = true
	box.get_child(0).grab_focus()


func _choose(id : String, p):
	_apply(id, p)
	_clamp_stats(p)
	visible = false
	get_tree().paused = false



func _apply(id : String, p):
	match id:
		"aoe": p.hitbox_scale *= 1.15
		"damage": p.damage_mult *= 1.15
		"speed": p.move_speed_mult *= 1.10
		"atk_speed": p.attack_speed_mult *= 1.15
		"health": p.health.increase_max(20)
		"regen": p.regen_per_sec += 0.5
		"iframes": p.iframe_time += 0.2
		"heal_clear": p.heal_on_clear += 8
		"thorns": p.thorns_damage += 5

		# rare
		"r_glass":
			p.damage_mult *= 1.3
			p.health.scale_max(0.6)
		"r_swift":
			p.move_speed_mult *= 1.25
			p.health.scale_max(0.7)
		"r_tank":
			p.health.scale_max(1.5)
			p.move_speed_mult *= 0.75
		"r_wide":
			p.hitbox_scale *= 1.25
			p.damage_mult *= 0.75
		"r_focus":
			p.damage_mult *= 1.2
			p.hitbox_scale *= 0.75
		"r_heavy":
			p.damage_mult *= 1.25
			p.attack_speed_mult *= 0.6
		"r_gamble":
			var picks = common_pool.duplicate()
			picks.shuffle()
			for i in 2:
				_apply(picks[i]["id"], p)

		"s_arrow": p.extra_arrows += 1
		"s_double": p.attack_twice = true
		"s_lifesteal": p.lifesteal += 0.2


func _clamp_stats(p):
	p.attack_speed_mult = clampf(p.attack_speed_mult, 0.3, 3.0)
	p.move_speed_mult = clampf(p.move_speed_mult, 0.4, 2.5)
	p.hitbox_scale = clampf(p.hitbox_scale, 0.5, 3.0)
	p.damage_mult = maxf(p.damage_mult, 0.2)
	p.iframe_time = minf(p.iframe_time, 1.0)
