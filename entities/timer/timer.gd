extends Reciever
signal send_signal

@export var func_godot_properties	: Dictionary
var signal_ID 						: String
var signal_parameter 				: String

var time			: float = 0.0
var current_time	: float = 0.0
var triggered		: bool = false
var is_stopped		: bool = false
var loop			: bool = false

func _ready() -> void:
	signal_ID = func_godot_properties.get("emit_signal_ID", "0")
	signal_parameter = func_godot_properties.get("signal_parameter", "0")
	time = func_godot_properties.get("time", 1.0)	
	
	is_stopped = !func_godot_properties.get("autostart", false)
	loop = func_godot_properties.get("is_looping", false)
	
	var recieve_signal_ID : String = func_godot_properties.get("recieve_signal_ID", "0")
	connect_senders(recieve_signal_ID, signal_recieved)

func _process(delta: float) -> void:
	if is_stopped:
		return
	
	current_time = move_toward(current_time, time, delta)
	if current_time >= time:
		send_signal.emit(signal_parameter)
		current_time = 0.0
		is_stopped = !loop

func signal_recieved(parameters: String) -> void:
	if triggered && !func_godot_properties.get("repeatable", false):
		return
	
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"timer_start":
				is_stopped = false
				pass
			"timer_stop":
				is_stopped = true
				current_time = 0.0
				pass
			"timer_reset":
				current_time = 0.0
				pass
			_:
				var param_additional : PackedStringArray = parameter.split(': ', false)

				if parameter.contains("timer_set"):
					time = param_additional[1].to_float()
