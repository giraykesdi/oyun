extends Node2D

var water_creatures: Array[Dictionary] = []
var water_wave_rect: ColorRect
var wave_time: float = 0.0

func _ready() -> void:
	GameManager.checkpoint_scene = "res://scenes/levels/Level2B_CyberBeach.tscn"
	if not GameManager.has_item("neon_sword"):
		GameManager.add_item("neon_sword")
	LevelBuilder.add_neon_environment(self)
	LevelBuilder.add_background_junkyard(self, 1300.0, "labyrinth")
	_add_cyber_sun()
	_build_level_geometry()
	_build_water_and_creatures()
	_spawn_godo()
	GameManager.emit_signal("status_message", "BÖLÜM 2B: Siber Plaj - Köprülerden Geç ve Sudaki Yaratıklara Dikkat Et!")

	var player: Node = get_node_or_null("Player")
	if player != null and player.has_signal("stun_finished"):
		player.stun_finished.connect(_on_player_stun_finished, CONNECT_ONE_SHOT)

func _spawn_godo() -> void:
	var godo := preload("res://scenes/objects/GodoNPC.gd").new()
	godo.position = Vector2(102, 138)
	add_child(godo)

func _on_player_stun_finished() -> void:
	var player: Node = get_node_or_null("Player")
	if player == null:
		return
	player.cutscene_lock = true
	if player.has_method("say"):
		player.say("Burası da neresi?! Kum ve PC parçaları... Galiba sudaki yaratıklar beni yemek istiyor!", 3.2)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func():
		if is_instance_valid(player):
			player.cutscene_lock = false
	)

func _add_cyber_sun() -> void:
	var sun := ColorRect.new()
	sun.z_index = -18
	sun.position = Vector2(210, 18)
	sun.size = Vector2(46, 46)
	sun.color = Color(1.0, 0.55, 0.25, 0.35)
	add_child(sun)
	var sun_core := ColorRect.new()
	sun_core.z_index = -18
	sun_core.position = Vector2(218, 26)
	sun_core.size = Vector2(30, 30)
	sun_core.color = Color(1.0, 0.85, 0.3, 0.45)
	add_child(sun_core)

func _build_level_geometry() -> void:
	# Tavan Giriş Borusu (PO buradan kumlu plaja düşer)
	LevelBuilder.add_entry_pipe(self, 44.0, 28.0)

	# 1. Başlangıç Kumlu Adası
	LevelBuilder.add_platform(self, Rect2(0, 138, 130, 48), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")

	# Köprü 1 (Suyun üstünden geçiş)
	_add_bridge_with_posts(Rect2(146, 132, 74, 10))

	# 2. Kumlu Ada + Trambolin
	LevelBuilder.add_platform(self, Rect2(236, 128, 92, 58), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")

	# Yüksek Anakart Köprüsü (Sıçrayan yaratığın üstünden)
	_add_bridge_with_posts(Rect2(348, 96, 86, 10))

	# 3. Orta Kumlu Adacık (Kalp yenileme adası)
	LevelBuilder.add_platform(self, Rect2(452, 134, 84, 52), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")

	# Köprü 2
	_add_bridge_with_posts(Rect2(552, 128, 96, 10))

	# 4. Büyük Kumlu Ada (PC Hurda Adası)
	LevelBuilder.add_platform(self, Rect2(664, 124, 124, 62), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")

	# Kumlu Basamak Blokları + Köprü 3
	LevelBuilder.add_platform(self, Rect2(808, 114, 44, 72), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")
	LevelBuilder.add_platform(self, Rect2(872, 102, 44, 84), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")
	_add_bridge_with_posts(Rect2(936, 118, 96, 10))

	# 5. Çıkış Kumlu Adası + Onarılacak Kablo ile Çıkılan Üst Çıkış Platformu
	LevelBuilder.add_platform(self, Rect2(1048, 126, 150, 60), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")
	LevelBuilder.add_platform(self, Rect2(1110, 56, 88, 14), Color(1.0, 0.82, 0.35, 1.0), Color(0.25, 0.2, 0.12, 1.0), "sand")

	# Sol ve Sağ Sınır Duvarları
	LevelBuilder.add_platform(self, Rect2(-16, -100, 16, 300), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")
	LevelBuilder.add_platform(self, Rect2(1198, -100, 16, 300), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")

	# Plaj + PC Karışımı Dekorasyonlar
	LevelBuilder.add_beach_decorations(self, [
		{"pos": Vector2(22, 138), "kind": "palm"},
		{"pos": Vector2(88, 138), "kind": "pc_scrap"},
		{"pos": Vector2(108, 138), "kind": "chip_shell"},
		{"pos": Vector2(256, 128), "kind": "umbrella"},
		{"pos": Vector2(284, 128), "kind": "chip_shell"},
		{"pos": Vector2(474, 134), "kind": "palm"},
		{"pos": Vector2(516, 134), "kind": "pc_scrap"},
		{"pos": Vector2(686, 124), "kind": "umbrella"},
		{"pos": Vector2(738, 124), "kind": "pc_scrap"},
		{"pos": Vector2(768, 124), "kind": "palm"},
		{"pos": Vector2(830, 114), "kind": "chip_shell"},
		{"pos": Vector2(1078, 126), "kind": "palm"},
		{"pos": Vector2(1110, 126), "kind": "pc_scrap"},
	])

func _add_bridge_with_posts(rect: Rect2) -> void:
	LevelBuilder.add_platform(self, rect, Color(0.95, 0.65, 0.28, 1.0), Color(0.28, 0.18, 0.1, 1.0), "bridge")
	var left_post := ColorRect.new()
	left_post.z_index = -2
	left_post.position = Vector2(rect.position.x + 4.0, rect.position.y + rect.size.y)
	left_post.size = Vector2(4.0, 56.0)
	left_post.color = Color(0.32, 0.2, 0.12, 0.95)
	add_child(left_post)

	var right_post := ColorRect.new()
	right_post.z_index = -2
	right_post.position = Vector2(rect.position.x + rect.size.x - 8.0, rect.position.y + rect.size.y)
	right_post.size = Vector2(4.0, 56.0)
	right_post.color = Color(0.32, 0.2, 0.12, 0.95)
	add_child(right_post)

func _build_water_and_creatures() -> void:
	# Derin su ve dalgalı üst yüzey
	var deep_water := ColorRect.new()
	deep_water.z_index = 4
	deep_water.position = Vector2(-20, 166)
	deep_water.size = Vector2(1260, 44)
	deep_water.color = Color(0.0, 0.35, 0.68, 0.85)
	add_child(deep_water)

	water_wave_rect = ColorRect.new()
	water_wave_rect.z_index = 5
	water_wave_rect.position = Vector2(-20, 160)
	water_wave_rect.size = Vector2(1260, 8)
	water_wave_rect.color = Color(0.1, 0.82, 1.0, 0.68)
	add_child(water_wave_rect)

	# Suya düşme tehlike alanı
	var water_hazard := Area2D.new()
	water_hazard.position = Vector2(600, 180)
	var col := CollisionShape2D.new()
	var shp := RectangleShape2D.new()
	shp.size = Vector2(1260, 28)
	col.shape = shp
	water_hazard.add_child(col)
	water_hazard.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and body.has_method("hurt_player"):
			GameManager.play_sfx("water_splash")
			body.hurt_player(GameManager.MAX_HEALTH, body.global_position, true, "Siber Plaj Sularına Düştün!")
	)
	add_child(water_hazard)

	# Sudaki Yaratıklar (Siber Köpekbalığı / Piranha)
	_spawn_water_creature(Vector2(182, 158), 26.0, 2.2, 0.0, 42.0)
	_spawn_water_creature(Vector2(390, 154), 32.0, 2.6, 1.2, 68.0)
	_spawn_water_creature(Vector2(600, 158), 38.0, 2.5, 2.1, 52.0)
	_spawn_water_creature(Vector2(984, 156), 34.0, 2.8, 0.7, 56.0)

func _spawn_water_creature(base_pos: Vector2, patrol_r: float, speed: float, phase: float, jump_h: float) -> void:
	var area := Area2D.new()
	area.position = base_pos
	area.z_index = 6

	# Kurbağa Su Yaratığı Görseli (4 kareli sprite sheet)
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/enemy_frog_sheet.png")
	spr.hframes = 4
	spr.frame = 0
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2(0, -4)
	area.add_child(spr)

	var col := CollisionShape2D.new()
	var shp := RectangleShape2D.new()
	shp.size = Vector2(16, 12)
	col.shape = shp
	col.position = Vector2(0, -2)
	area.add_child(col)

	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and body.has_method("hurt_player"):
			GameManager.play_sfx("frog_bite")
			body.hurt_player(1, area.global_position, false, "Sudaki Kurbağa Seni Isırdı!")
	)
	add_child(area)

	water_creatures.append({
		"node": area,
		"sprite": spr,
		"base": base_pos,
		"radius": patrol_r,
		"speed": speed,
		"phase": phase,
		"jump_h": jump_h,
		"was_leaping": false,
	})

func _process(delta: float) -> void:
	wave_time += delta
	if is_instance_valid(water_wave_rect):
		water_wave_rect.position.y = 160.0 + sin(wave_time * 3.5) * 1.5
	var player: Node2D = get_node_or_null("Player")
	for c in water_creatures:
		var node: Area2D = c["node"]
		var spr: Sprite2D = c["sprite"]
		if not is_instance_valid(node):
			continue
		var t: float = wave_time * float(c["speed"]) + float(c["phase"])
		var base: Vector2 = c["base"]
		var dx: float = sin(t * 0.8) * float(c["radius"])
		var leap_norm: float = max(0.0, sin(t * 1.4))
		var leap: float = leap_norm * float(c["jump_h"])
		var vy_sign: float = cos(t * 1.4)
		node.position = Vector2(base.x + dx, base.y - leap)
		if leap_norm >= 0.08 and not bool(c["was_leaping"]):
			c["was_leaping"] = true
			if player == null or abs(node.global_position.x - player.global_position.x) < 220.0:
				GameManager.play_sfx("frog_croak", 0.08)
		elif leap_norm < 0.08:
			c["was_leaping"] = false
		if is_instance_valid(spr):
			spr.flip_h = (cos(t * 0.8) >= 0.0)
			if leap_norm < 0.08:
				spr.frame = 0
			elif vy_sign > 0.0 and leap_norm < 0.35:
				spr.frame = 1
			elif vy_sign > 0.0:
				spr.frame = 3
			else:
				spr.frame = 2
