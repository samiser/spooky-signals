extends Reciever

@export var func_godot_properties	: Dictionary
var signal_ID						: String
var scene_path						: String

func _ready() -> void:
	signal_ID	= func_godot_properties.get("signal_ID", "0")
	scene_path	= func_godot_properties.get("scene_path", "0")
	
	if !scene_path.contains("res://"):
		scene_path = "res://entities/3d_label/3d_label.tscn"
	
	connect_senders(signal_ID, signal_recieved)
	
	if func_godot_properties.get("autostart", false):
		await get_tree().process_frame
		signal_recieved("spawn_obj")

func signal_recieved(parameters: String) -> void:
	var param_list : PackedStringArray = parameters.split(', ', false)
	for parameter in param_list:
		match parameter:
			"spawn_obj":
				var spawn_obj : Node3D = load(scene_path).instantiate()
				get_tree().root.add_child(spawn_obj)
				
				spawn_obj.global_position = $".".global_position
				spawn_obj.global_rotation = $".".global_rotation
				
				print(str(name) + " spawned obj (" + scene_path + ") at " + str($".".global_position))
