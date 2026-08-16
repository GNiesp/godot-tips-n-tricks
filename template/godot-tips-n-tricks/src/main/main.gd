## This node always stays as a root of the scene tree
class_name Main extends Node


func _ready() -> void:
    SignalBus.main_loaded.emit()