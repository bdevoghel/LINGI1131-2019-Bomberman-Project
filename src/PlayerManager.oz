functor
import
   Player000bomber
   % Add here the name of the functor of a player
   Player005Umberto
   Player005Tozzi
   Player003John
   Player022smart
   Player087Basic
   Player087Bomber
   Player087Keyboard
   Player105Alex
   Player105Alice
   Player021IA2
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind ID}
      case Kind
      of player000bomber then {Player000bomber.portPlayer ID}
      % Add here the pattern to recognize the name used in the 
      % input file and launch the portPlayer function from the functor
      [] player005Umberto then {Player005Umberto.portPlayer ID}
      [] player005Tozzi then {Player005Tozzi.portPlayer ID}
      [] player003John then {Player003John.portPlayer ID}
      [] player022smart then {Player022smart.portPlayer ID}
      [] player087Basic then {Player087Basic.portPlayer ID}
      [] player087Bomber then {Player087Bomber.portPlayer ID}
      [] player087Keyboard then {Player087Keyboard.portPlayer ID}
      [] player105Alex then {Player105Alex.portPlayer ID}
      [] player105Alice then {Player105Alice.portPlayer ID}
      [] player021IA2 then {Player021IA2.portPlayer ID}
      else
         raise 
            unknownedPlayer('Player not recognized by the PlayerManager '#Kind)
         end
      end
   end
end
