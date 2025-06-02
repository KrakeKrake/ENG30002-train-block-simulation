extends TabContainer

var update: bool = false


# When called, the function kinda starts
# Has to be this way otherwise null stuff happens
func get_data():
	var trains = get_tree().get_nodes_in_group("Gaggle_of_trains")
	for train: Trains in trains:
		var richtext = RichTextLabel.new()
		richtext.name = train.train_name
		add_child(richtext)
		update = true


func _physics_process(delta: float) -> void:
	# Get the state of trains and display it basically
	if update:
		for child in get_children():
			if child is not RichTextLabel:
				continue
				var train_state: String
			var train: Trains = get_train_with_name(child.name)
			if not train: continue
			var train_state: String
			match train.current_state:
				train.state.Accelerate:
					train_state = "Accelerating"
				train.state.Brake:
					train_state = "Slowing"
				train.state.EmergancyBrake:
					train_state = "Full Brake"
				train.state.Maintain:
					train_state = "Cruise"
				train.state.Stopped:
					train_state = "Full stop"
			var format_string = "Speed: %s\nState: %s\nTrack: %s\nNext Track: %s\nNext Junc: %s\nDistance Ahead: %s\nStop Distance: %s\nEmer. Stop Distance: %s"
			var actual_string = format_string % [str("%.3f" % train.speed), train_state, train.current_track.block_id,
			train.next_track.block_id, train.next_junc.junction_id, "%.3f" % train.distance_ahead, 
			"%.3f" % train.stopping_dist_comf, "%.3f" % train.stopping_dist_emergancy]
			child.text = actual_string

# Get the train based on the it's name alone (how the tabs are organised)
func get_train_with_name(train_des: String):
	var trains = get_tree().get_nodes_in_group("Gaggle_of_trains")
	
	for train: Trains in trains:
		if train.train_name == train_des:
			return train
	return null
	
