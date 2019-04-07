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
define
   Board
   Bombers
   PortBombers

   BombM
   NotificationM
   MapM

   TurnByTurnGameDelay = 1000 % msec between each turn
   WinnerId
   SpawnLocations

   fun {FindSpawnLocations} % returns a tuple of <position> where players can spawn (4 in Input.map)
      spawnLocations(pt(x:2 y:2) pt(x:12 y:2) pt(x:2 y:6) pt(x:12 y:6)) 
      % TODO : find all pt() where Input.map == 4
      % TODO : randomize order (for not all players begin at the same spot every game)
   end

   fun {ExecuteTurnByTurn TurnNb}
      {Browse turn#TurnNb}
      {Send BombM makeExplode} % make every bomb with timer at 0 explode

      {Delay TurnByTurnGameDelay}

      % for every player ...
      for I in 1..Input.nbBombers do
         Action
      in
         {Send PortBombers.I doaction(_ Action)}
         case Action
         of move(Pos) then 
            {Send Board movePlayer(Bombers.I Pos)}
            {Send NotificationM movePlayer(Bombers.I Pos)} % notify everyone
         [] bomb(Pos) then 
            {Send BombM plantBomb(PortBombers.I Pos)}
            {Send NotificationM bombPlanted(Pos)} % notify everyone
         [] null then 
            {Show 'Action null on turn '#TurnNb}
            % TODO : what now ?
         end
      end

      {Send BombM nextTurn} % decrease all bomb's timers

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

   fun {PlayersStillAlive} % returns a tuple containing <bomber>s which have <life> > 0
      '#'(bomber(id:~1 color:red name:none) bomber(id:~2 color:red name:none))
      % TODO
   end

in

   Board = {GUI.portWindow}
   {Send Board buildWindow}

   Bombers = {MakeTuple '#' Input.nbBombers}
   PortBombers = {MakeTuple '#' Input.nbBombers}

   BombM = {BombManager.initialize Board PortBombers NotificationM MapM}
   NotificationM = {NotificationManager.initialize Board PortBombers MapM}
   MapM = {MapManager.initialize}

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
   for I in 1..Input.nbBombers do
      {Send PortBombers.I assignSpawn(SpawnLocations.I)} % only at game initialisation
      {Send Board spawnPlayer(Bombers.I SpawnLocations.I)} % tell board to display player
      {Send PortBombers.I spawn(_ _)} % tell player he's alive
      {Send NotificationM spawnPlayer(Bombers.I SpawnLocations.I)} % notify everyone
   end

   % wait for click on 'start' button
   {Wait GUI.waitForStart}

   % run players
   if Input.isTurnByTurn then
      WinnerId = {ExecuteTurnByTurn 0}
   else 
      WinnerId = {ExecuteSimultaneous}
   end
   {Send Board displayWinner(WinnerId)}

   % TODO : quit game properly

end