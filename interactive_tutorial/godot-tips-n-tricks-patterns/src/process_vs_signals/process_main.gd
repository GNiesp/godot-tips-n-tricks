extends Node

@onready var hp_label: Label = %HPLabel
@onready var money_label: Label = %MoneyLabel

func _process(_delta: float) -> void:
    hp_label.text = str(ProcessSourceOfTruth.player_hp)
    money_label.text = str(ProcessSourceOfTruth.player_money)


func _ready() -> void:
    ProcessSourceOfTruth.player_hp_changed.connect(_on_player_hp_changed)
    ProcessSourceOfTruth.player_money_changed.connect(_on_player_money_changed)

func _on_player_hp_changed(hp: int):
    hp_label.text = str(hp)

func _on_player_money_changed(money: int):
    money_label.text = str(money)
