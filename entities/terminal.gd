extends Node3D

@export var user = ""

var commands = {
	help = { callable = help, help = "displays information about commands" },
	ping = { callable = ping, help = "sends ping to network objects" },
	scan = { callable = scan, help = "scans local area using connected radars" }, 
	route = { callable = route, help = "routes elevator to facility level" },
}

func route(argv):
	if argv.size() > 1:
		if Network.sections.has(argv[1]):
			if Network.current_sector == argv[1]:
				$UI.push_line("Already at %s." % argv[1])
				return
			var section = Network.sections[argv[1]] 
			Network.route(argv[1])
			$UI.push_line("Routing to %s\n[indent]%s[/indent]" % [argv[1], section.help])
		else:
			$UI.push_line("%s not found." % argv[1])
	else:
		$UI.push_line("Usage: route [sector]\n\nSectors:")
		for key in Network.sections.keys():
			$UI.push_line("%s%s" % [key, " <- YOU'RE HERE" if Network.current_sector == key else ""])

func scan(_argv):
	$UI.push_line("Network is inaccessible")

func ping(_argv):
	$UI.push_line("Network is inaccessible")

func help(argv):
	if argv.size() > 1:
		if commands.has(argv[1]):
			$UI.push_line("%s\t%s" % [argv[1], commands[argv[1]].help])
		else:
			$UI.push_line("%s not found." % argv[1])
	else:
		for command in commands.keys():
			$UI.push_line("%s\t%s" % [command, commands[command].help])

func _interact():
	Hud.open_ui($UI)

func _ready():
	$UI.user = user

