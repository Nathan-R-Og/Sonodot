extends Node
class_name LevelInfos
var count:float = 0;
var seconds:float = 0;
var milliseconds:float;
var minutes:float;
var time:String;
onready var act_container = $ActContainer
onready var HUD = get_node_or_null("./HUD")
onready var HUD_count = HUD.get_node_or_null("./Separate/STRCounters/Count")
onready var global : = get_tree().get_root().get_node("/root/AutoloadCharacters")
onready var players = $Players
export var zone_name : String
export var show_title_card: bool = false
export var next_level : PackedScene
onready var act_clear_music : AudioStreamPlayer = $ActClear
onready var act_score_total : AudioStreamPlayer = $ScoreTotal
onready var act_score_add : AudioStreamPlayer = $ScoreAdd
onready var ring_counter = HUD_count.get_node('RingCounter')

func _ready():
	players.set_owner(self)
	if show_title_card:
		HUD.show_title_card()
	else:
		HUD.transition.color.a = 0.0
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

#func update_ring_count(value:int):
#	if (ring_counter != null):
#		ring_counter.text = String(value);


func get_global_mouse_position() -> Vector2:
	return get_viewport().get_mouse_position()

func _process(delta):
	ring_counter.text = String(players.get_node("PlayersObj").get_child(0).rings)
	
	count += delta;
	seconds = int(count) % 60;
	minutes = floor(count / 60);
	milliseconds = floor((fmod(count, 60) - seconds) * 100);
	time = "%02d'%02d''%02d" % [minutes, seconds, milliseconds]
	var timer_counter = HUD_count.get_node_or_null('TimeCounter')
	if timer_counter != null:
		timer_counter.text = time;

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_full_screen"):
		OS.window_fullscreen = !OS.window_fullscreen
	#if event.scancode == KEY_0:
	#	Engine.time_scale = 2.0 - int(!event.is_pressed())

func get_current_act() -> int:
	return act_container.current_act
