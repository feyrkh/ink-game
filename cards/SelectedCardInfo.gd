extends Control

onready var ControlContainer = find_node("ControlContainer")
onready var TextContainer = find_node("TextContainer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("show_card_info", self, "show_card_info")
	EventBus.connect("hide_card_info", self, "hide_card_info")

func hide_card_info():
	visible = false
	Util.delete_children(ControlContainer)

func show_card_info(item):
	if item.has_method("get_card_info"):
		var info = item.get_card_info()
		if info is Control:
			ControlContainer.add_chid(info)
			ControlContainer.visible = true
			TextContainer.visible = false
		elif info is String:
			TextContainer.find_node("Label").text = info
			TextContainer.visible = true
			ControlContainer.visible = false
		else:
			printerr("Unexpected card info type: ", info)
