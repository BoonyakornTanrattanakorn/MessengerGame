extends Node

# SFX Manager - Placeholder for future sound effects implementation
# This will handle all sound effects in the game

func _ready() -> void:
	# Ensure SFX bus exists
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index == -1:
		# If SFX bus doesn't exist, create it by setting volume on Master
		pass

func play_sfx(sfx_path: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	# Placeholder for SFX playback
	# Future implementation will create and play sound effects
	var audio_player = AudioStreamPlayer.new()
	var audio_stream = load(sfx_path)
	
	if audio_stream == null:
		push_error("Failed to load SFX: %s" % sfx_path)
		return null
	
	audio_player.stream = audio_stream
	audio_player.volume_db = volume_db
	audio_player.bus = "SFX"
	add_child(audio_player)
	audio_player.play()
	
	# Auto-remove when finished
	await audio_player.finished
	audio_player.queue_free()
	
	return audio_player

func set_volume(volume_db: float) -> void:
	# Set SFX bus volume
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, volume_db)

func mute() -> void:
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, true)

func unmute() -> void:
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, false)
