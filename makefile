# ----------------------------
# group nb ??
# 59101600 : Brieuc DE VOGHEL
# 32981600 : Severine MERSCH-MERSCH
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here


ozc -c src/Input.oz -o bin/Input.ozf

PLAYERS = Player000name.oz 

compile:
	ozc -c src/PlayerManager.oz -o bin/PlayerManager.ozf
	ozc -c src/GUI.oz -o bin/GUI.ozf
	ozc -c src/Main.oz -o bin/Main.ozf

compilePlayers:
	ozc -c src/$(PLAYERS) -o bin/"$(PLAYERS)f"
	# + others

run:
	ozengine bin/Main.ozf

clean:
	rm -v bin/PlayerManager.ozf
	rm -v bin/GUI.ozf
	rm -v bin/Main.ozf
	rm -v bin/Player000name.ozf
