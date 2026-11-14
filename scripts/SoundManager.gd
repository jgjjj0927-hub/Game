extends Node

var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE := 8

var gunshot: AudioStreamWAV
var knife: AudioStreamWAV
var flesh: AudioStreamWAV
var sever: AudioStreamWAV

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	gunshot = _make_noise_burst(0.08, 0.9, 800.0, 0.3)
	knife = _make_noise_burst(0.12, 0.4, 2500.0, 0.7)
	flesh = _make_noise_burst(0.15, 0.6, 400.0, 0.5)
	sever = _make_noise_burst(0.25, 0.8, 200.0, 0.9)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	_players[0].stream = stream
	_players[0].volume_db = volume_db
	_players[0].pitch_scale = pitch
	_players[0].play()

func _make_noise_burst(duration: float, volume: float, filter_freq: float, roughness: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var prev := 0.0
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := exp(-t / (duration * 0.3))
		var noise := randf_range(-1.0, 1.0)
		var alpha := clamp(filter_freq / sample_rate, 0.0, 0.99)
		var filtered := prev + alpha * (noise - prev)
		prev = filtered
		var sample := filtered * env * volume * roughness
		var int_sample := int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
