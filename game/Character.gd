extends Node
class_name Character

const INK_VARS = ['char_name', 'pn_he', 'pn_him', 'pn_his']

var char_name = "Mysterious Stranger"
var pn_he = "he"
var pn_him = "him"
var pn_his = "his"

func load_from_story(ink_player:InkPlayer):
	for v in INK_VARS:
		set(v, ink_player.get_variable(v))

func load_into_story(ink_player:InkPlayer, prefix=''):
	for v in INK_VARS:
		ink_player.set_variable(prefix+v, get(v))
