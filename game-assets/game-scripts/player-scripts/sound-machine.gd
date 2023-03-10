extends Node
tool
class_name SoundMachine

enum Type{
	A_OMNI,
	A_2D
}

enum MixTarget{
	 MIX_TARGET_STEREO = 0,
	 MIX_TARGET_SURROUND = 1,
	 MIX_TARGET_CENTER = 2
}

export(Resource) var sound_collection
export(float, -80, 24, 0.1) var main_volume_db = 0.0
export(float, 0.01, 4.00, 0.01) var main_pitch_scale = 1.0
export(int, "Stereo", "Surround", "Center") var mix_target : int = MixTarget.MIX_TARGET_STEREO
var bus:String setget set_bus, get_bus

var _instantied_players = {} setget _set_instantied_players

func play(audio_name : String, from : float = 0.0) -> void:
	if sound_collection.has_sound(audio_name):
		var stream: AudioStreamPlayer = _setup_and_add_stream(Type.A_OMNI, audio_name)
		stream.play(from)
	else:
		print("do not have %s audio" % audio_name)

func play_2d(audio_name : String, from:float = 0.0, position:Vector2 = Vector2.ZERO):
	if sound_collection.has_sound(audio_name):
		var stream: AudioStreamPlayer2D = _setup_and_add_stream(Type.A_2D, audio_name)
		stream.global_position = position
		stream.play(from)

func _setup_and_add_stream(stream_:int, audio_name:String):
	var stream
	if !_instantied_players.has(audio_name):
		match stream_:
			Type.A_OMNI:
				stream = AudioStreamPlayer.new()
			Type.A_2D:
				stream = AudioStreamPlayer2D.new()
		_instantied_players[audio_name] = stream
		stream.connect('finished', self, 'delete_stream', [audio_name])
	else:
		stream = _instantied_players[audio_name]
	stream.set_stream(sound_collection.get_sound(audio_name))
	stream.set_volume_db(main_volume_db - 10)
	stream.set_pitch_scale(main_pitch_scale)
	stream.set_bus(bus)
	add_child(stream)
	return stream

func stop(audio_name : String):
	if _instantied_players.has(audio_name):
		_instantied_players[audio_name].stop()
	delete_stream(audio_name)

func get_stream(audio_name : String) -> AudioStream:
	var audio = sound_collection.get_audio(audio_name)
	assert (audio == null, "Audio name not exist")
	return audio

func delete_stream(audio_name:String):
	if _instantied_players.has(audio_name):
		var stream = _instantied_players[audio_name]
		_instantied_players.erase(audio_name)
		if stream.is_inside_tree():
			stream.queue_free()

func set_bus(val : String) -> void:
	bus = val

func get_bus() -> String:
	for i in AudioServer.get_bus_count():
		if AudioServer.get_bus_name(i) == bus:
			return bus
	return 'Master'

func _get_property_list():
	var properties = []
	
	# Bus property
	var bus_hint_string := ""
	for i in AudioServer.get_bus_count():
		if AudioServer.get_bus_name(i):
			bus_hint_string += AudioServer.get_bus_name(i) + ","
	bus_hint_string.erase(bus_hint_string.length()-1, 1)
	properties.append({
		"name": "bus",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": bus_hint_string
	})
	
	return properties

func _set_instantied_players(val : Dictionary):
	_instantied_players = val
