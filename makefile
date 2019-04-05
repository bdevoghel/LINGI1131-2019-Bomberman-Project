# ----------------------------
# group nb ??
# 59101600 : Brieuc DE VOGHEL
# noma2 : Severine MERSCH-MERSCH
# ----------------------------

# TODO complete the header with your group number, your noma's and full names

# TODO write your makefile here

ozc -c src/Input.oz -o bin/Input.ozf
ozc -c src/PlayerManager.oz -o bin/PlayerManager.ozf
# ozc -c src/players_files.oz -o bin/players_files.ozf
ozc -c src/GUI.oz -o bin/GUI.ozf
ozc -c src/Main.oz -o bin/Main.ozf

ozengine bin/Main.ozf