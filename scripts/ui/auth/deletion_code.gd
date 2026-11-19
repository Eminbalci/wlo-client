class_name DeletionCode
extends RefCounted

## Character deletion code. The code is typed when a character is created and asked again before
## it is deleted. Only a SHA-256 hash is stored with the character, never the code itself.
## Characters created before this existed have no hash and are deleted without a code, as before.

static func hash_code(code: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(code.to_utf8_buffer())
	return ctx.finish().hex_encode()


static func matches(code: String, stored_hash: String) -> bool:
	return stored_hash != "" and hash_code(code) == stored_hash
