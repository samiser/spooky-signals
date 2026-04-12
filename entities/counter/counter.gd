extends Reciever
signal send_signal

@export var func_godot_properties	: Dictionary
var signal_ID						: String
var finish_signal_parameter			: String
var reset_signal_parameter			: String

var count		: int = 0
var total		: int
var triggered	: bool = false

func _ready() -> void:
	signal_ID = func_godot_properties.get("emit_signal_ID", "0")
	finish_signal_parameter = func_godot_properties.get("finish_signal_parameter", "0")
	reset_signal_parameter = func_godot_properties.get("reset_signal_parameter", "0")
	
	var recieve_signal_ID : String = func_godot_properties.get("recieve_signal_ID", "0")
	connect_senders(recieve_signal_ID, signal_recieved)
	
	total = func_godot_properties.get("count", 1)

func signal_recieved(parameters: String) -> void:
	if triggered && !func_godot_properties.get("repeatable", false):
		return
	
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"counter_add":
				count += 1
			"counter_sub":
				count -= 1
				if count < 0:
					count = 0
					send_signal.emit(reset_signal_parameter)
			"counter_reset":
				count = 0
				send_signal.emit(reset_signal_parameter)
			_:
				var param_additional : PackedStringArray = parameter.split(': ', false)

				if parameter.contains("counter_set"):
					count = param_additional[1].to_int()
	
	if count >= total:
		send_signal.emit(finish_signal_parameter)
		triggered = true
		if func_godot_properties.get("reset_on_finish", false):
			count = 0
