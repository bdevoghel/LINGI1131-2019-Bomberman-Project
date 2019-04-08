functor
import
    Input
    System(show:Show print:Print)
    BombManager(getPosExplosions:GetPosExplosions)
export
    initialize:StartManager
define
    StartManager
    TreatStream

    Gui
    Map
    PosPlayers
    NotificationM

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

    proc {InitMap}
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

    proc {InitPosPlayers PortBombers}
        for I in 1..Input.nbBombers do
            PosPlayers.I = player(port:PortBombers.I pos:{Cell.new pt(x:~1 y:~1)} lives:{Cell.new Input.nbLives}) % pt(x:~1 y:~1) == not on board
        end
    end

    proc {ComputeVictims Pos}
        PosExplosions
    in
        PosExplosions = {GetPosExplosions Pos Input.fire ValidFlamePosition}
        for I in 1..{Record.width PosExplosions} do 
            for PP in 1..{Record.width PosPlayers} do
                if @(PosPlayers.PP.pos).x == PosExplosions.I.x andthen @(PosPlayers.PP.pos).y == PosExplosions.I.y then 
                    ID Result NewLife 
                in
                    {Send PosPlayers.PP.port gotHit(ID Result)}
                    if Result \= null then
                        death(NewLife) = Result
                        {Send Gui lifeUpdate(ID NewLife)}
                        (PosPlayers.(ID.id).lives) := NewLife
                        {Send Gui hidePlayer(ID)}
                        {Send NotificationM deadPlayer(ID)} % notify everyone
                    else 
                        {Show 'ERROR : Result in gotHit(ID Result) == null'}
                        % TODO : what now ?
                    end
                end
            end
        end
    end

    fun {ValidFlamePosition NewPos ?ToBeContinued} % same as in BombManager but synchronous with MapManager (otherwise blocks call)
        MapValue =  @{List.nth Map {Index NewPos.x NewPos.y}}
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
    fun {StartManager GuiPort PortBombers NotificationManagerPort}
        Stream
        Port
    in
        {NewPort Stream Port}
        thread
	        {TreatStream Stream}
        end
        Gui = GuiPort
        {InitMap}
        PosPlayers = {Tuple.make '#' Input.nbBombers}
        {InitPosPlayers PortBombers}
        NotificationM = NotificationManagerPort
        %thread {DebugMap} end
        Port
    end
        
    proc {TreatStream Stream}
        case Stream of nil then skip
        [] Message|T then
            case Message of nil then skip
            [] spawnPlayer(ID Pos) then
                (PosPlayers.(ID.id).pos) := Pos
                {TreatStream T}
            [] movePlayer(ID Pos) then
                (PosPlayers.(ID.id).pos) := Pos
                {TreatStream T}
            [] deadPlayer(ID) then
                (PosPlayers.(ID.id).pos) := pt(x:~1 y:~1)
                {TreatStream T}
            [] bombExploded(Pos) then
                {ComputeVictims Pos}
                {TreatStream T}
            [] boxRemoved(Pos) then
                {List.nth Map {Index Pos.x Pos.y}} := 0
                {TreatStream T}
            [] getMapValue(X Y ?MapValue) then
                MapValue = @{List.nth Map {Index X Y}}
                {TreatStream T}
            [] getPlayerLives(ID ?NbLives) then
                NbLives = @(PosPlayers.(ID.id).lives)
                {TreatStream T}
            [] getPlayersAlive(?PlayersAlive) then PlayersNotDead = {Cell.new '#'()} in
                for I in 1..Input.nbBombers do
                    if @(PosPlayers.I.lives) > 0 then PlayerID in
                        {Send PosPlayers.I.port getId(PlayerID)}
                        {Wait PlayerID}
                        PlayersNotDead := {Tuple.append 'otherPlayer'(PlayerID) @PlayersNotDead}
                    end
                end
                PlayersAlive = @PlayersNotDead
                {TreatStream T}
            else
                % WARNING : unsupported message
                {TreatStream T}
            end
        end
    end
end