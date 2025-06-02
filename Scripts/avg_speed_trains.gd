extends Label


var update: bool = false
var avg_speed: float

# Wait to be triggered because on start bunch of values will be null!
func get_data():
	update = true
	
# Get every train every physics_process 
# (60 times per second, or it tries to be at least)
func _physics_process(delta: float) -> void:
	var trains = get_tree().get_nodes_in_group("Gaggle_of_trains")
	avg_speed = 0
	# Sum all the trains speed, divide by num of trains
	# Multiply to get kmh!
	for train: Trains in trains:
		avg_speed += train.speed
	avg_speed /= get_tree().get_node_count_in_group("Gaggle_of_trains")
	avg_speed *= 3.6
	var speed_string = str("%.3f" % avg_speed)
	text = "Avg. speed: " + speed_string + "km/h"
