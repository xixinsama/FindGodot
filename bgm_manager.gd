extends AudioStreamPlayer

# 当前播放的音乐资源路径（用于避免重复加载）
var current_music_path: String = ""

# 播放背景音乐
# 参数 path: 音乐文件的资源路径，如 "res://music/bgm.ogg"
# 参数 volume_db: 音量（分贝），默认为 0（最大）
func play_music(path: String, bgm_volume_db: float = 0.0):
	# 如果当前已经在播放同一首音乐，且未停止，则不做操作（避免重复触发）
	if current_music_path == path and playing:
		return

	# 停止当前播放
	stop_music()

	# 加载新的音频流
	var new_stream = load(path) as AudioStream
	if new_stream:
		stream = new_stream
		volume_db = bgm_volume_db
		play()
		current_music_path = path
	else:
		push_error("无法加载音频文件: ", path)

# 停止音乐
func stop_music():
	stop()
	current_music_path = ""

# 设置音量（分贝）
func set_volume(bgm_volume_db: float):
	volume_db = bgm_volume_db

# 获取当前音量
func get_volume() -> float:
	return volume_db
