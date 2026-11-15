extends Node2D

func _ready() -> void:
	GameManager.checkpoint_scene = "res://scenes/levels/Level1_Junkyard.tscn"
	LevelBuilder.add_neon_environment(self)
	LevelBuilder.add_background_junkyard(self, 1000.0, "junkyard")
	_build_level_geometry()
	GameManager.emit_signal("status_message", "BÖLÜM 1: Donanım Çöplüğü - Kablo Bandını Bul ve Çıkış Borusuna Ulaş!")
	var player: Node = get_node_or_null("Player")
	if player != null and player.has_signal("stun_finished"):
		player.stun_finished.connect(_on_player_stun_finished, CONNECT_ONE_SHOT)

func _on_player_stun_finished() -> void:
	var player: Node = get_node_or_null("Player")
	var broken_cable: Node2D = get_node_or_null("BrokenExitCable")
	if player == null or broken_cable == null:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam == null:
		return
	var delta_pos: Vector2 = broken_cable.global_position + Vector2(0.0, 45.0) - player.global_position
	var tw := create_tween()
	tw.tween_property(cam, "offset", delta_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		if is_instance_valid(player) and player.has_method("say"):
			player.say("Şu sarkan kopmuş kabloya bak! Kıvılcım çıkarıyor... Bant bulup sarmalıyım!", 7.0)
	)
	tw.tween_interval(6.5)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_level_geometry() -> void:
	# Tavan Giriş Borusu (Oyuncu buradan aşağı düşer ve ilk başta sersemler)
	LevelBuilder.add_entry_pipe(self, 46.0, 28.0)

	# 1. Başlangıç Zemini (Taş Blok - Arada uçurum boşlukları var, aşağı düşen ölür!)
	LevelBuilder.add_platform(self, Rect2(0, 152, 165, 32), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")
	# Küçük taş basamak bloğu (uyumlu yan blok)
	LevelBuilder.add_platform(self, Rect2(126, 136, 26, 16), Color(0.45, 0.85, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")
	# Uçurum üstü zıplama bloğu (Trambolin platformu)
	LevelBuilder.add_platform(self, Rect2(195, 136, 75, 48), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")

	# Trambolin ile çıkılan orta anakart platformu (y = 100)
	LevelBuilder.add_platform(self, Rect2(285, 100, 90, 14), Color(1.0, 0.2, 0.7, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")
	# Orta platforma geri çıkmak için alt zemin uzantısı
	LevelBuilder.add_platform(self, Rect2(285, 148, 80, 36), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")

	# Kablo Bandının bulunduğu üst raf (y = 52 -> Orta platformdan y=100'den tam 48px tırmanarak çıkılır)
	LevelBuilder.add_platform(self, Rect2(368, 52, 112, 14), Color(1.0, 0.85, 0.1, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")

	# 2. Canavar Savaşı Arenası (x: 495 -> 905, y = 144)
	LevelBuilder.add_platform(self, Rect2(495, 144, 410, 40), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")

	# Çıkış Borusunun bulunduğu üst platform (y = 44 -> Arenadan y=144'ten 100px onarılan kabloyla çıkılır)
	LevelBuilder.add_platform(self, Rect2(812, 44, 96, 14), Color(0.0, 1.0, 0.65, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")

	# Sol ve Sağ Sınır Duvarları
	LevelBuilder.add_platform(self, Rect2(-16, -100, 16, 300), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")
	LevelBuilder.add_platform(self, Rect2(905, -100, 16, 300), Color(0.0, 0.9, 1.0, 1.0), Color(0.09, 0.11, 0.2, 1.0), "stone")

	# 1. Bölüm Taş Bloklarla Uyumlu Dekorasyonlar (Hurda sandıklar, sütunlar, terminaller, kablolar)
	LevelBuilder.add_stone_decorations(self, [
		{"pos": Vector2(24, 152), "kind": "wires"},
		{"pos": Vector2(88, 152), "kind": "terminal"},
		{"pos": Vector2(106, 152), "kind": "crate"},
		{"pos": Vector2(212, 136), "kind": "pillar"},
		{"pos": Vector2(325, 100), "kind": "wires"},
		{"pos": Vector2(395, 52), "kind": "crate"},
		{"pos": Vector2(530, 144), "kind": "pillar"},
		{"pos": Vector2(560, 144), "kind": "crate"},
		{"pos": Vector2(720, 144), "kind": "terminal"},
		{"pos": Vector2(765, 144), "kind": "wires"},
		{"pos": Vector2(885, 144), "kind": "pillar"},
	])
