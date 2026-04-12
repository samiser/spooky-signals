extends Reciever

@export var func_godot_properties	: Dictionary
var signal_ID 						: String

@onready var video_stream_player	: VideoStreamPlayer = $Control/VideoStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	signal_ID =  func_godot_properties.get("signal_ID", "0")
	
	var file_path : String = func_godot_properties.get("video_file_path", "0")
	if !file_path.contains("res://"):
		file_path = "res://videos/logo_vid_short.ogv"
	
	video_stream_player.stream = load(file_path)
	
	connect_senders(signal_ID, signal_recieved)

func signal_recieved(parameters: String) -> void:
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"video_play":
				video_stream_player.show()
				video_stream_player.play()
				var timer := get_tree().create_timer(video_stream_player.get_stream_length())
				await timer.timeout
				video_stream_player.hide()
			"video_stop":
				video_stream_player.stop()
