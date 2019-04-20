functor
import
    Input
    Projet2019util
    System(show:Show print:Print)
    OS(rand:Rand)
export
    portPlayer:StartPlayer
define   
    StartPlayer
    TreatStream
    Name = 'TiAmo'

    ID
    State
    SpawnPos
    Pos
    NbLives
    NbBombs
    NbPoints
    ShieldOn

    Map
    PosPlayers

    DangerMap

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%


    proc {InitMap}
        Map = {List.make Input.nbRow*Input.nbColumn}
        DangerMap = {List.make Input.nbRow*Input.nbColumn}
        for X in 1..Input.nbColumn do
            for Y in 1..Input.nbRow do
                {List.nth Map {Index X Y}} = {Cell.new ({List.nth {List.nth Input.map Y} X} mod 4)} % mod 4 is for spawnFloor == floor
                {List.nth DangerMap {Index X Y}} = {Cell.new 0}
            end
        end
    end

    fun {Index X Y}
        X + ((Y-1) * Input.nbColumn)
    end

    proc {InitPosPlayers}
        PosPlayers = {Tuple.make '#'() Input.nbBombers}
        for I in 1..Input.nbBombers do
            PosPlayers.I = player(pos:{Cell.new pt(x:~1 y:~1)} lives:{Cell.new Input.nbLives}) % pt(x:~1 y:~1) == not on board
        end
    end

    proc {ComputeDangerZone Pos}
        PosExplosions = {GetPosExplosions Pos Input.fire}
    in
        for I in 1..{Record.width PosExplosions} do %tuple des positions dangereuses
        {List.nth DangerMap {Index PosExplosions.I.x PosExplosions.I.y}}:=1
        %skip % TODO : update map
        end
    end

    fun {GetPosExplosions Pos Fire}
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

        fun {ValidFlamePosition NewPos ?ToBeContinued}
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
        {Propagate north Pos Fire}
        {Propagate east Pos Fire}
        {Propagate south Pos Fire}
        {Propagate west Pos Fire}
        @Positions
    end

    proc {DebugMap}
        M = {Cell.new Map} in 
        for Y in 1..Input.nbRow do
            for X in 1..Input.nbColumn do
                {Print @(@M.1)}
                M := @M.2
            end
            {Show ' '}
        end
        {Delay 2000}
        {DebugMap}
    end

    fun{ActionToExecute}
        if {DoMove} == true then
            PosCandidates = {MoveCandidates}
            NoDangerPos = {NoDangerZone PosCandidates}
        in
            if {Record.width NoDangerPos}>0 then
                Pos := NoDangerPos.(({Rand} mod {Record.width NoDangerPos}) + 1)
            else 
                Pos := PosCandidates.(({Rand} mod {Record.width PosCandidates}) + 1)
            
            end
            move(@Pos)
        else
            bomb(@Pos)
        end
    end

    % fun {ActionToExecute}
    %     if {DoMove} == true then
    %         PosCandidates = {MoveCandidates} % tuple of where the bomber could move
    %     in
    %         % for choosing random (like Player000bomber)
    %         Pos := PosCandidates.(({Rand} mod {Record.width PosCandidates}) + 1)

    %         % for choosing the smalest value
    %         %Pos := PosCandidates.1
    %         %for I in 2..{Record.width PosCandidates} do
    %         %    if @{List.nth Map {Index PosCandidates.I.x PosCandidates.I.y}} < @{List.nth Map {Index (@Pos).x (@Pos).y}} then
    %         %        Pos := PosCandidates.I
    %         %    end
    %         %end
    %         move(@Pos)
    %     else
    %         bomb(@Pos)
    %     end
    % end
    

    fun {DoMove}
        true
        % TODO : only moves for the moment
    end

    fun {MoveCandidates}
        Candidates = {Cell.new candidates()}
    in
        for Candidate in [pt(x:(@Pos).x+1 y:(@Pos).y) pt(x:(@Pos).x y:(@Pos).y+1) pt(x:(@Pos).x-1 y:(@Pos).y) pt(x:(@Pos).x y:(@Pos).y-1)] do
            MapValue = @{List.nth Map {Index Candidate.x Candidate.y}}
        in
            if MapValue \= 1 andthen MapValue \= 2 andthen MapValue \= 3 then
                Candidates := {Tuple.append '#'(Candidate) @Candidates}
            end
        end
        @Candidates
    end

    fun {NoDangerZone PosCandidates}
        NoDangerPos = {Cell.new noDanger()}
    in
        for I in 1..{Record.width PosCandidates} do
            DangerValue = @{List.nth DangerMap {Index PosCandidates.I.x PosCandidates.I.y}}
        in
            if DangerValue \= 1 then
                NoDangerPos := {Tuple.append '#'(PosCandidates.I) @NoDangerPos}
            end
        end
        @NoDangerPos
    end


    %%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

in
    fun {StartPlayer GivenID}
        Stream Port OutputStream
    in
        thread
            OutputStream = {Projet2019util.portPlayerChecker Name GivenID Stream}
        end
        {NewPort Stream Port}
        thread
	        {TreatStream OutputStream}
        end

        ID = GivenID
        State = {Cell.new off}
        NbLives = {Cell.new Input.nbLives}
        NbBombs = {Cell.new Input.nbBombs}
        NbPoints = {Cell.new 0}
        Pos = {Cell.new _}
        ShieldOn = {Cell.new false}

        {InitMap}
        {InitPosPlayers}

        % thread {DebugMap} end

        Port
    end
   
    proc {TreatStream Stream}
        case Stream of nil then skip
        [] H|T then
            case H of nil then skip
            [] getId(?GetID) then
                GetID = ID
            [] getState(?GetID ?GetState) then
                GetID = ID
                GetState = @State
            [] assignSpawn(Pos) then
                SpawnPos = Pos
            [] spawn(?GetID ?GetPos) then
                if @NbLives > 0 andthen @State == off then
                    GetID = ID
                    GetPos = SpawnPos
                    Pos := SpawnPos
                    State := on
                else
                    GetID = null
                    GetPos = null
                end
            [] doaction(?GetID ?Action) then
                if @State == on then
                    GetID = ID
                    Action = {ActionToExecute}
                else
                    GetID = null
                    Action = null
                end
            [] add(Type Option ?Result) then
                case Type of nil then skip
                [] bomb then
                    NbBombs := @NbBombs + Option
                    Result = @NbBombs
                [] point then
                    NbPoints := @NbPoints + Option
                    Result = @NbPoints
                [] life then
                    NbLives := @NbLives + Option
                    Result = @NbLives
                [] shield then
                    ShieldOn := true
                    Result = @ShieldOn
                end
            [] gotHit(?GetID ?Result) then
                if {Not @ShieldOn} andthen @State == on then
                    GetID = ID
                    NbLives := @NbLives - 1
                    Result = death(@NbLives)
                    State := off
                else
                    GetID = null
                    Result = null
                    ShieldOn := false
                end
            [] info(Message) then
                case Message of nil then skip
                [] spawnPlayer(ID Pos) then
                    (PosPlayers.(ID.id).pos) := Pos
                [] movePlayer(ID Pos) then
                    (PosPlayers.(ID.id).pos) := Pos
                [] deadPlayer(ID) then
                    skip
                [] bombPlanted(Pos) then
                    {ComputeDangerZone Pos}
                [] bombExploded(Pos) then
                    skip
                [] boxRemoved(Pos) then
                    {List.nth Map {Index Pos.x Pos.y}} := 0
                end
            else
                {Show H}
            end
            {TreatStream T}
        end
    end
end
