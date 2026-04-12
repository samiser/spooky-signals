extends AnimatableBody3D
class_name Dial

var _active = false
var _player: Player

@export var max_value		: float = 50.0
@export var min_value		: float = 0.0
@export var value			: float = 0.0
@export var step			: float = 1.0

@export var drag_sensitivity: float = 0.1

@export var screen : Screen

var max_rotation : float = -160.0
var min_rotation : float = 160.0

func _ready() -> void:
	_update_rotation_from_value()
	$dial_base.top_level = true

func interact(player: Player) -> void:
	_player = player
	_player.interacting = true
	_active = true

func stop_interact() -> void:
	_active = false
	_player.interacting = false
	_player = null

func _input(event: InputEvent) -> void:
	if !_active:
		return

	if event.is_action_released("click"):
		stop_interact()

	if event is InputEventMouseMotion:
		_handle_motion(event)
		get_viewport().set_input_as_handled()
		return
	
	if event is InputEventKey or event is InputEventShortcut:
		get_viewport().set_input_as_handled()
		return

func _process(_delta: float) -> void:
	if !_active: return
	
	if screen.current_screen.has_method("control"):
		screen.current_screen.control(self, value)

func _handle_motion(event: InputEventMouseMotion) -> void:
	var dv := -event.relative.y * drag_sensitivity
	if dv == 0.0:
		return

	var new_val := value + dv

	if step > 0.0:
		new_val = round((new_val - min_value) / step) * step + min_value

	value = clampf(new_val, min_value, max_value)
	_update_rotation_from_value()

func _update_rotation_from_value() -> void:
	var range_v := max_value - min_value
	if absf(range_v) < 1e-6:
		return
	var t := (value - min_value) / range_v
	var angle_deg := lerpf(min_rotation, max_rotation, t)
	var r := rotation_degrees
	r.z = angle_deg
	rotation_degrees = r
