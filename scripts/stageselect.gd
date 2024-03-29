extends Node2D

var state = "select"
var min_bg_move = 1
var max_bg_move = 15
var bg_move = min_bg_move
var transition_alpha = 1
var change_alpha = 0.1
var move_timer = - 1
var max_move_timer = 120
var confirmed_stage = false
var last_highlighted_stage = global.STAGE.dojo

onready  var audio = get_node("AudioStreamPlayer")
onready  var bg_grid = get_node("bg_grid")
onready  var bg_grid2 = get_node("bg_grid2")
onready  var transition = get_node("transition")
onready  var preview_stage = get_node("preview_stage")
onready  var sportraits = get_node("sportraits")
onready  var sportrait_player = get_node("sportraits/sportrait_dojo")
onready  var menu_yesno = get_node("menu_yesno")

onready  var msc_charselect = preload("res://sounds/charselect.ogg")
onready  var snd_select = preload("res://sounds/select.ogg")
onready  var snd_select2 = preload("res://sounds/select2.ogg")

func _ready():
	transition.visible = true
	if not global_audio.playing:
		global_audio.stream = msc_charselect
		global_audio.play(0)

func _process(delta):
	if global.steam_enabled:
		Steam.run_callbacks()
		
		if global.mode == global.MODE.online_lobby:
			if not confirmed_stage:
				var packet_size = Steam.getAvailableP2PPacketSize(0)
				while packet_size > 0:
					var packet_dict = Steam.readP2PPacket(packet_size, 0)
					var packet = packet_dict["data"]
					var sender_id = packet_dict["steamIDRemote"]
					var packet_type = packet[0]
					match packet_type:
						global.P_TYPE.ss_highlight:
							var packet_stage = packet[1]
							var highlight_sportrait = null
							for sportrait in sportraits.get_children():
								if sportrait.orig_stage == packet_stage:
									sportrait.set_highlight(1)
									highlight_sportrait = sportrait
								else :
									sportrait.set_highlight(0)
							if highlight_sportrait != null:
								sportrait_player = highlight_sportrait
								preview_stage.set_stage(packet_stage)
						global.P_TYPE.ss_select:
							var packet_stage = packet[1]
							var highlight_sportrait = null
							for sportrait in sportraits.get_children():
								if sportrait.orig_stage == packet_stage:
									highlight_sportrait = sportrait
							if highlight_sportrait != null:
								sportrait_player = highlight_sportrait
								sportrait_player.select_confirm()
								bg_move = max_bg_move
								play_audio(snd_select)
								global_audio.stop()
								move_timer = max_move_timer
								transition_alpha = 0
								preview_stage.set_stage(sportrait_player.stage)
								preview_stage.select()
						global.P_TYPE.ss_confirmed:
							global.stage = packet[1]
							state = "move"
							confirmed_stage = true
							if not global.lobby_join:
								global.relay_packet(packet)
							break
						global.P_TYPE.lobby_return:
							if global.lobby_join:
								get_tree().change_scene("res://scenes/online_lobby.tscn")
								break
					packet_size = Steam.getAvailableP2PPacketSize(0)
					
					if not global.lobby_join and packet_type != global.P_TYPE.lobby_init:
						global.relay_packet(packet)
					
				if global.lobby_state == global.LOBBY_STATE.player1 and not preview_stage.selected and last_highlighted_stage != preview_stage.curr_stage:
					broadcast_packet_highlight()
	
	transition.set_modulate(Color(1, 1, 1, transition_alpha))
	if menu_yesno.active:
		transition.set_modulate(Color(1, 1, 1, 0.75))
	elif state == "select":
		if transition_alpha > 0:
			transition_alpha -= change_alpha * (global.fps * delta)
		
		if global.mode != global.MODE.online_lobby or global.lobby_state == global.LOBBY_STATE.player1:
			sportrait_player = sportrait_player.select(1)
			if Input.is_action_just_pressed("player1_attack"):
				sportrait_player.select_confirm()
				bg_move = max_bg_move
				play_audio(snd_select)
				global_audio.stop()
				move_timer = max_move_timer
				transition_alpha = 0
				state = "move"
				global.set_stage(preview_stage.curr_stage)
				broadcast_packet_select()
				broadcast_packet_confirmed()
			if Input.is_action_just_pressed("player1_special") and global.mode != global.MODE.online_lobby:
				menu_yesno.active = true
				play_audio(snd_select2)
				
		for sportrait in sportraits.get_children():
			if sportrait == sportrait_player:
				sportrait.set_highlight(1)
				preview_stage.set_stage(sportrait.stage)
			else :
				sportrait.set_highlight(0)
	elif state == "back":
		if transition_alpha < 4:
			transition_alpha += change_alpha * (global.fps * delta)
		else :
			get_tree().change_scene("res://scenes/charselect.tscn")
	else :
		if bg_move > min_bg_move:
			bg_move -= 0.5 * (global.fps * delta)
		else :
			bg_move = min_bg_move
		if move_timer > 0:
			move_timer -= 1 * (global.fps * delta)
			if transition_alpha < 1 and move_timer < max_move_timer / 4:
				transition_alpha += change_alpha * (global.fps * delta)
		else :
			get_tree().change_scene("res://scenes/vsscreen.tscn")
	if bg_move > 0:
		bg_grid.set_position(Vector2(bg_grid.get_position().x, bg_grid.get_position().y + bg_move * (global.fps * delta)))
		if bg_grid.get_position().y > 80:
			bg_grid.set_position(Vector2(bg_grid.get_position().x, - 80))
		bg_grid2.set_position(Vector2(bg_grid2.get_position().x, bg_grid2.get_position().y + bg_move * (global.fps * delta)))
		if bg_grid2.get_position().y > 80:
			bg_grid2.set_position(Vector2(bg_grid2.get_position().x, - 80))

func back():
	state = "back"

func play_audio(snd):
	audio.volume_db = global.sfx_volume_db
	audio.stream = snd
	audio.play(0)

func broadcast_packet_highlight():
	if global.other_member_id > 0:
		var packet = PoolByteArray()
		packet.append(global.P_TYPE.ss_highlight)
		packet.append(preview_stage.curr_stage)
		last_highlighted_stage = preview_stage.curr_stage
		global.broadcast_packet(packet)

func broadcast_packet_select():
	if global.other_member_id > 0:
		var packet = PoolByteArray()
		packet.append(global.P_TYPE.ss_select)
		packet.append(preview_stage.curr_stage)
		global.broadcast_packet(packet)

func broadcast_packet_confirmed():
	if global.other_member_id > 0:
		var packet = PoolByteArray()
		packet.append(global.P_TYPE.ss_confirmed)
		packet.append(global.stage)
		global.broadcast_packet(packet)
