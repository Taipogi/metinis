class_name UpgradeMenu
extends CanvasLayer

const RARE_CHANCE := 0.25
const COLORS := {
	"common": Color.WHITE,
	"rare": Color(1.0, 0.8, 0.3),
	"special": Color(0.8, 0.5, 1.0),
}

var common_pool := [
	{"id": "aoe", "name": "Platesnis kardas", "desc": "+15% didesnis atakos plotas", "rarity": "common"},
	{"id": "damage", "name": "Aštrus ašmuo", "desc": "+15% daugiau žalos", "rarity": "common"},
	{"id": "speed", "name": "Greitos kojos", "desc": "+10% greičiau vaikštai", "rarity": "common"},
	{"id": "atk_speed", "name": "Greitos rankos", "desc": "+15% greičiau atakuoji", "rarity": "common"},
	{"id": "health", "name": "Stipri sveikata", "desc": "+20 HP", "rarity": "common"},
	{"id": "regen", "name": "Atgijimas", "desc": "+1 HP per sekundę", "rarity": "common"},
	{"id": "iframes", "name": "Koncentracija", "desc": "+0.5s nemirtingumo laiko po smūgio", "rarity": "common"},
	{"id": "heal_clear", "name": "Pasistiprinimas", "desc": "+8 HP kai išvalai kambarį", "rarity": "common"},
	{"id": "thorns", "name": "Aštrūs šarvai", "desc": "Tave žalojantiems priešams automatiškai nuimama -10 HP", "rarity": "common"},
]

var rare_pool := [
	{"id": "r_glass", "name": "Prasti šarvai, geras ginklas", "desc": "+30% žalos\n-40% HP", "rarity": "rare"},
	{"id": "r_swift", "name": "Lengvi šarvai", "desc": "+25% greičio\n-30% HP", "rarity": "rare"},
	{"id": "r_tank", "name": "Stambus sudėjimas", "desc": "+50% HP\n-25% greičio", "rarity": "rare"},
	{"id": "r_wide", "name": "Plačios rankos", "desc": "+25% atakos pločio\n-25% žalos", "rarity": "rare"},
	{"id": "r_focus", "name": "Sutelkimas jėgų", "desc": "+20% žalos\n-25% atakos pločio", "rarity": "rare"},
	{"id": "r_heavy", "name": "Sunkus smūgis", "desc": "+25% žalos\n-40% atakos greičio", "rarity": "rare"},
	{"id": "r_gamble", "name": "Šansas", "desc": "gauk 2 nežinomus pastiprinimus", "rarity": "rare"},
]

var special_pool := [
	{"id": "s_double", "name": "Dvigubas smūgis", "desc": "Atakuok dukart", "rarity": "special"},
	{"id": "s_lifesteal", "name": "Gybybės atėmimas", "desc": "atgauk 20% padarytos žalos kaip HP", "rarity": "special"},
]

var box : HBoxContainer


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
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


signal closed

func _choose(id : String, p):
	_apply(id, p)
	_clamp_stats(p)
	visible = false
	get_tree().paused = false
	closed.emit()

func _apply(id : String, p):
	match id:
		"aoe": p.hitbox_scale *= 1.15
		"damage": p.damage_mult *= 1.15
		"speed": p.move_speed_mult *= 1.10
		"atk_speed": p.attack_speed_mult *= 1.15
		"health": p.health.increase_max(20)
		"regen": p.regen_per_sec += 1
		"iframes": p.iframe_time += 0.5
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
