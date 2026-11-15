extends Area2D

@export var cable_height: float = 96.0
@export var is_broken: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var cable_rect: ColorRect = $CableVisual
@onready var core_line: ColorRect = $CoreVisual
@onready var broken_gap: ColorRect = $BrokenGapVisual
@onready var tape_patch: ColorRect = $TapePatchVisual

var rungs_root: Node2D
var copper_root: Node2D
var spark_lines: Array[Line2D] = []
var spark_timer: float = 0.0

func _ready() -> void:
	_setup_geometry()
	_update_visual_state()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_geometry() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22.0, cable_height + 16.0)
	collision_shape.shape = shape
	collision_shape.position = Vector2(0.0, cable_height * 0.5 - 4.0)

	cable_rect.position = Vector2(-6.0, 0.0)
	cable_rect.size = Vector2(12.0, cable_height)

	core_line.position = Vector2(-1.5, 0.0)
	core_line.size = Vector2(3.0, cable_height)

	if rungs_root != null:
		rungs_root.queue_free()
	rungs_root = Node2D.new()
	add_child(rungs_root)
	move_child(rungs_root, 2)

	# Sol ve sağ tırmanma rayları
	var left_rail := ColorRect.new()
	left_rail.position = Vector2(-6.0, 0.0)
	left_rail.size = Vector2(2.0, cable_height)
	left_rail.color = Color(0.28, 0.38, 0.56, 1.0)
	rungs_root.add_child(left_rail)

	var right_rail := ColorRect.new()
	right_rail.position = Vector2(4.0, 0.0)
	right_rail.size = Vector2(2.0, cable_height)
	right_rail.color = Color(0.28, 0.38, 0.56, 1.0)
	rungs_root.add_child(right_rail)

	# Üst ve alt platform montaj kelepçeleri
	var top_bracket := ColorRect.new()
	top_bracket.position = Vector2(-8.0, -2.0)
	top_bracket.size = Vector2(16.0, 4.0)
	top_bracket.color = Color(0.0, 0.9, 1.0, 0.95)
	rungs_root.add_child(top_bracket)

	var bottom_bracket := ColorRect.new()
	bottom_bracket.position = Vector2(-8.0, cable_height - 3.0)
	bottom_bracket.size = Vector2(16.0, 4.0)
	bottom_bracket.color = Color(0.22, 0.32, 0.48, 1.0)
	rungs_root.add_child(bottom_bracket)

	# Yatay tırmanma basamakları (Her 8 pikselde bir)
	var y_pos: float = 6.0
	while y_pos < cable_height - 4.0:
		var rung := ColorRect.new()
		rung.position = Vector2(-5.0, y_pos)
		rung.size = Vector2(10.0, 2.0)
		rung.color = Color(0.38, 0.55, 0.78, 0.9)
		rungs_root.add_child(rung)
		y_pos += 8.0

	var mid_y: float = cable_height * 0.5
	broken_gap.position = Vector2(-7.0, mid_y - 10.0)
	broken_gap.size = Vector2(14.0, 20.0)
	broken_gap.color = Color(0.03, 0.04, 0.08, 0.96)

	# Kopmuş yerde açıkta kalan bakır teller ve kıvılcımlar
	if copper_root != null:
		copper_root.queue_free()
	copper_root = Node2D.new()
	broken_gap.add_child(copper_root)
	spark_lines.clear()

	var wire_xs: Array[float] = [3.0, 6.5, 10.0]
	for i in range(wire_xs.size()):
		var wx: float = wire_xs[i]
		# Üstten sarkan bakır tel
		var top_wire := ColorRect.new()
		top_wire.position = Vector2(wx, 0.0)
		top_wire.size = Vector2(1.5, 7.0 + float(i % 2) * 2.0)
		top_wire.color = Color(0.9, 0.48, 0.16, 1.0)
		copper_root.add_child(top_wire)

		# Alttan çıkan bakır tel
		var bot_wire := ColorRect.new()
		var bh: float = 6.0 + float((i + 1) % 2) * 2.5
		bot_wire.position = Vector2(wx, 20.0 - bh)
		bot_wire.size = Vector2(1.5, bh)
		bot_wire.color = Color(0.95, 0.58, 0.22, 1.0)
		copper_root.add_child(bot_wire)

	for s in range(3):
		var sl := Line2D.new()
		sl.width = 1.2
		sl.default_color = Color(0.35, 0.95, 1.0, 0.95) if s % 2 == 0 else Color(1.0, 0.92, 0.3, 0.95)
		copper_root.add_child(sl)
		spark_lines.append(sl)

	tape_patch.position = Vector2(-7.0, mid_y - 11.0)
	tape_patch.size = Vector2(14.0, 22.0)

func _process(delta: float) -> void:
	if not is_broken or spark_lines.is_empty():
		return
	spark_timer -= delta
	if spark_timer <= 0.0:
		spark_timer = 0.07
		for i in range(spark_lines.size()):
			var sl: Line2D = spark_lines[i]
			sl.visible = randf() > 0.25
			if sl.visible:
				var sx: float = randf_range(2.5, 11.5)
				var sy: float = randf_range(4.0, 7.0)
				var ex: float = randf_range(2.5, 11.5)
				var ey: float = randf_range(13.0, 16.0)
				sl.points = PackedVector2Array([
					Vector2(sx, sy),
					Vector2((sx + ex) * 0.5 + randf_range(-3.0, 3.0), randf_range(8.5, 11.5)),
					Vector2(ex, ey)
				])

func _update_visual_state() -> void:
	if is_broken:
		core_line.color = Color(1.0, 0.22, 0.28, 0.95)
		broken_gap.visible = true
		tape_patch.visible = false
	else:
		core_line.color = Color(0.0, 0.95, 1.0, 0.95)
		broken_gap.visible = false

func is_climb_enabled() -> bool:
	return not is_broken

func get_interaction_prompt() -> String:
	if not is_broken:
		return "[W / S] Tırman"
	if GameManager.has_item("cable_tape"):
		return "[E] Kopuk Kabloyu Bantla (Kablo Bandı)"
	return "Kablo Kopuk ve Elektrik Kaçırıyor! (Kablo Bandı Gerekli)"

func interact(player: Node) -> void:
	if not is_broken:
		return
	if GameManager.has_item("cable_tape"):
		GameManager.consume_item("cable_tape")
		GameManager.play_sfx("tape")
		is_broken = false
		broken_gap.visible = false
		tape_patch.visible = true
		core_line.color = Color(0.2, 1.0, 0.6, 1.0)
		GameManager.emit_signal("status_message", "Kopuk Kablo Bantlandı! Artık Tırmanabilirsin [W]")
		if player.has_method("register_climbable"):
			player.register_climbable(self)
	else:
		GameManager.emit_signal("status_message", "Bu kabloyu onarmak için önce Kablo Bandını bulmalısın!")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("register_climbable"):
			body.register_climbable(self)
		if body.has_method("register_interactable"):
			body.register_interactable(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("unregister_climbable"):
			body.unregister_climbable(self)
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
