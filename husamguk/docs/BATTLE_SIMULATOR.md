# Battle Simulator Guide

전투 시스템을 터미널에서 테스트하고 밸런스를 조정하기 위한 시뮬레이터입니다.

## 개요

Battle Simulator는 Godot의 headless 모드를 활용하여 GUI 없이 전투를 자동으로 실행하고 통계를 수집합니다.

**주요 기능:**
- 다양한 유닛/장수 조합 테스트
- 배치 시뮬레이션 (N회 반복 실행)
- CSV 형식의 raw 데이터 출력
- JSON 형식의 요약 통계 출력
- 10배 빠른 시뮬레이션 속도

## 빠른 시작

### 1. Godot Engine 설치 확인

시뮬레이터는 Godot 4.5+ 콘솔 버전이 필요합니다.

```bash
# Godot 설치 경로 확인
C:\BIN\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe --version
```

### 2. 시뮬레이션 설정

`simulation_config.yaml` 파일을 편집하여 테스트할 시나리오를 정의합니다:

```yaml
simulations:
  - name: "my_test"
    team1:
      general: "gyeonhwon"
      units: ["spearman", "spearman"]
    team2:
      general: "wanggeon"
      units: ["heavy_cavalry", "heavy_cavalry"]
    iterations: 50
```

**사용 가능한 장수:**
- `gyeonhwon`, `wanggeon`, `gyunhwon`, `singeom`, `bogo`, `sangyeong`, `gyeonae`, `wonhoe`, `sumyeong`

**사용 가능한 유닛:**
- 보병: `spearman`, `swordsman`
- 기병: `light_cavalry`, `heavy_cavalry`
- 원거리: `archer`, `crossbowman`

### 3. 시뮬레이션 실행

```bash
cd C:\REPO\husamguk-game\husamguk

# Windows (기본 설정 파일 사용)
"C:\BIN\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe" --path . --headless scenes/battle_simulator.tscn
```

## 출력 파일

시뮬레이션 실행 후 `output/simulation/<scenario_name>/` 디렉토리에 결과가 생성됩니다:

### battles.csv (Raw Data)

각 전투의 상세 데이터:

| 컬럼 | 설명 |
|------|------|
| battle_id | 전투 번호 |
| team1_config | 팀 1 구성 (장수,유닛,유닛,...) |
| team2_config | 팀 2 구성 |
| winner | 승자 (team1 또는 team2) |
| duration | 전투 지속 시간 (초) |
| global_turns | 글로벌 턴 수 |
| team1_damage_dealt | 팀 1이 가한 총 데미지 |
| team1_damage_taken | 팀 1이 받은 총 데미지 |
| team2_damage_dealt | 팀 2가 가한 총 데미지 |
| team2_damage_taken | 팀 2가 받은 총 데미지 |

**예시:**
```csv
battle_id,team1_config,team2_config,winner,duration,global_turns,team1_damage_dealt,team1_damage_taken,team2_damage_dealt,team2_damage_taken
1,gyeonhwon,spearman,spearman,wanggeon,heavy_cavalry,heavy_cavalry,team2,8.89,8,144,210,210,144
```

### summary.json (요약 통계)

집계된 분석 결과:

```json
{
  "simulation_config": {
    "team1": "gyeonhwon,spearman,spearman",
    "team2": "wanggeon,heavy_cavalry,heavy_cavalry",
    "iterations": 3
  },
  "results": {
    "total_battles": 3,
    "team1_wins": 0,
    "team2_wins": 3,
    "team1_win_rate": "0.00%",
    "team2_win_rate": "100.00%"
  },
  "performance": {
    "average_duration_seconds": "8.93",
    "average_global_turns": "8.0",
    "total_duration_seconds": "26.78"
  },
  "damage_statistics": {
    "team1": {
      "avg_damage_dealt": "144.0",
      "avg_damage_taken": "210.0",
      "total_damage_dealt": 432,
      "total_damage_taken": 630
    },
    "team2": {
      "avg_damage_dealt": "210.0",
      "avg_damage_taken": "144.0",
      "total_damage_dealt": 630,
      "total_damage_taken": 432
    }
  }
}
```

## 수집되는 통계

### 기본 통계
- **승률**: 각 팀의 승리 횟수 및 승률
- **평균 전투 시간**: 전투당 평균 지속 시간 (초)
- **평균 글로벌 턴**: 전투당 평균 턴 수

### 데미지 통계
- **팀별 평균 데미지**: 전투당 가한/받은 평균 데미지
- **팀별 총 데미지**: 모든 전투의 누적 데미지

## 고급 사용법

### 여러 시나리오 동시 실행

`simulation_config.yaml`에 여러 시나리오를 정의하면 순차적으로 실행됩니다:

```yaml
simulations:
  - name: "scenario_1"
    team1: { general: "gyeonhwon", units: ["spearman", "spearman"] }
    team2: { general: "wanggeon", units: ["heavy_cavalry", "heavy_cavalry"] }
    iterations: 50

  - name: "scenario_2"
    team1: { general: "gyunhwon", units: ["archer", "archer"] }
    team2: { general: "singeom", units: ["swordsman", "swordsman"] }
    iterations: 50

  - name: "scenario_3"
    team1: { general: "bogo", units: ["light_cavalry", "archer"] }
    team2: { general: "sangyeong", units: ["spearman", "crossbowman"] }
    iterations: 100
```

### 커스텀 설정 파일

기본 설정 파일 대신 다른 파일을 사용하려면 `src/tools/battle_simulator.gd`의 `config_file` 변수를 수정하거나, 별도의 씬을 만드세요.

## 밸런스 분석 예시

### 창병 vs 중기병 대결

```yaml
- name: "spearman_vs_heavy_cavalry"
  team1:
    general: "gyeonhwon"
    units: ["spearman", "spearman"]
  team2:
    general: "wanggeon"
    units: ["heavy_cavalry", "heavy_cavalry"]
  iterations: 100
```

**결과 해석:**
- 창병은 대기병 특성을 가지고 있어 기병에게 보너스 데미지를 줍니다
- 하지만 중기병의 높은 공격력과 방어력으로 인해 승률이 낮을 수 있습니다
- 데미지 통계를 확인하여 밸런스 조정이 필요한지 판단합니다

### 원거리 유닛 비교

```yaml
- name: "archer_vs_crossbowman"
  team1:
    general: "gyunhwon"
    units: ["archer", "archer", "archer"]
  team2:
    general: "singeom"
    units: ["crossbowman", "crossbowman", "crossbowman"]
  iterations: 100
```

## 성능 최적화

시뮬레이터는 기본적으로 **10배 가속**되어 실행됩니다 (`Engine.time_scale = 10.0`).

속도를 조정하려면 `src/tools/battle_simulator.gd`의 `_ready()` 함수에서:

```gdscript
# 더 빠르게 (50배)
Engine.time_scale = 50.0

# 실시간 속도
Engine.time_scale = 1.0
```

**주의:** 너무 높은 time_scale은 물리 연산 오류를 일으킬 수 있습니다.

## 트러블슈팅

### "DataManager: Unit not found" 에러

- 유닛 ID가 올바른지 확인하세요
- 사용 가능한 유닛: `spearman`, `swordsman`, `light_cavalry`, `heavy_cavalry`, `archer`, `crossbowman`

### "DataManager: General not found" 에러

- 장수 ID가 올바른지 확인하세요
- 사용 가능한 장수: `gyeonhwon`, `wanggeon`, `gyunhwon`, `singeom`, `bogo`, `sangyeong`, `gyeonae`, `wonhoe`, `sumyeong`

### 출력 파일이 생성되지 않음

- `output/simulation/` 디렉토리 쓰기 권한을 확인하세요
- Godot가 headless 모드로 실행되었는지 확인하세요

### 전투가 너무 느림

- `src/tools/battle_simulator.gd`의 `Engine.time_scale` 값을 높이세요
- 기본값은 10.0입니다 (10배 가속)

## 파일 구조

```
husamguk/
├── src/tools/
│   └── battle_simulator.gd          # 시뮬레이터 메인 스크립트
├── scenes/
│   └── battle_simulator.tscn        # 시뮬레이터 씬
├── simulation_config.yaml           # 기본 설정 파일
├── test_simulation.yaml             # 테스트용 간단 설정
└── output/
    └── simulation/
        └── <scenario_name>/
            ├── battles.csv           # Raw 데이터
            └── summary.json          # 요약 통계
```

## 향후 확장 가능성

현재 수집되는 통계 외에도 다음과 같은 데이터를 추가할 수 있습니다:

- [ ] ATB 속도 vs 승률 상관관계
- [ ] 스킬 사용 빈도 및 효과
- [ ] 유닛별 기여도 (개별 데미지, 생존율)
- [ ] 턴별 HP 변화 추적
- [ ] 버프/디버프 효과 분석
- [ ] 유닛 배치 (전열/후열) 효과 분석

## 라이선스

이 시뮬레이터는 Husamguk 프로젝트의 일부입니다.
