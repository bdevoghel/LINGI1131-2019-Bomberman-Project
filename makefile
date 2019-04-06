# ----------------------------
# group nb : 5
# 32981600 : Severine MERSCH-MERSCH
# 59101600 : Brieuc DE VOGHEL
# ----------------------------


all:
	#@make clean
	@make compile
	@make compilePlayers
	@make compileInput
	@make run

compile:
	@ozc -c src/PlayerManager.oz -o bin/PlayerManager.ozf
	@ozc -c src/BombManager.oz -o bin/BombManager.ozf
	@ozc -c src/GUI.oz -o bin/GUI.ozf
	@ozc -c src/Main.oz -o bin/Main.ozf

compilePlayers:
	@ozc -c src/Player000name.oz -o bin/Player000name.ozf
	# + others

compileInput:
	@ozc -c src/Input.oz -o bin/Input.ozf

run:
	@ozengine bin/Main.ozf

main:
	@ozc -c src/BombManager.oz -o bin/BombManager.ozf
	@ozc -c src/Main.oz -o bin/Main.ozf
	@make run

clean:
	@rm -fv bin/PlayerManager.ozf
	@rm -fv bin/BombManager.ozf
	@rm -fv bin/GUI.ozf
	@rm -fv bin/Main.ozf
