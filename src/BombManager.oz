functor
import
    Input
export
    initialize:StartManager
    getPosExplosions:GetPositionsToUpdate
define
   
    StartManager
    TreatStream

    Gui
    Players
    NotificationM
    MapM

    proc {ExplodeBomb Pos Fire}
        PositionsToUpdate
    in
        {Send Gui hideBomb(Pos)}
        PositionsToUpdate = {GetPositionsToUpdate Pos Fire ValidFlamePosition}
        for I in 1..{Record.width PositionsToUpdate} do
            {Send Gui spawnFire(PositionsToUpdate.I)}
        end
    end

    proc {DissipateExplosion Pos Fire}
        PositionsToUpdate
    in
        PositionsToUpdate = {GetPositionsToUpdate Pos Fire ValidFlamePosition}
        for I in 1..{Record.width PositionsToUpdate} do 
            MapValue
        in
            {Send Gui hideFire(PositionsToUpdate.I)}

            {Send MapM getMapValue(PositionsToUpdate.I.x PositionsToUpdate.I.y MapValue)}
            if MapValue == 2 orelse MapValue == 3 then % box
                {Send Gui hideBox(PositionsToUpdate.I)}
                if MapValue == 2 then % box with point
                    {Send Gui spawnPoint(PositionsToUpdate.I)}
                elseif MapValue == 3 then % box with bonus
                    {Send Gui spawnBonus(PositionsToUpdate.I)}
                end
                {Send NotificationM boxRemoved(PositionsToUpdate.I)} % notify everyone
            end
        end
    end

    fun {GetPositionsToUpdate Pos Fire ValidFlamePosition} % ValidFlamePosition is for higher order programming
        Positions = {Cell.new pos(Pos)}
        proc {Propagate Dir Pos Fire}
            if Fire > 0 then
                case Dir
                of north then NewPos = 'pt'(x:Pos.x y:Pos.y-1) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then Positions := {Tuple.append '#'(NewPos) @Positions} end
                    if ToBeContinued then {Propagate north NewPos Fire-1} end
                [] east then NewPos = 'pt'(x:Pos.x+1 y:Pos.y) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then Positions := {Tuple.append '#'(NewPos) @Positions} end
                    if ToBeContinued then {Propagate east NewPos Fire-1} end
                [] south then NewPos = 'pt'(x:Pos.x y:Pos.y+1) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then Positions := {Tuple.append '#'(NewPos) @Positions} end
                    if ToBeContinued then {Propagate south NewPos Fire-1} end
                [] west then NewPos = 'pt'(x:Pos.x-1 y:Pos.y) ToBeContinued in
                    if {ValidFlamePosition NewPos ToBeContinued} then Positions := {Tuple.append '#'(NewPos) @Positions} end
                    if ToBeContinued then {Propagate west NewPos Fire-1} end
                end
            end
        end
    in
        {Propagate north Pos Fire}
        {Propagate east Pos Fire}
        {Propagate south Pos Fire}
        {Propagate west Pos Fire}
        @Positions
    end

    fun {ValidFlamePosition NewPos ?ToBeContinued}
        MapValue
    in
        {Send MapM getMapValue(NewPos.x NewPos.y MapValue)}
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

    fun {StartManager GuiPort PortBombers NotificationManagerPort MapManagerPort}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
	        {TreatStream Stream 'bombs'(1:'#'(pos:pt(x:1 y:1) timer:~1 fire:0 owner:'GOD'))}
        end
        Gui = GuiPort
        Players = PortBombers
        NotificationM = NotificationManagerPort
        MapM = MapManagerPort
        Port
    end
        
    proc {TreatStream Stream Bombs}
        case Stream of nil then skip
        [] H|T then
            case H of nil then skip
            [] plantBomb(Owner Pos) then NewBombs in
                {Send Gui spawnBomb(Pos)}
                NewBombs = {Tuple.append 'newBomb'('#'(pos:Pos timer:Input.timingBomb+1 fire:Input.fire owner:Owner)) Bombs}
                {TreatStream T NewBombs}
            [] makeExplode then
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:Fire owner:Owner) then
                        if Timer == 0 then
                            {ExplodeBomb Pos Fire}
                            {Send Owner add(bomb 1 _)}
                            {Send NotificationM bombExploded(Pos)} % notify everyone
                        end
                    end
                end
                {TreatStream T Bombs}
            [] nextTurn(GoodToGo) then NewBombs = {Cell.new bombs()} in % TODO : improve by not remembering the position of the fire ...
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:Fire owner:Owner) then
                        if Timer == 0 then
                            {DissipateExplosion Pos Fire}
                        else 
                            NewBombs := {Tuple.append newBomb('#'(pos:Pos timer:Timer-1 fire:Fire owner:Owner)) @NewBombs}
                        end
                    end
                end
                GoodToGo = unit
                {TreatStream T @NewBombs}
            else
                % WARNING : unsupported message
                {TreatStream T Bombs}
            end
        end
    end
end