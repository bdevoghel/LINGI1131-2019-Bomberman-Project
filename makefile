# ----------------------------
# group nb ??
# 59101600 : Brieuc DE VOGHEL
# 32981600 : Severine MERSCH-MERSCH
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here

PLAYERS = Player000name.oz
COMPILABLES = PlayerManager.oz GUI.oz Main.oz

ozc -c src/Input.oz -o bin/Input.ozf
PLAYERS = Player000name.oz 
all:
	clean

compile:
	ozc -c src/PlayerManager.oz -o bin/PlayerManager.ozf
	ozc -c src/GUI.oz -o bin/GUI.ozf
	ozc -c src/Main.oz -o bin/Main.ozf
	ozc -c src/$(COMPILABLES) -o bin/"$(COMPILABLES)f"

compilePlayers:
	ozc -c src/$(PLAYERS) -o bin/"$(PLAYERS)f"
	# + others

	ozc -c src/Input.oz -o bin/Input.ozf

run:
	ozengine bin/Main.ozf

clean:
	rm -v bin/PlayerManager.ozf
	rm -v bin/GUI.ozf
	rm -v bin/"$(COMPILABLES)f"
	rm -v bin/"$(PLAYERS)f"
