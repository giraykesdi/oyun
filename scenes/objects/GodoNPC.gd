extends Area2D

var sprite: Sprite2D
var fish_given: bool = false
var dialogue_active: bool = false
var current_player: Node = null

var dialog_layer: CanvasLayer
var dialog_panel: PanelContainer
var speaker_label: Label
var body_label: Label
var continue_label: Label

var lines: Array[Dictionary] = [
	{"speaker": "GODO", "color": Color(1.0, 0.42, 0.78), "text": "Vay! Taze siber balık mı getirdin bana? Çok teşekkür ederim küçük panda!"},
	{"speaker": "PO", "color": Color(0.3, 0.95, 1.0), "text": "Rica ederim Godo! Ben PO, ofisteki bilgisayardan buraya çekildim. Çıkışı arıyorum."},
	{"speaker": "GODO", "color": Color(1.0, 0.42, 0.78), "text": "Dikkatli ol PO... İlerideki bölümde çok tehlikeli şeyler seni bekliyor!"},
	{"speaker": "GODO", "color": Color(1.0, 0.42, 0.78), "text": "Bu bilgisayarın çekirdeğini ele geçiren devasa Kablo Bossu peşine düşecek. Engelleri aşmazsan seni tek hamlede yakalar!"},
	{"speaker": "PO", "color": Color(0.3, 0.95, 1.0), "text": "Kablo Bossu mu?! Korkutucu ama durmayacağım, gerçek dünyaya dönmem gerek!"},
	{"speaker": "GODO", "color": Color(1.0, 0.42, 0.78), "text": "Cesaretini sevdim dostum. Yukarıdaki kabloyu onarıp geç... Sana bol şans diliyorum, PO!"}
]

var line_idx: int = 0
var typing_done: bool = false
var char_timer: float = 0.0
var sfx_cooldown: int = 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1

	sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/npc_godo.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -14)
	add_child(sprite)

	var col := CollisionShape2D.new()
	var shp := RectangleShape2D.new()
	shp.size = Vector2(36, 30)
	col.shape = shp
	col.position = Vector2(0, -14)
	add_child(col)

	_build_dialogue_ui()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_dialogue_ui() -> void:
	dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 30
	dialog_layer.visible = false
	add_child(dialog_layer)

	dialog_panel = PanelContainer.new()
	dialog_panel.position = Vector2(18, 122)
	dialog_panel.size = Vector2(284, 50)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.14, 0.94)
	style.border_color = Color(1.0, 0.42, 0.78, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	dialog_panel.add_theme_stylebox_override("panel", style)
	dialog_layer.add_child(dialog_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	dialog_panel.add_child(vbox)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 7)
	vbox.add_child(speaker_label)

	body_label = Label.new()
	body_label.add_theme_font_size_override("font_size", 6)
	body_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(268, 22)
	vbox.add_child(body_label)

	continue_label = Label.new()
	continue_label.add_theme_font_size_override("font_size", 6)
	continue_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.text = "[E] Devam Et"
	vbox.add_child(continue_label)

func get_interaction_prompt() -> String:
	if not fish_given:
		var active_item = GameManager.get_active_item()
		if active_item != null and active_item.get("id", "") == "fish":
			return "[E] Godo'ya Balık Ver"
		return "[E] Godo ile Konuş"
	return "[E] Godo ile Konuş"

func interact(player: Node) -> void:
	if dialogue_active:
		return
	current_player = player
	if not fish_given:
		var active_item = GameManager.get_active_item()
		if active_item != null and active_item.get("id", "") == "fish":
			GameManager.consume_item("fish")
			GameManager.play_sfx("heart")
			fish_given = true
			_start_dialogue(0)
		elif GameManager.has_item("fish"):
			var msg := "Balığı eline al [4] ve Godo'ya ver!"
			GameManager.emit_signal("status_message", msg)
			if player.has_method("say"):
				player.say(msg, 2.5)
		else:
			var msg := "Godo ile konuşmak için ona balık vermen lazım!"
			GameManager.emit_signal("status_message", msg)
			if player.has_method("say"):
				player.say(msg, 2.8)
	else:
		lines = [
			{"speaker": "GODO", "color": Color(1.0, 0.42, 0.78), "text": "Dikkatli ol PO! Kablo Bossu çok hızlıdır, engelleri aşmayı unutma. Bol şans!"}
		]
		_start_dialogue(0)

func _start_dialogue(start_idx: int) -> void:
	dialogue_active = true
	line_idx = start_idx
	if is_instance_valid(current_player):
		current_player.cutscene_lock = true
	dialog_layer.visible = true
	_show_current_line()

func _show_current_line() -> void:
	var entry: Dictionary = lines[line_idx]
	speaker_label.text = entry["speaker"]
	speaker_label.add_theme_color_override("font_color", entry["color"])
	body_label.text = entry["text"]
	body_label.visible_characters = 0
	typing_done = false
	char_timer = 0.0
	sfx_cooldown = 0
	continue_label.visible = false

func _process(delta: float) -> void:
	if not dialogue_active or typing_done:
		return
	char_timer += delta
	while char_timer >= 0.028 and not typing_done:
		char_timer -= 0.028
		body_label.visible_characters += 1
		sfx_cooldown += 1
		if sfx_cooldown >= 3:
			sfx_cooldown = 0
			GameManager.play_sfx("story_text", 0.08)
		if body_label.visible_characters >= body_label.get_total_character_count():
			typing_done = true
			continue_label.visible = true

func _input(event: InputEvent) -> void:
	if not dialogue_active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not typing_done:
			body_label.visible_characters = body_label.get_total_character_count()
			typing_done = true
			continue_label.visible = true
		else:
			line_idx += 1
			if line_idx < lines.size():
				_show_current_line()
			else:
				_close_dialogue()

func _close_dialogue() -> void:
	dialogue_active = false
	dialog_layer.visible = false
	if is_instance_valid(current_player):
		current_player.cutscene_lock = false
		if current_player.has_method("_update_interaction_prompt"):
			current_player._update_interaction_prompt()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("register_interactable"):
		body.register_interactable(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
