functor
import
    Input
    GUI
    PlayerManager

    System(show:Show)
    Browser(browse:Browse)
    Tuples
    Records
    Cells
export
    initialize:StartManager
define
   
    StartManager
    TreatStream

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
                {Send Gui spawnBomb(Pos)}
                NewBombs = {Tuple.append 'newBomb'('#'(pos:Pos timer:Input.timingBomb+1 fire:Input.fire owner:Owner)) Bombs}
                % TODO : notify players
                {TreatStream T Gui NewBombs}
            [] makeExplode then
                for I in 1..{Record.width Bombs} do
                    case Bombs.I 
                    of nil then skip
                    [] '#'(pos:Pos timer:Timer fire:Fire owner:Owner) then
                        if Timer == 0 then
                            {Send Gui hideBomb(Pos)}
                            {Send Gui spawnFire(Pos)}
                            % TODO : make bomb explode properly
                            local NbBombs Score ID in
                                {Send Owner add(bomb 1 NbBombs)}
                                {Send Owner add(point 1 Score)}
                                {Send Owner getId(ID)}
                                {Wait ID} {Wait Score}
                                {Send Gui scoreUpdate(ID Score)}
                            end
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
                            {Send Gui hideFire(Pos)}
                            % TODO : make fire disapear properly
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