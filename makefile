# ----------------------------
# group nb ??
# 59101600 : Brieuc DE VOGHEL
# 32981600 : Severine MERSCH-MERSCH
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here

PLAYERS = src/Player000name.oz
PLAYERSexe = bin/Player000name.ozf
COMPILABLES = src/PlayerManager.oz src/GUI.oz src/Main.oz
EXECUTABLES = bin/PlayerManager.ozf bin/GUI.ozf bin/Main.ozf

all:
	clean
	compile
	compilePlayers
	compileInput
	run

compile:
	ozc -c $(COMPILABLES) -o $(EXECUTABLES)

compilePlayers:
	ozc -c $(PLAYERS) -o $(PLAYERSexe)
	# + others

compileInput:
	ozc -c src/Input.oz -o bin/Input.ozf

run:
	ozengine bin/Main.ozf

clean:
	rm -v $(EXECUTABLES)
	rm -v $(PLAYERSexe)
