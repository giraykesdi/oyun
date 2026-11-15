extends Node2D

func _ready() -> void:
	GameManager.checkpoint_scene = "res://scenes/levels/Level2_Labyrinth.tscn"
	if not GameManager.has_item("neon_sword"):
		GameManager.add_item("neon_sword")
	LevelBuilder.add_neon_environment(self)
	LevelBuilder.add_background_junkyard(self, 1650.0, "labyrinth")
	_build_level_geometry()
	GameManager.emit_signal("status_message", "BÖLÜM 2: Soğutma Suyu & Labirent - [Sol Tık / Q] Saldırı!")
	var player: Node = get_node_or_null("Player")
	if player != null and player.has_signal("stun_finished"):
		player.stun_finished.connect(func():
			if is_instance_valid(player) and player.has_method("say"):
				player.say("Soğutma suyuna düştüm! Çapraz trambolinden fırlayıp labirenti aşmalıyım!", 3.2)
		, CONNECT_ONE_SHOT)

func _build_level_geometry() -> void:
	# Tavan Giriş Borusu (Oyuncu buradan su çukuruna düşer ve ilk başta sersemler)
	LevelBuilder.add_entry_pipe(self, 86.0, 28.0)

	# 1. Su Birikintisi Çukuru (Sunken Basin - Toprak Blok)
	LevelBuilder.add_platform(self, Rect2(0, 96, 24, 84), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt") # Sol duvar
	LevelBuilder.add_platform(self, Rect2(24, 164, 96, 20), Color(0.0, 0.65, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt") # Çukur tabanı
	LevelBuilder.add_platform(self, Rect2(120, 112, 92, 72), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt") # Su birikintisi sağ çıkıntısı

	# Su Birikintisi Görseli (Yarı saydam neon mavi soğutma sıvısı)
	var water := ColorRect.new()
	water.position = Vector2(24, 146)
	water.size = Vector2(96, 18)
	water.color = Color(0.0, 0.75, 1.0, 0.42)
	add_child(water)

	# Suya Düşme Ses Tetikleyicisi
	var water_area := Area2D.new()
	water_area.position = Vector2(72, 155)
	var water_col := CollisionShape2D.new()
	var water_shape := RectangleShape2D.new()
	water_shape.size = Vector2(94, 16)
	water_col.shape = water_shape
	water_area.add_child(water_col)
	water_area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			GameManager.play_sfx("water_splash")
	)
	add_child(water_area)

	# Sudaki trambolin sonrası üst geçiş platformu (Labirent Girişi: y = 64)
	LevelBuilder.add_platform(self, Rect2(204, 64, 78, 12), Color(0.0, 1.0, 0.8, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")

	# 2. ÜÇ KATLI DEVRE LABİRENTİ - BÖLÜM A (x: 265 -> 805)
	# Labirent Alt Kat Zemini (x: 265 -> 1400, y = 156) - İki labirent bölümü boyunca uzanır
	LevelBuilder.add_platform(self, Rect2(265, 156, 1135, 24), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")

	# Labirent Orta Kat Koridorları (y = 106)
	LevelBuilder.add_platform(self, Rect2(280, 106, 224, 12), Color(1.0, 0.2, 0.65, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	LevelBuilder.add_platform(self, Rect2(540, 106, 260, 12), Color(1.0, 0.2, 0.65, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")

	# Labirent Üst Kat Koridorları (y = 56)
	LevelBuilder.add_platform(self, Rect2(325, 56, 250, 12), Color(0.2, 1.0, 0.55, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	LevelBuilder.add_platform(self, Rect2(610, 56, 190, 12), Color(0.2, 1.0, 0.55, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")

	# Labirent Tavanı (Tüm labirent boyunca) ve İç Duvar Bölmeleri
	LevelBuilder.add_platform(self, Rect2(280, 10, 1125, 10), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	LevelBuilder.add_platform(self, Rect2(475, 68, 12, 38), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt") # Orta-üst arası labirent duvarı
	LevelBuilder.add_platform(self, Rect2(605, 118, 12, 38), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt") # Alt-orta arası labirent duvarı

	# 3. ÜÇ KATLI DEVRE LABİRENTİ - BÖLÜM B (x: 805 -> 1400)
	# Alt katı kapatan duvar -> Orta kata tırmanmak zorunlu
	LevelBuilder.add_platform(self, Rect2(900, 118, 12, 38), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	# Orta Kat Koridoru B1 (x: 830 -> 1030)
	LevelBuilder.add_platform(self, Rect2(830, 106, 200, 12), Color(1.0, 0.2, 0.65, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	# Orta katı kapatan duvar -> Üst kata tırmanmak zorunlu
	LevelBuilder.add_platform(self, Rect2(1010, 68, 12, 38), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	# Üst Kat Koridoru B1 (x: 940 -> 1140)
	LevelBuilder.add_platform(self, Rect2(940, 56, 200, 12), Color(0.2, 1.0, 0.55, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	# Orta Kat Koridoru B2 (Üst kattan aşağı inilir, x: 1100 -> 1300)
	LevelBuilder.add_platform(self, Rect2(1100, 106, 200, 12), Color(1.0, 0.2, 0.65, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	# Orta katta Elektrik Tuzağı (Zıplayarak geçilir)
	LevelBuilder.add_shock_strip(self, Rect2(1225, 102, 22, 6))
	# Alt katta Elektrik Tuzağı
	LevelBuilder.add_shock_strip(self, Rect2(1330, 152, 24, 6))

	# 4. Labirent Çıkışı: Uçurum Arası Trambolin Adası ve Yüksek Çıkış Borusu Platformu
	LevelBuilder.add_platform(self, Rect2(1430, 148, 66, 32), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	LevelBuilder.add_platform(self, Rect2(1510, 48, 95, 16), Color(0.0, 1.0, 0.7, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")

	# Dış sınır duvarları
	LevelBuilder.add_platform(self, Rect2(-16, -100, 16, 300), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")
	LevelBuilder.add_platform(self, Rect2(1605, -100, 16, 300), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "dirt")

	# 2. Bölüm Toprak Bloklarla Uyumlu Dekorasyonlar (Yosunlar, parlayan mantarlar, ahşap/taş destekler)
	LevelBuilder.add_dirt_decorations(self, [
		{"pos": Vector2(145, 112), "kind": "moss"},
		{"pos": Vector2(172, 112), "kind": "mushroom"},
		{"pos": Vector2(236, 64), "kind": "moss"},
		{"pos": Vector2(315, 156), "kind": "wood_post"},
		{"pos": Vector2(355, 156), "kind": "mushroom"},
		{"pos": Vector2(430, 106), "kind": "moss"},
		{"pos": Vector2(560, 56), "kind": "mushroom"},
		{"pos": Vector2(655, 156), "kind": "stone_pile"},
		{"pos": Vector2(755, 156), "kind": "moss"},
		{"pos": Vector2(865, 106), "kind": "mushroom"},
		{"pos": Vector2(965, 156), "kind": "wood_post"},
		{"pos": Vector2(1155, 106), "kind": "moss"},
		{"pos": Vector2(1285, 156), "kind": "mushroom"},
		{"pos": Vector2(1445, 148), "kind": "stone_pile"},
	])
