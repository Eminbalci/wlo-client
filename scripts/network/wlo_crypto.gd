class_name WloCrypto
extends RefCounted

## Cryptographic cipher for Wonderland Online packet stream obfuscation.
## Implements the rolling congruential keystream cipher: K_{i+1} = (K_i * 3 + 7) & 0xFF.

const DEFAULT_SEED_KEY: int = 0xAD

var _rolling_key: int = DEFAULT_SEED_KEY

func _init(seed_key: int = DEFAULT_SEED_KEY) -> void:
	_rolling_key = seed_key

func reset(seed_key: int = DEFAULT_SEED_KEY) -> void:
	_rolling_key = seed_key

## In-place rolling XOR cipher transformation.
## Advances the internal cipher state for each byte.
func transform_in_place(buffer: PackedByteArray) -> void:
	for i in range(buffer.size()):
		buffer[i] ^= _rolling_key
		_rolling_key = (_rolling_key * 3 + 7) & 0xFF

## Transforms buffer and returns a new PackedByteArray.
func transform(source: PackedByteArray) -> PackedByteArray:
	var dest := source.duplicate()
	transform_in_place(dest)
	return dest

## Static single-byte symmetric XOR transform (legacy packet mode).
static func transform_static(data: PackedByteArray, key: int = DEFAULT_SEED_KEY) -> PackedByteArray:
	var result := data.duplicate()
	for i in range(result.size()):
		result[i] ^= key
	return result
