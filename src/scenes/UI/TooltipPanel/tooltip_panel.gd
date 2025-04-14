# This is the generic tooltip panel that will be used to display tooltips/hints
# It will use a timer to hide itself after a certain amount of time
# The timer will refresh if tooltip is triggered again
# It will also have a fade in and fade out animation
# It will have methods to show and hide the tooltip
extends PanelContainer

@onready var timer = $Timer
@onready var label = $Label

func _ready() -> void:
	# Connect the timer to the hide function
	timer.timeout.connect(hide_tooltip)


# TODO: Fix tooltip, it still sometimes hide too quickly
func show_tooltip(text: String, duration: float = 3) -> void:
	# Set the text of the label
	label.text = text

	timer.start(duration)

	# Show the tooltip
	self.show()
	self.modulate.a = 0.0  # Set initial alpha to 0 for fade-in effect
	get_tree().call_group("tweens", "kill", self)

	# Use tween to fade in the tooltip
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)


func hide_tooltip() -> void:
	# Only fade out if the tooltip is fully visible
	if self.modulate.a > 0.0:
		# Use tween to fade out the tooltip
		var tween = get_tree().create_tween()
		tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
		tween.tween_callback(self.hide)

