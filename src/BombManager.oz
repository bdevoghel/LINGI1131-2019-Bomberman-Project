functor
import
    Input
    System(show:Show)
export
    initialize:StartManager
define
   
    StartManager
    TreatStream

    Players

    proc {ExplodeBomb Gui Pos Fire}
        PositionsToUpdate
    in
        {Send Gui hideBomb(Pos)}
        PositionsToUpdate = {GetPositionsToUpdate Pos Fire}
        for I in 1..{Record.width PositionsToUpdate} do
            {Send Gui spawnFire(PositionsToUpdate.I)}
        end
    end

    proc {DissipateExplosion Gui Pos Fire}
        PositionsToUpdate
    in
        PositionsToUpdate = {GetPositionsToUpdate Pos Fire}
        for I in 1..{Record.width PositionsToUpdate} do
            MapValue = {List.nth {List.nth Input.map PositionsToUpdate.I.y} PositionsToUpdate.I.x}
        in
            {Send Gui hideFire(PositionsToUpdate.I)}
            if MapValue == 2 orelse MapValue == 3 then % box
                {Send Gui hideBox(PositionsToUpdate.I)}
                if MapValue == 2 then % box with point
                    {Send Gui spawnPoint(PositionsToUpdate.I)}
                elseif MapValue == 3 then % box with bonus
                    {Send Gui spawnBonus(PositionsToUpdate.I)}
                end

                % notify players
                for I in 1..{Record.width Players} do
                    {Show Players.I} {Show info(boxRemoved(PositionsToUpdate.I))}
                    %{Send Players.I info(boxRemoved(PositionsToUpdate.I))}
                    % TODO : debug
                end
            end
        end
    end

    fun {GetPositionsToUpdate Pos Fire}
        Positions = {Cell.new pos(Pos)}
        proc {Propagate Dir Pos Fire}
            if Fire > 0 then
                case Dir
                of north then NewPos = 'pt'(x:Pos.x y:Pos.y-1) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then
                        Positions := {Tuple.append '#'(NewPos) @Positions}
                    end
                    if ToBeContinued then {Propagate north NewPos Fire-1} end
                [] east then NewPos = 'pt'(x:Pos.x+1 y:Pos.y) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then
                        Positions := {Tuple.append '#'(NewPos) @Positions}
                    end
                    if ToBeContinued then {Propagate east NewPos Fire-1} end
                [] south then NewPos = 'pt'(x:Pos.x y:Pos.y+1) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then
                        Positions := {Tuple.append '#'(NewPos) @Positions}
                    end
                    if ToBeContinued then {Propagate south NewPos Fire-1} end
                [] west then NewPos = 'pt'(x:Pos.x-1 y:Pos.y) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then
                        Positions := {Tuple.append '#'(NewPos) @Positions}
                    end
                    if ToBeContinued then {Propagate west NewPos Fire-1} end
                end
            end
        end
        fun {ValidFlamePosition NewPos ?ToBeContinued}
            MapValue = {List.nth {List.nth Input.map NewPos.y} NewPos.x}
        in
            if MapValue == 1 then % wall
                ToBeContinued = false
                false
            elseif MapValue == 2 orelse MapValue == 3 then % box
                ToBeContinued = false
                true
            else 
                ToBeContinued = true
                true
            end
        end
    in
        {Propagate north Pos Fire-1}
        {Propagate east Pos Fire-1}
        {Propagate south Pos Fire-1}
        {Propagate west Pos Fire-1}
        @Positions
    end

in

    fun{StartManager Gui PortBombers}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
	        {TreatStream Stream Gui 'bombs'(1:'#'(pos:pt(x:1 y:1) timer:~1 fire:0 owner:god))}
        end
        Players = PortBombers
        Port
    end
        
    proc{TreatStream Stream Gui Bombs}
        case Stream
        of nil then skip
        [] H|T then
            case H 
            of placeBomb(Owner Pos) then NewBombs in
                {Send Gui spawnBomb(Pos)}
                NewBombs = {Tuple.append 'newBomb'('#'(pos:Pos timer:Input.timingBomb+1 fire:Input.fire owner:Owner)) Bombs}
                % TODO : notify players bombPlanted
                {TreatStream T Gui NewBombs}
            [] makeExplode then
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:Fire owner:Owner) then
                        if Timer == 0 then
                            {ExplodeBomb Gui Pos Fire}
                            % TODO : notify players bombExploded
                            {Send Owner add(bomb 1 _)}
                        end
                    end
                end
                {TreatStream T Gui Bombs}
            [] nextTurn then NewBombs = {Cell.new bombs()} in
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:Fire owner:Owner) then
                        if Timer == 0 then
                            {DissipateExplosion Gui Pos Fire}
                        else 
                            NewBombs := {Tuple.append 'newBomb'('#'(pos:Pos timer:Timer-1 fire:Fire owner:Owner)) @NewBombs}
                        end
                    end
                end                
                {TreatStream T Gui @NewBombs}
            else
                % WARNING : unsupported message
                {TreatStream T Gui Bombs}
            end
        end
    end
end