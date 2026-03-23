extends Node

var current_bgm: AudioStreamPlayer
var current_track: String = ""

func _ready() -> void:
	# Create the AudioStreamPlayer for BGM
	current_bgm = AudioStreamPlayer.new()
	current_bgm.bus = "Master"
	add_child(current_bgm)

func play_bgm(track_path: String, volume_db: float = 0.0, loop: bool = true) -> void:
	if track_path == current_track:
		return  # Already playing this track
	
	# Load the audio file
	var audio_stream = load(track_path)
	if audio_stream == null:
		push_error("Failed to load BGM: %s" % track_path)
		return
	
	# Stop previous track if playing
	if current_bgm.playing:
		await current_bgm.finished
	
	# Set up and play new track
	current_bgm.stream = audio_stream
	current_bgm.volume_db = volume_db
	current_bgm.bus = "Master"
	
	# Enable looping if supported
	if loop and audio_stream is AudioStreamOGG:
		audio_stream.loop = true
	
	current_bgm.play()
	current_track = track_path

func stop_bgm(fade_out: float = 0.0) -> void:
	if fade_out > 0.0:
		var tween = create_tween()
		tween.tween_property(current_bgm, "volume_db", -80, fade_out)
		await tween.finished
	
	current_bgm.stop()
	current_track = ""

func set_volume(volume_db: float) -> void:
	if current_bgm:
		current_bgm.volume_db = volume_db

func pause_bgm() -> void:
	if current_bgm and current_bgm.playing:
		current_bgm.stream_paused = true

func resume_bgm() -> void:
	if current_bgm and current_bgm.playing:
		current_bgm.stream_paused = false
