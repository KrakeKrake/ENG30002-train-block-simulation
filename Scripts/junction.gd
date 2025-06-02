extends Node2D
class_name Junction


@export var junction_id: String = "Junc01"
@onready var track_connections: Array[Tracks] = []
# Track : bool
var signal_dict = {}
var label: Label
var signals: Array = []


func _ready() -> void:
	label = $Label
	signal_dict = {}
	
# Asks the dict if the signal for the track given is true
func is_clear(track: Tracks):
	return signal_dict[track.block_id]

func _physics_process(delta: float) -> void:
	# OK
	# SO if this junction is at the END of a block, we ask for trains 
	# which are heading START TO END (Aka, with a direction of TRUE)
	# If this junc is at the start of a track, then we ask for 
	# trains heading from END TO START (AKA, direction of FALSE
	# Hardest thing in programming is naming things...
	var track: Tracks
	var sig: siggnal
	for i in range(track_connections.size()):
		track = track_connections[i]
		sig = signals[i]
		sig.set_label(track.block_id)
		var trains_headed_our_way: Array[Trains] = []
		if track.end_junc == self:
			trains_headed_our_way.append_array(track.trains_in_dir(false))
		elif track.start_junc == self:
			trains_headed_our_way.append_array(track.trains_in_dir(true))
		if trains_headed_our_way.size() > 0:
			signal_dict[track.block_id] = false # The next track has a RED signal
			sig.set_signal(false)
		else:
			signal_dict[track.block_id] = true
			sig.set_signal(true)


# Returns all the possible tracks that ARENT the input track... unless it's the only one
func possible_tracks(arrival_track: Tracks) -> Array:
	var to_return = []
	for track in track_connections:
		if track != arrival_track:
			to_return.append(track)
	if to_return.size() == 0:
		# If there are no tracks back it up
		return [arrival_track]
	return to_return

# Add another track to this Junction 
func add_connection(track: Tracks) -> void:
	var sig = load("res://signal.tscn").instantiate()
	if track not in track_connections:
		track_connections.append(track)
		signal_dict[track.block_id] = false
		add_child(sig)
		signals.append(sig)
		sig.position = Vector2(0, signals.size() * 20)
