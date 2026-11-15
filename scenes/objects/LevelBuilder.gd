class_name LevelBuilder
extends RefCounted

static var _tex_cache: Dictionary = {}

static func load_sprite_texture(res_path: String) -> Texture2D:
	if _tex_cache.has(res_path):
		return _tex_cache[res_path]
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			var tex := ImageTexture.create_from_image(img)
			_tex_cache[res_path] = tex
			return tex
	if ResourceLoader.exists(res_path):
		var loaded := load(res_path) as Texture2D
		if loaded != null:
			_tex_cache[res_path] = loaded
			return loaded
	return null

static func add_neon_environment(parent: Node) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_strength = 0.9
	env.glow_bloom = 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	parent.add_child(world_env)

static func add_entry_pipe(parent: Node, center_x: float, pipe_bottom_y: float = 28.0) -> Node2D:
	var pipe_root := Node2D.new()
	pipe_root.z_index = 5
	parent.add_child(pipe_root)

	var body := ColorRect.new()
	body.position = Vector2(center_x - 14.0, -24.0)
	body.size = Vector2(28.0, pipe_bottom_y + 18.0)
	body.color = Color(0.15, 0.23, 0.36, 1.0)
	pipe_root.add_child(body)

	var highlight := ColorRect.new()
	highlight.position = Vector2(center_x - 10.0, -24.0)
	highlight.size = Vector2(5.0, pipe_bottom_y + 18.0)
	highlight.color = Color(0.26, 0.38, 0.56, 1.0)
	pipe_root.add_child(highlight)

	var rim := ColorRect.new()
	rim.position = Vector2(center_x - 17.0, pipe_bottom_y - 8.0)
	rim.size = Vector2(34.0, 8.0)
	rim.color = Color(0.2, 0.3, 0.46, 1.0)
	pipe_root.add_child(rim)

	var neon_band := ColorRect.new()
	neon_band.position = Vector2(center_x - 16.0, pipe_bottom_y - 3.0)
	neon_band.size = Vector2(32.0, 2.0)
	neon_band.color = Color(0.0, 0.95, 1.0, 0.95)
	pipe_root.add_child(neon_band)

	var mouth := ColorRect.new()
	mouth.position = Vector2(center_x - 11.0, pipe_bottom_y - 1.0)
	mouth.size = Vector2(22.0, 3.0)
	mouth.color = Color(0.02, 0.03, 0.06, 1.0)
	pipe_root.add_child(mouth)

	return pipe_root

static func add_platform(
	parent: Node,
	rect: Rect2,
	border_color: Color = Color(0.0, 0.9, 1.0, 1.0),
	fill_color: Color = Color(0.09, 0.11, 0.2, 1.0),
	block_style: String = "auto"
) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5

	var shape_node := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape_node.shape = rect_shape
	body.add_child(shape_node)

	var tex_dirt: Texture2D = load_sprite_texture("res://assets/sprites/block_dirt.png")
	var tex_wood: Texture2D = load_sprite_texture("res://assets/sprites/block_wood.png")
	var tex_metal: Texture2D = load_sprite_texture("res://assets/sprites/block_metal.png")

	# Arka plan taban dolgusu (kenar boşluklarını önlemek için)
	var bg := ColorRect.new()
	bg.position = -rect.size * 0.5
	bg.size = rect.size
	bg.color = fill_color
	body.add_child(bg)

	# Kullanıcının gönderdiği blok görsellerini bölüm temasına göre döşe (Tile)
	if tex_dirt != null and tex_wood != null and tex_metal != null:
		if block_style == "stone":
			# 1. Bölüm: Taş Bloğu (block_metal.png) + ince raflarda uyumlu ahşap destek
			var chosen_tex: Texture2D = tex_metal
			if rect.size.y <= 15.0 and border_color.r > 0.85 and border_color.g > 0.7:
				chosen_tex = tex_wood
			var tile_stone := TextureRect.new()
			tile_stone.texture = chosen_tex
			tile_stone.stretch_mode = TextureRect.STRETCH_TILE
			tile_stone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile_stone.position = -rect.size * 0.5
			tile_stone.size = rect.size
			body.add_child(tile_stone)
		elif block_style == "dirt":
			# 2. Bölüm: Toprak Bloğu (block_dirt.png) + tavan/desteklerde uyumlu ahşap/toprak
			var chosen_dirt_tex: Texture2D = tex_dirt
			if rect.size.y <= 12.0 and rect.position.y <= 15.0:
				chosen_dirt_tex = tex_wood
			var tile_dirt := TextureRect.new()
			tile_dirt.texture = chosen_dirt_tex
			tile_dirt.stretch_mode = TextureRect.STRETCH_TILE
			tile_dirt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile_dirt.position = -rect.size * 0.5
			tile_dirt.size = rect.size
			body.add_child(tile_dirt)
		elif block_style == "sand":
			var tile_sand := TextureRect.new()
			tile_sand.texture = tex_dirt
			tile_sand.stretch_mode = TextureRect.STRETCH_TILE
			tile_sand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile_sand.modulate = Color(1.65, 1.35, 0.82, 1.0)
			tile_sand.position = -rect.size * 0.5
			tile_sand.size = rect.size
			body.add_child(tile_sand)
			var sand_crust := ColorRect.new()
			sand_crust.position = -rect.size * 0.5
			sand_crust.size = Vector2(rect.size.x, min(4.0, rect.size.y))
			sand_crust.color = Color(0.96, 0.83, 0.48, 0.92)
			body.add_child(sand_crust)
		elif block_style == "bridge":
			var tile_bridge := TextureRect.new()
			tile_bridge.texture = tex_wood
			tile_bridge.stretch_mode = TextureRect.STRETCH_TILE
			tile_bridge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile_bridge.modulate = Color(1.15, 0.95, 0.78, 1.0)
			tile_bridge.position = -rect.size * 0.5
			tile_bridge.size = rect.size
			body.add_child(tile_bridge)
		elif rect.size.y <= 22.0 or (border_color.r > 0.85 and border_color.g > 0.7):
			# İnce raflar, üst kat platformları ve eğilme blokları -> Ahşap/Kutu Blok (block_wood)
			var tile_wood := TextureRect.new()
			tile_wood.texture = tex_wood
			tile_wood.stretch_mode = TextureRect.STRETCH_TILE
			tile_wood.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile_wood.position = -rect.size * 0.5
			tile_wood.size = rect.size
			body.add_child(tile_wood)
		elif rect.position.y >= 130.0 and rect.size.y <= 48.0:
			# Alt zemin platformları -> Alt katman Toprak/ Kaya Blok (block_dirt), üst yüzey Ahşap veya Metal Blok
			var base_tile := TextureRect.new()
			base_tile.texture = tex_dirt
			base_tile.stretch_mode = TextureRect.STRETCH_TILE
			base_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			base_tile.position = -rect.size * 0.5
			base_tile.size = rect.size
			body.add_child(base_tile)

			if rect.size.y >= 24.0 and int(rect.position.x) % 3 != 0:
				var top_layer := TextureRect.new()
				top_layer.texture = tex_wood if int(rect.position.x) % 2 == 0 else tex_metal
				top_layer.stretch_mode = TextureRect.STRETCH_TILE
				top_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				top_layer.position = -rect.size * 0.5
				top_layer.size = Vector2(rect.size.x, min(13.0, rect.size.y))
				body.add_child(top_layer)
		else:
			# Yüksek kuleler, duvarlar ve endüstriyel bloklar -> Metal Tuğla Blok (block_metal)
			var tile_metal := TextureRect.new()
			tile_metal.texture = tex_metal
			tile_metal.stretch_mode = TextureRect.STRETCH_TILE
			tile_metal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile_metal.position = -rect.size * 0.5
			tile_metal.size = rect.size
			body.add_child(tile_metal)

	# Üst ince kontur çizgisi
	var top_trim := ColorRect.new()
	top_trim.position = -rect.size * 0.5
	top_trim.size = Vector2(rect.size.x, 1.0)
	top_trim.color = Color(border_color.r, border_color.g, border_color.b, 0.55)
	body.add_child(top_trim)

	parent.add_child(body)
	return body

static func add_beach_decorations(parent: Node, items: Array) -> void:
	# items: [{"pos": Vector2(x, y), "kind": "palm"|"umbrella"|"pc_scrap"|"chip_shell"}]
	for item in items:
		var pos: Vector2 = item["pos"]
		var kind: String = item.get("kind", "pc_scrap")
		if kind == "palm":
			for i in range(6):
				var seg := ColorRect.new()
				seg.z_index = -3
				seg.position = Vector2(pos.x - 2.0 + sin(float(i) * 0.45) * 2.5, pos.y - float(i + 1) * 6.0)
				seg.size = Vector2(4.0, 6.0)
				seg.color = Color(0.55, 0.36, 0.2, 1.0) if i % 2 == 0 else Color(0.46, 0.3, 0.16, 1.0)
				parent.add_child(seg)
			var top_y: float = pos.y - 38.0
			var leaf_offsets: Array[Vector2] = [Vector2(-14, -2), Vector2(-9, -6), Vector2(2, -6), Vector2(6, -2)]
			for lo in leaf_offsets:
				var leaf := ColorRect.new()
				leaf.z_index = -3
				leaf.position = Vector2(pos.x + lo.x, top_y + lo.y)
				leaf.size = Vector2(10.0, 4.0)
				leaf.color = Color(0.15, 0.85, 0.45, 0.95)
				parent.add_child(leaf)
			var cyber_coc := ColorRect.new()
			cyber_coc.z_index = -2
			cyber_coc.position = Vector2(pos.x - 2.0, top_y - 1.0)
			cyber_coc.size = Vector2(4.0, 4.0)
			cyber_coc.color = Color(0.0, 0.95, 1.0, 0.95)
			parent.add_child(cyber_coc)
		elif kind == "umbrella":
			var pole := ColorRect.new()
			pole.z_index = -3
			pole.position = Vector2(pos.x - 1.0, pos.y - 24.0)
			pole.size = Vector2(2.0, 24.0)
			pole.color = Color(0.85, 0.88, 0.92, 1.0)
			parent.add_child(pole)
			var canopy := ColorRect.new()
			canopy.z_index = -3
			canopy.position = Vector2(pos.x - 13.0, pos.y - 28.0)
			canopy.size = Vector2(26.0, 6.0)
			canopy.color = Color(1.0, 0.28, 0.45, 0.95)
			parent.add_child(canopy)
			var stripe := ColorRect.new()
			stripe.z_index = -3
			stripe.position = Vector2(pos.x - 5.0, pos.y - 28.0)
			stripe.size = Vector2(10.0, 6.0)
			stripe.color = Color(1.0, 0.92, 0.35, 0.95)
			parent.add_child(stripe)
		elif kind == "pc_scrap":
			var monitor := ColorRect.new()
			monitor.z_index = -2
			monitor.position = Vector2(pos.x - 8.0, pos.y - 11.0)
			monitor.size = Vector2(16.0, 11.0)
			monitor.color = Color(0.18, 0.22, 0.3, 1.0)
			parent.add_child(monitor)
			var scr := ColorRect.new()
			scr.z_index = -2
			scr.position = Vector2(pos.x - 6.0, pos.y - 9.0)
			scr.size = Vector2(12.0, 7.0)
			scr.color = Color(0.0, 0.88, 1.0, 0.65)
			parent.add_child(scr)
			var sand_pile := ColorRect.new()
			sand_pile.z_index = -1
			sand_pile.position = Vector2(pos.x - 10.0, pos.y - 3.0)
			sand_pile.size = Vector2(20.0, 3.0)
			sand_pile.color = Color(0.95, 0.82, 0.48, 0.95)
			parent.add_child(sand_pile)
		elif kind == "chip_shell":
			var chip := ColorRect.new()
			chip.z_index = -2
			chip.position = Vector2(pos.x - 4.0, pos.y - 4.0)
			chip.size = Vector2(8.0, 4.0)
			chip.color = Color(0.12, 0.55, 0.35, 1.0)
			parent.add_child(chip)
			var pin := ColorRect.new()
			pin.z_index = -2
			pin.position = Vector2(pos.x - 2.0, pos.y - 5.0)
			pin.size = Vector2(4.0, 1.0)
			pin.color = Color(1.0, 0.85, 0.2, 1.0)
			parent.add_child(pin)

static func add_decor_crate(parent: Node, pos: Vector2, use_stone: bool = false) -> void:
	var tex: Texture2D = load_sprite_texture("res://assets/sprites/block_metal.png" if use_stone else "res://assets/sprites/block_wood.png")
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = -2
	var h: float = float(tex.get_height())
	spr.position = Vector2(pos.x, pos.y - h * 0.5)
	parent.add_child(spr)

static func add_stone_decorations(parent: Node, items: Array) -> void:
	# items: [{"pos": Vector2(x, y), "kind": "crate"|"pillar"|"terminal"|"wires"}]
	for item in items:
		var pos: Vector2 = item["pos"]
		var kind: String = item.get("kind", "crate")
		if kind == "crate":
			add_decor_crate(parent, pos, false)
		elif kind == "pillar":
			var col_body := ColorRect.new()
			col_body.z_index = -3
			col_body.position = Vector2(pos.x - 5.0, pos.y - 26.0)
			col_body.size = Vector2(10.0, 26.0)
			col_body.color = Color(0.22, 0.25, 0.34, 0.9)
			parent.add_child(col_body)
			var cap := ColorRect.new()
			cap.z_index = -3
			cap.position = Vector2(pos.x - 7.0, pos.y - 28.0)
			cap.size = Vector2(14.0, 4.0)
			cap.color = Color(0.0, 0.9, 1.0, 0.75)
			parent.add_child(cap)
		elif kind == "terminal":
			var stand := ColorRect.new()
			stand.z_index = -2
			stand.position = Vector2(pos.x - 2.0, pos.y - 12.0)
			stand.size = Vector2(4.0, 12.0)
			stand.color = Color(0.2, 0.24, 0.32, 1.0)
			parent.add_child(stand)
			var screen := ColorRect.new()
			screen.z_index = -2
			screen.position = Vector2(pos.x - 6.0, pos.y - 20.0)
			screen.size = Vector2(12.0, 9.0)
			screen.color = Color(0.08, 0.1, 0.18, 1.0)
			parent.add_child(screen)
			var glow := ColorRect.new()
			glow.z_index = -2
			glow.position = Vector2(pos.x - 5.0, pos.y - 19.0)
			glow.size = Vector2(10.0, 7.0)
			glow.color = Color(0.0, 0.95, 0.8, 0.75)
			parent.add_child(glow)
		elif kind == "wires":
			for i in range(3):
				var w := ColorRect.new()
				w.z_index = -2
				w.position = Vector2(pos.x - 6.0 + float(i) * 5.0, pos.y - 6.0 - float(i % 2) * 3.0)
				w.size = Vector2(2.0, 6.0 + float(i % 2) * 3.0)
				w.color = Color(1.0, 0.2, 0.65, 0.85) if i % 2 == 0 else Color(0.0, 0.9, 1.0, 0.85)
				parent.add_child(w)

static func add_dirt_decorations(parent: Node, items: Array) -> void:
	# items: [{"pos": Vector2(x, y), "kind": "moss"|"wood_post"|"mushroom"|"stone_pile"}]
	for item in items:
		var pos: Vector2 = item["pos"]
		var kind: String = item.get("kind", "moss")
		if kind == "moss":
			var m1 := ColorRect.new()
			m1.z_index = -2
			m1.position = Vector2(pos.x - 8.0, pos.y - 2.0)
			m1.size = Vector2(16.0, 3.0)
			m1.color = Color(0.15, 0.85, 0.45, 0.85)
			parent.add_child(m1)
			var blade := ColorRect.new()
			blade.z_index = -2
			blade.position = Vector2(pos.x - 2.0, pos.y - 6.0)
			blade.size = Vector2(2.0, 4.0)
			blade.color = Color(0.25, 1.0, 0.6, 0.9)
			parent.add_child(blade)
		elif kind == "wood_post":
			add_decor_crate(parent, pos, false)
		elif kind == "stone_pile":
			add_decor_crate(parent, pos, true)
		elif kind == "mushroom":
			var stem := ColorRect.new()
			stem.z_index = -2
			stem.position = Vector2(pos.x - 1.5, pos.y - 6.0)
			stem.size = Vector2(3.0, 6.0)
			stem.color = Color(0.85, 0.9, 0.8, 0.95)
			parent.add_child(stem)
			var cap := ColorRect.new()
			cap.z_index = -2
			cap.position = Vector2(pos.x - 5.0, pos.y - 10.0)
			cap.size = Vector2(10.0, 4.0)
			cap.color = Color(0.0, 0.95, 0.85, 0.95)
			parent.add_child(cap)

static func add_low_crouch_barrier(parent: Node, rect: Rect2) -> StaticBody2D:
	var body := add_platform(parent, rect, Color(1.0, 0.85, 0.1, 1.0), Color(0.14, 0.12, 0.22, 1.0))
	var bottom_warn := ColorRect.new()
	bottom_warn.position = Vector2(-rect.size.x * 0.5, rect.size.y * 0.5 - 3.0)
	bottom_warn.size = Vector2(rect.size.x, 3.0)
	bottom_warn.color = Color(1.0, 0.55, 0.0, 1.0)
	body.add_child(bottom_warn)
	return body

static func add_shock_strip(parent: Node, rect: Rect2, damage: int = 1) -> Area2D:
	var area := Area2D.new()
	area.position = rect.position + rect.size * 0.5

	var shape_node := CollisionShape2D.new()
	var r_shape := RectangleShape2D.new()
	r_shape.size = Vector2(max(4.0, rect.size.x - 2.0), rect.size.y)
	shape_node.shape = r_shape
	area.add_child(shape_node)

	var base := ColorRect.new()
	base.position = -rect.size * 0.5
	base.size = rect.size
	base.color = Color(0.95, 0.15, 0.35, 0.9)
	area.add_child(base)

	var core := ColorRect.new()
	core.position = Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5)
	core.size = Vector2(rect.size.x, min(3.0, rect.size.y))
	core.color = Color(1.0, 0.92, 0.2, 1.0)
	area.add_child(core)

	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player") and body.has_method("hurt_player"):
			GameManager.play_sfx("electric_shock")
			body.hurt_player(damage, area.global_position, false, "Yüksek Voltajlı Elektrik Tuzağı!")
	)
	parent.add_child(area)
	return area

static func add_laser_gate(
	parent: Node,
	top_pos: Vector2,
	height: float,
	on_duration: float = 1.25,
	off_duration: float = 1.05,
	phase_offset: float = 0.0
) -> Area2D:
	var script := GDScript.new()
	script.source_code = """extends Area2D
var on_dur: float = 1.25
var off_dur: float = 1.05
var timer: float = 0.0
var is_active: bool = true
var beam: ColorRect
var core: ColorRect
var col: CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	if off_dur <= 0.0:
		return
	timer += delta
	var cycle: float = on_dur + off_dur
	var t: float = fmod(timer, cycle)
	var should_be_on: bool = (t < on_dur)
	if should_be_on != is_active:
		is_active = should_be_on
		beam.visible = is_active
		core.visible = is_active
		col.disabled = not is_active
		if is_active:
			for b in get_overlapping_bodies():
				_on_body(b)

func _on_body(body: Node) -> void:
	if is_active and body.is_in_group("player") and body.has_method("hurt_player"):
		GameManager.play_sfx("electric_shock")
		body.hurt_player(1, global_position, false, "Lazer Güvenlik Bariyeri!")
"""
	script.reload()

	var area := Area2D.new()
	area.set_script(script)
	area.position = top_pos
	area.on_dur = on_duration
	area.off_dur = off_duration
	area.timer = phase_offset

	var emitter_top := ColorRect.new()
	emitter_top.position = Vector2(-5, -2)
	emitter_top.size = Vector2(10, 5)
	emitter_top.color = Color(0.25, 0.3, 0.45, 1.0)
	area.add_child(emitter_top)

	var emitter_bot := ColorRect.new()
	emitter_bot.position = Vector2(-5, height - 3)
	emitter_bot.size = Vector2(10, 5)
	emitter_bot.color = Color(0.25, 0.3, 0.45, 1.0)
	area.add_child(emitter_bot)

	var beam := ColorRect.new()
	beam.position = Vector2(-3.0, 2.0)
	beam.size = Vector2(6.0, height - 4.0)
	beam.color = Color(1.0, 0.1, 0.45, 0.75)
	area.add_child(beam)

	var core := ColorRect.new()
	core.position = Vector2(-1.0, 2.0)
	core.size = Vector2(2.0, height - 4.0)
	core.color = Color(1.0, 0.85, 0.95, 1.0)
	area.add_child(core)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(6.0, max(4.0, height - 6.0))
	col.shape = shape
	col.position = Vector2(0.0, height * 0.5)
	area.add_child(col)

	area.beam = beam
	area.core = core
	area.col = col
	parent.add_child(area)
	return area

static func add_moving_drone(
	parent: Node,
	pos_a: Vector2,
	pos_b: Vector2,
	speed: float = 65.0
) -> Area2D:
	var script := GDScript.new()
	script.source_code = """extends Area2D
var point_a: Vector2
var point_b: Vector2
var move_speed: float = 65.0
var going_to_b: bool = true
var ring: Polygon2D

func _ready() -> void:
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	var target: Vector2 = point_b if going_to_b else point_a
	global_position = global_position.move_toward(target, move_speed * delta)
	if global_position.distance_to(target) < 1.5:
		going_to_b = !going_to_b
	if ring != null:
		ring.rotation_degrees += 260.0 * delta

func _on_body(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("hurt_player"):
		body.hurt_player(1, global_position, false, "Plazma Devriye Dronu!")
"""
	script.reload()

	var area := Area2D.new()
	area.set_script(script)
	area.position = pos_a
	area.point_a = pos_a
	area.point_b = pos_b
	area.move_speed = speed

	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(6, -6), Vector2(8, 0), Vector2(6, 6),
		Vector2(0, 8), Vector2(-6, 6), Vector2(-8, 0), Vector2(-6, -6)
	])
	ring.color = Color(1.0, 0.25, 0.55, 0.95)
	area.add_child(ring)

	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)
	])
	core.color = Color(1.0, 0.95, 0.3, 1.0)
	area.add_child(core)

	var col := CollisionShape2D.new()
	var c_shape := CircleShape2D.new()
	c_shape.radius = 6.5
	col.shape = c_shape
	area.add_child(col)

	area.ring = ring
	parent.add_child(area)
	return area

static func add_background_junkyard(parent: Node, total_width: float, theme: String = "junkyard") -> void:
	var bg_root := Node2D.new()
	bg_root.z_index = -10
	parent.add_child(bg_root)

	var sky_color := Color(0.035, 0.03, 0.075, 1.0)
	var accent_a := Color(0.0, 0.85, 1.0, 0.35)
	var accent_b := Color(1.0, 0.15, 0.6, 0.35)
	if theme == "labyrinth":
		sky_color = Color(0.02, 0.055, 0.08, 1.0)
		accent_a = Color(0.1, 1.0, 0.65, 0.38)
		accent_b = Color(0.0, 0.85, 1.0, 0.38)
	elif theme == "boss":
		sky_color = Color(0.06, 0.02, 0.065, 1.0)
		accent_a = Color(1.0, 0.18, 0.35, 0.42)
		accent_b = Color(1.0, 0.72, 0.1, 0.38)
	elif theme == "finale":
		sky_color = Color(0.03, 0.025, 0.06, 1.0)
		accent_a = Color(0.0, 0.9, 1.0, 0.32)
		accent_b = Color(1.0, 0.82, 0.2, 0.35)

	var dark_sky := ColorRect.new()
	dark_sky.position = Vector2(-200, -250)
	dark_sky.size = Vector2(total_width + 400, 600)
	dark_sky.color = sky_color
	bg_root.add_child(dark_sky)

	# Devre yolu çizgileri (PCB Traces) arka plan boyunca
	for row in range(3):
		var y_trace := 36.0 + float(row) * 44.0
		var trace := ColorRect.new()
		trace.position = Vector2(-100, y_trace)
		trace.size = Vector2(total_width + 200, 1.5)
		trace.color = Color(accent_a.r, accent_a.g, accent_a.b, 0.14)
		bg_root.add_child(trace)

	# Kuleler, İşlemciler (CPU), Soğutma Fanları, Hurda Yığınları ve Sarkan Kablolar
	var x: float = 0.0
	var idx: int = 0
	while x < total_width:
		var tower := ColorRect.new()
		var h: float = 74.0 + float((idx * 37) % 78)
		tower.position = Vector2(x, 180.0 - h)
		tower.size = Vector2(38.0, h + 60.0)
		tower.color = Color(0.055, 0.065, 0.125, 0.9) if theme != "boss" else Color(0.085, 0.04, 0.08, 0.9)
		bg_root.add_child(tower)

		# Kule üst LED'i
		var led := ColorRect.new()
		led.position = Vector2(x + 8.0, 185.0 - h)
		led.size = Vector2(22.0, 2.5)
		led.color = accent_a if idx % 2 == 0 else accent_b
		bg_root.add_child(led)

		# Kule içi küçük server ışıkları
		for k in range(3):
			var dot := ColorRect.new()
			dot.position = Vector2(x + 7.0 + float(k) * 9.0, 194.0 - h)
			dot.size = Vector2(3.0, 3.0)
			dot.color = accent_b if (idx + k) % 2 == 0 else accent_a
			bg_root.add_child(dot)

		# Her 3 blokta bir İşlemci (CPU) silüeti + altın pinler
		if idx % 3 == 1:
			_add_bg_cpu(bg_root, Vector2(x + 42.0, 48.0 + float((idx * 17) % 36)), accent_a)

		# Her 4 blokta bir Dönen Soğutma Fanı
		if idx % 4 == 2:
			_add_bg_fan(bg_root, Vector2(x + 20.0, 62.0 + float((idx * 23) % 35)), accent_a)

		# Yukarıdan sarkan arka plan kabloları
		if idx % 2 == 0:
			var cable := ColorRect.new()
			var clen := 24.0 + float((idx * 19) % 36)
			cable.position = Vector2(x + 48.0, -20.0)
			cable.size = Vector2(2.0, clen + 20.0)
			cable.color = Color(0.12, 0.16, 0.25, 0.75)
			bg_root.add_child(cable)
			var tip := ColorRect.new()
			tip.position = Vector2(x + 47.0, clen - 2.0)
			tip.size = Vector2(4.0, 4.0)
			tip.color = accent_b
			bg_root.add_child(tip)

		# Çöplük temasında alt hurda blokları
		if theme == "junkyard" and idx % 2 == 1:
			var scrap := ColorRect.new()
			scrap.position = Vector2(x + 38.0, 158.0)
			scrap.size = Vector2(22.0, 24.0)
			scrap.color = Color(0.08, 0.06, 0.12, 0.85)
			bg_root.add_child(scrap)

		x += 66.0
		idx += 1

static func _add_bg_cpu(parent: Node, pos: Vector2, glow_col: Color) -> void:
	var chip := Node2D.new()
	chip.position = pos
	parent.add_child(chip)

	var body := ColorRect.new()
	body.position = Vector2(-14, -14)
	body.size = Vector2(28, 28)
	body.color = Color(0.07, 0.09, 0.15, 0.95)
	chip.add_child(body)

	var core := ColorRect.new()
	core.position = Vector2(-7, -7)
	core.size = Vector2(14, 14)
	core.color = Color(glow_col.r, glow_col.g, glow_col.b, 0.28)
	chip.add_child(core)

	# Altın CPU pinleri (üst/alt/sağ/sol)
	for i in range(-10, 11, 5):
		var p_top := ColorRect.new()
		p_top.position = Vector2(float(i) - 1.0, -17.0)
		p_top.size = Vector2(2.0, 3.0)
		p_top.color = Color(0.95, 0.78, 0.2, 0.45)
		chip.add_child(p_top)

		var p_bot := ColorRect.new()
		p_bot.position = Vector2(float(i) - 1.0, 14.0)
		p_bot.size = Vector2(2.0, 3.0)
		p_bot.color = Color(0.95, 0.78, 0.2, 0.45)
		chip.add_child(p_bot)

static func _add_bg_fan(parent: Node, pos: Vector2, glow_col: Color) -> void:
	var fan_script := GDScript.new()
	fan_script.source_code = """extends Node2D
func _process(delta: float) -> void:
	rotation_degrees += 110.0 * delta
"""
	fan_script.reload()

	var frame := ColorRect.new()
	frame.position = pos - Vector2(14, 14)
	frame.size = Vector2(28, 28)
	frame.color = Color(0.06, 0.08, 0.14, 0.85)
	parent.add_child(frame)

	var rotor := Node2D.new()
	rotor.set_script(fan_script)
	rotor.position = pos
	parent.add_child(rotor)

	for a in [0.0, 90.0]:
		var blade := ColorRect.new()
		blade.position = Vector2(-10, -2)
		blade.size = Vector2(20, 4)
		blade.pivot_offset = Vector2(10, 2)
		blade.rotation_degrees = a
		blade.color = Color(glow_col.r, glow_col.g, glow_col.b, 0.28)
		rotor.add_child(blade)
