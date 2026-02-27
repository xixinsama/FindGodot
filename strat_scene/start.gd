extends Control

@onready var grid_container: GridContainer = $Panel/GridContainer
@onready var button: Button = $Button

@onready var check_button: CheckButton = $CheckButton
@onready var check_button_2: CheckButton = $CheckButton2
@onready var check_button_3: CheckButton = $CheckButton3

@onready var h_box_container: HBoxContainer = $Panel/HBoxContainer
@onready var h_box_container_2: HBoxContainer = $Panel/HBoxContainer2
@onready var v_box_container: VBoxContainer = $Panel/VBoxContainer
@onready var v_box_container_2: VBoxContainer = $Panel/VBoxContainer2

const grid_panel = preload("res://grid_panel/panel.tscn")
var panels: Array[GridPanel] = []

func _ready() -> void:
	check_button.button_pressed = GameManager.ratate_mode
	check_button_2.button_pressed = GameManager.nonograms_mode
	check_button_3.button_pressed = GameManager.no_fill_mode
	check_button.toggled.connect(_on_check_button_toggled)
	check_button_2.toggled.connect(_on_check_button_2_toggled)
	check_button_3.toggled.connect(_on_check_button_3_toggled)
	BgmManager.play_music("res://rsa.mp3")
	button.pressed.connect(game_start)
	for c in grid_container.get_children():
		panels.append(c)
	
	diff_000()
	
func game_start():
	get_tree().change_scene_to_file("res://main/main.tscn")

@onready var title_4: Label = $Title4
func check_diff():
	h_box_container.hide()
	v_box_container.hide()
	h_box_container_2.hide()
	v_box_container_2.hide()
	title_4.text = "* No other godots in the same row, column, or within 8 surrounding grids
					* Contains exactly one godot within the colored area \n"
	if GameManager.ratate_mode:
		diff_001()
		title_4.text += "* Now there are no more godot characters on the diagonal \n"
	else:
		diff_000()
	if GameManager.nonograms_mode:
		title_4.text += "* Color areas will be displayed as \"nonograms\" \n"
	if GameManager.no_fill_mode:
		title_4.text += "* Areas without color are no longer filled \n"
	# 无须填色
	if GameManager.nonograms_mode and GameManager.no_fill_mode:
		h_box_container_2.show()
		v_box_container_2.show()
		diff_010()
	elif GameManager.nonograms_mode and not GameManager.no_fill_mode:
		h_box_container.show()
		v_box_container.show()
		diff_010()
	## 需要填色
	elif not GameManager.nonograms_mode and GameManager.no_fill_mode:
		diff_110()
	elif not GameManager.nonograms_mode and not GameManager.no_fill_mode:
		diff_100()
	

func clear_all():
	for i in range(panels.size()):
		panels[i].set_sprite(8)

func diff_000():
	clear_all()
	panels[0].set_sprite(7)
	panels[1].set_sprite(7)
	panels[3].set_sprite(7)
	panels[4].set_sprite(7)
	
	panels[5].set_sprite(7)
	panels[9].set_sprite(7)
	panels[15].set_sprite(7)
	panels[19].set_sprite(7)
	
	panels[20].set_sprite(7)
	panels[21].set_sprite(7)
	panels[23].set_sprite(7)
	panels[24].set_sprite(7)
	
	panels[12].set_sprite(randi_range(2, 6))
	diff_100()
	
# 仅旋转
func diff_001():
	clear_all()
	panels[1].set_sprite(7)
	panels[3].set_sprite(7)
	panels[5].set_sprite(7)
	panels[9].set_sprite(7)
	panels[15].set_sprite(7)
	panels[19].set_sprite(7)
	panels[21].set_sprite(7)
	panels[23].set_sprite(7)
	
	panels[12].set_sprite(5)
	
	panels[7].set_sprite(8)
	panels[11].set_sprite(8)
	panels[13].set_sprite(8)
	panels[17].set_sprite(8)

# 全填充
func diff_100():
	for i in range(panels.size()):
		panels[i].set_sprite(panels[i].f, Color("ffec27"))

# 中心填充
func diff_110():
	diff_010()
	panels[12].set_sprite(randi_range(2, 6), Color("ffec27"))
	
	panels[7].set_sprite(8, Color("ffec27"))
	panels[11].set_sprite(8, Color("ffec27"))
	panels[13].set_sprite(8, Color("ffec27"))
	panels[17].set_sprite(8, Color("ffec27"))

func diff_010():
	for i in range(panels.size()):
		panels[i].set_sprite(panels[i].f, Color.WHITE)

func _on_check_button_toggled(toggled_on: bool) -> void:
	GameManager.ratate_mode = toggled_on
	print(GameManager.ratate_mode)
	check_diff()
func _on_check_button_2_toggled(toggled_on: bool) -> void:
	GameManager.nonograms_mode = toggled_on
	print(GameManager.nonograms_mode)
	check_diff()
func _on_check_button_3_toggled(toggled_on: bool) -> void:
	GameManager.no_fill_mode = toggled_on
	print(GameManager.no_fill_mode)
	check_diff()
