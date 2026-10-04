extends Node2D

## All sound assignments and independent volume controls live on this node.
signal sound_played(event: StringName)

@export_group("Enemy Pistol")
@export var light_shot: AudioStream
@export_range(-60.0, 6.0, 0.5) var light_shot_volume_db: float = -10.0
@export var heavy_shot: AudioStream
@export_range(-60.0, 6.0, 0.5) var heavy_shot_volume_db: float = -10.0

@export_group("Player AK47")
@export var ak47_burst: AudioStream
@export_range(-60.0, 6.0, 0.5) var ak47_burst_volume_db: float = -10.0

@export_group("Bullet Impact")
@export var bullet_impact: AudioStream
@export_range(-60.0, 6.0, 0.5) var bullet_impact_volume_db: float = -16.0

@export_group("Player Landing")
@export var landing: AudioStream
@export_range(-60.0, 6.0, 0.5) var landing_volume_db: float = -10.0

@export_group("Wood Crate Landing")
@export var crate_landing: AudioStream
@export_range(-60.0, 6.0, 0.5) var crate_landing_volume_db: float = -10.0

@export_group("Background Music")
@export var background_music: AudioStream
@export_range(-60.0, 6.0, 0.5) var music_volume_db: float = -20.0:
	set(value):
		music_volume_db = value
		if is_instance_valid(music_player):
			music_player.volume_db = value

@export_group("Spatial Sound")
@export var sfx_max_distance: float = 3500.0
@export_range(1, 64, 1) var maximum_voices: int = 32

var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer2D] = []
var one_shot_streams: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("game_audio")


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	# Music can continue under the victory overlay.
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	music_player.volume_db = music_volume_db
	if background_music != null:
		music_player.stream = _with_loop(background_music, true)
		music_player.finished.connect(music_player.play)
		music_player.play()


func play_effect(event: StringName, world_position: Vector2) -> void:
	var stream: AudioStream
	var volume: float = 0.0
	match event:
		&"light_shot":
			stream = light_shot
			volume = light_shot_volume_db
		&"heavy_shot":
			stream = heavy_shot
			volume = heavy_shot_volume_db
		&"ak47_burst":
			stream = ak47_burst
			volume = ak47_burst_volume_db
		&"bullet_impact":
			stream = bullet_impact
			volume = bullet_impact_volume_db
		&"landing":
			stream = landing
			volume = landing_volume_db
		&"crate_landing":
			stream = crate_landing
			volume = crate_landing_volume_db
		_:
			return
	# Empty Inspector fields deliberately mean silence.
	if stream == null:
		return
	for index in range(voices.size() - 1, -1, -1):
		if not is_instance_valid(voices[index]) or voices[index].is_queued_for_deletion():
			voices.remove_at(index)
	if voices.size() >= maximum_voices:
		var oldest: AudioStreamPlayer2D = voices.pop_front()
		oldest.stop()
		oldest.queue_free()
	var sound := AudioStreamPlayer2D.new()
	sound.name = "SFX_" + String(event)
	if not one_shot_streams.has(stream):
		one_shot_streams[stream] = _with_loop(stream, false)
	sound.stream = one_shot_streams[stream]
	sound.volume_db = volume
	sound.max_distance = sfx_max_distance
	sound.attenuation = 0.8
	sound.panning_strength = 0.6
	add_child(sound)
	sound.global_position = world_position
	sound.finished.connect(sound.queue_free)
	voices.append(sound)
	sound.play()
	sound_played.emit(event)


func _with_loop(source: AudioStream, looping: bool) -> AudioStream:
	var stream := source.duplicate() as AudioStream
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.set("loop", looping)
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
	return stream
