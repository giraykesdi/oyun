extends Area2D

signal plug_pulled

@onready var sprite: Sprite2D = $Sprite2D

var is_pulled: bool = false
var sway_active: bool = false
var sway_time: float = 0.0

var plug_head: Node2D
var cable_line: Line2D
var cable_core: Line2D
var led_light: ColorRect
var cable_anchor := Vector2(-6.0, -104.0)

func _ready() -> void:
	_build_plug_details()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_plug_details() -> void:
	# Tavan bağlantı kutusu
	var ceiling_box := ColorRect.new()
	ceiling_box.position = Vector2(-13, -106)
	ceiling_box.size = Vector2(14, 8)
	ceiling_box.color = Color(0.2, 0.25, 0.36, 1.0)
	add_child(ceiling_box)

	# Duvar Prizi (Sağ tarafta, fiş buna takılı)
	var socket_frame := ColorRect.new()
	socket_frame.position = Vector2(10, -16)
	socket_frame.size = Vector2(18, 32)
	socket_frame.color = Color(0.16, 0.2, 0.3, 1.0)
	add_child(socket_frame)

	var socket_inner := ColorRect.new()
	socket_inner.position = Vector2(13, -12)
	socket_inner.size = Vector2(12, 24)
	socket_inner.color = Color(0.06, 0.07, 0.12, 1.0)
	add_child(socket_inner)

	# Priz delikleri
	for hy in [-6.0, 4.0]:
		var hole := ColorRect.new()
		hole.position = Vector2(16, hy)
		hole.size = Vector2(5, 3)
		hole.color = Color(0.02, 0.02, 0.04, 1.0)
		add_child(hole)

	# Priz Güç LED'i
	led_light = ColorRect.new()
	led_light.position = Vector2(17, -15)
	led_light.size = Vector2(4, 2)
	led_light.color = Color(0.1, 1.0, 0.65, 1.0)
	add_child(led_light)

	# Üstten bağlı kalın kablo (Line2D)
	cable_line = Line2D.new()
	cable_line.width = 5.0
	cable_line.default_color = Color(0.1, 0.12, 0.18, 1.0)
	add_child(cable_line)

	cable_core = Line2D.new()
	cable_core.width = 1.6
	cable_core.default_color = Color(0.0, 0.95, 1.0, 0.9)
	add_child(cable_core)

	# Fiş başlığı düğümü (Sprite + metal uçlar)
	plug_head = Node2D.new()
	plug_head.position = Vector2(0, 0)
	add_child(plug_head)

	# Sprite2D'yi plug_head içine taşı
	remove_child(sprite)
	plug_head.add_child(sprite)
	sprite.position = Vector2.ZERO

	# Metal fiş dişleri (sağa doğru prize girer)
	for py in [-5.0, 3.0]:
		var prong := ColorRect.new()
		prong.position = Vector2(12, py)
		prong.size = Vector2(6, 2)
		prong.color = Color(0.85, 0.9, 0.98, 1.0)
		plug_head.add_child(prong)

	_update_cable_curve()

func _update_cable_curve() -> void:
	if cable_line == null or plug_head == null:
		return
	var end_pt := plug_head.position + Vector2(-8.0, 0.0).rotated(plug_head.rotation)
	var mid_pt := cable_anchor.lerp(end_pt, 0.55) + Vector2(-12.0, 6.0)
	var pts := PackedVector2Array([
		cable_anchor,
		cable_anchor.lerp(mid_pt, 0.5),
		mid_pt,
		mid_pt.lerp(end_pt, 0.5),
		end_pt
	])
	cable_line.points = pts
	cable_core.points = pts

func _process(delta: float) -> void:
	if sway_active:
		sway_time += delta * 2.6
		plug_head.position.x = -18.0 + sin(sway_time) * 4.5
		plug_head.rotation_degrees = -78.0 + sin(sway_time) * 10.0
	_update_cable_curve()

func get_interaction_prompt() -> String:
	if is_pulled:
		return "SİSTEM GÜCÜ KESİLDİ..."
	return "[E] Ana Güç Fişini Çek (Gerçek Hayata Dön!)"

func interact(player: Node) -> void:
	if is_pulled:
		return
	is_pulled = true
	if player.has_method("unregister_interactable"):
		player.unregister_interactable(self)
	GameManager.request_screen_shake(5.0, 0.4)
	GameManager.play_sfx("plug")

	# Priz LED'ini ve kablo enerjisini kapat
	led_light.color = Color(0.25, 0.08, 0.1, 1.0)
	cable_core.default_color = Color(0.18, 0.22, 0.28, 0.5)
	_spawn_pull_sparks()

	# Fişi prizden çıkarıp kablodan aşağı doğru sarktırma animasyonu
	var tw := create_tween()
	tw.tween_property(plug_head, "position:x", -16.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(plug_head, "position", Vector2(-18.0, 9.0), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(plug_head, "rotation_degrees", -78.0, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func(): sway_active = true)

	emit_signal("plug_pulled")

func _spawn_pull_sparks() -> void:
	for i in range(10):
		var sp := ColorRect.new()
		sp.size = Vector2(2, 2)
		sp.color = Color(1.0, 0.92, 0.2, 1.0) if i % 2 == 0 else Color(0.0, 0.95, 1.0, 1.0)
		sp.position = Vector2(12, randf_range(-8, 8))
		add_child(sp)
		var tw := sp.create_tween().set_parallel(true)
		tw.tween_property(sp, "position", sp.position + Vector2(randf_range(-28, 10), randf_range(-24, 18)), 0.4)
		tw.tween_property(sp, "modulate:a", 0.0, 0.4)
		tw.chain().tween_callback(sp.queue_free)

func _on_body_entered(body: Node) -> void:
	if not is_pulled and body.is_in_group("player") and body.has_method("register_interactable"):
		body.register_interactable(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
