extends Node
## Müzik ve Ses Efekti Yöneticisi (Autoload: MusicManager)
## - assets/audio/ klasöründeki dosyaları gerçek dosya isimlerine göre eşleştirir.
## - Arka plan müzikleri bitince otomatik başa sarar (loop).
## - Sahne değişince o sahneye ait müziği başlatır; aynı müzik zaten çalıyorsa kesmez.

const AUDIO_DIR: String = "res://assets/audio/"

# Rol -> Tam dosya adı eşleşmeleri (assets/audio/ içindeki gerçek dosyalar)
const EXACT_FILES: Dictionary = {
	# Arka Plan Müzikleri (Loop)
	"menu":         "menüdeyken çalan müzik.mp3",
	"level":        "normal bölümlerde arka plan müziği.mp3",
	"boss":         "boss geldiğinde arka plan müziği.mp3",
	"finale":       "bossu geçince final sahnesindeki arka plan müziği.mp3",

	# Bitiş Ekranı Sesi
	"victory":      "oyun tamamen bitince bitiş ekranında çıkan ses.mp3",

	# Ses Efektleri
	"click":        "menü ve oyun dışı butonlara basınca çıkan ses.mp3",
	"pickup":       "bir ıtem aldığında çıkan ses.mp3",
	"attack_spiky": "diken ile vurma sesi.mp3",
	"attack_neon":  "neon kılıç ile vurma sesi.mp3",
	"jump":         "zıplama sesi.mp3",
	"bounce":       "trambolin ile zıplama sesi.mp3",
	"bounce_land":  "trambolinden zıplayıp bir yere düştüğünde çıkan ses.mp3",
	"walk":         "taşta yürüme sesi.mp3",
	"stun":         "sersemleme sesi.mp3",
	"water_splash": "suya düşme sesi.mp3",
	"death":        "freesound_community-pixel-death-66829.mp3",
	"game_over":    "game over sesi ölünce çıkacak.mp3",
	"plug":         "fişi çekme sesi.mp3",
	"lights_off":   "fişi çektikten sonra tüm ışıkların sönmesi ile çıkan ses.mp3",
	"electric_shock": "elektrik çarpma sesi.mp3",
	"story_text":   "hikaye yazı sesi.mp3",
	"frog_croak":   "kurbaga_virak.mp3",
	"frog_bite":    "kurbaga_isirma.mp3",
}

# Sahne Adı -> Müzik Rolü
const SCENE_MUSIC: Dictionary = {
	"MainMenu":           "menu",
	"Scene1_OfficeIntro": "menu",
	"Level1_Junkyard":    "level",
	"Level2_Labyrinth":   "level",
	"Level2B_CyberBeach": "level",
	"Level3_BossChase":   "boss",
	"Scene5_Finale":      "finale",
}

var music_volume: float = 0.5
var sfx_volume: float = 0.5
var music_volume_db: float = -6.0
var sfx_volume_db: float = -6.0

var _music_player: AudioStreamPlayer
var _walk_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var _role_paths: Dictionary = {}
var _stream_cache: Dictionary = {}
var _current_music_role: String = ""
var _last_scene: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	# Müzik bittiğinde mevcut müziği başa sar
	_music_player.finished.connect(func():
		if _current_music_role != "" and _music_player.stream != null:
			_music_player.play()
	)

	_walk_player = AudioStreamPlayer.new()
	add_child(_walk_player)

	for i in range(10):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)

	_apply_volumes()
	_scan_audio_folder()

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	music_volume_db = -80.0 if music_volume <= 0.001 else linear_to_db(music_volume)
	if _music_player != null:
		_music_player.volume_db = music_volume_db

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	sfx_volume_db = -80.0 if sfx_volume <= 0.001 else linear_to_db(sfx_volume)
	if _walk_player != null:
		_walk_player.volume_db = -80.0 if sfx_volume <= 0.001 else sfx_volume_db - 2.0
	for p in _sfx_players:
		p.volume_db = sfx_volume_db

func _apply_volumes() -> void:
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _last_scene:
		_last_scene = scene
		if scene != null:
			var role: String = SCENE_MUSIC.get(scene.name, "")
			if role != "":
				play_music(role)

func _scan_audio_folder() -> void:
	var dir := DirAccess.open(AUDIO_DIR)
	if dir == null:
		push_warning("MusicManager: assets/audio klasörü bulunamadı.")
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			var clean := fname.trim_suffix(".import").trim_suffix(".remap")
			var ext := clean.get_extension().to_lower()
			if ext in ["mp3", "ogg", "wav"] and not files.has(clean):
				files.append(clean)
		fname = dir.get_next()
	dir.list_dir_end()

	for role in EXACT_FILES.keys():
		var target_name: String = EXACT_FILES[role]
		if files.has(target_name):
			_role_paths[role] = AUDIO_DIR + target_name
		else:
			# Unicode normalizasyonu ile eşleştirme yedeği
			for f in files:
				if f.to_lower() == target_name.to_lower():
					_role_paths[role] = AUDIO_DIR + f
					break

	print("MusicManager yüklendi (", _role_paths.size(), "/19 ses eşleşti)")

func _load_stream(path: String, loop: bool) -> AudioStream:
	var key := path + ("|loop" if loop else "")
	if _stream_cache.has(key):
		return _stream_cache[key]

	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
		if stream != null:
			stream = stream.duplicate() as AudioStream

	if stream == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			var ext := path.get_extension().to_lower()
			if ext == "mp3":
				var mp3 := AudioStreamMP3.new()
				mp3.data = FileAccess.get_file_as_bytes(abs_path)
				stream = mp3
			elif ext == "ogg":
				stream = AudioStreamOggVorbis.load_from_file(abs_path)
			elif ext == "wav":
				stream = AudioStreamWAV.load_from_file(abs_path)

	if stream == null:
		return null

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED

	_stream_cache[key] = stream
	return stream

func play_music(role: String) -> void:
	var path: String = _role_paths.get(role, "")
	if path == "":
		return
	if _music_player.playing and _music_player.stream != null and _music_player.get_meta("path", "") == path:
		_current_music_role = role
		return
	var stream := _load_stream(path, true)
	if stream == null:
		return
	_current_music_role = role
	_music_player.stream = stream
	_music_player.set_meta("path", path)
	_music_player.volume_db = music_volume_db
	_music_player.play()

func stop_music() -> void:
	_current_music_role = ""
	_music_player.stop()

func play_victory() -> void:
	stop_music()
	play_sfx("victory")

func play_sfx(role: String, pitch_variation: float = 0.0) -> void:
	var path: String = _role_paths.get(role, "")
	if path == "":
		return
	var stream := _load_stream(path, false)
	if stream == null:
		return
	var p := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()

func play_walk_step(pitch_variation: float = 0.08) -> void:
	var path: String = _role_paths.get("walk", "")
	if path == "":
		return
	var stream := _load_stream(path, false)
	if stream == null:
		return
	_walk_player.stream = stream
	_walk_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	_walk_player.play()

func stop_walk_step() -> void:
	if _walk_player.playing:
		_walk_player.stop()
