extends Control
class_name Main

@export_range(4, 13, 1, "or_greater") var N = 4                      # 当前网格大小/小猫数量
@export var ratate_mode: bool = false
@export var nonograms_mode: bool = false
@export var no_fill_mode: bool = false

@export var color1: Color = Color("7e2553")
@export var color2: Color = Color("ffec27")
@export var color3: Color = Color("29adff")
@export var color4: Color = Color("008751")


@onready var 重开: Button = $UI/重开
@onready var rich_text_label: RichTextLabel = $UI/RichTextLabel
@onready var 新游戏: Button = $UI/新游戏
@onready var 返回: Button = $UI/返回

@onready var up_label: Label = $VBoxContainer/HBoxContainer/Label
@onready var col_hints: HBoxContainer = $VBoxContainer/HBoxContainer/列信息

@onready var row_hints: VBoxContainer = $VBoxContainer/HBoxContainer2/行信息
@onready var grid_container: GridContainer = $VBoxContainer/HBoxContainer2/GridContainer
@onready var grid_container_2: GridContainer = $VBoxContainer/HBoxContainer2/GridContainer2
@onready var row_hints_2: VBoxContainer = $VBoxContainer/HBoxContainer2/行信息2

@onready var dowm_label: Label = $VBoxContainer/HBoxContainer3/Label
@onready var col_hints_2: HBoxContainer = $VBoxContainer/HBoxContainer3/列信息2

@onready var camera_2d: Camera2D = $Camera2D

const CELLSIZE: Vector2i = Vector2i(72, 72)
var cells := []                  # 二维数组，存储每个格子的Panel节点
var game_state: int = 1 # 游戏中:0
var health: int = 3:
	set(v):
		health = v
		if health == 0 and game_state == 0:
			print("Lose")
			game_state = 1
			reveal_godot(grid_data.size())
			await get_tree().create_timer(1.5).timeout
			rich_text_label.show()
			rich_text_label.text = "[b][wave][color=Black]LOSE~"
			新游戏.show()
			返回.show()
			
var godots: int:
	set(v):
		godots = v
		if godots == 0 and game_state == 0:
			print("Win")
			game_state = 1
			rich_text_label.show()
			rich_text_label.text = "[b][wave][rainbow]YOU WIN!!!"
			新游戏.show()
			返回.show()

func _ready() -> void:
	重开.pressed.connect(_on_new_game)
	新游戏.pressed.connect(_on_new_game)
	new_game()

# 全局变量（假设已在外部定义）
var grid_data: Array = []          # 存储每个 godot 的位置
var grid_color: Array = []          # 颜色矩阵，-1 表示未染色
var grid_color_4c: Array = []          # 四色矩阵，-1 表示未染色
var _can_place: Array = []          # 0:可用, 1:互斥, 2:godot所在

# 生成新关卡，直到成功
func new_game():
	var success: bool = generate_level(N)
	while not success:
		print(success)
		success = generate_level(N)
	
	game_state = 0
	health = 3
	godots = N
	rich_text_label.hide()
	新游戏.hide()
	返回.hide()
	
	#print_matrix(_can_place)
	
	#print_matrix(grid_color)
	if not no_fill_mode:
		fill_remaining()
	#print_matrix(grid_color)
	
	grid_color_4c = four_color_regions(grid_color)
	#grid_color_4c = grid_color
	#print_matrix(grid_color_4c)
	
	create_grid()
	
	update_hints()
	
	reveal_godot(ceili(float(N) / 4))
	
	## 更新UI
	var hint_size: float = (2 * N + 1) * 4
	up_label.custom_minimum_size = Vector2(hint_size, hint_size)
	up_label.text = "N = " + str(N)
	dowm_label.custom_minimum_size = Vector2(hint_size, hint_size)
	
	var v_total_size: float = 2 * hint_size + (N+3) * 76
	var zoom_scale := 720 / v_total_size
	camera_2d.zoom = Vector2(zoom_scale, zoom_scale)

func _on_new_game():
	if game_state == 1:
		new_game()
		N = randi_range(4, 13)

## 生成关卡数据
#region 第一步
func generate_level(n: int) -> bool:
	# 初始化矩阵
	grid_data.clear()
	grid_color.clear()
	grid_color_4c.clear()
	_can_place.clear()
	for r in range(n):
		grid_color.append([])
		_can_place.append([])
		for c in range(n):
			grid_color[r].append(-1)
			_can_place[r].append(0)
	
	# 逐行放置 godot
	var index := center_to_ends(n)
	var sp: int = 0
	for row in index:

		# 计算当前行可用的列数
		var available_cols = 0
		var can_place_row = _can_place[row]  # 局部引用，加速访问
		for col in range(n):
			if can_place_row[col] == 0:
				available_cols += 1
		if available_cols == 0:
			return false  # 无位置可放，生成失败
		
		# 随机选择一个起始列索引（采用原算法的线性探测方式）
		var start_col = randi() % available_cols
		var col = start_col
		while _can_place[row][col] != 0:
			col += 1
			# 防止越界（原算法理论上不会越界，但增加保护更安全）
			if col >= n:
				col = 0  # 折返继续查找（若需严格保持原算法可去掉此保护，但为了健壮性保留）
		var godot_pos = Vector2i(row, col)
		grid_color[row][col] = row
		# 标记互斥区域
		if not ratate_mode:
			mark_mutex_rc_plus_8(row, col, _can_place, n)
		else:
			mark_mutex_diag_plus_8(row, col, _can_place, n)
		# 蔓延颜色
		sp += 1
		var target_count = randi_range(0, sp)
		spread_color(row, col, row, target_count, _can_place, n)
		
		# 记录 godot 位置
		grid_data.append(godot_pos)
	
	return true

## 标记互斥格子：整行、整列、周围8格
func mark_mutex_rc_plus_8(r: int, c: int, can_place: Array, n: int):
	can_place[r][c] = 2  # godot 所在
	# 同行标记
	for i in range(n):
		if can_place[r][i] == 0:
			can_place[r][i] = 1
	# 同列标记
	for i in range(n):
		if can_place[i][c] == 0:
			can_place[i][c] = 1
	# 周围8格
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0:
				continue
			var nr = r + dr
			var nc = c + dc
			if nr >= 0 and nr < n and nc >= 0 and nc < n:
				if can_place[nr][nc] == 0:
					can_place[nr][nc] = 1

## 标记互斥格子：所有斜向格子（四个对角线方向的所有格子） + 周围8格（相邻的八个格子）
func mark_mutex_diag_plus_8(r: int, c: int, can_place: Array, n: int):
	# 中心点设为 godot 所在
	can_place[r][c] = 2
	
	# 1. 标记所有对角线方向上的格子（左上、右上、左下、右下）
	var directions_diag = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
	for dir in directions_diag:
		var nr = r + dir[0]
		var nc = c + dir[1]
		while nr >= 0 and nr < n and nc >= 0 and nc < n:
			if can_place[nr][nc] == 0:
				can_place[nr][nc] = 1
			nr += dir[0]
			nc += dir[1]
	
	# 2. 标记周围8格（九宫格内除中心外的8个格子）
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0:
				continue
			var nr = r + dr
			var nc = c + dc
			if nr >= 0 and nr < n and nc >= 0 and nc < n:
				if can_place[nr][nc] == 0:
					can_place[nr][nc] = 1

## 标记互斥格子：整行、整列 + 所有斜向格子（四个对角线方向的所有格子）
func mark_mutex_full_rowcol_plus_diag(r: int, c: int, can_place: Array, n: int):
	# 中心点设为 godot 所在
	can_place[r][c] = 2
	
	# 1. 标记整行
	for i in range(n):
		if i != c and can_place[r][i] == 0:
			can_place[r][i] = 1
	# 2. 标记整列
	for i in range(n):
		if i != r and can_place[i][c] == 0:
			can_place[i][c] = 1
	
	# 3. 标记所有对角线方向上的格子
	var directions_diag = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
	for dir in directions_diag:
		var nr = r + dir[0]
		var nc = c + dir[1]
		while nr >= 0 and nr < n and nc >= 0 and nc < n:
			if can_place[nr][nc] == 0:
				can_place[nr][nc] = 1
			nr += dir[0]
			nc += dir[1]

func spread_color(start_r: int, start_c: int, color: int, target_count: int, can_place: Array, n: int):
	# 方向向量（上下左右）
	var DIRECTIONS: Array = [[-1, 0], [1, 0], [0, -1], [0, 1]]
	
	# 使用数组模拟队列，head 指向当前处理位置（避免 pop_front 的 O(n) 开销）
	var queue = []          # 存储待扩展的格子坐标，每个元素为 [r, c]
	var head = 0
	var colored = 0         # 已染色的格子数
	
	# 将起点加入队列（起点本身不染色，但作为扩展起点）
	queue.append([start_r, start_c])
	
	while head < queue.size() and colored < target_count:
		var cur = queue[head]
		head += 1
		var cr = cur[0]
		var cc = cur[1]
		
		DIRECTIONS.shuffle()
		for dir in DIRECTIONS:
			var nr = cr + dir[0]
			var nc = cc + dir[1]
			if nr >= 0 and nr < n and nc >= 0 and nc < n:
				# 只考虑互斥格子且未被当前颜色染过（避免重复）
				if can_place[nr][nc] == 1 and grid_color[nr][nc] != color:
					grid_color[nr][nc] = color
					can_place[nr][nc] = 3 ####_____________________________________
					colored += 1
					queue.append([nr, nc])
					if colored >= target_count:
						break   # 达到目标，提前结束内层循环
		# 如果已经达到目标，跳出外层循环
		if colored >= target_count:
			break

# 填充剩余未染色格子（值为-1），根据相邻颜色随机染色
func fill_remaining():
	var rows = grid_color.size()
	if rows == 0:
		return
	var cols = grid_color[0].size()
	
	var changed = true
	var max_iter = rows * cols  # 防止无限循环
	var iter = 0
	
	while changed and iter < max_iter:
		changed = false
		for r in range(rows):
			for c in range(cols):
				if grid_color[r][c] == -1:
					# 收集四方向邻居的颜色（跳过-1）
					var neighbor_colors = []
					# 上
					if r > 0 and grid_color[r-1][c] != -1:
						neighbor_colors.append(grid_color[r-1][c])
					# 下
					if r < rows-1 and grid_color[r+1][c] != -1:
						neighbor_colors.append(grid_color[r+1][c])
					# 左
					if c > 0 and grid_color[r][c-1] != -1:
						neighbor_colors.append(grid_color[r][c-1])
					# 右
					if c < cols-1 and grid_color[r][c+1] != -1:
						neighbor_colors.append(grid_color[r][c+1])
					
					if neighbor_colors.size() > 0:
						# 随机选择一个邻居颜色
						var chosen = neighbor_colors[randi() % neighbor_colors.size()]
						grid_color[r][c] = chosen
						changed = true
		iter += 1
	
	# 如果仍有未染色格子（可能是孤立区域），则从全局已用颜色中随机选取
	if iter == max_iter:
		# 收集所有已使用的颜色
		var used_colors = []
		for r in range(rows):
			for c in range(cols):
				var val = grid_color[r][c]
				if val != -1 and not used_colors.has(val):
					used_colors.append(val)
		if used_colors.size() == 0:
			used_colors = [0]  # 默认颜色
		
		for r in range(rows):
			for c in range(cols):
				if grid_color[r][c] == -1:
					grid_color[r][c] = used_colors[randi() % used_colors.size()]
#endregion

func four_color_regions(grid):
	var rows = grid.size()
	var cols = grid[0].size()
	var visited = []
	for i in range(rows):
		visited.append([])
		for j in range(cols):
			visited[i].append(false)

	# region_map 记录每个格子所属的区域 ID（-1 表示不属于任何区域）
	var region_map = []
	for i in range(rows):
		region_map.append([])
		for j in range(cols):
			region_map[i].append(-1)

	var regions = []          # 存储每个区域包含的格子坐标列表
	var region_id = 0
	var dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]]

	# 第一步：用 BFS 找出所有连通区域（跳过颜色为 -1 的格子）
	for i in range(rows):
		for j in range(cols):
			if grid[i][j] == -1:
				continue  # 排除 -1 格子，不视为任何区域
			if not visited[i][j]:
				var color = grid[i][j]
				var stack = [[i, j]]
				visited[i][j] = true
				var region_cells = [[i, j]]

				while stack.size() > 0:
					var cell = stack.pop_back()
					var x = cell[0]
					var y = cell[1]
					for d in dirs:
						var nx = x + d[0]
						var ny = y + d[1]
						if nx >= 0 and nx < rows and ny >= 0 and ny < cols \
								and not visited[nx][ny] and grid[nx][ny] == color:
							visited[nx][ny] = true
							stack.append([nx, ny])
							region_cells.append([nx, ny])

				# 记录区域
				for cell in region_cells:
					region_map[cell[0]][cell[1]] = region_id
				regions.append(region_cells)
				region_id += 1

	# 第二步：构建区域邻接表（无向图，只考虑非 -1 格子）
	var adj = []
	for r in range(region_id):
		adj.append([])

	for i in range(rows):
		for j in range(cols):
			var rid = region_map[i][j]
			if rid == -1:
				continue  # 该格子不属于任何区域，跳过
			for d in dirs:
				var ni = i + d[0]
				var nj = j + d[1]
				if ni >= 0 and ni < rows and nj >= 0 and nj < cols:
					var nid = region_map[ni][nj]
					if nid != -1 and nid != rid and not nid in adj[rid]:
						adj[rid].append(nid)

	# 如果没有区域（所有格子都是 -1），直接返回全 -1 网格
	if region_id == 0:
		var empty_grid = []
		for i in range(rows):
			var row = []
			for j in range(cols):
				row.append(-1)
			empty_grid.append(row)
		return empty_grid

	# 第三步：对区域图进行四着色
	var colors = []
	for r in range(region_id):
		colors.append(-1)

	# 按邻居数量降序排列区域，提高回溯效率
	var order = range(region_id)
	order.sort_custom(func(a, b): return adj[a].size() > adj[b].size())

	# 使用数组包装 success 变量以便在递归函数中修改
	var success = [false]
	_backtrack(colors, adj, order, 0, success)

	if not success[0]:
		# 极少数情况下回溯可能未找到解，用贪心5色作为后备（理论不会发生）
		colors = []
		for r in range(region_id):
			colors.append(-1)
		for r in order:
			var used = []
			for nb in adj[r]:
				if colors[nb] != -1:
					used.append(colors[nb])
			var assigned = false
			for c in range(4):
				if not c in used:
					colors[r] = c
					assigned = true
					break
			if not assigned:
				colors[r] = 4   # 用第5色

	# 第四步：根据着色结果生成输出网格（-1 格子保持为 -1）
	var new_grid = []
	for i in range(rows):
		var row = []
		for j in range(cols):
			var rid = region_map[i][j]
			if rid == -1:
				row.append(-1)
			else:
				row.append(colors[rid])
		new_grid.append(row)
	return new_grid


# 回溯着色函数，递归尝试为每个区域分配颜色
func _backtrack(colors, adj, order, index, success):
	if success[0]:
		return
	if index == order.size():
		success[0] = true
		return
	var r = order[index]
	for c in range(4):
		var ok = true
		for nb in adj[r]:
			if colors[nb] == c:
				ok = false
				break
		if ok:
			colors[r] = c
			_backtrack(colors, adj, order, index + 1, success)
			if success[0]:
				return
			colors[r] = -1
	
#region 第二步
## 创建网格格子
const grid_panel = preload("res://grid_panel/panel.tscn")
func create_grid():
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()
	grid_container.columns = N
	
	for child in grid_container_2.get_children():
		child.queue_free()
	grid_container_2.columns = N
	
	for r in range(N):
		var row_cells = []
		for c in range(N):
			var panel: GridPanel = grid_panel.instantiate()
			grid_container.add_child(panel)
			panel.set_sprite(7, get_color(grid_color[r][c]))
			
			var panel2: GridPanel = grid_panel.instantiate()
			grid_container_2.add_child(panel2)
			if nonograms_mode:
				panel2.set_sprite(7, Color("214c55ff"))
			else:
				panel2.set_sprite(7, get_color_for_index(grid_color_4c[r][c]))
			panel2.grid_pos = Vector2i(r, c)
			if panel2.grid_pos in grid_data:
				panel2.contain_godot = true
			
			row_cells.append(panel2)
		cells.append(row_cells)

func update_hints():
	# 清除旧提示
	for child in row_hints.get_children():
		child.queue_free()
	for child in row_hints_2.get_children():
		child.queue_free()
	for child in col_hints.get_children():
		child.queue_free()
	for child in col_hints_2.get_children():
		child.queue_free()
	
	# 行提示：每行从左到右显示该行每个格子的颜色
	for r in range(N):
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_END
		hbox.custom_minimum_size.x = 2 * N * 4
		row_hints.add_child(hbox)
		var hbox_2 = HBoxContainer.new()
		hbox_2.alignment = BoxContainer.ALIGNMENT_BEGIN
		row_hints_2.add_child(hbox_2)
		var color_rect_b = ColorRect.new()
		color_rect_b.custom_minimum_size = Vector2(4, 72)
		color_rect_b.color = Color(0.0, 0.0, 0.0, 0.0)
		var color_rect_b_2 = color_rect_b.duplicate()
		hbox_2.add_child(color_rect_b_2)
		for c in range(N):
			var color = grid_color_4c[r][c]
			if color == 0 or color == 1:
				var color_rect = ColorRect.new()
				color_rect.custom_minimum_size = Vector2(4, 72)
				color_rect.color = get_color_for_index(color)
				hbox.add_child(color_rect)
			if color == 2 or color == 3:
				var color_rect = ColorRect.new()
				color_rect.custom_minimum_size = Vector2(4, 72)
				color_rect.color = get_color_for_index(color)
				hbox_2.add_child(color_rect)
		hbox.add_child(color_rect_b)
	# 列提示：每列从上到下显示该列每个格子的颜色
	for c in range(N):
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_END
		col_hints.add_child(vbox)
		var vbox_2 = VBoxContainer.new()
		vbox_2.alignment = BoxContainer.ALIGNMENT_BEGIN
		col_hints_2.add_child(vbox_2)
		# 空白填充
		var color_rect_b = ColorRect.new()
		color_rect_b.custom_minimum_size = Vector2(72, 4)
		color_rect_b.color = Color(0.0, 0.0, 0.0, 0.0)
		var color_rect_b_2 = color_rect_b.duplicate()
		vbox_2.add_child(color_rect_b_2)
		for r in range(N):
			var color = grid_color_4c[r][c]
			if color == 0 or color == 1:
				var color_rect = ColorRect.new()
				color_rect.custom_minimum_size = Vector2(72, 4)
				color_rect.color = get_color_for_index(color)
				vbox.add_child(color_rect)
			if color == 2 or color == 3:
				var color_rect = ColorRect.new()
				color_rect.custom_minimum_size = Vector2(72, 4)
				color_rect.color = get_color_for_index(color)
				vbox_2.add_child(color_rect)
		
		vbox.add_child(color_rect_b)

func get_color_for_index(i: int) -> Color:
	match i % 4:
		0:
			return color1
		1:
			return color2
		2:
			return color3
		3:
			return color4
		_:
			return Color(0.0, 0.0, 0.0, 1.0)

func get_color(i: int) -> Color:
	if i == -1: return Color(0.0, 0.0, 0.0, 1.0)
	var hue = float(i) / N
	return Color.from_hsv(hue, 0.8, 0.9)
#endregion


func print_matrix(array: Array) -> void:
	if array[0] is Array:
		for i in range(array.size()):
			print(array[i])
	print("\n")

func reveal_godot(n: int) -> void:
	if n > N: return
	var gd: Array = grid_data.duplicate()
	gd.shuffle()
	for i in range(n):
		var pos = gd[i]
		var p = cells[pos.x][pos.y] as GridPanel
		p.reveal()

func center_to_ends(n: int) -> Array:
##返回一个数组，包含从中间到两端的索引顺序（先左后右）"""
	var result = []
	if n <= 0:
		return result
	var mid := int(float(n - 1) / 2)      # 左中索引（整数除法）
	result.append(mid)
	var left = mid
	var right = mid
	while left > 0 or right < n - 1:
		if left > 0:
			left -= 1
			result.append(left)
		if right < n - 1:
			right += 1
			result.append(right)
	return result
