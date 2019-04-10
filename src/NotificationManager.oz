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

    proc {SendToPlayers Message}
        for P in 1..{Record.width Players} do
            {Send Players.P Message}
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
                {SendToPlayers info(spawnPlayer(ID Pos))}
                {Send MapM spawnPlayer(ID Pos)}
            [] movePlayer(ID Pos) then
                {SendToPlayers info(movePlayer(ID Pos))}
                {Send MapM movePlayer(ID Pos)}
            [] deadPlayer(ID) then
                {SendToPlayers info(deadPlayer(ID))}
            [] bombPlanted(Pos) then
                {SendToPlayers info(bombPlanted(Pos))}
            [] bombExploded(Pos) then
                {SendToPlayers info(bombExploded(Pos))}
                {Send MapM bombExploded(Pos)}
            [] boxRemoved(Pos) then
                {SendToPlayers info(boxRemoved(Pos))}
                {Send MapM boxRemoved(_)}
            [] spawnPoint(Pos) then
                {Send MapM spawnPoint(Pos)}
            [] spawnBonus(Pos) then
                {Send MapM spawnBonus(Pos)}
            [] add(ID Type Option ?Result) then
                {Send Players.(ID.id) add(Type Option Result)}
            end
            {TreatStream T}
        end
    end
end