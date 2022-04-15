extends Node2D

signal choice_selected(choice_idx)

const StoryChoice = preload("res://story/StoryChoice.tscn")
const DEFAULT_SCALE = Vector2(2, 2)

onready var ChoiceContainer = find_node("ChoiceContainer")

func create_choices(choices):
	var idx = 0
	for choice_text in choices:
		var c = StoryChoice.instance()
		c.rect_scale = DEFAULT_SCALE
		c.setup(idx, choice_text)
		ChoiceContainer.add_child(c)
		c.connect('choice_selected', self, 'choice_selected')
		idx += 1

func choice_selected(choice_idx):
	emit_signal("choice_selected", choice_idx)
