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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%

    proc {InitMap ?Map}
        Map = {List.make Input.nbRow*Input.nbColumn}
        for X in 1..Input.nbColumn do
            for Y in 1..Input.nbRow do
                {List.nth Map {Index X Y}} = {Cell.new ({List.nth {List.nth Input.map Y} X} mod 4)} % mod 4 is for spawnFloor == floor
            end
        end
    end

    fun {Index X Y}
        X + ((Y-1) * Input.nbColumn)
    end
    fun {Pos2Index Pos} % Pos :: pt(x:X y:Y)
        Pos.x + ((Pos.y-1) * Input.nbColumn)
    end

    proc {DebugMap Map}
        M = {Cell.new Map} in 
        for Y in 1..Input.nbRow do
            for X in 1..Input.nbColumn do Val = @(@M.1) in
                if Val < 0 then {Print Val} {Print ' '}
                elseif Val > 9 then {Print ' '} {Print Val} {Print ' '}
                else {Print '  '} {Print Val} {Print '  '}
                end

                M := @M.2
            end
            {Show ' '}
        end
        {Delay 1000}
        {DebugMap Map}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc {ExecuteAction ID BomberPos Map NbBombs ?GetID ?Action}
        PossibleMoves = {GetPossibleMoves Map NbBombs BomberPos} % tuple of where the bomber could move (or bomb if current position)
        Move = {Cell.new PossibleMoves.1}
        Center = pt(x:Input.nbColumn div 2 +1 y:Input.nbRow div 2 +1)
        fun {IsMoreInMiddel Pos1 Pos2}
            {DistTo Pos1 Center} < {DistTo Pos2 Center}
        end
        fun {DistTo Pos1 Pos2}
            {Number.abs Pos1.x - Pos2.x} + {Number.abs Pos1.y - Pos2.y}
        end
    in
        % for choosing random (like Player000bomber) : .(({Rand} mod {Record.width PossibleMoves}) + 1)
        for I in 2..{Record.width PossibleMoves} do
            if {IsMoreInMiddel PossibleMoves.I @Move} then
                Move := PossibleMoves.I
            end
        end
        {DoAction @Move ID BomberPos NbBombs ?GetID ?Action}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun {GetPossibleMoves Map NbBombs BomberPos}
        Candidates
    in
        if @NbBombs > 0 then
            Candidates = {Cell.new candidates((@BomberPos))}
        else
            Candidates = {Cell.new candidates()}
        end

        for Candidate in [pt(x:(@BomberPos).x+1 y:(@BomberPos).y) pt(x:(@BomberPos).x y:(@BomberPos).y+1) pt(x:(@BomberPos).x-1 y:(@BomberPos).y) pt(x:(@BomberPos).x y:(@BomberPos).y-1)] do
            MapValue = @{List.nth Map {Pos2Index Candidate}}
        in
            if MapValue mod 10 \= 1 andthen MapValue mod 10 \= 2 andthen MapValue mod 10 \= 3 then
                Candidates := {Tuple.append '#'(Candidate) @Candidates}
            end
        end

        @Candidates
    end

    proc {DoAction Move ID BomberPos NbBombs ?GetID ?Action}
        if Move == @BomberPos andthen @NbBombs > 0 then
            Action = bomb(@BomberPos)
            NbBombs := @NbBombs - 1
        elseif Move \= @BomberPos then
            Action = move(Move)
            BomberPos := Move
        else
            {Show 'ERROR : player wants to stay on same place'#ID}
        end
        GetID = ID
    end

    %%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

in
    fun {StartPlayer GivenID}
        Stream Port OutputStream

        ID
        State
        SpawnPos
        BomberPos
        NbLives
        NbBombs
        NbPoints
        ShieldOn

        Map
        PosPlayers
    in
        thread
            OutputStream = {Projet2019util.portPlayerChecker 'Tozzi' ID Stream}
        end
        {NewPort Stream Port}
        thread
	        {TreatStream OutputStream ID State SpawnPos BomberPos NbLives NbBombs NbPoints ShieldOn Map PosPlayers}
        end

        ID = GivenID
        State = {Cell.new off}
        NbLives = {Cell.new Input.nbLives}
        NbBombs = {Cell.new Input.nbBombs}
        NbPoints = {Cell.new 0}
        BomberPos = {Cell.new _}
        ShieldOn = {Cell.new false}

        {InitMap Map}

        % thread {DebugMap Map} end

        Port
    end
   
    proc {TreatStream Stream ID State SpawnPos BomberPos NbLives NbBombs NbPoints ShieldOn Map PosPlayers}
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
                    BomberPos := SpawnPos
                    State := on
                else
                    GetID = null
                    GetPos = null
                end
            [] doaction(?GetID ?Action) then
                if @State == on then
                    {ExecuteAction ID BomberPos Map NbBombs GetID Action}
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
                [] spawnPlayer(_ _) then
                    skip % basic player doesn't care
                [] movePlayer(_ _) then
                    skip % basic player doesn't care
                [] deadPlayer(_) then
                    skip % basic player doesn't care
                [] bombPlanted(_) then
                    skip % basic player doesn't care
                [] bombExploded(_) then
                    skip % basic player doesn't care
                [] boxRemoved(Pos) then
                    {List.nth Map {Pos2Index Pos}} := 0
                else
                    {Show 'ERROR : unknown infoMessage'#H}
                end
            else
                {Show 'ERROR : unknown message'#H}
            end
            {TreatStream T ID State SpawnPos BomberPos NbLives NbBombs NbPoints ShieldOn Map PosPlayers}
        end
    end
end
