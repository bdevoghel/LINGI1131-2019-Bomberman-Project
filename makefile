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
	@ozc -c src/GUI.oz -o bin/GUI.ozf
	@echo '=> GUI compiled'
	@ozc -c src/PlayerManager.oz -o bin/PlayerManager.ozf
	@ozc -c src/BombManager.oz -o bin/BombManager.ozf
	@echo '=> Managers compiled'
	@ozc -c src/Main.oz -o bin/Main.ozf
	@echo '=> Main compiled'

compilePlayers:
	#@ozc -c src/Player000name.oz -o bin/Player000name.ozf
	# + others
	@echo '=> Players compiled'

compileInput:
	@ozc -c src/Input.oz -o bin/Input.ozf
	@echo '=> Input compiled'

run:
	#@echo '*****************************************************************'
	@echo '=> Running Main'
	@ozengine bin/Main.ozf

main:
	@ozc -c src/BombManager.oz -o bin/BombManager.ozf
	@ozc -c src/Main.oz -o bin/Main.ozf
	@make -s run

clean:
	@rm -fv bin/PlayerManager.ozf
	@rm -fv bin/BombManager.ozf
	@rm -fv bin/GUI.ozf
	@rm -fv bin/Main.ozf
	@rm -fv bin/Input.ozf
	@rm -fv bin/Player000name.ozf

*.ozf:
	@echo 'I would like to help you, but...'
	# TODO