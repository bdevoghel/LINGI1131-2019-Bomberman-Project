functor
%import
export
    initialize:StartManager
define
    StartManager
    TreatStream

    Gui
    Players
    MapM

    proc {SendInfoToPlayers Message}
        for P in 1..{Record.width Players} do
            {Send Players.P info(Message)}
        end
    end
in
    fun {StartManager GuiPort PortBombers MapManagerPort}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
	        {TreatStream Stream}
        end
        Gui = GuiPort
        Players = PortBombers
        MapM = MapManagerPort
        Port
    end
        
    proc {TreatStream Stream}
        case Stream of nil then skip
        [] Message|T then
            case Message of nil then skip
            [] spawnPlayer(ID Pos) then
                {SendInfoToPlayers spawnPlayer(ID Pos)}
                {Send MapM spawnPlayer(ID Pos)}
                {TreatStream T}
            [] movePlayer(ID Pos) then
                {SendInfoToPlayers movePlayer(ID Pos)}
                {Send MapM movePlayer(ID Pos)}
                {TreatStream T}
            [] deadPlayer(ID) then
                {SendInfoToPlayers deadPlayer(ID)}
                {Send MapM deadPlayer(ID)}
                {TreatStream T}
            [] bombPlanted(Pos) then
                {SendInfoToPlayers bombPlanted(Pos)}
                {TreatStream T}
            [] bombExploded(Pos) then
                {SendInfoToPlayers bombExploded(Pos)}
                {Send MapM bombExploded(Pos)}
                {TreatStream T}
            [] boxRemoved(Pos) then
                {SendInfoToPlayers boxRemoved(Pos)}
                {Send MapM boxRemoved(Pos)}
                {TreatStream T}
            else
                % WARNING : unsupported message
                {TreatStream T}
            end
        end
    end
end