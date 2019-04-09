functor
import
   GUI
   Input
   PlayerManager
   BombManager
   NotificationManager
   MapManager

   System(show:Show) % debug only
   Browser(browse:Browse)
   Application(exit:Exit)
   OS(rand:Rand)
define
   Board
   Bombers
   PortBombers

   BombM
   NotificationM
   MapM

   TurnByTurnGameDelay = 1000 % msec between each turn
   SpawnLocations

   fun {FindSpawnLocations} % returns a tuple of <position> where players can spawn (4 in Input.map)
      SpawnPos = {Cell.new spawnPos()}
      N
      SpawnList

      fun {ValidRandom Max}
         R = ({Rand} mod Max) + 1
      in
         if @((@SpawnPos).R) == null then
            {ValidRandom Max}
         else
            R
         end
      end
   in
      % find all pt() where Input.map == 4
      for X in 1..Input.nbColumn do
         for Y in 1..Input.nbRow do
            if {List.nth {List.nth Input.map Y} X} == 4 then
               SpawnPos := {Tuple.append newPos({Cell.new pt(x:X y:Y)}) @SpawnPos}
            end
         end
      end

      % randomize order (for not all players begin at the same spot every game)
      N = {Record.width @SpawnPos}
      SpawnList = {MakeTuple '#' N}
      for I in 1..N do 
         X = {ValidRandom N} 
      in
         SpawnList.I = @((@SpawnPos).X)
         ((@SpawnPos).X) := null
      end

      SpawnList
   end

   fun {ExecuteTurnByTurn TurnNb}
      {Browse turn#TurnNb}
      {Send BombM makeExplode} % make every bomb with timer at 0 explode

      {Delay TurnByTurnGameDelay}

      % for every player ...
      for I in 1..Input.nbBombers do State in
         {Send PortBombers.I getState(_ State)}
         if State == on then Action in
            % execute action for player
            {Send PortBombers.I doaction(_ Action)}
            case Action
            of move(Pos) then 
               {Send Board movePlayer(Bombers.I Pos)}
               {Send NotificationM movePlayer(Bombers.I Pos)} % notify everyone
            [] bomb(Pos) then 
               {Send BombM plantBomb(PortBombers.I Pos)}
               {Send NotificationM bombPlanted(Pos)} % notify everyone
            [] null then 
               {Show 'Action null on turn'#TurnNb#'by Bomber'#Bombers.I}
               % TODO : what now ?
            end
         else NbLives ID Pos in
            {Send MapM getPlayerLives(Bombers.I NbLives)}
            if NbLives > 0 then
               % spawn player back if it has still lives left
               {Send PortBombers.I spawn(ID Pos)} % tell player he's alive
               {Wait ID}
               if ID \= null then
                  {Send Board spawnPlayer(ID Pos)} % tell board to display player
                  {Send NotificationM spawnPlayer(ID Pos)} % notify everyone
               else
                  skip
               end
            end
         end
      end

      local GoodToGo in
      {Send BombM nextTurn(GoodToGo)} % decrease all bomb's timers
      {Wait GoodToGo} % wait turn finishes properly
      end 

      % look for winner
      local WinnerId in
         WinnerId = {PlayersStillAlive}
         if {Record.width WinnerId} > 1 then
            {ExecuteTurnByTurn TurnNb+1}
         elseif {Record.width WinnerId} == 1 then
            WinnerId.1
         else
            none
         end
      end
   end

   fun {ExecuteSimultaneous}
      bomber(id:~1 color:red name:none)
      % TODO
   end

   fun {PlayersStillAlive} PlayersAlive in % returns a tuple containing <bomber>s which have <life> > 0
      {Send MapM getPlayersAlive(PlayersAlive)}
      PlayersAlive
   end

in
   % in case Stop button in pressed
   thread {Wait GUI.waitForStop} {Show 'Successful Exit'} {Exit 0} end

   Board = {GUI.portWindow}
   {Send Board buildWindow}

   Bombers = {MakeTuple '#' Input.nbBombers}
   PortBombers = {MakeTuple '#' Input.nbBombers}

   BombM = {BombManager.initialize Board PortBombers NotificationM MapM}
   NotificationM = {NotificationManager.initialize Board PortBombers MapM}
   MapM = {MapManager.initialize Board PortBombers NotificationM}

   % initialize bombers
   for I in 1..Input.nbBombers do
      Bombers.I = bomber(id:I color:{List.nth Input.colorsBombers I} name:{List.nth Input.bombers I})
      PortBombers.I = {PlayerManager.playerGenerator {List.nth Input.bombers I} Bombers.I}
   end

   % initialize players on board
   for I in 1..Input.nbBombers do
      {Send Board initPlayer(Bombers.I)}
   end

   % spawn players
   SpawnLocations = {FindSpawnLocations}
   for I in 1..Input.nbBombers do ID Pos in
      {Send PortBombers.I assignSpawn(SpawnLocations.I)} % only at game initialisation
      {Send PortBombers.I spawn(ID Pos)} % tell player he's alive ; Pos == SpawnLocations.I
      {Wait ID}
      {Send Board spawnPlayer(ID Pos)} % tell board to display player
      {Send NotificationM spawnPlayer(ID Pos)} % notify everyone
   end

   % wait for click on 'start' button
   {Delay 2000}
   {Browse 'Please press Start button once the game is displayed properly.'}
   {Wait GUI.waitForStart}

   % run players
   local WinnerId in
      if Input.isTurnByTurn then
         WinnerId = {ExecuteTurnByTurn 0}
      else 
         WinnerId = {ExecuteSimultaneous}
      end
      {Send Board displayWinner(WinnerId)}
   end

   % TODO : quit game properly

end