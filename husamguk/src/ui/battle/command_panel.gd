# CommandPanel - 군단 명령 패널 UI
# Phase 5C: 향상된 ATB 시스템
#
# 군단의 ATB가 차면 표시되는 명령 선택 패널.
# 공격, 방어, 회피, 경계, 이동 명령 버튼 제공.

class_name CommandPanel
extends PanelContainer

const Corps = preload("res://src/core/corps.gd")
const CorpsCommand = preload("res://src/core/corps_command.gd")

## 시그널
signal command_selected(command_type: CorpsCommand.CommandType)
signal command_cancelled()

## 현재 선택된 군단
var selected_corps: Corps = null

## UI 요소
var _title_label: Label
var _command_buttons: Dictionary = {}  # CommandType -> Button
var _cancel_button: Button
var _vbox: VBoxContainer

## 버튼 색상 (Phase 5C)
const BUTTON_COLORS = {
	CorpsCommand.CommandType.ATTACK: Color(0.8, 0.3, 0.3),         # 빨강
	CorpsCommand.CommandType.DEFEND: Color(0.3, 0.5, 0.8),         # 파랑
	CorpsCommand.CommandType.WATCH: Color(0.7, 0.6, 0.3),          # 노랑
	CorpsCommand.CommandType.CHANGE_FORMATION: Color(0.6, 0.4, 0.7), # 보라
}


func _init() -> void:
	custom_minimum_size = Vector2(200, 300)

	# 패널 스타일
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	# VBox 컨테이너
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)

	# 제목 라벨
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	_vbox.add_child(_title_label)

	# 구분선
	var separator = HSeparator.new()
	_vbox.add_child(separator)

	# 명령 버튼 생성
	_create_command_buttons()

	# 취소 버튼
	_cancel_button = Button.new()
	_cancel_button.custom_minimum_size = Vector2(0, 36)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_vbox.add_child(_cancel_button)

	# 초기에는 숨김
	visible = false


func _ready() -> void:
	_title_label.text = DataManager.get_localized("COMMAND_PANEL_TITLE")
	_cancel_button.text = DataManager.get_localized("COMMAND_CANCEL")

	# 버튼 텍스트 설정
	for cmd_type in _command_buttons:
		var button = _command_buttons[cmd_type]
		var key = _get_command_localization_key(cmd_type)
		button.text = DataManager.get_localized(key)


func _create_command_buttons() -> void:
	# Phase 5C: 새로운 명령 시스템
	var command_types = [
		CorpsCommand.CommandType.ATTACK,
		CorpsCommand.CommandType.DEFEND,
		CorpsCommand.CommandType.WATCH,
		CorpsCommand.CommandType.CHANGE_FORMATION,
	]

	for cmd_type in command_types:
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 40)

		# 버튼 스타일
		var style = StyleBoxFlat.new()
		style.bg_color = BUTTON_COLORS.get(cmd_type, Color(0.5, 0.5, 0.5))
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		button.add_theme_stylebox_override("normal", style)

		# 호버 스타일
		var hover_style = style.duplicate()
		hover_style.bg_color = style.bg_color.lightened(0.2)
		button.add_theme_stylebox_override("hover", hover_style)

		# 눌림 스타일
		var pressed_style = style.duplicate()
		pressed_style.bg_color = style.bg_color.darkened(0.2)
		button.add_theme_stylebox_override("pressed", pressed_style)

		button.pressed.connect(_on_command_button_pressed.bind(cmd_type))

		_vbox.add_child(button)
		_command_buttons[cmd_type] = button


func _get_command_localization_key(cmd_type: CorpsCommand.CommandType) -> String:
	match cmd_type:
		CorpsCommand.CommandType.ATTACK:
			return "COMMAND_ATTACK"
		CorpsCommand.CommandType.DEFEND:
			return "COMMAND_DEFEND"
		CorpsCommand.CommandType.WATCH:
			return "COMMAND_WATCH"
		CorpsCommand.CommandType.CHANGE_FORMATION:
			return "COMMAND_CHANGE_FORMATION"
	return "COMMAND_UNKNOWN"


## 패널 표시 (군단 선택 시)
func show_for_corps(corps: Corps) -> void:
	selected_corps = corps

	# 제목 업데이트
	if corps != null:
		_title_label.text = corps.get_display_name()

	# 버튼 활성화 상태 업데이트
	_update_button_states()

	visible = true


## 패널 숨김
func hide_panel() -> void:
	selected_corps = null
	visible = false


## 버튼 활성화 상태 업데이트
func _update_button_states() -> void:
	if selected_corps == null:
		for button in _command_buttons.values():
			button.disabled = true
		return

	# 기본적으로 모든 명령 활성화
	for cmd_type in _command_buttons:
		var button = _command_buttons[cmd_type]
		button.disabled = false

	# 이동 불가 상태 체크 (예: 고정된 군단)
	# TODO: 이동 가능 여부 확인 로직 추가


func _on_command_button_pressed(cmd_type: CorpsCommand.CommandType) -> void:
	command_selected.emit(cmd_type)


func _on_cancel_pressed() -> void:
	command_cancelled.emit()
	hide_panel()


## 특정 명령 버튼 비활성화
func disable_command(cmd_type: CorpsCommand.CommandType) -> void:
	if cmd_type in _command_buttons:
		_command_buttons[cmd_type].disabled = true


## 특정 명령 버튼 활성화
func enable_command(cmd_type: CorpsCommand.CommandType) -> void:
	if cmd_type in _command_buttons:
		_command_buttons[cmd_type].disabled = false


## 모든 버튼 비활성화
func disable_all_commands() -> void:
	for button in _command_buttons.values():
		button.disabled = true


## 현재 선택된 군단 반환
func get_selected_corps() -> Corps:
	return selected_corps
