extends Node2D


@onready var operation_label = $OperationLabel

var operation_value: int = 0
var is_blank: bool = false


func set_operation(value: int) -> void:
	is_blank = false
	operation_value = value

	if value >= 0:
		operation_label.text = "+" + str(value)
	else:
		operation_label.text = str(value)


func set_blank() -> void:
	is_blank = true
	operation_value = 0
	operation_label.text = ""


func get_operation() -> int:
	return operation_value


func get_is_blank() -> bool:
	return is_blank