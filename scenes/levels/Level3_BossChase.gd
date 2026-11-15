extends Node2D

func _ready() -> void:
	GameManager.checkpoint_scene = "res://scenes/levels/Level3_BossChase.tscn"
	LevelBuilder.add_neon_environment(self)
	LevelBuilder.add_background_junkyard(self, 3950.0, "boss")
	_build_chase_course()
	GameManager.emit_signal("status_message", "BÖLÜM 3: KABLO BOSS KAÇIŞI! Engelleri Aş ve Çıkış Borusuna Ulaş!")
	var player: Node = get_node_or_null("Player")
	if player != null and player.has_signal("stun_finished"):
		player.stun_finished.connect(func():
			if is_instance_valid(player) and player.has_method("say"):
				player.say("Olamaz! Devasa Kablo Bossu peşimde! Durmadan sağa koşmalıyım!", 3.2)
		, CONNECT_ONE_SHOT)

func _build_chase_course() -> void:
	# Tavan Giriş Borusu (x = 160)
	LevelBuilder.add_entry_pipe(self, 160.0, 28.0)

	# =========================================================================
	# AŞAMA 1: Başlangıç Zemini, Eğilme Tüneli ve İlk Elektrik Çukuru (x: 0 -> 490)
	# =========================================================================
	LevelBuilder.add_platform(self, Rect2(0, 152, 490, 32))
	# Alçak Engel 1 (Altında 14px boşluk -> S/Ctrl ile eğilerek geçilir)
	LevelBuilder.add_low_crouch_barrier(self, Rect2(265, 90, 48, 48))
	# Zıplanacak Yüksek Voltaj Şok Şeridi 1
	LevelBuilder.add_shock_strip(self, Rect2(365, 148, 28, 6))

	# =========================================================================
	# AŞAMA 2: Uçurum Atlama, Yüksek Kule Tırmanışı ve Lazer Kapısı (x: 540 -> 1080)
	# =========================================================================
	LevelBuilder.add_platform(self, Rect2(540, 136, 175, 48))
	# Hareketli Plazma Dronu 1 (Yatay devriye)
	LevelBuilder.add_moving_drone(self, Vector2(575, 122), Vector2(675, 122), 62.0)

	# Tırmanılacak Yüksek Duvar Platformu 1 (y = 76; alt platform y = 136 -> fark: 60px)
	LevelBuilder.add_platform(self, Rect2(710, 76, 210, 108), Color(0.0, 0.95, 1.0, 1.0))
	# Üst platformda Alçak Engel 2 (Eğilerek geçilir)
	LevelBuilder.add_low_crouch_barrier(self, Rect2(785, 14, 52, 48))

	# İniş basamağı ve Zamanlamalı Lazer Kapısı 1 (x: 920 -> 1080)
	LevelBuilder.add_platform(self, Rect2(920, 144, 160, 40))
	LevelBuilder.add_laser_gate(self, Vector2(1005, 84), 60.0, 1.15, 1.05, 0.0)

	# =========================================================================
	# AŞAMA 3: Çift Trambolinli Uçurum Adaları ve Orta Kule (x: 1130 -> 1740)
	# =========================================================================
	# Uçurum Ortasındaki Sıçrama Adası
	LevelBuilder.add_platform(self, Rect2(1135, 126, 85, 20), Color(1.0, 0.2, 0.7, 1.0))
	# Ana Platform (x: 1270 -> 1740, y = 148)
	LevelBuilder.add_platform(self, Rect2(1270, 148, 470, 36))
	# Zıplanacak Şok Şeridi 2
	LevelBuilder.add_shock_strip(self, Rect2(1345, 144, 30, 6))
	# Alçak Engel 3
	LevelBuilder.add_low_crouch_barrier(self, Rect2(1425, 86, 60, 48))

	# Orta Tırmanma Kulesi 2 (y = 92; alt platform y = 148 -> fark: 56px)
	LevelBuilder.add_platform(self, Rect2(1555, 92, 185, 92), Color(1.0, 0.2, 0.65, 1.0))
	# Kule üstünde Dikey Plazma Dronu 2
	LevelBuilder.add_moving_drone(self, Vector2(1650, 78), Vector2(1650, 34), 58.0)

	# =========================================================================
	# AŞAMA 4: İkili Zig-Zag Tüneli, Lazer ve Şok Tuzakları (x: 1790 -> 2440)
	# =========================================================================
	LevelBuilder.add_platform(self, Rect2(1790, 148, 650, 36))
	# Alçak Engel 4 (Eğil)
	LevelBuilder.add_low_crouch_barrier(self, Rect2(1865, 86, 56, 48))
	# Şok Şeridi 3 (Zıpla)
	LevelBuilder.add_shock_strip(self, Rect2(1965, 144, 32, 6))
	# Zamanlamalı Lazer Kapısı 2
	LevelBuilder.add_laser_gate(self, Vector2(2045, 88), 60.0, 1.1, 1.0, 0.6)
	# Alçak Engel 5 (Uzun Eğilme Tüneli)
	LevelBuilder.add_low_crouch_barrier(self, Rect2(2115, 86, 68, 48))

	# Yüksek Tırmanma Kulesi 3 (y = 88; alt platform y = 148 -> fark: 60px)
	LevelBuilder.add_platform(self, Rect2(2255, 88, 185, 96), Color(0.2, 1.0, 0.6, 1.0))
	# Kule üstünde Şok Şeridi 4
	LevelBuilder.add_shock_strip(self, Rect2(2335, 84, 28, 6))

	# =========================================================================
	# AŞAMA 5: Kanyon Geçişi, Dronlar ve Çoklu Tırmanış (x: 2495 -> 3080)
	# =========================================================================
	# Kanyon Adası 1
	LevelBuilder.add_platform(self, Rect2(2495, 134, 95, 18), Color(0.0, 0.9, 1.0, 1.0))
	# Kanyon Ana Zemin (x: 2635 -> 3080, y = 148)
	LevelBuilder.add_platform(self, Rect2(2635, 148, 445, 36))
	# Yatay Hızlı Plazma Dronu 3
	LevelBuilder.add_moving_drone(self, Vector2(2675, 134), Vector2(2805, 134), 76.0)
	# Alçak Engel 6
	LevelBuilder.add_low_crouch_barrier(self, Rect2(2845, 86, 54, 48))

	# Tırmanma Kulesi 4 (y = 92; alt platform y = 148 -> fark: 56px)
	LevelBuilder.add_platform(self, Rect2(2945, 92, 135, 92), Color(1.0, 0.3, 0.7, 1.0))

	# =========================================================================
	# AŞAMA 6: Son Hızlı Depar, Lazer + Eğilme + Final Trambolin Kulesi (x: 3130 -> 3520)
	# =========================================================================
	LevelBuilder.add_platform(self, Rect2(3130, 148, 390, 36))
	# Zamanlamalı Lazer Kapısı 3
	LevelBuilder.add_laser_gate(self, Vector2(3195, 88), 60.0, 1.05, 0.95, 0.3)
	# Alçak Engel 7
	LevelBuilder.add_low_crouch_barrier(self, Rect2(3250, 86, 52, 48))
	# Son Tırmanma ve Trambolin Kulesi 5 (y = 100; alt platform y = 148 -> fark: 48px)
	LevelBuilder.add_platform(self, Rect2(3350, 100, 170, 84))

	# =========================================================================
	# AŞAMA 7: Final Sıçraması ve Çıkış Borusu Platformu (x: 3565 -> 3820)
	# =========================================================================
	LevelBuilder.add_platform(self, Rect2(3565, 46, 255, 24), Color(0.1, 1.0, 0.6, 1.0))
