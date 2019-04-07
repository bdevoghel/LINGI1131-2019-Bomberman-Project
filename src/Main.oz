functor
import
   GUI
   Input
   PlayerManager
   BombManager

   System(show:Show) % debug only
   Browser(browse:Browse)
define
   Board
   Bombers
   PortBombers
   Bombs

   TurnByTurnGameDelay = 1000 % msec between each turn
   WinnerId

   fun {FindSpawnLocations} % returns a tuple of <position> where players can spawn (4 in Input.map)
      spawnLocations(pt(x:2 y:2) pt(x:12 y:2) pt(x:2 y:6) pt(x:12 y:6)) 
      % TODO : find in function of Input.map
      % TODO : randomize order
   end
   SpawnLocations

   fun {ExecuteTurnByTurn TurnNb}
      {Send Bombs makeExplode} % make every bomb with timer at 0 explode

      {Delay TurnByTurnGameDelay}

      for I in 1..Input.nbBombers do % for every player ...
         Action
      in
         {Send PortBombers.I doaction(_ Action)}
         case Action
         of move(Pos) then 
            {Send Board movePlayer(Bombers.I Pos)}
            % TODO : notify players
         [] bomb(Pos) then 
            {Send Bombs placeBomb(PortBombers.I Pos)}
         [] null then 
            {Show 'ACTION null on turn '#TurnNb} % TODO : what now ?
         end
      end

      {Send Bombs nextTurn} % decrease bomb's timers
      {Browse turn#TurnNb}

      % look for winner
      WinnerId = {PlayersStillAlive}
      if {Record.width WinnerId} > 1 then
         {ExecuteTurnByTurn TurnNb+1}
      else 
         WinnerId.1
      end
   end

   fun {ExecuteSimultaneous}
      bomber(id:~1 color:red name:none)
      % TODO
   end

   fun {PlayersStillAlive}
      '#'(bomber(id:~1 color:red name:none) bomber(id:~2 color:red name:none))
      % TODO
   end

in

   Board = {GUI.portWindow}
   {Send Board buildWindow}

   Bombers = {MakeTuple '#' Input.nbBombers}
   PortBombers = {MakeTuple '#' Input.nbBombers}

   Bombs = {BombManager.initialize Board PortBombers}

   % initialise bombers
   for I in 1..Input.nbBombers do
      Bombers.I = bomber(id:I color:{List.nth Input.colorsBombers I} name:{List.nth Input.bombers I})
      PortBombers.I = {PlayerManager.playerGenerator {List.nth Input.bombers I} Bombers.I}
   end

   % initialise players on board
   for I in 1..Input.nbBombers do
      {Send Board initPlayer(Bombers.I)}
   end

   % spawn players
   SpawnLocations = {FindSpawnLocations}
   for I in 1..Input.nbBombers do
      {Send PortBombers.I assignSpawn(SpawnLocations.I)} % only at game initialisation

      {Send Board spawnPlayer(Bombers.I SpawnLocations.I)} % tell board to display player
      {Send PortBombers.I spawn(_ _)} % tell player he's alive
   end

   % wait for board do be displayed properly
   local X Y in
      thread {Wait 10000} Y=unit end
      {Send Board bindWhenReady(X)} % binds X (as soon as previous calls are done ~ build is done)
      {WaitOr X Y}
   end
   % ou a default d'avoir la liberte de faire de belles choses ... :
   {Delay 7000} {Browse 5} {Delay 1000} {Browse 4} {Delay 1000} {Browse 3} {Delay 1000} {Browse 2} {Delay 1000} {Browse 1} {Delay 1000} {Browse 'GO'}

   % run players
   if Input.isTurnByTurn then
      WinnerId = {ExecuteTurnByTurn 0}
   else 
      WinnerId = {ExecuteSimultaneous}
   end
   {Send Board displayWinner(WinnerId)}

   % TODO : quit game properly

end