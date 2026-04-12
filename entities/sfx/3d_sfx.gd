extends Reciever
signal send_signal

@onready var sfx					: AudioStreamPlayer3D = $"."
@export var func_godot_properties	: Dictionary
var signal_ID 						: String

var subtitle 						: String
var subtitle_priority 				: int

func _ready() -> void:
	signal_ID = func_godot_properties.get("signal_ID", "0")
	subtitle = func_godot_properties.get("subtitle", "0")
	subtitle_priority = func_godot_properties.get("subtitle_priority", 1)
	sfx.stream = load(func_godot_properties.get("sfx_file_path", "res://audio/music/intro_music.ogg"))
	sfx.volume_db = func_godot_properties.get("volume_db", 0.0)
	var pitch_var : float = func_godot_properties.get("pitch_variation", 0.0)
	sfx.pitch_scale = func_godot_properties.get("pitch_level", 1.0) + randf_range(-pitch_var, pitch_var)
	sfx.playing = func_godot_properties.get("autoplay", false)
	sfx.unit_size = func_godot_properties.get("range", 10.0)
	sfx.panning_strength = func_godot_properties.get("pan_strength", 1.0)
	
	connect_senders(signal_ID, signal_recieved)

func signal_recieved(parameters: String) -> void:
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"sfx_play":
				sfx.play()
				var pitch_var : float = func_godot_properties.get("pitch_variation", 0.0)
				sfx.pitch_scale = func_godot_properties.get("pitch_level", 1.0) + randf_range(-pitch_var, pitch_var)
				if subtitle != "0" && subtitle != "":
					send_signal.emit("player_subtitle_priority: " + str(subtitle_priority) + ", player_subtitle_time: " + str(sfx.stream.get_length()) + ", player_set_subtitle: " + subtitle)
			"sfx_stop":
				sfx.stop()

func _display_subtitle() -> void:
	pass
