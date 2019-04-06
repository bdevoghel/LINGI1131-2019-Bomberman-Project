functor
import
    Input

    Browser(browse:Browse)
export
    initialize:StartManager
define
   
    StartManager
    TreatStream

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
            {Send Gui hideFire(PositionsToUpdate.I)}
        end
    end

    fun {GetPositionsToUpdate Pos Fire}
        Positions = {Cell.new pos(Pos)}
    in
        %%%%%%%%%%%%%%%%%%%%%%%%%%% WROK IN PROGRESS %%%%%%%%%%%%%%%%%%%%%%%%%%%
        for X in 1..Input.nbRow do
            for Y in 1..Input.nbColumn do
                if (Pos.x == X andthen {Number.abs Pos.y-Y} < Fire) 
                    orelse (Pos.y == Y andthen {Number.abs Pos.x-X} < Fire) then % in cardinal directions at [Fire] distance from [Pos]
                    Positions := {Tuple.append 'newPos'('pt'(x:X y:Y)) @Positions}
                end
            end
        end
        %@Positions
        %%%%%%%%%%%%%%%%%%%%%%%%%%% WROK IN PROGRESS %%%%%%%%%%%%%%%%%%%%%%%%%%%
        pos(Pos)
    end

in

    fun{StartManager Gui}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
	        {TreatStream Stream Gui 'bombs'(1:'#'(pos:pt(x:1 y:1) timer:~1 fire:0 owner:god))}
        end
        Port
    end
        
    proc{TreatStream Stream Gui Bombs}
        case Stream
        of nil then skip
        [] H|T then
            case H 
            of placeBomb(Owner Pos) then NewBombs in
                {Send Gui spawnBomb(Pos)} % display bomb
                NewBombs = {Tuple.append 'newBomb'('#'(pos:Pos timer:Input.timingBomb+1 fire:Input.fire owner:Owner)) Bombs}
                % TODO : notify players
                {TreatStream T Gui NewBombs}
            [] makeExplode then
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:Fire owner:Owner) then
                        if Timer == 0 then
                            {ExplodeBomb Gui Pos Fire}
                            % TODO : notify players
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
                {Browse 'Unsupported message'#H}
                {TreatStream T Gui Bombs}
            end
        end
    end
end