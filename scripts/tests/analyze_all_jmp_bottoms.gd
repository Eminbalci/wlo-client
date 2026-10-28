extends SceneTree

func _init() -> void:
	var histogram = {}
	var samples_per_bottom = {}
	
	var parser1 = preload("res://scripts/core/jma_parser.gd").open_jma("res://assets/jma/001.jma")
	if parser1:
		for entry_name in parser1._entries.keys():
			if not entry_name.ends_with(".jmp"): continue
			var anim = parser1.get_jmp_animation(entry_name)
			if not anim or anim.frames.is_empty(): continue
			var total = anim.frames.size()
			var idx = 32 if total >= 64 else (16 if total >= 32 else 0)
			if idx >= total: idx = 0
			var f = anim.frames[idx]
			var b = f.pivot_y + f.height
			histogram[b] = histogram.get(b, 0) + 1
			if not samples_per_bottom.has(b):
				samples_per_bottom[b] = []
			if samples_per_bottom[b].size() < 3:
				samples_per_bottom[b].append(entry_name)
				
	print("--- JMP Stand Bottom Y Distribution (001.jma) ---")
	var keys = histogram.keys()
	keys.sort()
	for k in keys:
		print("  bottom_y=%d: count=%d, samples=%s" % [k, histogram[k], str(samples_per_bottom[k])])
	quit(0)
