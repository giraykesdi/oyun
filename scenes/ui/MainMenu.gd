extends Control

@onready var start_btn: Button = $MainCard/StartBtn
@onready var audio_btn: Button = $MainCard/AudioBtn
@onready var help_btn: Button = $MainCard/HelpBtn
@onready var credits_btn: Button = $MainCard/CreditsBtn
@onready var quit_btn: Button = $MainCard/QuitBtn
@onready var audio_panel: Control = $AudioPanel
@onready var close_audio_btn: Button = $AudioPanel/CloseAudioBtn
@onready var music_slider: HSlider = $AudioPanel/MusicSlider
@onready var music_value: Label = $AudioPanel/MusicValue
@onready var sfx_slider: HSlider = $AudioPanel/SfxSlider
@onready var sfx_value: Label = $AudioPanel/SfxValue
@onready var help_panel: Control = $HelpPanel
@onready var close_help_btn: Button = $HelpPanel/CloseHelpBtn
@onready var credits_panel: Control = $CreditsPanel
@onready var close_credits_btn: Button = $CreditsPanel/CloseCreditsBtn
@onready var crt_overlay: ColorRect = $CRTOverlay
@onready var title_label: Label = $MainCard/TitleLabel
@onready var main_card: Control = $MainCard

var time_acc: float = 0.0
var fans: Array[Node2D] = []
var cpu_cores: Array[ColorRect] = []
var data_packets: Array[Dictionary] = []
var bg_particles: Array[Dictionary] = []
var mini_hero: Sprite2D

func _ready() -> void:
	GameManager.reset_for_new_game()
	audio_panel.visible = false
	help_panel.visible = false
	credits_panel.visible = false
	crt_overlay.visible = GameManager.crt_enabled
	GameManager.crt_toggled.connect(func(en: bool): crt_overlay.visible = en)

	_build_cyberpunk_backdrop()
	_style_buttons()

	start_btn.pressed.connect(_on_start_pressed)
	audio_btn.pressed.connect(_on_audio_pressed)
	help_btn.pressed.connect(_on_help_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	close_audio_btn.pressed.connect(func(): audio_panel.visible = false)
	close_help_btn.pressed.connect(func(): help_panel.visible = false)
	close_credits_btn.pressed.connect(func(): credits_panel.visible = false)

	music_slider.value = round(GameManager.music_volume * 100.0)
	sfx_slider.value = round(GameManager.sfx_volume * 100.0)
	music_value.text = str(int(music_slider.value)) + "%"
	sfx_value.text = str(int(sfx_slider.value)) + "%"
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	start_btn.grab_focus()
	for b in [start_btn, audio_btn, help_btn, credits_btn, quit_btn, close_audio_btn, close_help_btn, close_credits_btn]:
		b.pressed.connect(func(): GameManager.play_sfx("click"))

func _build_cyberpunk_backdrop() -> void:
	var fx_layer := Control.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx_layer)
	move_child(fx_layer, 1)

	# Arka plan anakart devre ızgarası (PCB Grid)
	for x in range(16, 320, 32):
		var vline := ColorRect.new()
		vline.position = Vector2(float(x), 0.0)
		vline.size = Vector2(1.0, 180.0)
		vline.color = Color(0.0, 0.75, 1.0, 0.06)
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(vline)
	for y in range(18, 180, 28):
		var hline := ColorRect.new()
		hline.position = Vector2(0.0, float(y))
		hline.size = Vector2(320.0, 1.0)
		hline.color = Color(0.0, 0.75, 1.0, 0.07)
		hline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(hline)

	# Sol ve Sağ Büyük İşlemci (CPU) Çipleri + Altın Pinler
	_add_menu_cpu(fx_layer, Vector2(28, 86), Color(0.0, 0.92, 1.0, 1.0))
	_add_menu_cpu(fx_layer, Vector2(292, 86), Color(1.0, 0.2, 0.65, 1.0))

	# Üst Köşelerde Dönen Soğutma Fanları
	_add_menu_fan(fx_layer, Vector2(28, 28), Color(0.0, 0.9, 1.0, 0.45))
	_add_menu_fan(fx_layer, Vector2(292, 28), Color(1.0, 0.25, 0.65, 0.45))

	# CPU'lardan Ana Karta Uzanan Parlak Veri Yolları ve Akan Veri Paketleri
	var paths := [
		{"y": 54.0,  "x0": 28.0,  "x1": 60.0,  "col": Color(0.0, 1.0, 1.0, 0.95), "speed": 42.0},
		{"y": 116.0, "x0": 28.0,  "x1": 60.0,  "col": Color(0.2, 1.0, 0.65, 0.95), "speed": 55.0},
		{"y": 54.0,  "x0": 292.0, "x1": 260.0, "col": Color(1.0, 0.2, 0.65, 0.95), "speed": 46.0},
		{"y": 116.0, "x0": 292.0, "x1": 260.0, "col": Color(1.0, 0.85, 0.2, 0.95), "speed": 52.0},
	]
	for p in paths:
		var track := ColorRect.new()
		track.position = Vector2(min(p["x0"], p["x1"]), p["y"])
		track.size = Vector2(abs(p["x1"] - p["x0"]), 1.5)
		track.color = Color(p["col"].r, p["col"].g, p["col"].b, 0.35)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(track)

		var pkt := ColorRect.new()
		pkt.size = Vector2(4, 3)
		pkt.position = Vector2(p["x0"], p["y"] - 0.8)
		pkt.color = p["col"]
		pkt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(pkt)
		data_packets.append({
			"node": pkt,
			"x0": p["x0"],
			"x1": p["x1"],
			"y": p["y"] - 0.8,
			"t": randf(),
			"speed": p["speed"]
		})

	# Yükselen Neon Piksel Parçacıkları
	for i in range(18):
		var dot := ColorRect.new()
		dot.size = Vector2(2, 2)
		dot.position = Vector2(randf_range(4.0, 316.0), randf_range(0.0, 178.0))
		dot.color = Color(0.0, 0.95, 1.0, 0.35) if i % 2 == 0 else Color(1.0, 0.25, 0.65, 0.35)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(dot)
		bg_particles.append({"node": dot, "speed": randf_range(10.0, 24.0)})

	# Ana Kart Üzerinde Neon Köşe Vurguları + Mini Kahraman Önizlemesi
	for corner_pos in [Vector2(42, 8), Vector2(270, 8), Vector2(42, 158), Vector2(270, 158)]:
		var corner := ColorRect.new()
		corner.position = corner_pos
		corner.size = Vector2(8, 8)
		corner.color = Color(1.0, 0.2, 0.65, 0.95)
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_card.add_child(corner)

	var title_line := ColorRect.new()
	title_line.position = Vector2(64, 32)
	title_line.size = Vector2(192, 1.5)
	title_line.color = Color(0.0, 0.95, 1.0, 0.65)
	title_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_card.add_child(title_line)

	mini_hero = Sprite2D.new()
	mini_hero.texture = preload("res://assets/sprites/player.png")
	mini_hero.position = Vector2(66, 23)
	mini_hero.scale = Vector2(0.85, 0.85)
	main_card.add_child(mini_hero)

func _add_menu_cpu(parent: Node, pos: Vector2, glow_col: Color) -> void:
	var cpu := Node2D.new()
	cpu.position = pos
	parent.add_child(cpu)

	var outer := ColorRect.new()
	outer.position = Vector2(-18, -18)
	outer.size = Vector2(36, 36)
	outer.color = Color(0.08, 0.1, 0.18, 0.95)
	cpu.add_child(outer)

	var border := ColorRect.new()
	border.position = Vector2(-15, -15)
	border.size = Vector2(30, 30)
	border.color = Color(glow_col.r, glow_col.g, glow_col.b, 0.25)
	cpu.add_child(border)

	var core := ColorRect.new()
	core.position = Vector2(-8, -8)
	core.size = Vector2(16, 16)
	core.color = Color(glow_col.r, glow_col.g, glow_col.b, 0.75)
	cpu.add_child(core)
	cpu_cores.append(core)

	# Altın CPU Pinleri
	for i in range(-14, 15, 5):
		for py in [-21.0, 18.0]:
			var pin := ColorRect.new()
			pin.position = Vector2(float(i), py)
			pin.size = Vector2(2, 3)
			pin.color = Color(1.0, 0.82, 0.2, 0.75)
			cpu.add_child(pin)
		for px in [-21.0, 18.0]:
			var pin_h := ColorRect.new()
			pin_h.position = Vector2(px, float(i))
			pin_h.size = Vector2(3, 2)
			pin_h.color = Color(1.0, 0.82, 0.2, 0.75)
			cpu.add_child(pin_h)

func _add_menu_fan(parent: Node, pos: Vector2, glow_col: Color) -> void:
	var frame := ColorRect.new()
	frame.position = pos - Vector2(13, 13)
	frame.size = Vector2(26, 26)
	frame.color = Color(0.07, 0.09, 0.16, 0.9)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)

	var rotor := Node2D.new()
	rotor.position = pos
	parent.add_child(rotor)
	fans.append(rotor)

	for a in [0.0, 90.0]:
		var blade := ColorRect.new()
		blade.position = Vector2(-10, -2)
		blade.size = Vector2(20, 4)
		blade.pivot_offset = Vector2(10, 2)
		blade.rotation_degrees = a
		blade.color = glow_col
		rotor.add_child(blade)

	var hub := ColorRect.new()
	hub.position = Vector2(-3, -3)
	hub.size = Vector2(6, 6)
	hub.color = Color(0.9, 0.95, 1.0, 0.85)
	rotor.add_child(hub)

func _style_buttons() -> void:
	_apply_btn_style(start_btn, Color(0.15, 1.0, 0.65, 1.0))
	_apply_btn_style(audio_btn, Color(0.2, 1.0, 0.85, 1.0))
	_apply_btn_style(help_btn, Color(1.0, 0.88, 0.25, 1.0))
	_apply_btn_style(credits_btn, Color(0.3, 0.9, 1.0, 1.0))
	_apply_btn_style(quit_btn, Color(1.0, 0.25, 0.45, 1.0))
	_apply_btn_style(close_audio_btn, Color(1.0, 0.88, 0.25, 1.0))
	_apply_btn_style(close_help_btn, Color(1.0, 0.88, 0.25, 1.0))
	_apply_btn_style(close_credits_btn, Color(0.2, 1.0, 0.7, 1.0))

func _apply_btn_style(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.09, 0.18, 0.95)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.75)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.28, 0.98)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(2)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.4, 1.0)
	pressed.border_color = Color(1, 1, 1, 1)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _process(delta: float) -> void:
	time_acc += delta * 3.0
	title_label.modulate = Color(
		0.25 + 0.2 * sin(time_acc),
		0.95,
		1.0,
		1.0
	)

	if mini_hero != null:
		mini_hero.position.y = 22.0 + sin(time_acc * 1.4) * 1.5

	for f in fans:
		f.rotation_degrees += 140.0 * delta

	for i in range(cpu_cores.size()):
		var pulse := 0.55 + 0.35 * sin(time_acc * 1.5 + float(i) * 1.6)
		cpu_cores[i].modulate.a = pulse

	for p in data_packets:
		p["t"] = fmod(p["t"] + delta * (p["speed"] / 40.0), 1.0)
		var px: float = lerpf(p["x0"], p["x1"], p["t"])
		p["node"].position.x = px

	for pt in bg_particles:
		var n: ColorRect = pt["node"]
		n.position.y -= pt["speed"] * delta
		if n.position.y < -4.0:
			n.position.y = 182.0
			n.position.x = randf_range(4.0, 316.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_help"):
		audio_panel.visible = false
		credits_panel.visible = false
		help_panel.visible = !help_panel.visible
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if audio_panel.visible or help_panel.visible or credits_panel.visible:
				audio_panel.visible = false
				help_panel.visible = false
				credits_panel.visible = false
				get_viewport().set_input_as_handled()

func _on_start_pressed() -> void:
	GameManager.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/levels/Scene1_OfficeIntro.tscn")

func _on_audio_pressed() -> void:
	help_panel.visible = false
	credits_panel.visible = false
	audio_panel.visible = true
	close_audio_btn.grab_focus()

func _on_help_pressed() -> void:
	audio_panel.visible = false
	credits_panel.visible = false
	help_panel.visible = true
	close_help_btn.grab_focus()

func _on_credits_pressed() -> void:
	audio_panel.visible = false
	help_panel.visible = false
	credits_panel.visible = true
	close_credits_btn.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_music_slider_changed(val: float) -> void:
	music_value.text = str(int(val)) + "%"
	GameManager.set_music_volume(val / 100.0)

func _on_sfx_slider_changed(val: float) -> void:
	sfx_value.text = str(int(val)) + "%"
	GameManager.set_sfx_volume(val / 100.0)
