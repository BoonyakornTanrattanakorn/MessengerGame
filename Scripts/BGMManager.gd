extends Node

var current_bgm: AudioStreamPlayer
var current_track: String = ""

func _ready() -> void:
	# Create the AudioStreamPlayer for BGM
	current_bgm = AudioStreamPlayer.new()
	current_bgm.bus = "Master"
	# Allow BGM to continue playing when game is paused
	current_bgm.process_mode = Node.PROCESS_MODE_ALWAYS
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
	if loop and audio_stream.has_meta("loop"):
		audio_stream.set_meta("loop", true)
	elif loop and "loop" in audio_stream:
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
	# Set Master bus volume (affects BGM)
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		AudioServer.set_bus_volume_db(master_bus_index, volume_db)

func pause_bgm() -> void:
	if current_bgm and current_bgm.playing:
		current_bgm.stream_paused = true

func resume_bgm() -> void:
	if current_bgm and current_bgm.playing:
		current_bgm.stream_paused = false
