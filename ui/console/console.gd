extends MarginContainer
class_name Console

@onready var output: TextEdit = $Control/VBoxContainer/PanelContainer/Output
@onready var line_edit: LineEdit = $Control/VBoxContainer/LineEdit
@onready var visibility_timer: Timer = $VisibilityTimer

@export var hide_on_startup: bool

var texts: = PackedStringArray()
var commands: Array[ConsoleCommand] = []

func print(text: Variant) -> void:
	print(str(text))
	if texts.size() == 50:
		texts.remove_at(0)
	texts.append(str(text))
	output.text = "  " + "\n  ".join(texts)
	output.scroll_vertical = texts.size()
	visible = true
	visibility_timer.start()

func _ready() -> void:
	output.text = ""
	Global.console = self
	line_edit.visible = false
	visibility_timer.stop()
	if hide_on_startup:
		visible = false
	commands.append(ConsoleCommand.new("cls", 0, func(_args):
		texts.clear()
		output.text = ""
	))

func _handle_command(command: String) -> void:
	var split: = command.split(" ")
	for c in commands:
		var com: ConsoleCommand = c
		if com.name != split[0]:
			continue
		var args: = split.slice(1)
		if com.num_args != -1 && com.num_args != args.size():
			self.print("/%s: Expected %d arguments, but got %d." % [split[0], com.num_args, args.size()])
		else:
			com.f.call(args)
		return
	self.print("/%s: No command with such name found." % split[0])

func _process(_delta) -> void:
	if Input.is_action_just_pressed("console_focus"):
		visible = true
		line_edit.visible = true
		line_edit.grab_focus()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("console_focus_command"):
		visible = true
		line_edit.visible = true
		line_edit.text = "/"
		line_edit.grab_focus()
		line_edit.caret_column = 1
		get_viewport().set_input_as_handled()

func _on_line_edit_text_submitted(new_text: String) -> void:
	line_edit.text = ""
	line_edit.release_focus()
	line_edit.visible = false
	if new_text != "":
		if new_text.begins_with("/"):
			_handle_command(new_text.substr(1).strip_edges())
		else:
			self.print(new_text)
	else:
		visible = not visibility_timer.is_stopped()

func _on_visibility_timer_timeout() -> void:
	if not line_edit.has_focus():
		visible = false

