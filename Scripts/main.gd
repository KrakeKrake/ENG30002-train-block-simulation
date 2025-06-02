extends Node2D

# Define the node that holds all the track stuff
var Track_Network: Node2D


func _ready() -> void:
	# Assign it to the node
	Track_Network = $Network
	# Create tracks in a triangle
	# Technicallity means they always want to "enter" stations
	# from the left and leave from the right? So they cross over often...
	# Doesn't effect the simulation tho, just looks odd
	create_track(Vector2(200.0, 50.0), Vector2(550.0, 50.0))
	create_track(Vector2(550.0, 50.0), Vector2(380.0, 390.0))
	create_track(Vector2(380.0, 390.0), Vector2(200.0, 50.0))
	
	# For every track, create two trains 
	for i in Track_Network.get_children():
		if i is Tracks:
			create_train(i, true if randi_range(0, 1) == 1 else false)
			create_train(i, true if randi_range(0, 1) == 1 else false)
			create_train(i, true if randi_range(0, 1) == 1 else false)
			create_train(i, true if randi_range(0, 1) == 1 else false)
			create_train(i, true if randi_range(0, 1) == 1 else false)
			create_train(i, true if randi_range(0, 1) == 1 else false)
	get_tree().call_group("get_data_after_timer", "get_data")
	#var tracks: Array[Tracks] = []
	#for i in Track_Network.get_children():
		#if i is Tracks:
			#tracks.append(i)
	#create_train(tracks[0], true, 0.5)
	#create_train(tracks[1], true, 1.0)
	#create_train(tracks[0], false, 0.5)
	#create_train(tracks[1], false, 1.0)
	#get_tree().call_group("get_data_after_timer", "get_data")
	

func create_train(track: Tracks, at_start: bool = true, progress: float = randf_range(0, 1)):
	# Instantiate and place the trains on a track, random direction
	# Random starting position!
	var new_train: Trains = load("res://train.tscn").instantiate()
	new_train.place_on_track(track, progress, at_start)
	# Hehe, gaggle of gavis... Godot groups are REALLY useful...
	new_train.add_to_group("Gaggle_of_trains")
	# The track needs to keep a record of what trains are on it
	track.trains.append(new_train)
	
func create_track(start_point: Vector2, end_point: Vector2) -> Tracks:
	var new_track = load("res://tracks.tscn").instantiate()
	# Start point calculation
	# It'll snap to any nearby point (Idea of placing tracks was abandoned tho)
	# Unnecessary but does no harm 
	var start_data = junc_near_point(start_point)
	var end_data = junc_near_point(end_point)
	# Format
	# Junction: junc
	# pos: Junc.position
	var start_junc: Junction
	var end_junc: Junction
	# If there is a junction near the start, attach it to the track!
	# Otherwise create a junction there
	if start_data:
		start_point = start_data.pos
		new_track.start_junc = start_data.junction
	else:
		new_track.start_junc = load("res://junction.tscn").instantiate()
		Track_Network.add_child(new_track.start_junc)
	if end_data:
		end_point = end_data.pos
		new_track.end_junc = end_data.junction
	else:
		new_track.end_junc = load("res://junction.tscn").instantiate()
		Track_Network.add_child(new_track.end_junc)
		
	# Assign a bunch of ponts and connections to keep track of
	new_track.start_junc.position = start_point
	new_track.end_junc.position = end_point
	new_track.start_junc.add_connection(new_track)
	new_track.end_junc.add_connection(new_track)
	Track_Network.add_child(new_track)
	new_track.initialise(start_point, end_point)
	
	# Give the Tracks some nice indioviduality
	new_track.block_id = "Track_" + str(Track_Network.get_child_count())
	new_track.start_junc.junction_id = "Junc_" + str(start_point.x) + "_" + str(start_point.y)
	new_track.end_junc.junction_id = "Junc_" + str(end_point.x) + "_" + str(end_point.y)
	return new_track

	
func junc_near_point(point: Vector2, threshold: float = 5.0) -> Dictionary:
	var children = Track_Network.get_children()
	var closest = threshold
	var result = {}
	# Just get nearby junctions (within 5.0 distance) to snap to
	for junc in children:
		if junc is Junction:
			var start_dist = junc.position.distance_to(point)
			if start_dist <= closest:
				closest = start_dist
				result = {
					"junction": junc,
					"pos": junc.position
				}
			var end_dist = junc.position.distance_to(point)
			if end_dist <= closest:
				closest = end_dist
				result = {
					"junction": junc,
					"pos": junc.position
				}
				
	if result.is_empty():
		return {}
	return result

# This is a signal.
# When anoter node (in this case the horizontal slider) is adjusted
# It emits a "signal", and triggers this function 
# And passes it's value too it. So I can mess with stuff!
func _on_h_slider_value_changed(value: float = 1.0) -> void:
	Engine.time_scale = value
	$Controls/Label.text = "Time Scale: x" + str(value)
