# ----------------------------
# group nb ??
# 59101600 : Brieuc DE VOGHEL
# 32981600 : Severine MERSCH-MERSCH
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

all:
	clean
	compile
	compilePlayers
	compileInput
	run

compile:
	ozc -c src/PlayerManager.oz -o bin/PlayerManager.ozf
	ozc -c src/GUI.oz -o bin/GUI.ozf
	ozc -c src/Main.oz -o bin/Main.ozf

compilePlayers:
	ozc -c src/Player000name.oz -o bin/Player000name.ozf
	# + others

compileInput:
	ozc -c src/Input.oz -o bin/Input.ozf

run:
	ozengine bin/Main.ozf

clean:
	rm -v bin/PlayerManager.ozf
	rm -v bin/GUI.ozf
	rm -v bin/Main.ozf
