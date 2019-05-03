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
   OS(rand:Rand pipe:Pipe)
define
   BombersList
   ColorsList
   Board
   Bombers
   PortBombers

   BombM
   NotificationM
   MapM

   TurnByTurnGameDelay = 1000 % msec between each turn
   SpawnLocations

   StopPlayers

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

   fun {ExecuteTurnByTurn TurnNb} GoodToGo in
      {Browse turn#TurnNb}
      % for every player ...
      for I in 1..Input.nbBombers do 
         {ExecutePlayer I}
      end

      {Send BombM nextTurn(GoodToGo)} % decrease all bomb's timers
      {Wait GoodToGo} % wait turn finishes properly
      {Send BombM makeExplode} % make every bomb with timer at 0 explode

      {Delay TurnByTurnGameDelay}

      if {Record.width {PlayersStillAlive}} > 1 andthen {NbBoxesLeft} > 0 then 
         {ExecuteTurnByTurn TurnNb+1}
      else 
         % find winner(s) with the most points
         {FindWinner}
      end
   end

   fun {ExecuteSimultaneous}
      % for every player ...
      for I in 1..Input.nbBombers do
         thread {ExecutePlayer I} end
      end

      if {EndOfSimultaneous} then % loops in EndOfSimultaneous until end
         StopPlayers = true
         % find winner(s) with the most points
         {FindWinner}
      end
   end

   proc {ExecutePlayer I}
      ID State 
   in
      {Send PortBombers.I getState(ID State)}
      if State == on then Action in
         % execute action for player
         {Send PortBombers.I doaction(_ Action)}
         case Action
         of move(Pos) then 
            {Send Board movePlayer(ID Pos)}
            {Send NotificationM movePlayer(ID Pos)} % notify everyone
         [] bomb(Pos) then
            if Input.isTurnByTurn then
               {Send BombM plantBomb(ID Pos)}
            else
               {Send BombM plantBombSimultaneous(ID Pos)}
            end
            {Send NotificationM bombPlanted(Pos)} % notify everyone
         [] null then 
            {Show 'ERROR : action null on by Bomber'#ID}
         end
      else NbLives Pos in % if state == off
         {Send MapM getPlayerLives(ID NbLives)} {Wait NbLives}
         if NbLives > 0 then
            % spawn player back if it has still lives left
            {Send PortBombers.I spawn(_ Pos)} % tell player he's alive
            {Wait Pos}
            if ID \= null then
               {Send Board spawnPlayer(ID Pos)} % tell board to display player
               {Send NotificationM spawnPlayer(ID Pos)} % notify everyone
            end
         end
      end

      if {Not Input.isTurnByTurn} andthen {Value.isFree StopPlayers} then
         {Delay ({Rand} mod (Input.thinkMax - Input.thinkMin)) + Input.thinkMin}
         {ExecutePlayer I}
      end
   end

   fun {EndOfSimultaneous}
      if {Record.width {PlayersStillAlive}} > 1 andthen {NbBoxesLeft} > 0 then
         {Delay 100}
         {EndOfSimultaneous}
      else
         true
      end
   end

   fun {FindWinner}
      Winners = {Cell.new winners(winners:nil score:~1)}
   in
      for I in 1..Input.nbBombers do
         Result in
         {Send NotificationM add(Bombers.I point 0 Result)}
         if Result > @(Winners).score then
            Winners := winners(winners:Bombers.I score:Result)
         elseif Result == @(Winners).score then
            Winners := winners(winners:Bombers.I|@(Winners).winners score:Result)
         end
      end
      @(Winners).winners
   end

   fun {PlayersStillAlive} PlayersAlive in % returns a tuple containing <bomber>s which have <life> > 0
      {Send MapM getPlayersAlive(PlayersAlive)}
      PlayersAlive
   end

   fun {NbBoxesLeft} NbBoxes in
      {Send MapM getNbBoxes(NbBoxes)}
      NbBoxes
   end

in
   % in case Stop button in pressed
   thread {Wait GUI.waitForStop} {Show 'Successful Exit'} {Exit 0} end
   thread {Wait GUI.waitForRestart} {Show 'Restarting Game (no more debugging available)'} {Pipe make ['run'] _ _} {Delay 100} {Exit 0} end

   Board = {GUI.portWindow}
   {Send Board buildWindow}

   Bombers = {MakeTuple '#' Input.nbBombers}
   PortBombers = {MakeTuple '#' Input.nbBombers}

   BombM = {BombManager.initialize Board PortBombers NotificationM MapM}
   NotificationM = {NotificationManager.initialize Board PortBombers MapM}
   MapM = {MapManager.initialize Board PortBombers NotificationM}

   % randomize order of players
   local
      N = Input.nbBombers 
      TakenIndex = {MakeTuple '#' N}
      fun {ValidRandom Max}
         R = ({Rand} mod Max) + 1
      in
         if {Value.isFree TakenIndex.R} then
            R
         else
            {ValidRandom Max}
         end
      end
   in
      BombersList = {MakeTuple '#' N}
      ColorsList = {MakeTuple '#' N}
      for I in 1..N do 
         X = {ValidRandom N} 
      in
         BombersList.I = {List.nth Input.bombers X}
         ColorsList.I = {List.nth Input.colorsBombers X}
         TakenIndex.X = I
      end
   end

   % initialize bombers
   for I in 1..Input.nbBombers do
      Bombers.I = bomber(id:I color:ColorsList.I name:BombersList.I)
      PortBombers.I = {PlayerManager.playerGenerator BombersList.I Bombers.I}
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
      %ICI est ce que dans l'initialisation on n'utiliserait pas aussi NotifM pour spawn a transm a board?
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
      {Show winnerID#WinnerId}
      {Send Board displayWinner(WinnerId)}
   end

end