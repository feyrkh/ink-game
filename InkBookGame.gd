extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$InkBook.start_story('res://assets/ink/new_game.ink.json', self, "story_loaded")
	pass

func story_loaded(successfully):
	var story:InkPlayer = $InkBook.get_story()
	story.connect("ended", self, 'new_character_created')

func new_character_created():
	var new_char = load("res://game/Character.tscn").instance()
