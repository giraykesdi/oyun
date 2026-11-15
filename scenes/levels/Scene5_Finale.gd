extends Node2D

@onready var power_plug = $PowerPlug
@onready var ending_layer: CanvasLayer = $EndingLayer
@onready var blackout_rect: ColorRect = $EndingLayer/BlackoutRect
@onready var real_world_panel: Control = $EndingLayer/RealWorldPanel

var neon_lights: Array[ColorRect] = []
var wall_lamps: Array[Dictionary] = []
var game_completed: bool = false

var epilogue_active: bool = false
var epilogue_typing_done: bool = false
var epilogue_char_timer: float = 0.0
var epilogue_body: Label = null
var epilogue_prompt: Label = null
signal epilogue_finished

func _ready() -> void:
	GameManager.checkpoint_scene = "res://scenes/levels/Scene5_Finale.tscn"
	LevelBuilder.add_neon_environment(self)
	_build_corridor()
	power_plug.plug_pulled.connect(_on_plug_pulled)
	GameManager.emit_signal("status_message", "FİNAL: Engelleri Aş, Kırmızı Halılı Güç Koridorundan Yürü ve Fişi Çek [E]!")
	var player: Node = get_node_or_null("Player")
	if player != null and player.has_signal("stun_finished"):
		player.stun_finished.connect(func():
			if is_instance_valid(player) and player.has_method("say"):
				player.say("Sonunda güç çekirdeği koridoru! Ana güç fişini bulmalıyım!", 3.0)
		, CONNECT_ONE_SHOT)

	var plug_hint_area := Area2D.new()
	plug_hint_area.position = Vector2(1890, 120)
	var hint_col := CollisionShape2D.new()
	var hint_shp := RectangleShape2D.new()
	hint_shp.size = Vector2(80, 120)
	hint_col.shape = hint_shp
	plug_hint_area.add_child(hint_col)
	plug_hint_area.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and body.has_method("say"):
			body.say("İşte büyük güç fişi! Galiba bunu çekersem boss ölecek ve gerçek dünyaya dönebileceğim!", 4.0)
			plug_hint_area.queue_free()
	)
	add_child(plug_hint_area)

func _build_corridor() -> void:
	# Detaylı siberpunk/işlemci arka planı
	LevelBuilder.add_background_junkyard(self, 2260.0, "finale")

	# Tavan Giriş Borusu
	LevelBuilder.add_entry_pipe(self, 46.0, 28.0)

	# Koridor Tavanı ve Dış Duvarlar
	LevelBuilder.add_platform(self, Rect2(80, 12, 2080, 14), Color(1.0, 0.15, 0.6, 1.0))
	LevelBuilder.add_platform(self, Rect2(-16, -40, 16, 240))
	LevelBuilder.add_platform(self, Rect2(2156, -40, 24, 240))

	# Koridor Bölüm 1 (x: 0 -> 520, y = 148)
	LevelBuilder.add_platform(self, Rect2(0, 148, 520, 36), Color(0.0, 0.95, 1.0, 1.0))
	LevelBuilder.add_low_crouch_barrier(self, Rect2(190, 86, 52, 48))
	LevelBuilder.add_shock_strip(self, Rect2(310, 144, 28, 6))
	LevelBuilder.add_laser_gate(self, Vector2(420, 88), 60.0, 1.2, 1.0, 0.0)

	# Koridor Bölüm 2: Uçurum Üstü Kule ve Lazerli Geçit (x: 575 -> 1040)
	LevelBuilder.add_platform(self, Rect2(575, 148, 465, 36), Color(0.0, 0.95, 1.0, 1.0))
	LevelBuilder.add_moving_drone(self, Vector2(620, 134), Vector2(730, 134), 66.0)
	LevelBuilder.add_platform(self, Rect2(775, 92, 155, 92), Color(1.0, 0.25, 0.65, 1.0))
	LevelBuilder.add_low_crouch_barrier(self, Rect2(835, 30, 48, 48))
	LevelBuilder.add_laser_gate(self, Vector2(985, 88), 60.0, 1.15, 1.0, 0.5)

	# Koridor Bölüm 3: Güvenlik Çıkışı (x: 1095 -> 1550, y = 148)
	LevelBuilder.add_platform(self, Rect2(1095, 148, 455, 36), Color(0.1, 1.0, 0.65, 1.0))
	LevelBuilder.add_shock_strip(self, Rect2(1185, 144, 30, 6))
	LevelBuilder.add_low_crouch_barrier(self, Rect2(1275, 86, 54, 48))

	# Koridor Bölüm 4: EKSTRA KIRMIZI HALILI ANA GÜÇ KORİDORU (x: 1550 -> 2160)
	LevelBuilder.add_platform(self, Rect2(1550, 148, 610, 36), Color(1.0, 0.82, 0.18, 1.0))

	# Kırmızı Halı & Altın Şerit Detayları
	var carpet := ColorRect.new()
	carpet.z_index = 2
	carpet.position = Vector2(1556, 145)
	carpet.size = Vector2(586, 4)
	carpet.color = Color(0.78, 0.08, 0.18, 1.0)
	add_child(carpet)

	var gold_trim := ColorRect.new()
	gold_trim.z_index = 2
	gold_trim.position = Vector2(1556, 145)
	gold_trim.size = Vector2(586, 1)
	gold_trim.color = Color(1.0, 0.85, 0.25, 0.9)
	add_child(gold_trim)

	# Giriş Kemeri ("ANA GÜÇ ODASI")
	var arch_col := ColorRect.new()
	arch_col.z_index = -2
	arch_col.position = Vector2(1550, 26)
	arch_col.size = Vector2(10, 122)
	arch_col.color = Color(0.95, 0.72, 0.15, 0.85)
	add_child(arch_col)

	# Koridor boyunca sıralı neon sistem ışıkları (Fiş çekilince tek tek sönecek)
	var x: float = 85.0
	while x < 2080.0:
		var pillar := ColorRect.new()
		pillar.z_index = -5
		pillar.position = Vector2(x, 26)
		pillar.size = Vector2(8, 122)
		pillar.color = Color(1.0, 0.78, 0.18, 0.6) if x >= 1550.0 else Color(0.0, 0.9, 1.0, 0.55)
		add_child(pillar)
		neon_lights.append(pillar)
		x += 85.0

	# Duvar lambaları (Fiş çekilince yavaşça sönme animasyonu için)
	var lx: float = 130.0
	while lx < 2090.0:
		var is_power_room := lx >= 1550.0
		var halo := ColorRect.new()
		halo.z_index = -4
		halo.position = Vector2(lx - 11, 47)
		halo.size = Vector2(26, 26)
		halo.color = Color(1.0, 0.85, 0.35, 0.22) if is_power_room else Color(0.35, 0.88, 1.0, 0.2)
		add_child(halo)

		var bracket := ColorRect.new()
		bracket.z_index = -3
		bracket.position = Vector2(lx - 1, 52)
		bracket.size = Vector2(6, 4)
		bracket.color = Color(0.22, 0.24, 0.34, 1.0)
		add_child(bracket)

		var bulb := ColorRect.new()
		bulb.z_index = -3
		bulb.position = Vector2(lx - 2, 56)
		bulb.size = Vector2(8, 8)
		bulb.color = Color(1.0, 0.92, 0.45, 1.0) if is_power_room else Color(0.55, 0.95, 1.0, 1.0)
		add_child(bulb)

		wall_lamps.append({"bulb": bulb, "halo": halo})
		lx += 130.0

func _on_plug_pulled() -> void:
	GameManager.stop_walk_step()
	GameManager.stop_music()
	GameManager.play_sfx("lights_off")
	GameManager.emit_signal("status_message", "ANA FİŞ ÇEKİLDİ! SİSTEM GÜCÜ KESİLİYOR...")

	# Oyuncuyu sinematik boyunca sabitle ve geriye (Boss'a) döndür
	var player := get_node_or_null("Player") as CharacterBody2D
	if player != null:
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		var p_sprite := player.get_node_or_null("Sprite2D") as Sprite2D
		if p_sprite != null:
			p_sprite.flip_h = true
			p_sprite.frame = 0
		var p_cam := player.get_node_or_null("Camera2D") as Camera2D
		if p_cam != null:
			var tw_cam := create_tween()
			tw_cam.tween_property(p_cam, "position:x", -42.0, 0.7).set_trans(Tween.TRANS_SINE)

	# Sinematik siyah şeritler (Letterbox)
	var top_bar := ColorRect.new()
	top_bar.position = Vector2(0, -16)
	top_bar.size = Vector2(320, 16)
	top_bar.color = Color(0, 0, 0, 1)
	ending_layer.add_child(top_bar)
	ending_layer.move_child(top_bar, 0)

	var bot_bar := ColorRect.new()
	bot_bar.position = Vector2(0, 180)
	bot_bar.size = Vector2(320, 16)
	bot_bar.color = Color(0, 0, 0, 1)
	ending_layer.add_child(bot_bar)
	ending_layer.move_child(bot_bar, 1)

	var tw_bars := create_tween().set_parallel(true)
	tw_bars.tween_property(top_bar, "position:y", 0.0, 0.4)
	tw_bars.tween_property(bot_bar, "position:y", 164.0, 0.4)

	# Duvar lambaları fiş çekilirken yavaşça söner
	for lamp in wall_lamps:
		var bulb := lamp["bulb"] as ColorRect
		var halo := lamp["halo"] as ColorRect
		var tw_lamp := create_tween().set_parallel(true)
		tw_lamp.tween_property(bulb, "color", Color(0.08, 0.09, 0.14, 1.0), 1.4).set_trans(Tween.TRANS_SINE)
		tw_lamp.tween_property(halo, "color:a", 0.0, 1.4).set_trans(Tween.TRANS_SINE)

	# Koridor ışıkları sondan başa söner
	for i in range(neon_lights.size() - 1, -1, -1):
		neon_lights[i].color = Color(0.05, 0.05, 0.08, 0.3)
		await get_tree().create_timer(0.045).timeout

	# Kablo Boss'u kadraja girer!
	var boss_scene := preload("res://scenes/enemies/CableBoss.tscn")
	var boss := boss_scene.instantiate()
	boss.active = false
	boss.monitoring = false
	boss.monitorable = false
	boss.position = Vector2(1860.0, 102.0)
	add_child(boss)

	GameManager.emit_signal("status_message", "KABLO BOSS'U KADRAJA GİRDİ! AMA GÜÇ KESİLDİ!")
	var tw_boss := create_tween()
	tw_boss.tween_property(boss, "position:x", 2002.0, 1.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_boss.finished

	# Boss kıvılcımlar saçarak kısa devre yapar ve ölür
	GameManager.emit_signal("status_message", "KABLO BOSS'U KISA DEVRE YAPIP YOK OLUYOR!")
	await boss.play_death_cinematic()
	await get_tree().create_timer(0.6).timeout

	var tw := create_tween()
	tw.tween_property(blackout_rect, "color:a", 1.0, 0.95)
	await tw.finished

	# Gerçek Dünyaya Dönüş & Şaşırma Sinematiği
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	await _play_office_return_cinematic(top_bar, bot_bar)

	top_bar.queue_free()
	bot_bar.queue_free()

	# Harf harf yazılan kapanış hikayesi
	await _play_epilogue_story()

	# Altın Taçlı "KAZANDINIZ!" Ekranı
	real_world_panel.visible = true
	GameManager.play_victory()
	var crown := real_world_panel.get_node("HeroRoot/Crown") as Node2D
	var title := real_world_panel.get_node("VictoryTitle") as Label
	var hero := real_world_panel.get_node("HeroRoot") as Node2D
	hero.scale = Vector2(0.2, 0.2)
	var tw_in := create_tween()
	tw_in.tween_property(hero, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tw_crown := create_tween().set_loops()
	tw_crown.tween_property(crown, "position:y", -45.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw_crown.tween_property(crown, "position:y", -42.0, 0.5).set_trans(Tween.TRANS_SINE)
	var tw_title := create_tween().set_loops()
	tw_title.tween_property(title, "modulate", Color(1.3, 1.2, 0.7, 1.0), 0.45)
	tw_title.tween_property(title, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)
	game_completed = true

func _play_office_return_cinematic(top_bar: ColorRect, bot_bar: ColorRect) -> void:
	var cut := Control.new()
	cut.size = Vector2(320, 180)
	ending_layer.add_child(cut)
	ending_layer.move_child(cut, ending_layer.get_child_count() - 1)
	ending_layer.move_child(top_bar, ending_layer.get_child_count() - 1)
	ending_layer.move_child(bot_bar, ending_layer.get_child_count() - 1)

	var bg := ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0.06, 0.07, 0.12, 1.0)
	cut.add_child(bg)

	var floor_rect := ColorRect.new()
	floor_rect.position = Vector2(0, 132)
	floor_rect.size = Vector2(320, 48)
	floor_rect.color = Color(0.1, 0.11, 0.18, 1.0)
	cut.add_child(floor_rect)

	# Gece Penceresi
	var win := ColorRect.new()
	win.position = Vector2(32, 32)
	win.size = Vector2(60, 48)
	win.color = Color(0.03, 0.05, 0.11, 1.0)
	cut.add_child(win)
	var moon := ColorRect.new()
	moon.position = Vector2(74, 38)
	moon.size = Vector2(10, 10)
	moon.color = Color(0.8, 0.9, 1.0, 0.85)
	cut.add_child(moon)

	# Masa ve Kapanmış Monitör
	var table := ColorRect.new()
	table.position = Vector2(130, 108)
	table.size = Vector2(80, 6)
	table.color = Color(0.28, 0.22, 0.18, 1.0)
	cut.add_child(table)
	for lx in [134.0, 200.0]:
		var leg := ColorRect.new()
		leg.position = Vector2(lx, 114)
		leg.size = Vector2(6, 18)
		leg.color = Color(0.2, 0.16, 0.14, 1.0)
		cut.add_child(leg)

	var mon_frame := ColorRect.new()
	mon_frame.position = Vector2(154, 78)
	mon_frame.size = Vector2(30, 26)
	mon_frame.color = Color(0.18, 0.2, 0.28, 1.0)
	cut.add_child(mon_frame)

	var mon_off := ColorRect.new()
	mon_off.position = Vector2(157, 81)
	mon_off.size = Vector2(24, 20)
	mon_off.color = Color(0.05, 0.06, 0.09, 1.0)
	cut.add_child(mon_off)

	# Karakter monitörden fırlayıp yere düşer
	var worker := Sprite2D.new()
	worker.texture = preload("res://assets/sprites/player.png")
	worker.position = Vector2(169, 91)
	worker.scale = Vector2(0.1, 0.1)
	cut.add_child(worker)

	var bubble := Label.new()
	bubble.position = Vector2(118, 86)
	bubble.size = Vector2(48, 14)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.add_theme_font_size_override("font_size", 8)
	bubble.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	bubble.text = ""
	cut.add_child(bubble)

	var sub := Label.new()
	sub.position = Vector2(14, 20)
	sub.size = Vector2(292, 34)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 7)
	sub.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	sub.text = "GERÇEK DÜNYAYA DÖNÜŞ..."
	cut.add_child(sub)

	var fade := ColorRect.new()
	fade.size = Vector2(320, 180)
	fade.color = Color(0.8, 0.98, 1.0, 1.0)
	cut.add_child(fade)

	var tw_f := create_tween()
	tw_f.tween_property(fade, "color:a", 0.0, 0.65)
	await tw_f.finished

	# Monitörden dışarı fırlama
	GameManager.play_sfx("bounce")
	var tw_pop := create_tween().set_parallel(true)
	tw_pop.tween_property(worker, "position", Vector2(138, 115), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_pop.tween_property(worker, "scale", Vector2(1.45, 1.45), 0.65)
	tw_pop.tween_property(worker, "rotation_degrees", 360.0, 0.65)
	await tw_pop.finished
	worker.rotation_degrees = 0.0

	# Şaşkınlıkla etrafa bakma (! / ?)
	sub.text = "Ne?! Ofise geri mi döndüm?!"
	bubble.text = "!?"
	await get_tree().create_timer(1.15).timeout
	worker.flip_h = true
	bubble.text = "?!"
	await get_tree().create_timer(1.0).timeout
	worker.flip_h = false
	bubble.text = "!"
	sub.text = "Monitör tamamen kapandı... Başardım!"
	var tw_hop := create_tween()
	tw_hop.tween_property(worker, "position:y", 106.0, 0.16)
	tw_hop.tween_property(worker, "position:y", 115.0, 0.16)
	await tw_hop.finished
	await get_tree().create_timer(1.6).timeout

	var tw_end := create_tween()
	tw_end.tween_property(fade, "color:a", 1.0, 0.65)
	tw_end.parallel().tween_property(fade, "color", Color(0, 0, 0, 1), 0.65)
	await tw_end.finished
	cut.queue_free()

func _play_epilogue_story() -> void:
	var panel := ColorRect.new()
	panel.size = Vector2(320, 180)
	panel.color = Color(0.02, 0.03, 0.07, 1.0)
	ending_layer.add_child(panel)

	var border := ColorRect.new()
	border.position = Vector2(16, 16)
	border.size = Vector2(288, 148)
	border.color = Color(0.06, 0.09, 0.16, 0.96)
	panel.add_child(border)

	var accent := ColorRect.new()
	accent.position = Vector2(16, 16)
	accent.size = Vector2(288, 3)
	accent.color = Color(1.0, 0.82, 0.25, 1.0)
	panel.add_child(accent)

	var header := Label.new()
	header.position = Vector2(26, 24)
	header.size = Vector2(268, 16)
	header.text = "SONSÖZ — GERÇEK DÜNYAYA DÖNÜŞ"
	header.add_theme_font_size_override("font_size", 8)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 1.0))
	panel.add_child(header)

	epilogue_body = Label.new()
	epilogue_body.position = Vector2(26, 42)
	epilogue_body.size = Vector2(268, 96)
	epilogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epilogue_body.add_theme_font_size_override("font_size", 8)
	epilogue_body.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
	epilogue_body.text = "Panda PO ana güç fişini çektiği an Kablo Boss'unun tüm devresi çöktü.\nDijital kabus karanlığa gömülürken ofisindeki monitör de sonsuza dek sustu.\n\nArtık hem gerçek dünya hem de ofisteki sistem güvende...\nBambu çayını alıp eve dönme vakti geldi kahraman PO!"
	epilogue_body.visible_characters = 0
	panel.add_child(epilogue_body)

	epilogue_prompt = Label.new()
	epilogue_prompt.position = Vector2(26, 142)
	epilogue_prompt.size = Vector2(268, 14)
	epilogue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	epilogue_prompt.add_theme_font_size_override("font_size", 8)
	epilogue_prompt.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0, 1.0))
	epilogue_prompt.text = "[E / SPACE] Tamamla"
	epilogue_prompt.visible = false
	panel.add_child(epilogue_prompt)

	epilogue_typing_done = false
	epilogue_char_timer = 0.0
	epilogue_active = true
	await epilogue_finished
	epilogue_active = false
	panel.queue_free()

func _process(delta: float) -> void:
	if not epilogue_active or epilogue_typing_done or epilogue_body == null:
		return
	epilogue_char_timer += delta
	var total := epilogue_body.get_total_character_count()
	while epilogue_char_timer >= 0.028 and epilogue_body.visible_characters < total:
		epilogue_char_timer -= 0.028
		epilogue_body.visible_characters += 1
		if epilogue_body.visible_characters % 3 == 0:
			GameManager.play_sfx("story_text", 0.12)
	if epilogue_body.visible_characters >= total:
		epilogue_typing_done = true
		if epilogue_prompt != null:
			epilogue_prompt.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if epilogue_active and (event.is_action_pressed("jump") or event.is_action_pressed("interact")):
		if not epilogue_typing_done and epilogue_body != null:
			epilogue_body.visible_characters = epilogue_body.get_total_character_count()
			epilogue_typing_done = true
			if epilogue_prompt != null:
				epilogue_prompt.visible = true
		else:
			epilogue_finished.emit()
		return
	if game_completed and (event.is_action_pressed("jump") or event.is_action_pressed("interact")):
		GameManager.go_to_main_menu()
