extends Spatial

const PCCardEntity:PackedScene = preload("res://cards/impl/PCCardEntity.tscn")

onready var CardTable = find_node("CardTable")

func _ready() -> void:
	new_game()
	EventBus.emit_signal("change_address", "")

func new_game():
	var player = PCCardEntity.instance()
	player.setup("", Vector3(0, 0, 0), "Feyr")
	EventBus.emit_signal("register_entity", "", player.data["name"], player)

