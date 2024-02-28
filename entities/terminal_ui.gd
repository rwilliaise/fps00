extends Control

@onready var commands = get_parent().commands
var user = ""

func push_line(line):
	$RichTextLabel.append_text("[color=gray]%s[/color]\n" % line)

func _animation_finished(anim_name):
	if anim_name == "open":
		push_line("(c) Liasion Co.")
		push_line("Enter 'help' for more information.")
		$LineEdit.grab_focus()

func _submit_command(cmd):
	$LineEdit.clear()
	$RichTextLabel.append_text("%s@lnco $ %s\n" % [user, cmd])

	var split = cmd.strip_edges().split(" ")
	if commands.has(split[0]):
		commands[split[0]].callable.call(split)
	else:
		push_line("No command named %s" % split[0])

func _ui_open():
	$LineEdit.clear()
	$AnimationPlayer.play("open")

func _ui_close():
	$RichTextLabel.clear()
	size = Vector2(512, 32)

