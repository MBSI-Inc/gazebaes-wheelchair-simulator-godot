extends Node

@export var brain_command_port: int = 8053
@export var frame_port: int = 8052
@export var gaze_track_command_port: int = 8051
@export var screenshot_fetcher: Node

var is_moving: bool = false
var target_turn_rate: float = 0.0
var target_speed: float = 10.0
var user_input_trigger: Array = []
var last_received_udp_packet: String = ""
var all_received_udp_packets: String = ""

var _gaze_thread: Thread
var _tcp_thread: Thread

var _gaze_client = PacketPeerUDP.new()
var _brain_client = PacketPeerUDP.new()

func _ready():
	user_input_trigger.resize(5)
	for i in range(5):
		user_input_trigger[i] = false

	print("Listening for movement command on 127.0.0.1:", gaze_track_command_port)

	_gaze_client.listen(gaze_track_command_port)
	_brain_client.listen(brain_command_port)

	_gaze_thread = Thread.new()
	_gaze_thread.start(_receive_data)

	_tcp_thread = Thread.new()
	_tcp_thread.start(_connect_screenshot_fetcher)

func _exit_tree():
	_gaze_thread.wait_to_finish()
	_tcp_thread.wait_to_finish()

# ===============================
# UDP RECV LOGIC
# ===============================
func _receive_data(userdata = null):
	var timer := Time.get_ticks_msec()
	while true:
		if _gaze_client.get_available_packet_count() > 0:
			var pkt = _gaze_client.get_packet()
			var text = pkt.get_string_from_utf8()
			print(">> UDP listener received data: ", text)
			var parts = text.split(" ", false)
			if parts.size() < 2:
				continue
			var command = parts[0]
			var value = parts[1]
			if command == "c":
				if value == "move":
					if Time.get_ticks_msec() - timer > 125:
						is_moving = not is_moving
						timer = Time.get_ticks_msec()
				elif value == "input_0":
					user_input_trigger[0] = true
			elif command == "d":
				var trimmed = value.substr(1, value.length() - 2)
				var values = trimmed.split(",")
				if values.size() >= 2:
					var _target_speed = float(values[0])
					var _target_turn_rate = float(values[1])
					target_speed = _target_speed
					target_turn_rate = _target_turn_rate

		OS.delay_msec(10)

# ===============================
# TCP FRAME SERVER LOGIC
# ===============================
func _connect_screenshot_fetcher(userdata = null):
	var server = TCPServer.new()
	print("Starting TCP Server at ", frame_port)
	server.listen(frame_port)
	while true:
		if server.is_connection_available():
			var client = server.take_connection()
			print("Client connected.")
			var stream = client.get_stream_peer()
			while stream.get_available_bytes() > 0:
				var received = stream.get_utf8_string(stream.get_available_bytes())
				print("Received:", received)
				var frame_bytes: PackedByteArray = screenshot_fetcher.call("get_camera_view_byte_array")
				var length_header = PackedByteArray()
				length_header.resize(4)
				length_header.encode_u32(0, frame_bytes.size())
				var msg = length_header + frame_bytes
				stream.put_data(msg)
			client.disconnect_from_host()
		OS.delay_msec(100)

# ===============================
# UTILS / PUBLIC API
# ===============================
func get_latest_direction() -> float:
	return target_turn_rate

func get_latest_target_speed() -> float:
	return target_speed

func get_latest_movement() -> bool:
	return is_moving

func get_input_trigger(i: int = 0) -> bool:
	if user_input_trigger[i]:
		user_input_trigger[i] = false
		return true
	return false
