extends Reciever
signal send_signal

@export var func_godot_properties	: Dictionary
@onready var sound					: AudioStreamPlayer3D = $Sound

@onready var button_sfx : AudioStream = load("res://audio/sfx/button.wav")
@onready var error_sfx	: AudioStream = load("res://audio/sfx/error.wav")

var signal_ID 						: String
var recieve_signal_ID				: String
var signal_parameter				: String

var triggered						: bool = false
var allowed							: bool = true
var repeatable						: bool = true

func _ready() -> void:
	signal_ID = func_godot_properties.get("emit_signal_ID", "0")
	recieve_signal_ID = func_godot_properties.get("recieve_signal_ID", "0")
	signal_parameter = func_godot_properties.get("signal_parameter", "0")
	allowed = func_godot_properties.get("autoallow", true)
	repeatable = func_godot_properties.get("repeatable", true)
	
	$Screen.current_screen.set_text(signal_ID)
	
	connect_senders(recieve_signal_ID, signal_recieved)

func interact(player: Player) -> void:
	if (!triggered || repeatable) && allowed:
		send_signal.emit(signal_parameter)
		triggered = true
		sound.stream = button_sfx
		if !repeatable:
			$Screen.current_screen.set_text(" ")
	else:
		sound.stream = error_sfx
	
	sound.play()

func signal_recieved(parameters: String) -> void:	
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"button_copy_params":
				var new_param : String = parameters.replace("trigger_copy_params", "")
				signal_parameter = new_param
				pass
			"button_on":
				allowed = true
				$Screen.current_screen.set_text(signal_ID)
			"button_off":
				allowed = false
				$Screen.current_screen.set_text(" ")
			"button_toggle":
				allowed = !allowed
				if allowed:
					$Screen.current_screen.set_text(signal_ID)
				else:
					$Screen.current_screen.set_text(" ")
			"button_reset_triggered":
				triggered = false
