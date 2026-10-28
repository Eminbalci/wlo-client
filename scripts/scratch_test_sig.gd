extends SceneTree

signal sig_zero
signal sig_one(path: String)

func _init() -> void:
	var on_cutscene_done: Callable = func(_arg = null) -> void:
		print("Signal fired successfully with arg: ", _arg)
	sig_zero.connect(on_cutscene_done)
	sig_one.connect(on_cutscene_done)
	print("Emitting sig_zero...")
	sig_zero.emit()
	print("Emitting sig_one...")
	sig_one.emit("res://maps/test.tscn")
	quit()
