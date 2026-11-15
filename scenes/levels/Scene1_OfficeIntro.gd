extends Node2D

@onready var worker_sprite: Sprite2D = $WorkerSprite
@onready var monitor_screen: ColorRect = $Desk/MonitorScreen
@onready var story_label: Label = $UI/StoryLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var flash_rect: ColorRect = $UI/FlashRect
@onready var help_panel: Control = $UI/HelpPanel
@onready var title_label: Label = $UI/TitleLabel

const PROLOGUE_PAGES: Array[String] = [
	"YIL 2026 — SAAT 23:45 // PO'NUN GECE MESAİSİ\n\nŞirketin en üst katındaki sunucu ofisinde herkes çoktan evine dönmüştü. Geriye sadece çalışkan ve sevimli sistem mühendisi panda PO kalmıştı.\n\nPO, elinde sıcak bambu çayıyla ofise adım attı ve her zamanki gibi gece raporlarını kapatıp eve gitmeyi planlıyordu...",
	"GİZEMLİ ARIZA: 0xB0U-NC3\n\nDışarıda yağmur camlara vururken, yıllardır kimsenin dokunmaya cesaret edemediği eski ana bilgisayarın fanları birden çılgınca dönmeye başladı.\n\nMonitörden neon kıvılcımlar sıçrıyor, ekranda garip bir hata kodu yanıp sönüyordu: 0xB0U-NC3!",
	"DİJİTAL ÇÖPLÜĞE YOLCULUK\n\nBu sıradan bir yazılım hatası değildi! Bilgisayarın içinde unutulmuş hurda devreler, dijital böcekler ve dev Kablo Boss'u uyanmıştı.\n\nPO'nun gerçek dünyaya geri dönebilmesi için sistemin kalbine inip ana güç fişini çekmesi gerekiyordu... Ama PO henüz başına geleceklerden habersiz, masasına yürüyordu."
]

var cam: Camera2D
var error_lbl: Label
var vortex_ring: Polygon2D
var spark_lines: Array[Line2D] = []
var top_bar: ColorRect
var bottom_bar: ColorRect
var lamp_glow: ColorRect
var alarm_overlay: ColorRect

var prologue_panel: Control
var prologue_title: Label
var prologue_body: Label
var prologue_prompt: Label
var prologue_active: bool = true
var prologue_page: int = 0
var typing_done: bool = false
var type_acc: float = 0.0
var last_char_count: int = 0

var shake_amount: float = 0.0
var is_walking_in: bool = false
var is_glitching: bool = false
var is_sucking: bool = false
var skipped: bool = false
var time_acc: float = 0.0
var step_timer: float = 0.0

func _ready() -> void:
	GameManager.reset_for_new_game()
	LevelBuilder.add_neon_environment(self)
	help_panel.visible = false
	title_label.visible = false
	story_label.visible = false
	hint_label.visible = false

	# Ofis sahnesinde karakteri orantılı olarak büyüt (1.45x, ayaklar zeminde y=132)
	worker_sprite.scale = Vector2(1.45, 1.45)
	worker_sprite.position = Vector2(24.0, 115.0)

	_build_cinematic_props()
	_build_prologue_ui()
	_start_prologue_page(0)

func _build_prologue_ui() -> void:
	prologue_panel = Control.new()
	prologue_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(prologue_panel)

	var bg := ColorRect.new()
	bg.size = Vector2(320, 180)
	bg.color = Color(0.025, 0.025, 0.065, 0.98)
	prologue_panel.add_child(bg)

	var border := ColorRect.new()
	border.position = Vector2(14, 12)
	border.size = Vector2(292, 156)
	border.color = Color(0.0, 0.88, 1.0, 0.85)
	prologue_panel.add_child(border)

	var inner := ColorRect.new()
	inner.position = Vector2(16, 14)
	inner.size = Vector2(288, 152)
	inner.color = Color(0.04, 0.045, 0.11, 0.98)
	prologue_panel.add_child(inner)

	prologue_title = Label.new()
	prologue_title.position = Vector2(22, 19)
	prologue_title.size = Vector2(276, 14)
	prologue_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prologue_title.add_theme_font_size_override("font_size", 8)
	prologue_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.75, 1.0))
	prologue_title.text = "BÖLÜM 0 — HİKAYE (1/2)"
	prologue_panel.add_child(prologue_title)

	prologue_body = Label.new()
	prologue_body.position = Vector2(24, 36)
	prologue_body.size = Vector2(272, 108)
	prologue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prologue_body.add_theme_font_size_override("font_size", 6)
	prologue_body.add_theme_constant_override("line_spacing", 2)
	prologue_body.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
	prologue_panel.add_child(prologue_body)

	prologue_prompt = Label.new()
	prologue_prompt.position = Vector2(22, 148)
	prologue_prompt.size = Vector2(276, 14)
	prologue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prologue_prompt.add_theme_font_size_override("font_size", 7)
	prologue_prompt.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
	prologue_prompt.text = "[E] veya [SPACE] Hızlandır"
	prologue_panel.add_child(prologue_prompt)

func _start_prologue_page(idx: int) -> void:
	prologue_page = idx
	typing_done = false
	type_acc = 0.0
	last_char_count = 0
	prologue_title.text = "BÖLÜM 0 — PO'NUN HİKAYESİ (%d/%d)" % [idx + 1, PROLOGUE_PAGES.size()]
	prologue_body.text = PROLOGUE_PAGES[idx]
	prologue_body.visible_characters = 0
	prologue_prompt.text = "[E] veya [SPACE] Metni Tamamla"

func _build_cinematic_props() -> void:
	cam = Camera2D.new()
	cam.position = Vector2(160.0, 90.0)
	add_child(cam)

	# Ofis Gece Penceresi
	var win_frame := ColorRect.new()
	win_frame.position = Vector2(28, 30)
	win_frame.size = Vector2(64, 52)
	win_frame.color = Color(0.14, 0.16, 0.25, 1.0)
	add_child(win_frame)
	move_child(win_frame, 1)

	var win_glass := ColorRect.new()
	win_glass.position = Vector2(31, 33)
	win_glass.size = Vector2(58, 46)
	win_glass.color = Color(0.03, 0.05, 0.12, 1.0)
	add_child(win_glass)
	move_child(win_glass, 2)

	var moon := ColorRect.new()
	moon.position = Vector2(72, 38)
	moon.size = Vector2(10, 10)
	moon.color = Color(0.75, 0.88, 1.0, 0.85)
	add_child(moon)
	move_child(moon, 3)

	# Tavan Ofis Lambası
	var lamp_cord := ColorRect.new()
	lamp_cord.position = Vector2(167, 0)
	lamp_cord.size = Vector2(2, 26)
	lamp_cord.color = Color(0.2, 0.22, 0.3, 1.0)
	add_child(lamp_cord)

	var lamp_hood := ColorRect.new()
	lamp_hood.position = Vector2(158, 26)
	lamp_hood.size = Vector2(20, 6)
	lamp_hood.color = Color(0.25, 0.28, 0.38, 1.0)
	add_child(lamp_hood)

	lamp_glow = ColorRect.new()
	lamp_glow.position = Vector2(142, 32)
	lamp_glow.size = Vector2(52, 100)
	lamp_glow.color = Color(1.0, 0.92, 0.65, 0.07)
	add_child(lamp_glow)

	# Masaüstü Kasa ve Kahve Kupası
	var pc_case := ColorRect.new()
	pc_case.position = Vector2(189, 86)
	pc_case.size = Vector2(16, 22)
	pc_case.color = Color(0.14, 0.16, 0.24, 1.0)
	add_child(pc_case)

	var pc_led := ColorRect.new()
	pc_led.position = Vector2(192, 90)
	pc_led.size = Vector2(3, 3)
	pc_led.color = Color(0.1, 1.0, 0.55, 1.0)
	add_child(pc_led)

	var mug := ColorRect.new()
	mug.position = Vector2(146, 103)
	mug.size = Vector2(5, 5)
	mug.color = Color(0.85, 0.85, 0.9, 1.0)
	add_child(mug)

	error_lbl = Label.new()
	error_lbl.position = Vector2(156, 84)
	error_lbl.size = Vector2(26, 14)
	error_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_lbl.add_theme_font_size_override("font_size", 5)
	error_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	error_lbl.text = "OK"
	add_child(error_lbl)

	vortex_ring = Polygon2D.new()
	vortex_ring.position = Vector2(169, 91)
	vortex_ring.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(10, -10), Vector2(14, 0), Vector2(10, 10),
		Vector2(0, 14), Vector2(-10, 10), Vector2(-14, 0), Vector2(-10, -10)
	])
	vortex_ring.color = Color(0.0, 0.95, 1.0, 0.0)
	vortex_ring.scale = Vector2(0.2, 0.2)
	add_child(vortex_ring)

	for i in range(4):
		var line := Line2D.new()
		line.width = 1.5
		line.default_color = Color(0.0, 1.0, 1.0, 0.9) if i % 2 == 0 else Color(1.0, 0.2, 0.65, 0.9)
		line.visible = false
		add_child(line)
		spark_lines.append(line)

	var ui_layer := $UI
	alarm_overlay = ColorRect.new()
	alarm_overlay.size = Vector2(320, 180)
	alarm_overlay.color = Color(1.0, 0.08, 0.3, 0.0)
	alarm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(alarm_overlay)
	ui_layer.move_child(alarm_overlay, 0)

	top_bar = ColorRect.new()
	top_bar.position = Vector2(0, -18)
	top_bar.size = Vector2(320, 18)
	top_bar.color = Color(0.0, 0.0, 0.0, 1.0)
	ui_layer.add_child(top_bar)
	ui_layer.move_child(top_bar, 1)

	bottom_bar = ColorRect.new()
	bottom_bar.position = Vector2(0, 180)
	bottom_bar.size = Vector2(320, 22)
	bottom_bar.color = Color(0.0, 0.0, 0.0, 1.0)
	ui_layer.add_child(bottom_bar)
	ui_layer.move_child(bottom_bar, 2)

	story_label.position = Vector2(16, 20)
	story_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	story_label.add_theme_constant_override("outline_size", 2)

	hint_label.position = Vector2(20, 163)
	hint_label.add_theme_font_size_override("font_size", 6)
	hint_label.text = "[SPACE / E] Sahneyi Geç"

func _process(delta: float) -> void:
	time_acc += delta

	# Hikaye sayfası harf harf yazma (Typewriter)
	if prologue_active and not typing_done:
		type_acc += delta * 34.0
		var total := prologue_body.get_total_character_count()
		var target := mini(int(type_acc), total)
		if target > last_char_count:
			prologue_body.visible_characters = target
			if target % 3 == 0:
				GameManager.play_sfx("story_text", 0.12)
			last_char_count = target
		if target >= total:
			typing_done = true
			prologue_prompt.text = "[E] veya [SPACE] Sonraki Sayfa ►" if prologue_page < PROLOGUE_PAGES.size() - 1 else "[E] veya [SPACE] Ofise Geç ►"
		return

	if shake_amount > 0.0:
		cam.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
	else:
		cam.offset = Vector2.ZERO

	if is_walking_in:
		var walk_wave := sin(time_acc * 18.0)
		worker_sprite.position.y = 115.0 - abs(walk_wave) * 2.0
		worker_sprite.rotation_degrees = walk_wave * 4.5
		step_timer -= delta
		if step_timer <= 0.0:
			GameManager.play_walk_step(0.08)
			step_timer = 0.17

	if is_glitching:
		monitor_screen.color = Color(1.0, 0.1, 0.45, 1.0) if int(time_acc * 18.0) % 2 == 0 else Color(0.0, 0.95, 1.0, 1.0)
		error_lbl.text = "ERR!" if int(time_acc * 12.0) % 2 == 0 else "0xB0"
		lamp_glow.color.a = 0.02 if int(time_acc * 14.0) % 2 == 0 else 0.12
		alarm_overlay.color.a = 0.09 if int(time_acc * 8.0) % 2 == 0 else 0.02

	if is_sucking:
		vortex_ring.rotation_degrees += 320.0 * delta
		for i in range(spark_lines.size()):
			var line := spark_lines[i]
			line.visible = true
			var mid := worker_sprite.position.lerp(Vector2(169, 91), 0.5) + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			line.points = PackedVector2Array([Vector2(169, 91), mid, worker_sprite.position])

func _unhandled_input(event: InputEvent) -> void:
	if prologue_active:
		if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
			if not typing_done:
				typing_done = true
				prologue_body.visible_characters = -1
				prologue_prompt.text = "[E] veya [SPACE] Sonraki Sayfa ►" if prologue_page < PROLOGUE_PAGES.size() - 1 else "[E] veya [SPACE] Ofise Geç ►"
			elif prologue_page < PROLOGUE_PAGES.size() - 1:
				GameManager.play_sfx("click")
				_start_prologue_page(prologue_page + 1)
			else:
				GameManager.play_sfx("click")
				prologue_active = false
				var tw_p := create_tween()
				tw_p.tween_property(prologue_panel, "modulate:a", 0.0, 0.4)
				await tw_p.finished
				prologue_panel.visible = false
				_play_cutscene()
		return

	if skipped:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		skipped = true
		GameManager.stop_walk_step()
		GameManager.set_checkpoint_and_load_level("res://scenes/levels/Level1_Junkyard.tscn")

func _play_cutscene() -> void:
	story_label.visible = true
	hint_label.visible = true

	var tw_bars := create_tween().set_parallel(true)
	tw_bars.tween_property(top_bar, "position:y", 0.0, 0.45)
	tw_bars.tween_property(bottom_bar, "position:y", 158.0, 0.45)

	# AŞAMA 1: Panda PO ofise normal bir şekilde yürüyerek gelir
	is_walking_in = true
	story_label.text = "ŞİRKET OFİSİ — 23:45\nPanda PO için sıradan bir gece mesaisi gibi başlamıştı..."
	var tw_walk := create_tween()
	tw_walk.tween_property(worker_sprite, "position:x", 136.0, 2.4)
	await tw_walk.finished
	is_walking_in = false
	GameManager.stop_walk_step()
	worker_sprite.position.y = 115.0
	worker_sprite.rotation_degrees = 0.0
	if skipped:
		return

	# AŞAMA 2: Masada normal çalışma
	story_label.text = "PO bilgisayarın başına geçti, gece raporlarını kontrol ediyordu..."
	var tw_bob := create_tween().set_loops(5)
	tw_bob.tween_property(worker_sprite, "position:y", 113.5, 0.25)
	tw_bob.tween_property(worker_sprite, "position:y", 115.0, 0.25)
	await get_tree().create_timer(2.6).timeout
	if skipped:
		return

	# AŞAMA 3: BİR ANDA Kritik Hata 0xB0U-NC3!
	is_glitching = true
	shake_amount = 1.8
	GameManager.play_sfx("attack_neon")
	story_label.text = "AMA BİR ANDA...\nKRİTİK HATA: 0xB0U-NC3! Sistem kontrolden çıkıyor!"
	var tw_zoom1 := create_tween().set_parallel(true)
	tw_zoom1.tween_property(cam, "zoom", Vector2(1.26, 1.26), 1.8).set_trans(Tween.TRANS_SINE)
	tw_zoom1.tween_property(cam, "position", Vector2(158.0, 96.0), 1.8).set_trans(Tween.TRANS_SINE)
	tw_zoom1.tween_property(worker_sprite, "position:x", 122.0, 0.5)
	await get_tree().create_timer(2.5).timeout
	if skipped:
		return

	# AŞAMA 4: Girdap Açılıyor ve Çekim Başlıyor!
	is_sucking = true
	shake_amount = 3.5
	GameManager.play_sfx("stun")
	story_label.text = "MONİTÖRDEN ÇIKAN NEON GİRDABI SENİ İÇİNE ÇEKİYOR!"
	var tw_vortex := create_tween().set_parallel(true)
	tw_vortex.tween_property(vortex_ring, "color:a", 0.85, 0.5)
	tw_vortex.tween_property(vortex_ring, "scale", Vector2(1.45, 1.45), 1.0)
	tw_vortex.tween_property(cam, "zoom", Vector2(1.52, 1.52), 1.5)
	tw_vortex.tween_property(cam, "position", Vector2(165.0, 92.0), 1.5)
	await get_tree().create_timer(1.5).timeout
	if skipped:
		return

	# AŞAMA 5: Bilgisayarın İçine Çekilme & Işık Patlaması
	hint_label.visible = false
	shake_amount = 5.0
	GameManager.play_sfx("bounce")
	var tw_suck := create_tween().set_parallel(true)
	tw_suck.tween_property(worker_sprite, "position", Vector2(169, 91), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_suck.tween_property(worker_sprite, "scale", Vector2(0.05, 0.05), 1.1)
	tw_suck.tween_property(worker_sprite, "rotation_degrees", 720.0, 1.1)
	tw_suck.tween_property(flash_rect, "color:a", 1.0, 1.15)
	await tw_suck.finished
	if skipped:
		return

	GameManager.set_checkpoint_and_load_level("res://scenes/levels/Level1_Junkyard.tscn")
