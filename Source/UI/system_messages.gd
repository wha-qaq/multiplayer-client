extends Control

@export var from_bottom = false

@onready var example = $Label
@onready var container = $Container

func show_message(text : String):
	var clone = example.duplicate()
	clone.text = text
	container.add_child(clone)
	if not from_bottom:
		container.move_child(clone, 0)
	
	var tween = clone.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	clone.modulate.a = 0
	clone.show()
	
	tween.tween_property(clone, "modulate:a", 1, 0.8).from(0).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1 + minf(len(text) * 0.025, 3.5))
	tween.tween_property(clone, "modulate:a", 0, 0.8).from(1)
	tween.tween_callback(clone.queue_free)

func _ready():
	if from_bottom:
		container.alignment = BoxContainer.ALIGNMENT_END
	
	var found = MessagingSystem.flush_messages()
	for message in found:
		show_message(message)
	MessagingSystem.on_message.connect(show_message)
