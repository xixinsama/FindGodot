extends Panel
class_name GridPanel

@onready var sprite_2d: Sprite2D = $Sprite2D

var grid_pos: Vector2i = Vector2i(-1, -1)
var contain_godot: bool = false
var revealed: bool = false
var marked: bool = false      # 新增：标注状态
var f: int = 0:
	set(v):
		f = v
		sprite_2d.frame = f

func _ready():
	# 连接鼠标进入信号，用于拖拽标注
	mouse_entered.connect(_on_mouse_entered)

func set_sprite(frame: int, fmodulate: Color = Color.WHITE):
	if frame >= 0 and frame <= 8:
		f = frame
		sprite_2d.self_modulate = fmodulate

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if not revealed and not marked:
					reveal()
			MOUSE_BUTTON_RIGHT:
				toggle_mark()

func _on_mouse_entered():
	# 拖拽标注：右键按住、格子未揭示且未标注时，将其标注
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not revealed and not marked:
		set_marked(true)

# 揭示格子
func reveal():
	if revealed: return
	revealed = true
	if contain_godot:
		var color := sprite_2d.self_modulate
		set_sprite(randi_range(1, 6), color)
		var main := get_tree().get_first_node_in_group(&"main") as Main
		main.godots -= 1
	else:
		set_sprite(8, Color(0.439, 0.0, 0.063, 0.788))
		var main := get_tree().get_first_node_in_group(&"main") as Main
		main.health -= 1

# 切换标注状态
func toggle_mark():
	set_marked(not marked)

# 统一设置标注状态并更新视觉
func set_marked(value: bool):
	if marked == value:
		return
	marked = value
	update_visual()

# 根据当前状态更新 Sprite 显示
func update_visual():
	if revealed: return
	if marked:
		set_sprite(8, sprite_2d.self_modulate)
	else:
		set_sprite(7, sprite_2d.self_modulate)
