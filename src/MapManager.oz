functor
import
    Input
    System(show:Show print:Print)
export
    initialize:StartManager
define
    StartManager
    TreatStream

    Map

    proc {MakeMap}
        Map = {List.make Input.nbRow*Input.nbColumn}
        for X in 1..Input.nbColumn do
            for Y in 1..Input.nbRow do
                {List.nth Map {Index X Y}} = {Cell.new {List.nth {List.nth Input.map Y} X}}
            end
        end
    end

    fun {Index X Y}
        X + ((Y-1) * Input.nbColumn)
    end
in
    fun {StartManager}
        Stream
        Port

        proc {DebugMap}
            M = {Cell.new Map} in 
            for Y in 1..Input.nbRow do
                for X in 1..Input.nbColumn do
                    {Print @(@M.1)}
                    M := @M.2
                end
                {Show ' '}
            end
            {Delay 10000}
            {DebugMap}
        end
    in
        {NewPort Stream Port}
        thread
	        {TreatStream Stream}
        end

        {MakeMap}
        %thread {DebugMap} end
        Port
    end
        
    proc {TreatStream Stream}
        case Stream of nil then skip
        [] Message|T then
            case Message of nil then skip
            [] spawnPlayer(ID Pos) then
                skip
                {TreatStream T}
            [] movePlayer(ID Pos) then
                skip
                {TreatStream T}
            [] deadPlayer(ID) then
                skip
                {TreatStream T}
            [] boxRemoved(Pos) then
                {TreatStream updatePos(Pos.x Pos.y 0)|T}
            [] getMapValue(X Y ?MapValue) then
                MapValue = @{List.nth Map {Index X Y}}
                {TreatStream T}
            [] updatePos(X Y NewMapValue) then
                {List.nth Map {Index X Y}} := NewMapValue
                {TreatStream T}
            else
                % WARNING : unsupported message
                {TreatStream T}
            end
        end
    end
end