functor
import
   GUI
   Input
   PlayerManager
   Browser(browse:Browse)
   %Time %(delay:Delay)
   OS
   %Application
   %System(show:Show)
define
   Board
   PortBomber1
   Bomber1
in
   %% Implement your controller here
   Board = {GUI.portWindow}
   {Send Board buildWindow}
   Bomber1 = bomber(id:1 color:red name:player000bomber)
   PortBomber1 = {PlayerManager.playerGenerator player000bomber Bomber1}
   {Send Board initPlayer(Bomber1)}
   {Delay 4000}
   {Send Board spawnPlayer(Bomber1 pt(x:2 y:2))}
   {Delay 3000}
   {Send Board movePlayer(Bomber1 pt(x:3 y:2))}

end
