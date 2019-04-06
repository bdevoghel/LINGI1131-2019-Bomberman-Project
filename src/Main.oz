functor
import
   GUI
   Input
   PlayerManager
   BombManager

   System(show:Show)
   Browser(browse:Browse)
   OS % for Delay
   Lists
define
   Board
   Bombers
   PortBombers
   Bombs

   fun {FindSpawnLocations} % returns a tuple of <position> where players can spawn (4 in Input.map)
      % TODO

      % for given map
      spawnLocations(pt(x:2 y:2) pt(x:12 y:2) pt(x:2 y:6) pt(x:12 y:6)) 

      % TODO : randomize order
   end
   SpawnLocations

   TurnByTurnGameSpeed = 1000 % msec between each turn

in

   Board = {GUI.portWindow}
   {Send Board buildWindow}

   Bombers = {MakeTuple '#' Input.nbBombers}
   PortBombers = {MakeTuple '#' Input.nbBombers}

   Bombs = {BombManager.initialize Board}

   % initialise bombers
   for I in 1..Input.nbBombers do
      Bombers.I = bomber(id:I color:{List.nth Input.colorsBombers I} name:{List.nth Input.bombers I})
      PortBombers.I = {PlayerManager.playerGenerator {List.nth Input.bombers I} Bombers.I}
   end

   % initialise players on board
   for I in 1..Input.nbBombers do
      {Send Board initPlayer(Bombers.I)}
   end

   {Delay 5000} % wait for board do be displayed properly

   % spawn players
   SpawnLocations = {FindSpawnLocations}
   for I in 1..Input.nbBombers do ID Pos in
      {Send PortBombers.I assignSpawn(SpawnLocations.I)} % only at game initialisation

      {Send Board spawnPlayer(Bombers.I SpawnLocations.I)} % tell board to display player
      {Send PortBombers.I spawn(ID Pos)} % tell player he's alive
   end

   if Input.isTurnByTurn then

   %%%%%%%%%%%%%%%%%%% TURN BY TURN %%%%%%%%%%%%%%%%%%%
      for N in 1..100 do % do 100 turns
         {Send Bombs makeExplode} % make every bomb with timer at 0 explode

         {Delay TurnByTurnGameSpeed}

         for I in 1..Input.nbBombers do % for every player
            ID Action
         in
            {Send PortBombers.I doaction(ID Action)}
            case Action
            of move(Pos) then 
               {Send Board movePlayer(Bombers.I Pos)}
            [] bomb(Pos) then 
               {Send Bombs placeBomb(PortBombers.I Pos)}
            [] null then 
               {Show 'ACTION null on turn '#N}
            else {Show 'ERROR : UNKNOWN ACTION'}
            end
         end

         {Send Bombs nextTurn} % decrease bomb's timers
         {Browse N}
      end

   else 
   %%%%%%%%%%%%%%%%%%% SIMULTANEOUS %%%%%%%%%%%%%%%%%%%

      skip
      % TODO
   end

   % TODO : quit game properly

end
