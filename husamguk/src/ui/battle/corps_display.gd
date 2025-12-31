# CorpsDisplay - 군단 표시 UI 컴포넌트
# Phase 5C: 향상된 ATB 시스템
#
# 그리드 타일 위에 표시되는 군단 정보.
# 병사 수, HP, ATB 바, 진형 아이콘 등을 표시.

class_name CorpsDisplay
extends Control

const Corps = preload("res://src/core/corps.gd")

## 군단 클릭 시그널
signal corps_clicked(corps: Corps)

## 군단 호버 시그널
signal corps_hovered(corps: Corps)

## 표시 중인 군단
var corps: Corps = null

## 타일 크기 (TileDisplay와 일치)
const TILE_SIZE: int = 40

# UI 요소
var _background: ColorRect
var _hp_bar: ColorRect
var _hp_bar_bg: ColorRect
var _atb_bar: ColorRect
var _atb_bar_bg: ColorRect
var _soldier_label: Label
var _general_indicator: ColorRect
var _selection_border: ColorRect
var _command_indicator: Label

## 선택 상태
var is_selected: bool = false

## 아군/적군 색상
const ALLY_COLOR = Color(0.2, 0.5, 0.8, 0.9)
const ENEMY_COLOR = Color(0.8, 0.3, 0.3, 0.9)
const ALLY_COLOR_DARK = Color(0.15, 0.35, 0.6)
const ENEMY_COLOR_DARK = Color(0.6, 0.2, 0.2)


func _init() -> void:
	custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	size = Vector2(TILE_SIZE, TILE_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_visuals()


func _create_visuals() -> void:
	# 배경 (아군/적군 구분)
	_background = ColorRect.new()
	_background.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	_background.position = Vector2(2, 2)
	_background.color = ALLY_COLOR
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	# HP 바 배경
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(TILE_SIZE - 6, 4)
	_hp_bar_bg.position = Vector2(3, TILE_SIZE - 7)
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar_bg)

	# HP 바
	_hp_bar = ColorRect.new()
	_hp_bar.size = Vector2(TILE_SIZE - 6, 4)
	_hp_bar.position = Vector2(3, TILE_SIZE - 7)
	_hp_bar.color = Color.GREEN
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar)

	# ATB 바 배경
	_atb_bar_bg = ColorRect.new()
	_atb_bar_bg.size = Vector2(TILE_SIZE - 6, 3)
	_atb_bar_bg.position = Vector2(3, 3)
	_atb_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	_atb_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_atb_bar_bg)

	# ATB 바
	_atb_bar = ColorRect.new()
	_atb_bar.size = Vector2(0, 3)
	_atb_bar.position = Vector2(3, 3)
	_atb_bar.color = Color.YELLOW
	_atb_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_atb_bar)

	# 병사 수 레이블
	_soldier_label = Label.new()
	_soldier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_soldier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_soldier_label.size = Vector2(TILE_SIZE, TILE_SIZE - 12)
	_soldier_label.position = Vector2(0, 4)
	_soldier_label.add_theme_font_size_override("font_size", 12)
	_soldier_label.add_theme_color_override("font_color", Color.WHITE)
	_soldier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_soldier_label)

	# 장수 표시기 (좌상단 작은 점)
	_general_indicator = ColorRect.new()
	_general_indicator.size = Vector2(6, 6)
	_general_indicator.position = Vector2(4, 8)
	_general_indicator.color = Color.GOLD
	_general_indicator.visible = false
	_general_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_general_indicator)

	# 명령 표시기 (우상단)
	_command_indicator = Label.new()
	_command_indicator.size = Vector2(12, 12)
	_command_indicator.position = Vector2(TILE_SIZE - 14, 8)
	_command_indicator.add_theme_font_size_override("font_size", 10)
	_command_indicator.add_theme_color_override("font_color", Color.WHITE)
	_command_indicator.visible = false
	_command_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_command_indicator)

	# 선택 테두리
	_selection_border = ColorRect.new()
	_selection_border.size = Vector2(TILE_SIZE, TILE_SIZE)
	_selection_border.color = Color.WHITE
	_selection_border.visible = false
	_selection_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_selection_border)

	# 선택 테두리 내부 투명
	var inner = ColorRect.new()
	inner.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	inner.position = Vector2(2, 2)
	inner.color = Color.TRANSPARENT
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_border.add_child(inner)


## 군단 설정
func setup(corps_data: Corps) -> void:
	corps = corps_data

	if corps == null:
		visible = false
		return

	visible = true

	# 아군/적군 색상
	if corps.is_ally:
		_background.color = ALLY_COLOR
	else:
		_background.color = ENEMY_COLOR

	# 장수 표시
	_general_indicator.visible = (corps.general != null)

	# 시그널 연결
	if not corps.took_damage.is_connected(_on_corps_damaged):
		corps.took_damage.connect(_on_corps_damaged)
	if not corps.destroyed.is_connected(_on_corps_destroyed):
		corps.destroyed.connect(_on_corps_destroyed)

	_update_display()


## 표시 업데이트
func _update_display() -> void:
	if corps == null:
		return

	# 병사 수 표시
	_soldier_label.text = str(corps.soldier_count)

	# HP 바 업데이트
	var hp_ratio = corps.get_hp_percent() / 100.0
	_hp_bar.size.x = (TILE_SIZE - 6) * hp_ratio

	# HP 색상 (HP에 따라 변화)
	if hp_ratio > 0.6:
		_hp_bar.color = Color.GREEN
	elif hp_ratio > 0.3:
		_hp_bar.color = Color.YELLOW
	else:
		_hp_bar.color = Color.RED

	# ATB 바 업데이트
	var atb_ratio = corps.get_atb_percent() / 100.0
	_atb_bar.size.x = (TILE_SIZE - 6) * atb_ratio

	# ATB 만충 시 색상 변화
	if atb_ratio >= 1.0:
		_atb_bar.color = Color.CYAN
	else:
		_atb_bar.color = Color.YELLOW


## 프레임마다 ATB 업데이트
func _process(_delta: float) -> void:
	if corps != null and corps.is_alive:
		_update_atb_bar()


## ATB 바만 업데이트 (최적화)
func _update_atb_bar() -> void:
	var atb_ratio = corps.get_atb_percent() / 100.0
	_atb_bar.size.x = (TILE_SIZE - 6) * atb_ratio

	if atb_ratio >= 1.0:
		_atb_bar.color = Color.CYAN
	else:
		_atb_bar.color = Color.YELLOW


## 선택 상태 설정
func set_selected(selected: bool) -> void:
	is_selected = selected
	_selection_border.visible = selected


## 명령 표시기 설정
func show_command_indicator(command_type: int) -> void:
	_command_indicator.visible = true
	match command_type:
		0:  # ATTACK
			_command_indicator.text = "⚔"
		1:  # DEFEND
			_command_indicator.text = "🛡"
		2:  # EVADE
			_command_indicator.text = "↔"
		3:  # WATCH
			_command_indicator.text = "👁"
		4:  # MOVE
			_command_indicator.text = "→"


## 명령 표시기 숨김
func hide_command_indicator() -> void:
	_command_indicator.visible = false


## 마우스 입력 활성화/비활성화 (이동 선택 시 타일 클릭을 위해)
func set_mouse_input_enabled(enabled: bool) -> void:
	if enabled:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE


## 피해 시 콜백
func _on_corps_damaged(_casualties: int, remaining: int) -> void:
	_soldier_label.text = str(remaining)
	_update_display()

	# 피해 플래시 효과
	_flash_damage()


## 파괴 시 콜백
func _on_corps_destroyed() -> void:
	# 페이드 아웃 애니메이션
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)


## 피해 플래시 효과
func _flash_damage() -> void:
	var original_color = _background.color
	_background.color = Color.RED

	var tween = create_tween()
	tween.tween_property(_background, "color", original_color, 0.2)


## 마우스 입력 처리
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			corps_clicked.emit(corps)


## 마우스 진입/퇴장 시 시그널
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if corps != null:
				corps_hovered.emit(corps)
				if not is_selected:
					_background.color = _background.color.lightened(0.2)
		NOTIFICATION_MOUSE_EXIT:
			if corps != null and not is_selected:
				if corps.is_ally:
					_background.color = ALLY_COLOR
				else:
					_background.color = ENEMY_COLOR
