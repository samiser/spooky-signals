extends Reciever
signal send_signal

@export var func_godot_properties	: Dictionary
@onready var area					: Area3D = $"."

var signal_ID						: String
var signal_parameter				: String
var triggered						: bool = false
var is_allowed						: bool = true

func _ready() -> void:
	signal_ID			= func_godot_properties.get("signal_ID", "0");
	signal_parameter	= func_godot_properties.get("signal_parameter", "0");
	is_allowed			= func_godot_properties.get("autoallow", true);
	
	area.body_entered.connect(_on_area_3d_body_entered)
	connect_senders(func_godot_properties.get("recieve_signal_ID", "0"), signal_recieved)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if !is_allowed:
		return
	
	if !triggered or  func_godot_properties.get("repeatable", true):
		send_signal.emit(signal_parameter)
		triggered = true

func signal_recieved(parameters: String) -> void:	
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"trigger_copy_params":
				var new_param : String = parameters.replace("trigger_copy_params", "")
				signal_parameter = new_param
				pass
			"trigger_on":
				is_allowed = true
			"trigger_off":
				is_allowed = false
			"trigger_toggle":
				is_allowed = !is_allowed
			"trigger_reset_triggered":
				triggered = false
