extends RichTextLabel

const UNHOVERED_COLOR = Color.black
const HOVERED_COLOR = Color.red

signal choice_selected(choice_idx)

func _ready():
	modulate = UNHOVERED_COLOR
	connect('meta_hover_started', self, 'meta_hover_started')
	connect('meta_hover_ended', self, 'meta_hover_ended')

func setup(choice_idx, choice_text):
	bbcode_text = '[url={data="choice"}]'+choice_text+"[/url]"
	connect("meta_clicked", self, 'choice_selected', [choice_idx])

func choice_selected(metadata, choice_idx):
	emit_signal('choice_selected', choice_idx)

func meta_hover_started(meta_data):
	modulate = HOVERED_COLOR

func meta_hover_ended(meta_data):
	modulate = UNHOVERED_COLOR
