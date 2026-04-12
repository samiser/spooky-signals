extends Reciever
class_name Player

@onready var character_body	: CharacterBody3D = $"."
@onready var camera			: Camera3D = $Camera3D
var camera_attached			: bool = true

var time_passed				: float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	default_height = $CollisionShape3D.shape.height
	default_fov = $Camera3D.fov
	
	$UI/locationLabel.text = ""
	
	connect_senders("player", signal_recieved)

#----------------------------------------------------
# Player Movement
#----------------------------------------------------

var allow_control		: bool = true
var is_grounded			: bool = true
var gravity				: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var jump_speed			: int = 4
var crouch_time			: float = 0.1
var crouch_height		: float = 1.1
var default_height		: float # set in _ready
var mouse_sensitivity	: float = 0.002
var lean_speed			: float = 2.0

var is_crouched			: bool = false
var is_sprinting		: bool = false
var released_crouch		: bool = false
var crouch_tween		: Tween

var default_fov			: float
var zoom_fov			: float = 40.0
var is_zoomed			: bool = false
var zoom_tween			: Tween

func _get_desired_inputs() -> Dictionary:
	var desired_move	: Vector2	= Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var desired_lean	: float	= Input.get_axis("lean_left", "lean_right")
	var desired_sprint	: bool	= Input.is_action_pressed("sprint")
	var desired_jump	: bool	= Input.is_action_just_pressed("jump")
	
	if !allow_control:
		desired_move = Vector2.ZERO
		desired_lean = 0.0
		desired_sprint = false
	
	return {
			"move"	: desired_move,
			"lean"	: desired_lean,
			"sprint": desired_sprint,
			"jump"	: desired_jump
			}

func _can_sprint(desired_move : Vector2) -> bool:
	return !is_crouched && is_grounded && desired_move != Vector2.ZERO && stamina_recovered

func _physics_process(delta):
	if !interacting:
		var desired_inputs	: Dictionary	= _get_desired_inputs()
		var desired_move	: Vector2		= desired_inputs.get("move")
		var desired_sprint	: bool			= desired_inputs.get("sprint")
		
		var movement_dir = character_body.transform.basis * Vector3(desired_move.x, 0, desired_move.y)
		
		is_sprinting = desired_sprint && _can_sprint(desired_move)
		is_grounded = character_body.is_on_floor()
		
		var current_speed : float = _get_move_speed(delta)
		
		character_body.velocity.x = movement_dir.x * current_speed
		character_body.velocity.z = movement_dir.z * current_speed
		
		if camera_attached:
			_set_camera_lean(desired_inputs.get("lean"), delta)
		
		if shake_time > 0.0:
			character_body.velocity += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * clampf(shake_time, 0.0, 1.0) * shake_magnitude * delta
			shake_time -= delta
		
		if is_grounded:
			_play_footstep_sounds(movement_dir.length() * current_speed, delta) 
			if desired_inputs.get("jump"):
				_jump()
	else:
		character_body.velocity.x = 0
		character_body.velocity.z = 0
	
	character_body.velocity.y += -gravity * delta
	character_body.move_and_slide()

var speed					: int = 4
var sprint_multiplier		: float = 1.6
var current_stamina			: float = 1.0
var current_stamina_delay	: float = 0.0
var stamina_loss_rate		: float = 0.22
var stamina_recover_rate	: float = 0.4
var stamina_recovered		: bool = true
var stamina_recover_delay	: float = 2.0
var shake_time				: float = 0.0
var shake_magnitude			: float = 128.0

func _get_move_speed(delta : float) -> float:
		var _speed : float = speed

		if is_sprinting:
			_speed *= sprint_multiplier
			current_stamina -= stamina_loss_rate * delta
			current_stamina_delay = stamina_recover_delay
			if current_stamina <= 0.0:
				stamina_recovered = false
		else:
			if is_alive:
				if current_stamina < 1.0:
					if current_stamina_delay > 0.0:
						current_stamina_delay -= delta
					else:
						current_stamina += stamina_recover_rate * delta
				else:
					stamina_recovered = true
			
		if is_crouched && is_grounded:
			_speed = speed / 2.0
		
		return _speed

func _jump() -> void:
	character_body.velocity.y = jump_speed

func _set_crouch(crouch : bool) -> void:
	if !crouch: # standing up
		var checks		: int = -1
		var body_radius : float = $CollisionShape3D.shape.radius

		while(checks < 4): # checks surrounding area of player if there's space to stand up
			var check_point : Vector3 = Vector3.FORWARD.rotated(Vector3.UP, checks * (PI / 2))
			check_point = check_point * body_radius
			
			if checks == -1: # check center
				check_point = Vector3.ZERO
				
			check_point.y += crouch_height
			
			$StandRayCheck.position = check_point
			$StandRayCheck.force_raycast_update()
			
			if $StandRayCheck.is_colliding():
				return
			else:
				checks += 1
			
		released_crouch = false

	if crouch_tween != null && crouch_tween.is_running():
		crouch_tween.stop()
	
	is_crouched = crouch
	var body_height	: float = 1.8
	var cam_height	: float = body_height - 0.1
	
	if is_crouched:
		body_height	= crouch_height
		cam_height	= body_height - 0.1
	
	crouch_tween = get_tree().create_tween()
	crouch_tween.tween_property($CollisionShape3D.shape, "height", body_height, crouch_time)
	crouch_tween.tween_property(camera, "position:y", cam_height, crouch_time)

func _set_camera_lean(lean_input : float, delta : float) -> void:
	camera.position.x			= move_toward(camera.position.x, lean_input * 0.32, delta * lean_speed)
	camera.rotation_degrees.z	= move_toward(camera.rotation_degrees.z, -lean_input * 14.0, delta * lean_speed * 64.0)

func _process(delta: float) -> void:
	time_passed += delta
	
	if !is_alive:
		var flash_colour := Color.RED * ((sin(time_passed * 10.0) / 2.0) + 1.0)
		$UI/VBoxContainer/Health/HealthBar.get("theme_override_styles/background").border_color = flash_colour
		$UI/VBoxContainer/Health/HealthBar.get("theme_override_styles/fill").border_color = flash_colour
		
	_set_crosshair_visibility()
	_stamina_ui()

#----------------------------------------------------
# Player UI
#----------------------------------------------------

@onready var stamina_bar_default_colour			: Color = $UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/fill").bg_color
@onready var stamina_bar_default_border_colour	: Color = $UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/fill").border_color

func _stamina_ui() -> void:
	if !stamina_recovered:
		var flash_colour : Color = Color.RED * ((sin(time_passed * 10.0) / 2.0) + 1.0)
		$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/background").border_color = flash_colour
		$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/fill").border_color = flash_colour
	else:
		$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/background").border_color = stamina_bar_default_border_colour
		$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/fill").border_color = stamina_bar_default_border_colour
					
	var display_stamina_bar : bool = current_stamina < 1.0
	$UI/VBoxContainer/Stamina.visible = display_stamina_bar
	
	if display_stamina_bar:
		var sprint_bar_colour : Color = Color(0.8, 0.3, 0.3, 1.0).lerp(stamina_bar_default_colour, current_stamina / 1.0)
		$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/fill").bg_color = sprint_bar_colour
		$UI/VBoxContainer/Stamina/StaminaBar.value = current_stamina

@onready var crosshair			: TextureRect = $UI/Crosshair
@onready var crosshair_default	: Texture2D = load("res://ui/crosshair_default.png")
@onready var crosshair_interact	: Texture2D = load("res://ui/crosshair_interact.png")

func _set_crosshair_visibility() -> void:
	if interacting || !camera_attached:
		crosshair.hide()
		$UI/interactLabel.text = ""
		return
	
	crosshair.show()
	if _looking_at_interactable():
		crosshair.texture = crosshair_interact
		if !is_zoomed:
			$UI/interactLabel.text = _looking_at_interactable().name
	else:
		crosshair.texture = crosshair_default
		$UI/interactLabel.text = ""

#----------------------------------------------------
# Player Footsteps
#----------------------------------------------------

@export var generic_step_sounds	: Array[AudioStream]
var step_timer					: float = 1.0
var step_rate					: float = 0.6

func _play_footstep_sounds(velocity : float, delta : float) -> void:
	step_timer -= velocity * step_rate * delta
	if step_timer <= 0.0:
		step_timer = 1.0
		$MovementSoundStream.volume_db = -24.0
		if is_crouched:
			$MovementSoundStream.volume_db = -36.0
		$MovementSoundStream.stream = generic_step_sounds[randi_range(0, generic_step_sounds.size() - 1)]
		$MovementSoundStream.pitch_scale = randf_range(0.9, 1.1)
		$MovementSoundStream.play()

#----------------------------------------------------
# Player Camera Zoom
#----------------------------------------------------

func toggle_zoom() -> void:
	if zoom_tween != null && zoom_tween.is_running():
		zoom_tween.stop()
	
	is_zoomed = !is_zoomed
	var zoom_level : float = zoom_fov if is_zoomed else default_fov
		
	zoom_tween = get_tree().create_tween()
	zoom_tween.tween_property($Camera3D, "fov", zoom_level, 0.14)

#----------------------------------------------------
# Player Interacting
#----------------------------------------------------

var interact_distance: float = 4.0
var interacting: bool = false
var current_interactable: Node3D 

func _unhandled_input(event: InputEvent) -> void: # TODO: split this up more
	if !allow_control:
		return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		character_body.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(80), deg_to_rad(80))
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("click"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_try_interact()
	
	if event.is_action_pressed("zoom"):
		if not interacting:
			toggle_zoom()
	
	if event.is_action_pressed("crouch"):
		if not interacting:
			_set_crouch(true)
			released_crouch = false
	if event.is_action_released("crouch"):
		released_crouch = true
	
	if is_crouched && released_crouch:
		if not interacting:
			_set_crouch(false)
	
	if event.is_action_released("click"):
		if interacting and current_interactable.has_method("on_release"):
			current_interactable.on_release()

func stop_interacting() -> void:
	interacting = false
	current_interactable = null

func _looking_at_interactable() -> Node3D:
	var from	: Vector3 = camera.global_transform.origin
	var to		: Vector3 = from + (-camera.global_transform.basis.z) * interact_distance

	var space_state	: PhysicsDirectSpaceState3D = character_body.get_world_3d().direct_space_state
	var query		: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var hit : Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return null

	var collider: Node3D = hit.collider

	if collider and collider.has_method("interact") and not (collider is Screen and not collider.current_screen is Terminal):
		return collider
	else:
		return null

func _try_interact():
	var interactable: Node3D = _looking_at_interactable()
	
	if interactable:
		interactable.interact(self)
		current_interactable = interactable

#----------------------------------------------------
# Player Damage/Death
#----------------------------------------------------

@export var generic_dmg_sounds	: Array[AudioStream]
@export var die_sounds			: Array[AudioStream]
var is_alive					: bool = true
var current_health				: float = 100.0
var health_bar_tween			: Tween
var damage_flash_tween			: Tween

func apply_damage(amount : float) -> void:
	if !is_alive:
		return
	
	if health_bar_tween != null && health_bar_tween.is_running():
		health_bar_tween.stop()
		
	$UI/VBoxContainer/Health/HealthBar.value = current_health
	current_health -= amount
	
	health_bar_tween = get_tree().create_tween()
	health_bar_tween.tween_property($UI/VBoxContainer/Health/HealthBar, "value", current_health, 0.2)
	var health_bar_colour : Color = Color(0.8, 0.3, 0.3, 1.0).lerp(stamina_bar_default_colour, current_health / 100.0)
	$UI/VBoxContainer/Health/HealthBar.get("theme_override_styles/fill").bg_color = health_bar_colour
	
	if damage_flash_tween != null && damage_flash_tween.is_running():
		damage_flash_tween.stop()
		
	damage_flash_tween = get_tree().create_tween()
	$UI/fadePanel.color = Color(0.5, 0.0, 0.0, 1.0)
	damage_flash_tween.tween_property($UI/fadePanel, "modulate:a", 0.2, 0.1)
	damage_flash_tween.tween_property($UI/fadePanel, "modulate:a", 0.0, 0.5)
	
	$AudioStreamPlayer2D.stream = generic_dmg_sounds[randi_range(0, generic_dmg_sounds.size() - 1)]
	$AudioStreamPlayer2D.play()
	
	shake_time = 1.0
	shake_magnitude = amount * 4.0
	
	if current_health <= 0.0:
		_die()
	else:
		await damage_flash_tween.finished
		$UI/fadePanel.color = Color.BLACK

func _die() -> void:
	is_alive = false
	allow_control = false
	
	$AudioStreamPlayer2D.stream = die_sounds[randi_range(0, die_sounds.size() - 1)]
	$AudioStreamPlayer2D.play()
	
	signal_recieved("player_fade_out")
	
	var cam_drop_tween := get_tree().create_tween()
	var dead_cam_height = 0.6 if is_crouched else 0.1

	cam_drop_tween.tween_property(camera, "position:y", dead_cam_height, 0.6)
	cam_drop_tween.parallel().tween_property(camera, "rotation_degrees:z", 20 * randi_range(-1, 1), 0.6)
	
	await get_tree().create_timer(4.0).timeout
	_respawn()

func _respawn() -> void:
	allow_control			= true
	is_alive				= true
	current_health			= 100.0
	current_stamina			= 1.0
	current_stamina_delay	= 0.0
	
	if is_crouched:
		_set_crouch(false)
	
	signal_recieved("player_camera_reset, player_teleport: 0 0 0, player_fade_in")
	
	$UI/VBoxContainer/Stamina/StaminaBar.value = 1.0
	$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/background").border_color = stamina_bar_default_border_colour
	$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/fill").border_color = stamina_bar_default_border_colour
	$UI/VBoxContainer/Stamina/StaminaBar.get("theme_override_styles/fill").bg_color = stamina_bar_default_colour
	
	$UI/VBoxContainer/Health/HealthBar.value = 100.0
	$UI/VBoxContainer/Health/HealthBar.get("theme_override_styles/fill").border_color = stamina_bar_default_border_colour
	$UI/VBoxContainer/Health/HealthBar.get("theme_override_styles/fill").bg_color = stamina_bar_default_colour
	$UI/VBoxContainer/Health/HealthBar.get("theme_override_styles/background").border_color = stamina_bar_default_border_colour

#----------------------------------------------------
# Player Signals
#----------------------------------------------------

var next_subtitle_priority	: int = 1
var next_subtitle_time		: float = 1.0

func signal_recieved(parameters: String) -> void: # TODO: Split this up more
	var param_list : PackedStringArray = parameters.split(', ', false)
	
	for parameter in param_list:
		match parameter:
			"player_gravity_on":
				gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
			"player_gravity_off":
				gravity = 0.0
			"player_control_off":
				allow_control = false
			"player_control_on":
				allow_control = true
			"player_control_toggle":
				allow_control = !allow_control
			"player_fade_in":
				var tween := get_tree().create_tween()
				tween.tween_property($UI/fadePanel, "color", Color.BLACK, 2.0)
				tween.parallel().tween_property($UI/fadePanel, "modulate:a", 0.0, 2.0).from(1.0)
			"player_fade_out":
				var tween := get_tree().create_tween()
				tween.tween_property($UI/fadePanel, "color", Color.BLACK, 2.0)
				tween.parallel().tween_property($UI/fadePanel, "modulate:a", 1.0, 2.0).from(0.0)
			"player_camera_reset":
				camera.top_level = false
				
				var body_height := 1.8
				var cam_height := body_height - 0.1
				if is_crouched:
					cam_height = body_height - 0.1
					
				camera.position = Vector3.ZERO
				camera.position.y = cam_height
				
				camera.fov = default_fov
				
				camera.rotation = Vector3.ZERO
				camera_attached = true
				_set_crosshair_visibility()
			_:
				var param_additional : PackedStringArray = parameter.split(': ', false)

				if parameter.contains("player_update_location_ui"):
					if $UI/locationLabel.text == param_additional[1]:
						return
					
					$UI/locationLabel.text = param_additional[1]
					var tween := get_tree().create_tween()
					tween.tween_property($UI/locationLabel, "visible_ratio", 1, 0.4).from(0.0) 
				
				if parameter.contains("player_gravity_set"):
					gravity = param_additional[1].to_float()
				
				if parameter.contains("player_shake_time"):
					shake_time = param_additional[1].to_float()
				
				if parameter.contains("player_shake_magnitude"):
					shake_magnitude = param_additional[1].to_float()
				
				if parameter.contains("player_teleport"):
					var teleport_string : PackedStringArray = parameter.split(' ', false)
					character_body.global_position.x = teleport_string[1].to_float()
					character_body.global_position.y = teleport_string[2].to_float()
					character_body.global_position.z = teleport_string[3].to_float()
				
				if parameter.contains("player_angle"):
					character_body.global_rotation_degrees.y = param_additional[1].to_float()
				
				if parameter.contains("player_camera_pos"):
					var cam_string : PackedStringArray = parameter.split(' ', false)
					camera.global_position.x = cam_string[1].to_float()
					camera.global_position.y = cam_string[2].to_float()
					camera.global_position.z = cam_string[3].to_float()
					
					camera.top_level = true
					camera_attached = false
					camera.fov = default_fov
					_set_crosshair_visibility()
				
				if parameter.contains("player_camera_rot"):
					var cam_string : PackedStringArray = parameter.split(' ', false)
					camera.global_rotation_degrees.x = cam_string[1].to_float()
					camera.global_rotation_degrees.y = cam_string[2].to_float()
					camera.global_rotation_degrees.z = cam_string[3].to_float()
				
				if parameter.contains("player_set_subtitle"):
					param_additional[1] = param_additional[1].replace('/', ',')
					print(param_additional[1] + " (" + str(next_subtitle_priority) + ", " + str(next_subtitle_time) + "s)")
					
					var subtitle_label :RichTextLabel= $UI/SubtitleContainer/Subtitle.duplicate()
					$UI/SubtitleContainer.add_child(subtitle_label)
					subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					subtitle_label.text = param_additional[1]
					subtitle_label.visible = true
					
					var delete_timer := get_tree().create_timer(next_subtitle_time)
					await delete_timer.timeout

					var display_tween := get_tree().create_tween()
					display_tween.tween_property(subtitle_label, "modulate:a", 0.0, 3.0)
					await display_tween.finished
					subtitle_label.queue_free()
					
				if parameter.contains("player_subtitle_priority"):
					next_subtitle_priority = param_additional[1].to_int()
				
				if parameter.contains("player_subtitle_time"):
					next_subtitle_time = param_additional[1].to_float()
				
				if parameter.contains("player_damage"):
					apply_damage(param_additional[1].to_float())
