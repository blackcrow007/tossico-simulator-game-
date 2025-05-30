extends PanelContainer

# Signal emitted when a choice is made by the player.
signal choice_selected(choice_index: int)

# UI Element References
@onready var prompt_label: Label = $VBoxContainer/PromptLabel
@onready var choice_buttons_container: HBoxContainer = $VBoxContainer/ButtonsContainer
# Note: The actual path for ButtonsContainer might be VBoxContainer/HBoxContainer
# if ButtonsContainer is meant to be a direct child of the main VBox.
# The provided path $VBoxContainer/ButtonsContainer implies ButtonsContainer is a sibling to PromptLabel.
# I will assume ButtonsContainer is inside the VBoxContainer along with PromptLabel for now.

# Array to store references to the actual button nodes
var _buttons: Array[Button] = []

func _ready():
	# Populate the _buttons array and connect signals
	if choice_buttons_container:
		for i in range(choice_buttons_container.get_child_count()):
			var child = choice_buttons_container.get_child(i)
			if child is Button:
				_buttons.append(child)
				child.connect("pressed", Callable(self, "_on_button_pressed").bind(child))
				child.hide() # Initially hide all buttons
			else:
				print("Non-button child found in ButtonsContainer: ", child.name)
	else:
		printerr("ChoicePopup: choice_buttons_container not found or path is incorrect. Check scene structure.")

	if prompt_label == null:
		printerr("ChoicePopup: prompt_label not found. Check scene structure.")

	self.hide() # Hide the popup itself initially

func _on_button_pressed(button_node: Button):
	var choice_index = _buttons.find(button_node)
	if choice_index != -1:
		emit_signal("choice_selected", choice_index)
		# Optional: Disable buttons to prevent multiple signals before hiding
		for btn in _buttons:
			btn.disabled = True
		self.hide()
	else:
		printerr("Pressed button not found in _buttons array. This should not happen.")

func display_choice(prompt_text: String, choices: Array[String]):
	if prompt_label:
		prompt_label.text = prompt_text
	else:
		printerr("ChoicePopup: prompt_label is null, cannot display prompt.")
		return

	if _buttons.is_empty() and choice_buttons_container: # Attempt to repopulate if empty (e.g. if ready was too early)
		print("ChoicePopup: _buttons array was empty, attempting to repopulate.")
		for i in range(choice_buttons_container.get_child_count()):
			var child = choice_buttons_container.get_child(i)
			if child is Button and not _buttons.has(child): # Check if not already added
				_buttons.append(child)
				if not child.is_connected("pressed", Callable(self, "_on_button_pressed")):
					child.connect("pressed", Callable(self, "_on_button_pressed").bind(child))
				# child.hide() # Don't hide here, visibility is set below

	if _buttons.is_empty():
		printerr("ChoicePopup: No buttons found to display choices.")
		return

	for i in range(_buttons.size()):
		if i < choices.size():
			_buttons[i].text = choices[i]
			_buttons[i].disabled = false # Re-enable button
			_buttons[i].show()
		else:
			_buttons[i].hide()

	self.show() # Show the entire popup

# Example of how to call this from another script:
# var choice_popup_instance = preload("res://ui/ChoicePopup.tscn").instantiate()
# get_tree().get_root().add_child(choice_popup_instance)
# choice_popup_instance.connect("choice_selected", Callable(self, "_on_my_choice_handler"))
# choice_popup_instance.display_choice("What do you want to do?", ["Option 1", "Option 2", "Leave"])

# func _on_my_choice_handler(index: int):
#     print("Player selected choice: ", index)
