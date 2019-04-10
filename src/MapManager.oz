functor
import
    Input
    System(show:Show print:Print)
    BombManager(getPosExplosions:GetPosExplosions)

    OS(rand:Rand)
export
    initialize:StartManager
define
    StartManager
    TreatStream

    Gui
    Map
    PosPlayers
    NotificationM

    NbBoxesLeft

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
    end

    proc {InitMap}
        NbBoxesLeft = {Cell.new 0}
        Map = {List.make Input.nbRow*Input.nbColumn}
        for X in 1..Input.nbColumn do
            for Y in 1..Input.nbRow do
                {List.nth Map {Index X Y}} = {Cell.new {List.nth {List.nth Input.map Y} X}}
                if @{List.nth Map {Index X Y}} == 2 orelse @{List.nth Map {Index X Y}} == 3 then
                    NbBoxesLeft := @NbBoxesLeft + 1
                end
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
                        (PosPlayers.(ID.id).pos) := pt(x:~1 y:~1)
                    else 
                        {Show 'ERROR : result in gotHit(ID Result) == null'}
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

    proc {ExecuteMove ID Pos} Result in 
        (PosPlayers.(ID.id).pos) := Pos
        if @{List.nth Map {Index Pos.x Pos.y}} == 5 then % walks on point
            {Send Gui hidePoint(Pos)}
            {List.nth Map {Index Pos.x Pos.y}} := 0

            {Send NotificationM add(ID point 1 Result)}
            {Wait Result}
            {Send Gui scoreUpdate(ID Result)}
        elseif @{List.nth Map {Index Pos.x Pos.y}} == 6 then % walks on bonus
            {Send Gui hideBonus(Pos)}
            {List.nth Map {Index Pos.x Pos.y}} := 0

            if Input.useExtention then
                % TODO : implement extention
                if {Rand} mod 2 == 0 then                   
                    {Send NotificationM add(ID point 10 Result)}
                    {Wait Result}
                    {Send Gui scoreUpdate(ID Result)}
                else
                    {Send NotificationM add(ID bomb 1 Result)}
                end
            else
                if {Rand} mod 2 == 0 then                   
                    {Send NotificationM add(ID point 10 Result)}
                    {Wait Result}
                    {Send Gui scoreUpdate(ID Result)}
                else
                    {Send NotificationM add(ID bomb 1 Result)}
                end
            end
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
        PosPlayers = {Tuple.make '#'() Input.nbBombers}
        {InitPosPlayers PortBombers}
        NotificationM = NotificationManagerPort

        Port
    end
        
    proc {TreatStream Stream}
        case Stream of nil then skip
        [] Message|T then
            case Message of nil then skip
            [] spawnPlayer(ID Pos) then
                (PosPlayers.(ID.id).pos) := Pos
            [] movePlayer(ID Pos) then
                {ExecuteMove ID Pos}
            [] bombExploded(Pos) then
                {ComputeVictims Pos}
            [] boxRemoved(_) then
                NbBoxesLeft := @NbBoxesLeft - 1
            [] getMapValue(X Y ?MapValue) then
                MapValue = @{List.nth Map {Index X Y}}
            [] getPlayerLives(ID ?NbLives) then
                NbLives = @(PosPlayers.(ID.id).lives)
            [] getPlayersAlive(?PlayersAlive) then PlayersNotDead = {Cell.new '#'()} in
                for I in 1..Input.nbBombers do
                    if @(PosPlayers.I.lives) > 0 then PlayerID in
                        {Send PosPlayers.I.port getId(PlayerID)}
                        % {Wait PlayerID}
                        PlayersNotDead := {Tuple.append otherPlayer(PlayerID) @PlayersNotDead}
                    end
                end
                PlayersAlive = @PlayersNotDead
            [] spawnPoint(Pos) then
                {Send Gui spawnPoint(Pos)}
                {List.nth Map {Index Pos.x Pos.y}} := 5
            [] spawnBonus(Pos) then
                {Send Gui spawnBonus(Pos)}
                {List.nth Map {Index Pos.x Pos.y}} := 6
            [] getNbBoxes(?NbBoxes) then
                NbBoxes = @NbBoxesLeft
            [] debugMap then
                 thread {DebugMap} end
            end
            {TreatStream T}
        end
    end
end