@echo off
REM Battle Simulator Launcher
REM Usage: run_simulation.bat <team1> <team2> <iterations> [output_path]
REM Example: run_simulation.bat "gyeonhwon,infantry,infantry" "wanggeon,cavalry,cavalry" 5

set BATTLE_SIM_TEAM1=%~1
set BATTLE_SIM_TEAM2=%~2
set BATTLE_SIM_ITERATIONS=%~3
set BATTLE_SIM_OUTPUT=%~4

REM Default output path
if "%BATTLE_SIM_OUTPUT%"=="" set BATTLE_SIM_OUTPUT=output/simulation

echo ===================================
echo Battle Simulator Launcher
echo ===================================
echo Team 1: %BATTLE_SIM_TEAM1%
echo Team 2: %BATTLE_SIM_TEAM2%
echo Iterations: %BATTLE_SIM_ITERATIONS%
echo Output: %BATTLE_SIM_OUTPUT%
echo ===================================
echo.

"C:\BIN\Godot_v4.5.1-stable_win64\Godot_v4.5.1-stable_win64_console.exe" --path "%~dp0" --headless scenes/battle_simulator.tscn

echo.
echo Simulation complete!
