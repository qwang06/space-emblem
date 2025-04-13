# This script manages the display and interaction of a dialog box in the game.
extends MarginContainer

var dialog_data = []
var utils = Utils.new()
var _current_chapter = {}
var _current_sequence = 0
var _continue_icon = null
var _continue_tween = null

@onready var cursor = %Cursor

func _ready() -> void:
	_continue_icon = utils.find_descendant_by_name(self, "ContinueIcon")
	# Load the JSON file
	var file = FileAccess.open("res://assets/dialog/test.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()

		if error == OK:
			dialog_data = json.get_data()
		else:
			print("Error parsing JSON: ", error)
	else:
		print("File does not exist")

func _process(_delta: float) -> void:
	# Check if the dialog box is visible
	if self.is_visible():
		animate_continue_icon()

# Set dialog data by string chapterId
func set_dialog_data_by_chapter(chapterId: String) -> void:
	var chapter = get_dialog_data_by_chapter(chapterId)
	if chapter:
		_current_chapter = chapter
		_current_sequence = 0

		# Set the content label text
		var content_label = get_content_label()
		var title_label = get_title_label()
		# var portrait_label = get_portrait_label()
		
		# Get the dialog sequence
		var dialog_sequence = chapter.get("dialogSequence", [])
		var num_of_dialog = dialog_sequence.size()
		if num_of_dialog > 0:
			content_label.text = dialog_sequence[0].get("text", "")
			title_label.text = dialog_sequence[0].get("speaker", "")

			# If there is more dialog, show the continue icon
			if num_of_dialog > 1:
				_continue_icon.show()
		else:
			print("No dialog sequence found in chapter: ", chapterId)
	else:
		print("Chapter not found with ID: ", chapterId)
		return

# Next dialog sequence
func next() -> void:
	var content_label = get_content_label()
	var title_label = get_title_label()
	# var portrait_label = get_portrait_label()

	# Get the dialog sequence
	var dialog_sequence = _current_chapter.get("dialogSequence", [])
	_current_sequence += 1
	# Check if there is a next dialog
	if _current_sequence >= dialog_sequence.size() - 1:
		_continue_icon.hide()
	if dialog_sequence.size() > _current_sequence:
		content_label.text = dialog_sequence[_current_sequence].get("text", "")
		title_label.text = dialog_sequence[_current_sequence].get("speaker", "")
	else:
		print("No dialog sequence found in chapter: ", _current_chapter["chapterId"])
		return

func start() -> void:
	# Show the dialog box
	self.show()

	# Hide the cursor
	cursor.hide()

func animate_continue_icon() -> void:
	if (
		(_continue_tween and _continue_tween.is_running())
		or not _continue_icon 
		or not _continue_icon.is_visible()
	):
		return

	var current_position = _continue_icon.position
	var new_position = current_position + Vector2(0, -5) # Move down by 10 pixels

	# Set a tween to animate the ContinueIcon
	_continue_tween = get_tree().create_tween();
	_continue_tween.tween_property(_continue_icon, "position", new_position, 1)
	_continue_tween.tween_property(_continue_icon, "position", current_position, 1)
	_continue_tween.set_loops()

# ===================================================================
# Utility functions
# ===================================================================
func get_dialog_data() -> Array:
	return dialog_data

func get_dialog_data_by_chapter(id: String) -> Dictionary:
	for chapter in dialog_data:
		if chapter.has("chapterId") and chapter["chapterId"] == id:
			return chapter
	return {}

func get_dialog_data_by_index(index: int) -> Dictionary:
	if index >= 0 and index < dialog_data.size():
		return dialog_data[index]
	return {}

# Get content label
func get_content_label() -> Label:
	return utils.find_descendant_by_name(self, "Content")

# Get portrait label
func get_portrait_label() -> TextureRect:
	return utils.find_descendant_by_name(self, "Portrait")

# Get title label
func get_title_label() -> Label:
	return utils.find_descendant_by_name(self, "Title")

# ===================================================================
# Signal handlers
# ===================================================================
func _on_cursor_confirm_pressed(tile: Vector2i) -> void:
	print("Cursor confirm pressed at tile: ", tile)

	# Check if the dialog box is visible
	if self.is_visible():
		# Call the next function to show the next dialog sequence
		next()
