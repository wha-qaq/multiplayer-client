extends Control

func start_playing():
	if !PlayerAuth.can_login():
		$AuthPanel.show()
		return
	
	

func _ready():
	pass
