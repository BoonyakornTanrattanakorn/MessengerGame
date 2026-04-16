extends Node

const SFX_BASE := "res://assets/audio/sfx/RPG_Essentials_Free"

const SFX_EVENTS := {
	# Player / movement
	"player.step_grass": SFX_BASE + "/12_Player_Movement_SFX/03_Step_grass_03.ogg",
	"player.step_rock": SFX_BASE + "/12_Player_Movement_SFX/08_Step_rock_02.ogg",
	"player.step_wood": SFX_BASE + "/12_Player_Movement_SFX/12_Step_wood_03.ogg",
	"player.step_water": SFX_BASE + "/12_Player_Movement_SFX/14_Step_water_02.ogg",
	"player.dash": SFX_BASE + "/12_Player_Movement_SFX/30_Jump_03.ogg",
	"player.interact": SFX_BASE + "/10_UI_Menu_SFX/013_Confirm_03.ogg",
	"player.hit": SFX_BASE + "/12_Player_Movement_SFX/61_Hit_03.ogg",
	"player.death": SFX_BASE + "/10_Battle_SFX/69_Enemy_death_01.ogg",

	# Skills / combat
	"skill.wind.cast": SFX_BASE + "/8_Atk_Magic_SFX/25_Wind_01.ogg",
	"skill.fire.small": SFX_BASE + "/12_Player_Movement_SFX/56_Attack_03.ogg",
	"skill.fire.heavy": SFX_BASE + "/8_Atk_Magic_SFX/04_Fire_explosion_04_medium.ogg",
	"skill.water.cast": SFX_BASE + "/8_Atk_Magic_SFX/22_Water_02.ogg",
	"skill.water.charge": SFX_BASE + "/8_Atk_Magic_SFX/45_Charge_05.ogg",
	"skill.earth.cast": SFX_BASE + "/8_Atk_Magic_SFX/30_Earth_02.ogg",
	"skill.shield.up": SFX_BASE + "/8_Buffs_Heals_SFX/17_Def_buff_01.ogg",

	# UI
	"ui.hover": SFX_BASE + "/10_UI_Menu_SFX/001_Hover_01.ogg",
	"ui.confirm": SFX_BASE + "/10_UI_Menu_SFX/013_Confirm_03.ogg",
	"ui.decline": SFX_BASE + "/10_UI_Menu_SFX/029_Decline_09.ogg",
	"ui.denied": SFX_BASE + "/10_UI_Menu_SFX/033_Denied_03.ogg",
	"ui.use_item": SFX_BASE + "/10_UI_Menu_SFX/051_use_item_01.ogg",
	"ui.equip": SFX_BASE + "/10_UI_Menu_SFX/070_Equip_10.ogg",
	"ui.pause": SFX_BASE + "/10_UI_Menu_SFX/092_Pause_04.ogg",
	"ui.unpause": SFX_BASE + "/10_UI_Menu_SFX/098_Unpause_04.ogg",
}

var _stream_cache: Dictionary = {}

func _ready() -> void:
	# Ensure SFX bus exists
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index == -1:
		# If SFX bus doesn't exist, create it by setting volume on Master
		pass

func has_event(event_key: String) -> bool:
	return SFX_EVENTS.has(event_key)

func list_event_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for event_key in SFX_EVENTS.keys():
		keys.append(String(event_key))
	return keys

func play_event(event_key: String) -> AudioStreamPlayer:
	if not SFX_EVENTS.has(event_key):
		push_warning("Unknown SFX event key: %s" % event_key)
		return null
	return play_sfx(String(SFX_EVENTS[event_key]))

func play_sfx(sfx_path: String) -> AudioStreamPlayer:
func has_event(event_key: String) -> bool:
	return SFX_EVENTS.has(event_key)

func list_event_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for event_key in SFX_EVENTS.keys():
		keys.append(String(event_key))
	return keys

func play_event(event_key: String) -> AudioStreamPlayer:
	if not SFX_EVENTS.has(event_key):
		push_warning("Unknown SFX event key: %s" % event_key)
		return null
	return play_sfx(String(SFX_EVENTS[event_key]))

func play_sfx(sfx_path: String) -> AudioStreamPlayer:
	var audio_player = AudioStreamPlayer.new()
	var audio_stream: AudioStream = _stream_cache.get(sfx_path, null)
	if audio_stream == null:
		audio_stream = load(sfx_path)
		if audio_stream != null:
			_stream_cache[sfx_path] = audio_stream
	var audio_stream: AudioStream = _stream_cache.get(sfx_path, null)
	if audio_stream == null:
		audio_stream = load(sfx_path)
		if audio_stream != null:
			_stream_cache[sfx_path] = audio_stream
	
	if audio_stream == null:
		push_error("Failed to load SFX: %s" % sfx_path)
		return null
	
	audio_player.stream = audio_stream
	audio_player.volume_db = 0.0
	audio_player.volume_db = 0.0
	audio_player.bus = "SFX"
	add_child(audio_player)
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()


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
