# ----------------------------
# group nb : 5
# 32981600 : Severine MERSCH-MERSCH
# 59101600 : Brieuc DE VOGHEL
# ----------------------------


all:
	@make -s compile
	@make -s compilePlayers
	@make -s compileInput
	@make -s run

compile:
	@make -s GUI.ozf
	@make -s PlayerManager.ozf
	@make -s BombManager.ozf
	@make -s NotificationManager.ozf
	@make -s MapManager.ozf
	@make -s Main.ozf

compilePlayers:
	@make -s Player005Umberto.ozf
	@make -s Player005Tozzi.ozf
	# + others
	@echo '=> Players compiled'

compileInput:
	@make -s Input.ozf

run:
	@echo '=> Running Main'
	@ozengine bin/Main.ozf

main:
	@make -s BombManager.ozf
	@make -s NotificationManager.ozf
	@make -s MapManager.ozf
	@make -s Main.ozf
	@make -s compilePlayers
	@make -s run

workInProgress:
	#@make -s compilePlayers
	@make -s compileInput
	@make -s run

scenarios:
	@make -s compile
	@make -s compilePlayers
	@ozc -c src/scenarios/Input1.oz -o bin/Input.ozf
	@echo 'SCENARIO 1'
	@make -s run
	@ozc -c src/scenarios/Input2.oz -o bin/Input.ozf
	@echo 'SCENARIO 2'
	@make -s run
	@ozc -c src/scenarios/Input3.oz -o bin/Input.ozf
	@echo 'SCENARIO 3'
	@make -s run
	@ozc -c src/scenarios/Input4.oz -o bin/Input.ozf
	@echo 'SCENARIO 4'
	@make -s run
	@ozc -c src/scenarios/Input5.oz -o bin/Input.ozf
	@echo 'SCENARIO 5'
	@make -s run
	@ozc -c src/scenarios/Input6.oz -o bin/Input.ozf
	@echo 'SCENARIO 6'
	@make -s run

clean:
	@rm -fv bin/PlayerManager.ozf
	@rm -fv bin/BombManager.ozf
	@rm -fv bin/NotificationManager.ozf
	@rm -fv bin/MapManager.ozf
	@rm -fv bin/GUI.ozf
	@rm -fv bin/Main.ozf
	@rm -fv bin/Input.ozf
	@rm -fv bin/Player005Umberto.ozf
	@rm -fv bin/Player005Tozzi.ozf
	@rm -fv bin/Input1.ozf
	@rm -fv bin/Input2.ozf
	@rm -fv bin/Input3.ozf
	@rm -fv bin/Input4.ozf
	@rm -fv bin/Input5.ozf
	@rm -fv bin/Input6.ozf

GUI.ozf:
	@ozc -c src/GUI.oz -o bin/GUI.ozf
	@echo '=> GUI compiled'
PlayerManager.ozf:
	@ozc -c src/PlayerManager.oz -o bin/PlayerManager.ozf
	@echo '=> PlayerManager compiled'
BombManager.ozf:
	@ozc -c src/BombManager.oz -o bin/BombManager.ozf
	@echo '=> BombManager compiled'
NotificationManager.ozf:
	@ozc -c src/NotificationManager.oz -o bin/NotificationManager.ozf
	@echo '=> NotificationManager compiled'
MapManager.ozf:
	@ozc -c src/MapManager.oz -o bin/MapManager.ozf
	@echo '=> MapManager compiled'
Input.ozf:
	@ozc -c src/Input.oz -o bin/Input.ozf
	@echo '=> Input compiled'
Main.ozf:
	@ozc -c src/Main.oz -o bin/Main.ozf
	@echo '=> Main compiled'
Player005Umberto.ozf:
	@ozc -c src/Player005Umberto.oz -o bin/Player005Umberto.ozf
Player005Tozzi.ozf:
	@ozc -c src/Player005Tozzi.oz -o bin/Player005Tozzi.ozf