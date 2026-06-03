extends Node

onready var tween_out = get_node("Tween")
onready var tween_in = get_node("Tween2")

var music_data = [{"track_name": "Old BGM #1", "loop_begin": 769201, "loop_end": 8641727}, {"track_name": "Old BGM #2", "loop_begin": 769901, "loop_end": 5378207}, {"track_name": "Old BGM #3", "loop_begin": 1053066, "loop_end": 6449731}, {"track_name": "Old BGM #4", "loop_begin": 770254, "loop_end": 7681129}, {"track_name": "Old BGM #5", "loop_begin": 608466, "loop_end": 3035100}, {"track_name": "Old BGM #6", "loop_begin": 1322177, "loop_end": 6698233}, {"track_name": "Old BGM #7", "loop_begin": 888428, "loop_end": 5319191}, {"track_name": "Old BGM #8", "loop_begin": 2882064, "loop_end": 6338191}, {"track_name": "Banana Beats", "loop_begin": 480000}, {"track_name": "Big Man Zaroff", "loop_begin": 480000}, {"track_name": "Capsule Machine", "loop_begin": 480000}, {"track_name": "Hex of Funkiness", "loop_begin": 480000}, {"track_name": "Instant Ramen", "loop_begin": 480000}, {"track_name": "Rainbow Peppers", "loop_begin": 480000}, {"track_name": "Spin to Win!", "loop_begin": 480000}, {"track_name": "The Mouse Song", "loop_begin": 480000}, {"track_name": "Bird Whistle", "loop_begin": 355367}, {"track_name": "Essence Party", "loop_begin": 0}, {"track_name": "Guillotine Dance", "loop_begin": 353297}, {"track_name": "Roll of the Dice", "loop_begin": 271837}, {"track_name": "Landlocked", "loop_begin": 240000}, {"track_name": "Mad for Money", "loop_begin": 240000}]
var current_music_node
var current_track
var current_loops

func _free_if_orphaned():
	if not is_inside_tree():
		queue_free()

func _init():
	if not Utils.is_connected("freeing_orphans", self, "_free_if_orphaned"):
		Utils.connect("freeing_orphans", self, "_free_if_orphaned")

func _ready():
	if current_music_node == null:
		current_music_node = $"Music"

func play_set_music(track_name):
	tween_in.remove_all()
	tween_out.remove_all()
	current_loops = 0
	for m in music_data:
		if m.track_name == track_name:
			current_track = m
			break
	current_music_node.stop()
	current_music_node.volume_db = $"/root/Main/Options Sprite/Options".music.goal_volume
	if current_music_node == $"Music":
		current_music_node = $"Music2"
	else:
		current_music_node = $"Music"
	var track = current_track.track_name
	if current_track != null and current_track.track_name.substr(0, 9) == "Old BGM #":
		track = "bgm" + str(int(current_track.track_name.substr(9, 1)) - 1)
	current_music_node.set_stream(load("res://music/%s.ogg" % str(track)))
	current_music_node.volume_db = $"/root/Main/Options Sprite/Options".music.goal_volume
	current_music_node.stream.loop_offset = current_track.loop_begin / 48000.0
	if $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
		current_music_node.play(0)

func play_rand_music():
	current_loops = 0
	var music_arr = []
	var backup_music_arr = []
	for i in range(music_data.size() - 2):
		if $"/root/Main/Pop-up Sprite/Pop-up".emails.size() > 0 and $"/root/Main/Pop-up Sprite/Pop-up".emails[0].type == "ending" and not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
			if $"/root/Main/Options Sprite/Options".tracks[music_data[i].track_name][0] == 0 and $"/root/Main/Options Sprite/Options".tracks[music_data[i].track_name][1] == 1:
				music_arr.push_back(music_data[i])
			elif $"/root/Main/Options Sprite/Options".tracks[music_data[i].track_name][1] == 1:
				backup_music_arr.push_back(music_data[i])
		elif $"/root/Main/Pop-up Sprite/Pop-up".endless_mode and not $"/root/Main/Options Sprite/Options".visible and not $"/root/Main/Title".visible:
			if $"/root/Main/Options Sprite/Options".tracks[music_data[i].track_name][1] == 1:
				music_arr.push_back(music_data[i])
		else:
			if $"/root/Main/Options Sprite/Options".tracks[music_data[i].track_name][0] == 1:
				music_arr.push_back(music_data[i])
	if music_arr.size() == 0:
		if backup_music_arr.size() > 0:
			music_arr = backup_music_arr
		else:
			return
	var m_tbe = []
	for m in music_arr:
		if current_track != null and current_track.track_name == m.track_name and music_arr.size() > 1:
			m_tbe.push_back(m)
	for m in m_tbe:
		music_arr.erase(m)
	randomize()
	current_track = music_arr[floor(rand_range(0, music_arr.size()))]
	if current_music_node == $"Music":
		current_music_node = $"Music2"
	else:
		current_music_node = $"Music"
	var track = current_track.track_name
	if current_track != null and current_track.track_name.substr(0, 9) == "Old BGM #":
		track = "bgm" + str(int(current_track.track_name.substr(9, 1)) - 1)
	current_music_node.set_stream(load("res://music/%s.ogg" % str(track)))
	current_music_node.volume_db = $"/root/Main/Options Sprite/Options".music.goal_volume - 20
	current_music_node.stream.loop_offset = current_track.loop_begin / 48000.0
	if $"/root/Main/Options Sprite/Options".music.goal_volume > -80:
		current_music_node.play(0)

func fade_out():
	if not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not OS.is_window_focused()) and current_music_node.volume_db > $"/root/Main/Options Sprite/Options".music.goal_volume - 8:
		tween_out.interpolate_property(current_music_node, "volume_db", current_music_node.volume_db, $"/root/Main/Options Sprite/Options".music.goal_volume - 8, 2.00, 1, Tween.EASE_IN, 0)
		tween_out.start()

func fully_fade_out():
	if not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not OS.is_window_focused()) and current_music_node.volume_db > $"/root/Main/Options Sprite/Options".music.goal_volume - 80:
		tween_out.interpolate_property(current_music_node, "volume_db", current_music_node.volume_db, $"/root/Main/Options Sprite/Options".music.goal_volume - 80, 2.00, 1, Tween.EASE_IN, 0)
		tween_out.start()

func fade_in():
	if not ($"/root/Main/Options Sprite/Options".mute_while_in_background and not OS.is_window_focused()) and current_music_node.volume_db <= $"/root/Main/Options Sprite/Options".music.goal_volume:
		tween_in.interpolate_property(current_music_node, "volume_db", current_music_node.volume_db, $"/root/Main/Options Sprite/Options".music.goal_volume, 2.00, 1, Tween.EASE_IN, 0)
		tween_in.start()

func report_errors(err, filepath):
	var result_hash = {
		ERR_FILE_NOT_FOUND: "File: not found",
		ERR_FILE_BAD_DRIVE: "File: Bad drive error",
		ERR_FILE_BAD_PATH: "File: Bad path error.",
		ERR_FILE_NO_PERMISSION: "File: No permission error.",
		ERR_FILE_ALREADY_IN_USE: "File: Already in use error.",
		ERR_FILE_CANT_OPEN: "File: Can't open error.",
		ERR_FILE_CANT_WRITE: "File: Can't write error.",
		ERR_FILE_CANT_READ: "File: Can't read error.",
		ERR_FILE_UNRECOGNIZED: "File: Unrecognized error.",
		ERR_FILE_CORRUPT: "File: Corrupt error.",
		ERR_FILE_MISSING_DEPENDENCIES: "File: Missing dependencies error.",
		ERR_FILE_EOF: "File: End of file (EOF) error."
	}
	if err in result_hash:
		print("Error: ", result_hash[err], " ", filepath)
	else:
		print("Unknown error with file ", filepath, " error code: ", err)

func loadfile(filepath):
	var file = File.new()
	var err = file.open(filepath, File.READ)
	if err != OK:
		report_errors(err, filepath)
		file.close()
		return AudioStreamSample.new()

	var bytes = file.get_buffer(file.get_len())

	if filepath.ends_with(".wav"):

		var newstream = AudioStreamSample.new()

		for i in range(0, 100):
			var those4bytes = str(char(bytes[i])+char(bytes[i+1])+char(bytes[i+2])+char(bytes[i+3]))
			
			if those4bytes == "RIFF": 
				pass
			if those4bytes == "WAVE": 
				pass
			if those4bytes == "fmt ":
				var formatsubchunksize = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
				var fsc0 = i+8

				var format_code = bytes[fsc0] + (bytes[fsc0+1] << 8)
				var format_name
				if format_code == 0: format_name = "8_BITS"
				elif format_code == 1: format_name = "16_BITS"
				elif format_code == 2: format_name = "IMA_ADPCM"
				newstream.format = format_code
				
				var channel_num = bytes[fsc0+2] + (bytes[fsc0+3] << 8)
				if channel_num == 2: newstream.stereo = true
				var sample_rate = bytes[fsc0+4] + (bytes[fsc0+5] << 8) + (bytes[fsc0+6] << 16) + (bytes[fsc0+7] << 24)
				newstream.mix_rate = sample_rate
				var byte_rate = bytes[fsc0+8] + (bytes[fsc0+9] << 8) + (bytes[fsc0+10] << 16) + (bytes[fsc0+11] << 24)
				var bits_sample_channel = bytes[fsc0+12] + (bytes[fsc0+13] << 8)
				var bits_per_sample = bytes[fsc0+14] + (bytes[fsc0+15] << 8)
			if those4bytes == "data":
				var audio_data_size = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)

				var data_entry_point = (i+8)
				
				newstream.data = bytes.subarray(data_entry_point, data_entry_point+audio_data_size-1)
		var samplenum = newstream.data.size() / 4
		newstream.loop_end = samplenum
		newstream.loop_mode = 0
		return newstream
	else:
		print ("ERROR: Wrong filetype or format")
	file.close()