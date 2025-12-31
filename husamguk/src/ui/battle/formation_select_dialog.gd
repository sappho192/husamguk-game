# FormationSelectDialog - 진형 선택 다이얼로그
# Phase 5C: 진형 변경 UI
#
# 군단이 사용 가능한 진형 목록을 표시하고 선택 가능하게 함.

class_name FormationSelectDialog
extends PanelContainer

const Corps = preload("res://src/core/corps.gd")
const Formation = preload("res://src/core/formation.gd")

## 시그널
signal formation_selected(formation: Formation)
signal cancelled()

## UI 요소
var _title_label: Label
var _formation_list: VBoxContainer
var _cancel_button: Button
var _scroll_container: ScrollContainer

## 현재 선택 대상 군단
var _selected_corps: Corps = null


func _init() -> void:
	custom_minimum_size = Vector2(400, 500)

	# 다이얼로그 중앙 배치 - 앵커를 중앙으로 설정하고 피벗도 중앙으로
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -200  # custom_minimum_size.x / 2
	offset_top = -250   # custom_minimum_size.y / 2
	offset_right = 200
	offset_bottom = 250
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	# 패널 스타일
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.98)
	style.border_color = Color(0.6, 0.5, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)

	# VBox 컨테이너
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	# 제목 라벨
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	vbox.add_child(_title_label)

	# 구분선
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# 스크롤 컨테이너
	_scroll_container = ScrollContainer.new()
	_scroll_container.custom_minimum_size = Vector2(0, 320)
	vbox.add_child(_scroll_container)

	# 진형 목록
	_formation_list = VBoxContainer.new()
	_formation_list.add_theme_constant_override("separation", 8)
	_scroll_container.add_child(_formation_list)

	# 취소 버튼
	_cancel_button = Button.new()
	_cancel_button.custom_minimum_size = Vector2(0, 40)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	vbox.add_child(_cancel_button)

	# 초기에는 숨김
	visible = false


func _ready() -> void:
	if DataManager:
		_title_label.text = DataManager.get_localized("UI_FORMATION_SELECT")
		_cancel_button.text = DataManager.get_localized("COMMAND_CANCEL")


## 다이얼로그 표시
func show_for_corps(corps: Corps) -> void:
	if corps == null:
		push_warning("FormationSelectDialog: Cannot show for null corps")
		return

	_selected_corps = corps
	_populate_formations()
	visible = true


## 다이얼로그 숨김
func hide_dialog() -> void:
	_selected_corps = null
	visible = false


## 진형 목록 채우기
func _populate_formations() -> void:
	# 기존 버튼 제거
	for child in _formation_list.get_children():
		child.queue_free()

	if _selected_corps == null:
		return

	# 사용 가능한 진형 목록 가져오기
	var available_formation_ids = _selected_corps.available_formations

	for formation_id in available_formation_ids:
		var formation = DataManager.create_formation_instance(formation_id)
		if formation == null:
			continue

		# 진형 카테고리 제한 확인
		if not formation.can_be_used_by(_selected_corps.category):
			continue

		# 진형 버튼 생성
		var formation_button = _create_formation_button(formation)
		_formation_list.add_child(formation_button)


## 진형 버튼 생성
func _create_formation_button(formation: Formation) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(360, 100)
	button.pressed.connect(_on_formation_selected.bind(formation))

	# 버튼 스타일
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.25, 0.25, 0.3, 0.9)
	normal_style.border_color = Color(0.5, 0.5, 0.6)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(6)
	normal_style.set_content_margin_all(12)
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.35, 0.35, 0.4, 0.95)
	hover_style.border_color = Color(0.7, 0.6, 0.4)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	hover_style.set_content_margin_all(12)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.3, 0.3, 0.35, 0.95)
	pressed_style.border_color = Color(0.6, 0.5, 0.3)
	pressed_style.set_border_width_all(3)
	pressed_style.set_corner_radius_all(6)
	pressed_style.set_content_margin_all(12)
	button.add_theme_stylebox_override("pressed", pressed_style)

	# VBox 레이아웃
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 버튼의 전체 영역을 사용하도록 앵커 설정
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	button.add_child(vbox)

	# 진형 이름
	var name_label = Label.new()
	name_label.text = formation.get_display_name()
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(320, 0)  # 충분한 가로 폭 보장
	vbox.add_child(name_label)

	# 스탯 요약
	var stats_label = Label.new()
	stats_label.text = formation.get_summary()
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.custom_minimum_size = Vector2(320, 0)
	vbox.add_child(stats_label)

	# 진형 설명
	var desc_label = Label.new()
	desc_label.text = formation.get_description()
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.custom_minimum_size = Vector2(320, 0)
	vbox.add_child(desc_label)

	return button


## 진형 선택 핸들러
func _on_formation_selected(formation: Formation) -> void:
	formation_selected.emit(formation)
	hide_dialog()


## 취소 버튼 핸들러
func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide_dialog()
