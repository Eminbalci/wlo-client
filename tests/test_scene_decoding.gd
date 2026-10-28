extends SceneTree

func _init() -> void:
	var file_path = "res://assets/data/SceneData.dat"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open SceneData.dat")
		quit(1)
		return
	var data = file.get_buffer(file.get_length())
	var rec_size: int = 131
	var total_records: int = data.size() / rec_size
	print("Total records in SceneData.dat: ", total_records)
	
	var count_offset_0: int = 0
	var count_offset_6: int = 0
	
	for i in range(1, total_records):
		var offset: int = i * rec_size
		var rec = data.slice(offset, offset + rec_size)
		
		var raw0: int = rec.decode_u16(0)
		var id0: int = ((raw0 ^ 0xea6c) - 9) & 0xffff
		
		var raw6: int = rec.decode_u16(6)
		var id6: int = ((raw6 ^ 0xea6c) - 9) & 0xffff
		
		# Reverse name bytes to inspect
		for ebx in range(1, 11):
			var i1: int = ebx + 8
			var i2: int = 21 - ebx + 8
			var tmp: int = rec[i1]
			rec[i1] = rec[i2]
			rec[i2] = tmp
		
		var name_bytes = rec.slice(9, 29)
		var nul = name_bytes.find(0)
		if nul != -1: name_bytes = name_bytes.slice(0, nul)
		var name_str = name_bytes.get_string_from_ascii()
		
		if id0 in [10001, 10002, 10003, 11096, 33298]:
			print("Record %d: offset0 id=%d raw=0x%x, offset6 id=%d raw=0x%x, name='%s'" % [i, id0, raw0, id6, raw6, name_str])
	
	quit(0)
