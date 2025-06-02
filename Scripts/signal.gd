extends Node2D
class_name siggnal
# VISUAL ONLY

var label: Label
var poly: Polygon2D

# My naming sense is impeccible
func _ready():
	label = $Label
	poly = $"Signal uhhh"

# Sets the text for what track it represents
func set_label(input: String):
	label.text = input

# Changes red and green 
func set_signal(input: bool):
	if input:
		poly.color = Color.GREEN
	else:
		poly.color = Color.RED
