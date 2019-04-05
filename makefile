# ----------------------------
# group nb ??
# 59101600 : Brieuc DE VOGHEL
# 32981600 : Severine MERSCH-MERSCH
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here

PLAYERS = Player000name.oz
COMPILABLES = PlayerManager.oz GUI.oz Main.oz

all:
	clean
	compile
	compilePlayers
	compileInput
	run

compile:
	ozc -c src/$(COMPILABLES) -o bin/"$(COMPILABLES)f"

compilePlayers:
	ozc -c src/$(PLAYERS) -o bin/"$(PLAYERS)f"
	# + others

compileInput:
	ozc -c src/Input.oz -o bin/Input.ozf

run:
	ozengine bin/Main.ozf

clean:
	rm -v bin/"$(COMPILABLES)f"
	rm -v bin/"$(PLAYERS)f"
