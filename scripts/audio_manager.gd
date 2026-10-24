extends Node
## Autoload singleton (registered as `AudioManager`).
## Owns music + SFX playback and independent volume controls.
## All streams are original procedurally-generated AudioStreamWAV resources
## stored in res://assets/audio/, so the game never fails on a missing file.

const MUSIC_DIR := "res://Assets/audio/music_%s.tres"
const SFX_DIR := "res://Assets/audio/sfx_%s.tres"
const SFX_POOL := 12

var music_volume: float = 0.6
var sfx_volume: float = 0.9

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _current_track: String = ""
var _music_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep audio alive while paused
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer%d" % i
		add_child(p)
		_sfx_players.append(p)


func _load_music(track: String) -> AudioStream:
	if _music_cache.has(track):
		return _music_cache[track]
	var path := MUSIC_DIR % track
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	_music_cache[track] = stream
	return stream


func _load_sfx(sfx_name: String) -> AudioStream:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	var path := SFX_DIR % sfx_name
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	_sfx_cache[sfx_name] = stream
	return stream


## Play a looping music track. Re-requesting the current track is a no-op.
func play_music(track: String, restart: bool = false) -> void:
	if track == _current_track and _music_player.playing and not restart:
		return
	var stream := _load_music(track)
	if stream == null:
		return
	_current_track = track
	_music_player.stream = stream
	_music_player.volume_db = _to_db(music_volume)
	_music_player.play()


func stop_music() -> void:
	_current_track = ""
	_music_player.stop()


func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	var stream := _load_sfx(sfx_name)
	if stream == null:
		return
	var p := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = _to_db(sfx_volume)
	p.pitch_scale = pitch
	p.play()


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_music_player.volume_db = _to_db(music_volume)


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)


func _to_db(v: float) -> float:
	if v <= 0.001:
		return -80.0
	return linear_to_db(v)
