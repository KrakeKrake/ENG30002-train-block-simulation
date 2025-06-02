extends Node2D
class_name Trains

@export var accel: float = 1.3 # In m/s^2
@export var decel: float = -0.85 # In m/s^2
@export var emergancy_decel: float = -1.05
@export var train_length: int = 6 # In carriages
@export var moving_block: bool = true
var next_junc: Junction
# Otherwise it will constantly flip between tracks
var train_name = "Train!"
var transfer_cooldown = 0.0
const TRANSFER_COOLDOWN_TIME = 0.1
var label: Label
var stopped: bool = false
var current_track: Tracks = null
var next_track: Tracks = null
var speed: float = 0.0  # Current speed
var target_speed: float = 40.277777 # Speed targeted
# METRO actually limits trains to 130kmh, but HCMT can reach 140kmh
# Speed is good btw 
var start_to_end: bool # false = end_to_start true = start to end
var progress: float = 0.0 # 1.0 is finished
var progress_meters: float = 0.0
# PathFollow2D allows the train to move really...
var path_follow: PathFollow2D
# Distance to the start and end of the track
var distance_to_start: float
var distance_to_end: float
enum state {Accelerate, Brake, EmergancyBrake, Maintain, Stopped}
var current_state = state.Accelerate
var dist_to_infront: float
var distance_ahead: float = 100.0
var stopping_dist_comf
var stopping_dist_emergancy
var safety_buffer = 10 # In meters how close other trains are allowed to get to each other when stationary
func _ready() -> void:
	label = $Label
	train_name = "train_" + str(get_tree().get_node_count_in_group("Gaggle_of_trains") + 1)
	label.text = train_name
		
func _physics_process(delta: float) -> void:
	# Do physics maths here!
	
	# Nice physics to get stopping distances, IRL there should be more taken into account probs...
	stopping_dist_comf = (speed * speed) / (2 * abs(decel))
	stopping_dist_emergancy = (speed * speed) / (2 * abs(emergancy_decel))
	
	# Ask the next junction if the next track is clear
	# False means we gotta stop
	# True means full steam ahea
	var next_signal
	if next_junc and next_track:
		next_signal = next_junc.is_clear(next_track)
	else: # Ig just be true then?
		next_signal = true
	
	# Simple switch for, are we using the moving block or signal system
	if moving_block:
		var next_track_direction = (next_junc == next_track.start_junc) 
		# Distance ahead... this only works for trains in the same block
		# Some bug I can't work out for trains on the next block? Idk
		distance_ahead = min(
		current_track.closest_distance_to_train_in_dir(start_to_end, self),
		abs(current_track.track_length - progress_meters) + next_track.closest_distance_to_train_in_dir(next_track_direction, self))
		# distance_ahead is the distance to the train ahead/ if not then it's just a big number
		
		# Set states based on stuff
		if distance_ahead < safety_buffer:
			current_state = state.EmergancyBrake
		elif distance_ahead < safety_buffer + stopping_dist_emergancy:
			current_state = state.EmergancyBrake
		elif distance_ahead < safety_buffer + stopping_dist_comf:
			current_state = state.Brake
		elif distance_ahead < safety_buffer + stopping_dist_comf + 10: 
			current_state = state.Maintain
		else:
			if speed == target_speed:
				current_state = state.Maintain
			else:
				current_state = state.Accelerate
		
		
		
	else:
		if not next_signal: # So if the signal is false (RED)
			if speed > 0.5:
				if distance_to_end - 5 <= stopping_dist_emergancy: 
					current_state = state.EmergancyBrake
				elif distance_to_end - 5 <= stopping_dist_comf:
					current_state = state.Brake
				elif distance_to_end > stopping_dist_comf or distance_to_end > current_track.track_length/4:
					current_state = state.Accelerate
				else:
					current_state = state.Stopped
		else:
			current_state = state.Accelerate
	
	# Do the state
	match current_state:
		state.Accelerate:
			speed = min(speed + accel * delta, target_speed)
		state.Brake:
			speed = max(speed + decel * delta, 0)
		state.EmergancyBrake:
			speed = max(speed + emergancy_decel * delta, 0)
		state.Maintain:
			speed = speed
		state.Stopped:
			speed = 0
	
	# Update progress and positions 
	var current_progress = path_follow.progress
	if start_to_end:
		path_follow.progress = current_progress + (speed * delta)
		progress_meters = path_follow.progress
	else:
		path_follow.progress = current_progress - (speed * delta)
		progress_meters = current_track.track_length - path_follow.progress
	progress = path_follow.progress_ratio
	distance_to_start = progress_meters
	distance_to_end = current_track.track_length - progress_meters
	transfer_cooldown += delta
	
	# If we are at the end of the track.
	# Unrealistically... (For signal system only) the train is forced to stop 
	# No matter the speed, at a red signal, but they still try to brake
	if (progress >= 1.0 and start_to_end) or (progress <= 0.0 and not start_to_end):
		if moving_block:
			# If we are in moving block
			# The cooldown solves a bug with them getting stuck
			# forever switching tracks at junctions otherwise
			if transfer_cooldown > 0.5:
				handle_end_of_run()
		else:
			if next_signal and transfer_cooldown > 0.5:
				handle_end_of_run()
			else:
				# So yeah, stops the train if red
				speed = 00.0
				current_state = state.Stopped
	
	
# At the end of the block (and green signal) do this stuff!
func handle_end_of_run() -> void:
	var new_start_to_end: bool
	if next_junc == next_track.start_junc:
		new_start_to_end = true
		# Because the junc we are heading to/at is the 
		# Start junc for the next track
	elif next_junc == next_track.end_junc:
		new_start_to_end = false
	
	# Remove train from current PathFollow2D and track
	if get_parent():
		var old_path_follow = get_parent()
		old_path_follow.remove_child(self)
		old_path_follow.get_parent().remove_child(old_path_follow)
		old_path_follow.queue_free()
	
	# Todo with the arrays that hold trains
	current_track.remove_train(self) # Remove self from the finished track
	current_track = next_track
	current_track.trains.append(self) # Add to the list of trains on the new track
	# Add new
	path_follow = PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = true
	current_track.path.add_child(path_follow)
	path_follow.add_child(self)
	position = Vector2.ZERO
	
	# IF we are starting from the start progress is now 0.0
	# If we are starting from the end it's 1.0
	if new_start_to_end:
		path_follow.progress_ratio = 0.0
		next_junc = current_track.end_junc
		progress = 0.0
		progress_meters = 0.0
	else: 
		path_follow.progress_ratio = 1.0
		next_junc = current_track.start_junc
		progress = 1.0
		progress_meters = current_track.track_length
	# Maintain speed here (Target speed basically can't be reached?)
	speed = min(speed, target_speed)
	current_state = state.Accelerate
	start_to_end = new_start_to_end
	next_track = next_junc.possible_tracks(current_track)[0]
	transfer_cooldown = 0.0


# Place the train on the given track, at the given progress (0.0-1.0) in this direction
func place_on_track(track: Tracks, progress: float, at_start: bool):
	
	current_track = track
	path_follow = PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = true
	
	current_track.path.add_child(path_follow)
	path_follow.add_child(self)
	if at_start:
		path_follow.progress_ratio = progress
		next_junc = current_track.end_junc
		progress = progress
		progress_meters = current_track.track_length * progress
		next_junc = current_track.end_junc
	else: 
		rotation = PI
		path_follow.progress_ratio = progress
		next_junc = current_track.start_junc
		progress = progress
		progress_meters = current_track.track_length * progress
		next_junc = current_track.start_junc
	next_track = next_junc.possible_tracks(track)[0]
	
	
	start_to_end = at_start
	
	
	
	
	
	
	
	
	
	
