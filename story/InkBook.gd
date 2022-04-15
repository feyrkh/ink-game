extends Node2D

const DEFAULT_SCALE = Vector2(1, 1)
const USE_SIGNALS = true
const MAX_HEIGHT = 470
const PAGEBREAK = '~#PB#~'
const IMAGE = 'img:'

const StoryParagraph = preload("res://story/StoryParagraph.tscn")
const StoryChoiceContainer = preload("res://story/StoryChoiceContainer.tscn")

var ErrorType := preload("res://addons/inkgd/runtime/enums/error.gd").ErrorType
var InkList := preload("res://addons/inkgd/runtime/lists/ink_list.gd") as GDScript

export var bind_externals: bool = false

var page_text = [[]]
var viewing_page_number = 0
var ready_for_page_update = false
var current_choice_container
onready var StagingArea:VBoxContainer = find_node("StagingArea")
onready var FinalPageCopy:VBoxContainer = find_node("FinalPageCopy")
onready var LeftPage:VBoxContainer = find_node("LeftPage")
onready var RightPage:VBoxContainer = find_node("RightPage")
onready var StoryChoices:Control = find_node("StoryChoices")
onready var inkPlayer:InkPlayer = find_node("InkPlayer")

func _ready():
	RightPage.rect_min_size = LeftPage.rect_min_size

	$InkPlayer.connect("loaded", self, "story_loaded")
	$InkPlayer.connect("continued", self, "story_continued")
	$InkPlayer.connect("prompt_choices", self, "story_prompt_choices")
	$InkPlayer.connect("ended", self, "story_ended")

	$InkPlayer.connect("exception_raised", self, "story_exception_raised")
	$InkPlayer.connect("error_encountered", self, "story_error_encountered")

	print(get_parent())
	if (get_parent() == get_tree().root):
		start_story('res://assets/ink/demo.ink.json')
	update_page_buttons()
	$PageBack.connect("pressed", self, 'page_back')
	$PageForward.connect("pressed", self, 'page_forward')

func update_page_buttons():
	var max_viewing_page = page_text.size() - 1
	max_viewing_page -= (max_viewing_page % 2)
	viewing_page_number = clamp(viewing_page_number, 0, max_viewing_page)
	$PageBack.visible = viewing_page_number > 0
	$PageForward.visible = viewing_page_number < max_viewing_page

func page_back():
	viewing_page_number -= 2
	rerender_pages()

func page_forward():
	viewing_page_number += 2
	rerender_pages()

func rerender_pages():
	Util.delete_children(LeftPage)
	Util.delete_children(RightPage)
	rerender_page(LeftPage, viewing_page_number)
	rerender_page(RightPage, viewing_page_number+1)
	update_page_buttons()

func rerender_page(page, page_idx):
	if page_idx < 0 or page_idx >= page_text.size():
		return
	var sentences = page_text[page_idx]
	for sentence in sentences:
		if sentence.begins_with(IMAGE):
			var img = build_image(sentence)
			page.add_child(img)
		else:
			var copy = build_paragraph(sentence)
			page.add_child(copy)

func build_paragraph(sentence):
	var copy = StoryParagraph.instance()
	copy.bbcode_text = sentence
	copy.connect("meta_hover_started", self, "meta_hover_started")
	copy.connect("meta_hover_ended", self, "meta_hover_ended")
	return copy

func build_image(text):
	var img = TextureRect.new()
	img.texture = load_texture_from_img_string(text)
	img.size_flags_horizontal = Control.SIZE_FILL
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return img

func start_story(resource_name, notify_obj=null, notify_method=null):
	var file = load(resource_name)
	$InkPlayer.ink_file = file
	if notify_obj and notify_method:
		$InkPlayer.connect("loaded", notify_obj, notify_method)
	$InkPlayer.create_story()

func _process(delta):
	if StagingArea.get_child_count() == 0:
		set_process(false)
		return
	if !ready_for_page_update:
		ready_for_page_update = true
		return
	ready_for_page_update = false
	var topText = StagingArea.get_child(0)
	var topTextHeight
	# Figure out the height of the newly added element
	if topText is TextureRect:
		topTextHeight = topText.rect_size.y
	else:
		topTextHeight = topText.get_content_height()

	# Remove the element from the staging area
	StagingArea.remove_child(topText)

	# create a copy of the element to insert into the main view, move the staged element to the 'final' page area
	var newly_inserted_element
	var history_string
	if ('bbcode_text' in topText):
		history_string = topText.bbcode_text
		newly_inserted_element = build_paragraph(history_string)
	elif topText is TextureRect:
		history_string = IMAGE+topText.texture.resource_path
		newly_inserted_element = build_image(history_string)

	if (history_string == PAGEBREAK):
		#page_text[-1].push_back(topText.bbcode_text)
		start_new_page()
		newly_inserted_element.queue_free()
	elif topTextHeight + FinalPageCopy.rect_size.y > MAX_HEIGHT:
		# We're about to overflow the last page, so start a new one
		start_new_page()
		page_text[-1].push_back(history_string)
		FinalPageCopy.add_child(topText)
		if viewing_page_number == page_text.size() - 2:
			# Our lefthand page is N, and our new page is N+1, so we can add this
			# text immediately, since the right-hand page was previously empty
			RightPage.add_child(newly_inserted_element)
		else:
			# Otherwise the new text must be going onto a page after the one
			# we're currently viewing, and we don't need to worry about updating
			# our visible pages and can discard the new element
			newly_inserted_element.queue_free()
	else:
		# We still have room, add this to the end of the current page
		page_text[-1].push_back(history_string)
		FinalPageCopy.add_child(topText)
		if viewing_page_number == page_text.size() - 1:
			# We're viewing the left page
			LeftPage.add_child(newly_inserted_element)
		elif viewing_page_number == page_text.size() - 2:
			# We're viewing the right page
			RightPage.add_child(newly_inserted_element)
		else:
			# We're viewing an older page and don't need to update our view
			newly_inserted_element.queue_free()
	update_page_buttons()

func start_new_page():
	page_text.push_back([])
	clear_final_page_copy()

func clear_final_page_copy():
	while FinalPageCopy.get_child_count() > 0:
		FinalPageCopy.remove_child(FinalPageCopy.get_child(0))
	FinalPageCopy.rect_size.y = 0

func story_continue_story():
	if USE_SIGNALS:
		$InkPlayer.continue_story()
	else:
		while $InkPlayer.can_continue:
			var text = $InkPlayer.continue_story()
			add_text(text)

		if $InkPlayer.has_choices:
			story_prompt_choices($InkPlayer.current_choices)
		else:
			story_ended()

func story_loaded(successfully):
	if !successfully:
		return

	story_evaluate_functions()
	story_continue_story()

func story_continued(text, tags):
	if 'pagebreak' in tags:
		add_text(PAGEBREAK)
	if text[-1] == '\n':
		text = text.substr(0, text.length()-1)
	add_text(text)

	$InkPlayer.continue_story()

func add_text(text):
	if text.begins_with(IMAGE):
		var img = build_image(text)
		StagingArea.add_child(img)
	else:
		var label = build_paragraph(text)
		StagingArea.add_child(label)
	set_process(true)
	ready_for_page_update = false

func story_prompt_choices(choices):
	if !choices.empty():
		current_choice_container = StoryChoiceContainer.instance()
		StoryChoices.add_child(current_choice_container)
		current_choice_container.create_choices(choices)
		current_choice_container.connect("choice_selected", self, "story_choice_selected")


func story_ended():
	# End of story: let's check whether you took the cup of tea.
	#var teacup = $InkPlayer.get_variable("teacup")
	pass


func story_choice_selected(index):
	current_choice_container.queue_free()

	$InkPlayer.choose_choice_index(index)
	story_continue_story()


func story_exception_raised(message, stack_trace):
	# This method gives a chance to react to a story-breaking exception.
	printerr(message)
	for line in stack_trace:
		printerr(line)


func story_error_encountered(message, type):
	match type:
		ErrorType.ERROR:
			printerr(message)
		ErrorType.WARNING:
			print(message)
		ErrorType.AUTHOR:
			print(message)

func story_observe_variables(variable_name, new_value):
	print("Variable '%s' changed to: %s" %[variable_name, new_value])


func story_bind_externals(varNameArray:Array, bindToObj:Object, bindToMethodName:String):
	# Externals are contextual to the story. Here, variables
	# 'forceful' & 'evasive' as well asfunction 'should_show_debug_menu'
	# only exists in The Intercept.
	$InkPlayer.observe_variables(varNameArray, bindToObj, bindToMethodName)
#	if !bind_externals:
#		return
#	$InkPlayer.observe_variables(["forceful", "evasive"], self, "story_observe_variables")

func get_story() -> InkPlayer:
	return inkPlayer

func story_evaluate_functions():
	pass

func meta_hover_started(data):
	pass

func meta_hover_ended(data):
	pass

func load_texture_from_img_string(img_string):
	var path = img_string.substr(IMAGE.length())
	if path.begins_with('res://'):
		return load(path)
	else:
		return load('res://'+path)
