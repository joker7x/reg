extends Node

const MAX_PLAYERS: = 10
var players: Array[AudioStreamPlayer] = []

func _ready():
	for i in MAX_PLAYERS:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)

func play_sfx(clip: SFXClip):
	var player = _get_available_player()
	if player == null or clip == null:
		push_warning("SoundManager: tried to play with null player/clip")
		return

	player.stream = clip.stream
	player.volume_db = randf_range(clip.min_volume, clip.max_volume)
	player.pitch_scale = randf_range(clip.min_pitch, clip.max_pitch)
	player.play()



func play_sfx_random(clips: Array[SFXClip], key: String):
	if clips.is_empty():
		return
	var clip: SFXClip = ShuffledBag.pool_for(key, clips).next()
	play_sfx(clip)



func play_sfx_pitched(clip: SFXClip, pitch: float):
	var player = _get_available_player()
	if player == null or clip == null:
		push_warning("SoundManager: tried to play with null player/clip")
		return
	player.stream = clip.stream
	player.volume_db = randf_range(clip.min_volume, clip.max_volume)
	player.pitch_scale = pitch
	player.play()

func stop_sfx(clip: SFXClip) -> void :
	if clip == null or clip.stream == null:
		return
	for p in players:
		if p.playing and p.stream == clip.stream:
			p.stop()

func _get_available_player():
	for p in players:
		if not p.playing:
			return p
	return players[0]
