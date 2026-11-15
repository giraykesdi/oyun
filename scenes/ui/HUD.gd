extends CanvasLayer

@onready var hearts: Array[Node2D] = [
	$Root/TopBar/HealthBox/Heart1,
	$Root/TopBar/HealthBox/Heart2,
	$Root/TopBar/HealthBox/Heart3
]
@onready var slot_panels: Array[ColorRect] = [
	$Root/TopBar/Hotbar/Slot1,
	$Root/TopBar/Hotbar/Slot2,
	$Root/TopBar/Hotbar/Slot3,
	$Root/TopBar/Hotbar/Slot4
]
@onready var slot_labels: Array[Label] = [
	$Root/TopBar/Hotbar/Slot1/Label,
	$Root/TopBar/Hotbar/Slot2/Label,
	$Root/TopBar/Hotbar/Slot3/Label,
	$Root/TopBar/Hotbar/Slot4/Label
]
@onready var prompt_label: Label = $Root/PromptLabel
@onready var status_label: Label = $Root/StatusLabel
@onready var help_panel: Control = $Root/HelpPanel
@onready var death_panel: Control = $Root/DeathPanel
@onready var death_reason_label: Label = $Root/DeathPanel/DeathReason
@onready var try_again_btn: Button = $Root/DeathPanel/TryAgainBtn
@onready var menu_btn: Button = $Root/DeathPanel/MenuBtn
@onready var pause_panel: Control = $Root/PausePanel
@onready var pause_music_slider: HSlider = $Root/PausePanel/MusicSlider
@onready var pause_music_value: Label = $Root/PausePanel/MusicValue
@onready var pause_sfx_slider: HSlider = $Root/PausePanel/SfxSlider
@onready var pause_sfx_value: Label = $Root/PausePanel/SfxValue
@onready var resume_btn: Button = $Root/PausePanel/ResumeBtn
@onready var checkpoint_btn: Button = $Root/PausePanel/CheckpointBtn
@onready var pause_menu_btn: Button = $Root/PausePanel/PauseMenuBtn
@onready var settings_logo_btn: Button = $Root/TopBar/SettingsLogoBtn
@onready var crt_overlay: ColorRect = $Root/CRTOverlay

const SLOT_SHORT_NAMES: Array[String] = ["1:Diken", "2:Neon", "3:Bant", "4:Balık"]

func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.interaction_prompt_changed.connect(_on_prompt_changed)
	GameManager.status_message.connect(_on_status_message)
	GameManager.crt_toggled.connect(_on_crt_toggled)
	GameManager.player_died.connect(_on_player_died)

	try_again_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.focus_mode = Control.FOCUS_NONE
	try_again_btn.pressed.connect(_on_try_again_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	resume_btn.pressed.connect(func():
		GameManager.play_sfx("click")
		_set_paused(false)
	)
	checkpoint_btn.pressed.connect(_on_checkpoint_pressed)
	pause_menu_btn.pressed.connect(_on_pause_menu_pressed)
	settings_logo_btn.pressed.connect(func():
		if not death_panel.visible:
			GameManager.play_sfx("click")
			_set_paused(not pause_panel.visible)
	)

	pause_music_slider.value = round(GameManager.music_volume * 100.0)
	pause_sfx_slider.value = round(GameManager.sfx_volume * 100.0)
	pause_music_value.text = str(int(pause_music_slider.value)) + "%"
	pause_sfx_value.text = str(int(pause_sfx_slider.value)) + "%"
	pause_music_slider.value_changed.connect(_on_music_slider_changed)
	pause_sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	_on_health_changed(GameManager.current_health, GameManager.MAX_HEALTH)
	_on_inventory_changed(GameManager.slots, GameManager.active_slot)
	_on_prompt_changed("")
	help_panel.visible = false
	death_panel.visible = false
	pause_panel.visible = false
	crt_overlay.visible = GameManager.crt_enabled

func _input(event: InputEvent) -> void:
	if not death_panel.visible:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo:
			var pcode: Key = event.physical_keycode
			var kcode: Key = event.keycode
			if pcode == KEY_E or pcode == KEY_SPACE or kcode == KEY_E or kcode == KEY_SPACE:
				get_viewport().set_input_as_handled()
				_on_try_again_pressed()
				return
			elif pcode == KEY_M or kcode == KEY_M:
				get_viewport().set_input_as_handled()
				_on_menu_pressed()
				return
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if death_panel.visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if help_panel.visible:
				help_panel.visible = false
			else:
				_set_paused(not pause_panel.visible)
			get_viewport().set_input_as_handled()
			return

	if pause_panel.visible:
		return

	if event.is_action_pressed("toggle_help"):
		help_panel.visible = !help_panel.visible
		get_viewport().set_input_as_handled()

func _on_health_changed(current_hp: int, _max_hp: int) -> void:
	for i in range(hearts.size()):
		var h: Node2D = hearts[i]
		var fill: Polygon2D = h.get_node("Fill")
		var shine: Polygon2D = h.get_node("Shine")
		if i < current_hp:
			fill.color = Color(1.0, 0.16, 0.38, 1.0)
			shine.visible = true
			var tw := create_tween()
			tw.tween_property(h, "scale", Vector2(1.25, 1.25), 0.08)
			tw.tween_property(h, "scale", Vector2(1.0, 1.0), 0.1)
		else:
			fill.color = Color(0.22, 0.1, 0.18, 0.75)
			shine.visible = false
			h.scale = Vector2(0.9, 0.9)

func _on_inventory_changed(slots: Array, active_idx: int) -> void:
	for i in range(4):
		var item = slots[i]
		var is_active: bool = (i == active_idx)
		if is_active:
			slot_panels[i].color = Color(0.0, 0.75, 0.95, 0.9)
		elif item != null:
			slot_panels[i].color = Color(0.18, 0.22, 0.35, 0.85)
		else:
			slot_panels[i].color = Color(0.08, 0.08, 0.14, 0.6)

		if item != null:
			slot_labels[i].text = SLOT_SHORT_NAMES[i]
			slot_labels[i].modulate = Color(1, 1, 1, 1)
		else:
			slot_labels[i].text = str(i + 1) + ":---"
			slot_labels[i].modulate = Color(0.5, 0.5, 0.6, 0.8)

func _on_prompt_changed(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = (text != "")

func _on_status_message(msg: String) -> void:
	status_label.text = msg
	status_label.modulate = Color(0.4, 1.0, 1.0, 1.0)
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(status_label, "modulate:a", 0.0, 0.5)

func _on_crt_toggled(enabled: bool) -> void:
	crt_overlay.visible = enabled

func _on_player_died(reason: String) -> void:
	GameManager.play_sfx("game_over")
	help_panel.visible = false
	prompt_label.visible = false
	death_reason_label.text = reason
	death_panel.visible = true
	death_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(death_panel, "modulate:a", 1.0, 0.25)

func _on_try_again_pressed() -> void:
	GameManager.play_sfx("click")
	death_panel.visible = false
	GameManager.call_deferred("respawn_at_checkpoint")

func _on_menu_pressed() -> void:
	GameManager.play_sfx("click")
	death_panel.visible = false
	_set_paused(false)
	GameManager.call_deferred("go_to_main_menu")

func _set_paused(paused: bool) -> void:
	pause_panel.visible = paused
	get_tree().paused = paused
	if paused:
		GameManager.stop_walk_step()
		pause_music_slider.value = round(GameManager.music_volume * 100.0)
		pause_sfx_slider.value = round(GameManager.sfx_volume * 100.0)
		pause_music_value.text = str(int(pause_music_slider.value)) + "%"
		pause_sfx_value.text = str(int(pause_sfx_slider.value)) + "%"
		resume_btn.grab_focus()

func _on_checkpoint_pressed() -> void:
	GameManager.play_sfx("click")
	_set_paused(false)
	GameManager.respawn_at_checkpoint()

func _on_pause_menu_pressed() -> void:
	GameManager.play_sfx("click")
	_set_paused(false)
	GameManager.go_to_main_menu()

func _on_music_slider_changed(val: float) -> void:
	pause_music_value.text = str(int(val)) + "%"
	GameManager.set_music_volume(val / 100.0)

func _on_sfx_slider_changed(val: float) -> void:
	pause_sfx_value.text = str(int(val)) + "%"
	GameManager.set_sfx_volume(val / 100.0)
