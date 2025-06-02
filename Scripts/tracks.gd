extends Node2D
class_name Tracks

@export var speed_limit: float = 50
@export var bi_directional: bool = true
@export var block_id: String = "block_01"  # For signaling system

var start_pos: Vector2
var end_pos: Vector2

@onready var follow: PathFollow2D

@onready var path: Path2D
@onready var track_length: float = 0.0 # in meters

@onready var line: Line2D

@onready var start_junc: Junction # The junction at the start
@onready var end_junc: Junction # Guess what

var trains: Array[Trains] = []

func _ready() -> void:
	path = get_node("Path")
	line = get_node("TrackLine")
	

func initialise(start_point: Vector2, end_point: Vector2, _point_array: Array[Vector2] = []) -> void:
	start_pos = start_point
	end_pos = end_point
	
	var curve = Curve2D.new()
	# For making it look nice, makes it curvy rather than straight line
	var distance = start_point.distance_to(end_point)
	var control_offset = distance
	curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(control_offset, 0))
	curve.add_point(
		end_point - start_point,
		Vector2(-control_offset, 0),
		Vector2.ZERO
	)
	position = start_point
	path.curve = curve
	
	if path:
		track_length = calculate_track_length()
		
		line.width = 5.0
		line.default_color = Color(0.0, 0.0, 0.0)
		
		var point_count = 100
		for i in range(point_count + 1):
			var t = float(i) / float(point_count)
			var point_pos = curve.sample_baked(t * curve.get_baked_length())
			line.add_point(point_pos)
	
func remove_train(train: Trains):
	trains.erase(train)
	
func trains_in_dir(direction: bool):
	var to_return: Array
	for train in trains:
		if train.start_to_end == direction:
			# True is clockwise
			to_return.append(train)
	return to_return

# Still makes me unhappy...
func closest_distance_to_train_in_dir(dir: bool, train_requesting: Trains):
	var closest_distance = 1000.0

	for train in trains:
		if train == train_requesting or train.start_to_end != dir:
			continue 
		
		var distance_to_train = train.progress_meters - train_requesting.progress_meters
		if distance_to_train > 0 and distance_to_train < closest_distance:
			closest_distance = distance_to_train
		
	return closest_distance
	

func calculate_track_length() -> float:
	var curve = path.curve

	# For case of no curves
	if curve.get_point_count() < 2:
		return 0.0
	
	# Use the baked length for more accurate measurement
	return curve.get_baked_length()




func connect_to_start(track: Tracks) -> void:
	start_junc.add_connection(track)
func connect_to_end(track: Tracks) -> void:
	end_junc.add_connection(track)
