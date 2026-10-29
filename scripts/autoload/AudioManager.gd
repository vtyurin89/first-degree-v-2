extends Node

const BUS_NAME := "WorldAmbience"

var _bus_index := -1
var _reverb: AudioEffectReverb
var _lowpass: AudioEffectLowPassFilter


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()


func set_zone(_zone_name: String, room_size: float, damping: float, cutoff_hz: float) -> void:
	if _reverb != null:
		_reverb.room_size = clampf(room_size, 0.0, 1.0)
		_reverb.damping = clampf(damping, 0.0, 1.0)
	if _lowpass != null:
		_lowpass.cutoff_hz = clampf(cutoff_hz, 20.0, 20500.0)


func _ensure_bus() -> void:
	_bus_index = AudioServer.get_bus_index(BUS_NAME)
	if _bus_index == -1:
		AudioServer.add_bus()
		_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_index, BUS_NAME)
		AudioServer.set_bus_send(_bus_index, "Master")
	_reverb = _find_or_add_reverb()
	_lowpass = _find_or_add_lowpass()


func _find_or_add_reverb() -> AudioEffectReverb:
	for index in AudioServer.get_bus_effect_count(_bus_index):
		var effect := AudioServer.get_bus_effect(_bus_index, index)
		if effect is AudioEffectReverb:
			return effect
	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.6
	reverb.damping = 0.4
	reverb.wet = 0.2
	reverb.dry = 1.0
	AudioServer.add_bus_effect(_bus_index, reverb)
	return reverb


func _find_or_add_lowpass() -> AudioEffectLowPassFilter:
	for index in AudioServer.get_bus_effect_count(_bus_index):
		var effect := AudioServer.get_bus_effect(_bus_index, index)
		if effect is AudioEffectLowPassFilter:
			return effect
	var lowpass := AudioEffectLowPassFilter.new()
	lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(_bus_index, lowpass)
	return lowpass
