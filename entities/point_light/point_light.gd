@tool
extends Reciever

@export var func_godot_properties	: Dictionary
var signal_ID						: String

@onready var point_light			: OmniLight3D = $"."
var flicker_amount					: float = 0.0
var start_light_energy				: float = 0.0

func _ready() -> void:
	signal_ID = func_godot_properties.get("signal_ID", "0")

	point_light.light_color = func_godot_properties.get("colour", Color.WHITE)
	start_light_energy = func_godot_properties.get("energy", 1.0)
	point_light.light_energy = start_light_energy
	point_light.omni_range = func_godot_properties.get("size", 10.0)
	point_light.shadow_enabled = func_godot_properties.get("shadows", false)
	point_light.light_volumetric_fog_energy = func_godot_properties.get("fog_energy", 0.0)

	if func_godot_properties.get("autoflicker", false):
		flicker_amount = func_godot_properties.get("flicker_amount", 0.0)
	
	if(!Engine.is_editor_hint()):
		connect_senders(signal_ID, signal_recieved)
	
	request_ready()

func _process(delta: float) -> void:
	if(flicker_amount <= 0.0):
		return
	
	point_light.light_energy = start_light_energy + sin(Time.get_ticks_usec()) * flicker_amount

func signal_recieved(parameters: String) -> void:
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"light_off":
				point_light.hide()
			"light_on":
				point_light.show()
				point_light.light_energy = start_light_energy
			"light_toggle":
				if point_light.is_visible_in_tree():
					point_light.hide()
				else:
					point_light.show()
			"light_start_flicker":
				flicker_amount = func_godot_properties.get("flicker_amount", 0.0)
			"light_end_flicker":
				flicker_amount = 0
				point_light.light_energy = start_light_energy
			"light_toggle_flicker":
				if flicker_amount == 0:
					flicker_amount = func_godot_properties.get("flicker_amount", 0.0)
				else:
					flicker_amount = 0
					point_light.light_energy = start_light_energy
			_:
				var param_additional : PackedStringArray = parameter.split(': ', false)

				if parameter.contains("light_set_energy"):
					point_light.light_energy = param_additional[1].to_float()
					start_light_energy = point_light.light_energy 
				
				if parameter.contains("light_set_flicker"):
					flicker_amount = param_additional[1].to_float()
