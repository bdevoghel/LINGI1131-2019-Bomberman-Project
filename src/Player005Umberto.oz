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

    proc {InitPosPlayers PosPlayers}
        PosPlayers = {Tuple.make '#'() Input.nbBombers}
        for I in 1..Input.nbBombers do
            PosPlayers.I = player(pos:{Cell.new pt(x:~1 y:~1)} lives:{Cell.new Input.nbLives}) % pt(x:~1 y:~1) == not on board
        end
    end

    proc {ComputeDangerZone Map Pos}
        PosExplosions = {GetPosExplosions Map Pos Input.fire}
    in
        % TODO : update map properly
        for I in 1..{Record.width PosExplosions} do
            MapValue = @{List.nth Map {Pos2Index PosExplosions.I}}
        in
            if MapValue == 0 then
                {List.nth Map {Pos2Index PosExplosions.I}} := ~100 % TODO : quid bonus ? quid info precedente ?
            end
        end
    end

    fun {GetPosExplosions Map Pos Fire}
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
            MapValue =  @{List.nth Map {Pos2Index NewPos}}
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

    proc {DebugMap Map}
        M = {Cell.new Map} in 
        for Y in 1..Input.nbRow do
            for X in 1..Input.nbColumn do
                {Print @(@M.1)}
                M := @M.2
            end
            {Show ' '}
        end
        {Delay 2000}
        {DebugMap Map}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc {ExecuteAction ID BomberPos Map NbBombs ?GetID ?Action}
        PossibleMoves = {GetPossibleMoves Map NbBombs BomberPos} % tuple of where the bomber could move (or bomb if current position)
    in
        % for choosing random (like Player000bomber)
        % PossibleMoves.(({Rand} mod {Record.width PossibleMoves}) + 1)
        {Show ID.id#executeAction#possibleMoves#{Record.width PossibleMoves}}

        if {Record.width PossibleMoves} < 2 then
            if {Record.width PossibleMoves} == 1 then
                {Show ID.id#executeAction#onlyOption}
                {DoAction PossibleMoves.1 ID BomberPos NbBombs GetID Action}
            else
                {Show 'ERROR : bomber has nowhere to move'#ID}
            end
        else % has to choose between moves
            if {Record.width PossibleMoves} == 2 andthen @NbBombs > 0 then % go back or bomb
                {Show ID.id#executeAction#goBackOrBomb}
                {DoAction @BomberPos ID BomberPos NbBombs GetID Action} % bomb
            else
                {Show ID.id#executeAction#goToSafestPlace}
                {DoAction {ComputeSafestPlace BomberPos PossibleMoves Map} ID BomberPos NbBombs GetID Action}
            end
        end
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
            if MapValue \= 1 andthen MapValue \= 2 andthen MapValue \= 3 then
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

    fun {ComputeSafestPlace BomberPos PossibleMoves Map}
        SafestMoves = {Cell.new safePlaces()}
    in
        for I in 1..{Record.width PossibleMoves} do
            if @{List.nth Map {Pos2Index PossibleMoves.I}} >= 0 then
                SafestMoves := {Tuple.append add(PossibleMoves.I) @SafestMoves}
            end
        end
        
        if {Record.width @SafestMoves} == 1 then
            {Show onlyOneSafeMove#@SafestMoves}
            (@SafestMoves).1
        elseif {Record.width @SafestMoves} > 1 then Best = {Cell.new (@SafestMoves).2} in % choseBestSafePlace
            for I in 1..{Record.width @SafestMoves} do
                if (@SafestMoves).I \= @BomberPos then
                    Best := {BestLocation Map (@SafestMoves).I @Best}
                end
            end
            {Show choseBestSafePlace#@Best}
            @Best
        else Best = {Cell.new PossibleMoves.1} in % choseLessDangerousPlace
            for I in 2..{Record.width PossibleMoves} do
                Best := {BestLocation Map PossibleMoves.I @Best}
            end
            {Show choseLessDangerousPlace#@Best}
            @Best
        end
    end

    fun {BestLocation Map Option1 Option2}
        if @{List.nth Map {Pos2Index Option1}} > @{List.nth Map {Pos2Index Option2}} then
            Option1
        else
            Option2
        end
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
            OutputStream = {Projet2019util.portPlayerChecker 'UmbertoTozzi' ID Stream}
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
        {InitPosPlayers PosPlayers}

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
                [] spawnPlayer(ID Pos) then
                    (PosPlayers.(ID.id).pos) := Pos
                [] movePlayer(ID Pos) then
                    (PosPlayers.(ID.id).pos) := Pos
                [] deadPlayer(ID) then
                    (PosPlayers.(ID.id).pos) := pt(x:~1 y:~1)
                [] bombPlanted(Pos) then
                    {ComputeDangerZone Map Pos}
                [] bombExploded(Pos) then
                    {Show 'Bomb exploded at'#Pos#'(information to treat)'}
                    skip % TODO : bombExploded
                [] boxRemoved(Pos) then MapValue = @{List.nth Map {Pos2Index Pos}} in
                    if MapValue == 2 then % box with point
                        {List.nth Map {Pos2Index Pos}} := 5
                    elseif MapValue == 3 then % box with bonus
                        {List.nth Map {Pos2Index Pos}} := 6
                    else
                        {Show 'ERROR : box removed where no box was'#Pos}
                    end
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
