# TileDisplay - 단일 타일 표시 UI 컴포넌트
# Phase 5A: 전투 지형 시스템
#
# 하나의 그리드 타일을 표시. 지형 색상, 하이라이트, 클릭 처리.

class_name TileDisplay
extends Control

const TerrainTile = preload("res://src/core/terrain_tile.gd")

## 타일 클릭 시그널
signal tile_clicked(grid_pos: Vector2i)

## 타일 마우스 오버 시그널
signal tile_hovered(grid_pos: Vector2i)

## 유닛 표시 시그널 (타일에 유닛이 있을 때)
signal unit_clicked(grid_pos: Vector2i)

## 타일 크기 (픽셀)
const TILE_SIZE: int = 40

## 그리드 좌표
var grid_pos: Vector2i = Vector2i(-1, -1)

## 지형 데이터
var terrain: TerrainTile = null

## 하이라이트 상태
var is_highlighted: bool = false
var highlight_color: Color = Color.TRANSPARENT

## 선택 상태
var is_selected: bool = false

## 점령 중인 유닛/군단 (Phase 5B)
var occupant: RefCounted = null

# UI 요소
var background_rect: ColorRect
var highlight_rect: ColorRect
var border_rect: ColorRect
var terrain_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	size = Vector2(TILE_SIZE, TILE_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_visuals()


func _create_visuals() -> void:
	# 배경 (지형 색상)
	background_rect = ColorRect.new()
	background_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	background_rect.color = Color.LIGHT_GREEN
	add_child(background_rect)

	# 하이라이트 오버레이
	highlight_rect = ColorRect.new()
	highlight_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	highlight_rect.color = Color.TRANSPARENT
	highlight_rect.visible = false
	add_child(highlight_rect)

	# 테두리
	border_rect = ColorRect.new()
	border_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	border_rect.color = Color(0.3, 0.3, 0.3, 0.3)
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border_rect)

	# 테두리 내부 투명하게 (외곽선만 표시)
	var inner_rect = ColorRect.new()
	inner_rect.position = Vector2(1, 1)
	inner_rect.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
	inner_rect.color = Color.TRANSPARENT
	inner_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_rect.add_child(inner_rect)

	# 지형 약어 레이블 (디버그용)
	terrain_label = Label.new()
	terrain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	terrain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	terrain_label.size = Vector2(TILE_SIZE, TILE_SIZE)
	terrain_label.add_theme_font_size_override("font_size", 10)
	terrain_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 0.5))
	terrain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	terrain_label.visible = false  # 기본적으로 숨김
	add_child(terrain_label)


## 지형 데이터로 타일 설정
func setup_terrain(terrain_data: TerrainTile) -> void:
	terrain = terrain_data
	if terrain == null:
		background_rect.color = Color.GRAY
		terrain_label.text = "?"
		return

	background_rect.color = terrain.color
	terrain_label.text = terrain.char_code

	# 통과 불가 지형은 어둡게
	if not terrain.is_passable():
		background_rect.color = terrain.color.darkened(0.4)


## 하이라이트 설정
func set_highlight(color: Color) -> void:
	highlight_color = color
	highlight_rect.color = Color(color.r, color.g, color.b, 0.4)
	highlight_rect.visible = true
	is_highlighted = true


## 하이라이트 해제
func clear_highlight() -> void:
	highlight_rect.visible = false
	is_highlighted = false
	highlight_color = Color.TRANSPARENT


## 선택 상태 설정
func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		border_rect.color = Color.WHITE
	else:
		border_rect.color = Color(0.3, 0.3, 0.3, 0.3)


## 유닛/군단 점령 설정 (Phase 5B)
func set_occupant(unit: RefCounted) -> void:
	occupant = unit
	# TODO: 유닛 표시 UI 추가


## 지형 레이블 표시/숨김 (디버그용)
func show_terrain_label(show: bool) -> void:
	terrain_label.visible = show


## 마우스 입력 처리
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tile_clicked.emit(grid_pos)
	elif event is InputEventMouseMotion:
		tile_hovered.emit(grid_pos)


## 마우스 진입 시 시각적 피드백
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if not is_highlighted and not is_selected:
				border_rect.color = Color(0.5, 0.5, 0.5, 0.5)
		NOTIFICATION_MOUSE_EXIT:
			if not is_highlighted and not is_selected:
				border_rect.color = Color(0.3, 0.3, 0.3, 0.3)
