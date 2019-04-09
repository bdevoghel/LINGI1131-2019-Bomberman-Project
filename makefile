# ----------------------------
# group nb : 5
# 32981600 : Severine MERSCH-MERSCH
# 59101600 : Brieuc DE VOGHEL
# ----------------------------


all:
	@make -s clean
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

clean:
	@rm -fv bin/PlayerManager.ozf
	@rm -fv bin/BombManager.ozf
	@rm -fv bin/NotificationManager.ozf
	@rm -fv bin/MapManager.ozf
	@rm -fv bin/GUI.ozf
	@rm -fv bin/Main.ozf
	@rm -fv bin/Input.ozf
	@rm -fv bin/Player005Umberto.ozf

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