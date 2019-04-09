functor
import
    Input

    OS(rand:Rand)
    System(show:Show)
export
    initialize:StartManager
    getPosExplosions:GetPositionsToUpdate
define
   
    StartManager
    TreatStream
    Port

    Gui
    Players
    NotificationM
    MapM

    proc {ExplodeBomb Bomb}
        PositionsToUpdate
    in
        {Send Gui hideBomb(Bomb.pos)}
        PositionsToUpdate = {GetPositionsToUpdate Bomb.pos Bomb.fire ValidFlamePosition}
        Bomb.explosionPos = PositionsToUpdate
        for I in 1..{Record.width PositionsToUpdate} do
            {Send Gui spawnFire(PositionsToUpdate.I)}
        end
    end

    proc {DissipateExplosion Bomb}
        PositionsToUpdate
    in
        if Input.isTurnByTurn then
            PositionsToUpdate = Bomb.explosionPos
        else
            PositionsToUpdate = {GetPositionsToUpdate Bomb.pos Bomb.fire ValidFlamePosition}
        end

        for I in 1..{Record.width PositionsToUpdate} do MapValue in
            {Send Gui hideFire(PositionsToUpdate.I)}

            {Send MapM getMapValue(PositionsToUpdate.I.x PositionsToUpdate.I.y MapValue)}
            if MapValue == 2 orelse MapValue == 3 then % box
                {Send Gui hideBox(PositionsToUpdate.I)}
                if MapValue == 2 then % box with point
                    {Send NotificationM spawnPoint(PositionsToUpdate.I)}
                elseif MapValue == 3 then % box with bonus
                    {Send NotificationM spawnBonus(PositionsToUpdate.I)}
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

    fun {ValidFlamePosition NewPos ?ToBeContinued} MapValue in
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
    in
        {NewPort Stream Port}
        thread
	        {TreatStream Stream 'bombs'()}
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
            [] plantBomb(ID Pos) then NewBombs in
                {Send Gui spawnBomb(Pos)}
                NewBombs = {Tuple.append newBomb('#'(pos:Pos timer:Input.timingBomb+1 fire:Input.fire owner:ID explosionPos:_)) Bombs}
                {TreatStream T NewBombs}
            [] makeExplode then
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:_ owner:ID explosionPos:_) then
                        if Timer == 0 then
                            {ExplodeBomb Bombs.I}
                            {Send NotificationM add(ID bomb 1 _)}
                            {Send NotificationM bombExploded(Pos)} % notify everyone
                        end
                    end
                end
                {TreatStream T Bombs}
            [] nextTurn(?GoodToGo) then NewBombs = {Cell.new bombs()} in
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:Fire owner:ID explosionPos:X) then
                        if Timer == 0 then
                            {DissipateExplosion Bombs.I}
                        else 
                            NewBombs := {Tuple.append newBomb('#'(pos:Pos timer:Timer-1 fire:Fire owner:ID explosionPos:X)) @NewBombs}
                        end
                    end
                end
                GoodToGo = unit
                {TreatStream T @NewBombs}
            [] plantBombSimultaneous(ID Pos) then NewBomb in
                thread
                    NewBomb = newBomb(pos:Pos timer:_ fire:Input.fire owner:ID explosionPos:_)

                    % delay before explosion
                    {Delay ({Rand} mod (Input.timingBombMax - Input.timingBombMin)) + Input.timingBombMin}
                    {Show explode}
                    {ExplodeBomb NewBomb}
                    {Send NotificationM add(ID bomb 1 _)}
                    {Send NotificationM bombExploded(Pos)} % notify everyone
                    {Show okExplode}

                    % delay of explosion
                    {Delay 1000}
                    {Show dissipate}
                    {DissipateExplosion NewBomb}
                    {Show okDissipate}
                end
                {TreatStream T _}
            else
                % WARNING : unsupported message
                {TreatStream T Bombs}
            end
        end
    end
end