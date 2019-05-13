functor
export
   isTurnByTurn:IsTurnByTurn
   useExtention:UseExtention
   printOK:PrintOK
   nbRow:NbRow
   nbColumn:NbColumn
   map:Map
   nbBombers:NbBombers
   bombers:Bombers
   colorsBombers:ColorsBombers
   nbLives:NbLives
   nbBombs:NbBombs
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   fire:Fire
   timingBomb:TimingBomb
   timingBombMin:TimingBombMin
   timingBombMax:TimingBombMax
define
   IsTurnByTurn UseExtention PrintOK
   NbRow NbColumn Map
   NbBombers Bombers ColorsBombers
   NbLives NbBombs
   ThinkMin ThinkMax
   TimingBomb TimingBombMin TimingBombMax Fire
in 


%%%% Style of game %%%%
   
   IsTurnByTurn = false
   UseExtention = false
   PrintOK = false


%%%% Description of the map %%%%
   
   NbRow = 7
   NbColumn = 7
   Map = [[1 1 1 1 1 1 1]
          [1 4 0 2 0 4 1]
	      [1 0 1 3 1 0 1]
	      [1 2 3 3 3 2 1]
	      [1 0 1 3 1 0 1]
	      [1 4 0 2 0 4 1]
	      [1 1 1 1 1 1 1]]

%%%% Players description %%%%

   % you can choose from : player000bomber player005Umberto player005Tozzi player003John player087Bomber player087Keyboard player105Alice player038Luigi player007James

   NbBombers = 2
   Bombers = [player005Tozzi player005Umberto]
   ColorsBombers = [red green]

%%%% Parameters %%%%

   NbLives = 3
   NbBombs = 1
 
   ThinkMin = 500  % in millisecond
   ThinkMax = 2000 % in millisecond
   
   Fire = 3
   TimingBomb = 3 
   TimingBombMin = 3000 % in millisecond
   TimingBombMax = 4000 % in millisecond

end
