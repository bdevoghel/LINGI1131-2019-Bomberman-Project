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
        for I in 1..{Record.width PosExplosions} do
            MapValue = @{List.nth Map {Pos2Index PosExplosions.I}}
        in
            {List.nth Map {Pos2Index PosExplosions.I}} := MapValue + 100*Input.timingBomb
        end
    end
    proc {ComputeNoDangerZone Map Pos}
        PosExplosions = {GetPosExplosions Map Pos Input.fire}
    in
        for I in 1..{Record.width PosExplosions} do
            MapValue = @{List.nth Map {Pos2Index PosExplosions.I}}
        in
            if MapValue >= 100 then
                {List.nth Map {Pos2Index PosExplosions.I}} := MapValue - 100*Input.timingBomb
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
            if MapValue mod 10 == 1 then % wall
                ToBeContinued = false
                false
            elseif MapValue == 2 orelse MapValue == 3 then % box %pas de modulo car plusieurs bombes vont plus loin
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

    proc {ExecuteAction ID BomberPos Map NbBombs PosPlayers ?GetID ?Action}
        PossibleMoves = {GetPossibleMoves Map NbBombs BomberPos} % tuple of where the bomber could move (or bomb if current position)
    in
        if {Record.width PossibleMoves} < 2 then
            if {Record.width PossibleMoves} == 1 then %revenir d'ou il vient --> il peut pas rester a sa place car n'a pas de bombe
                {DoAction PossibleMoves.1 ID BomberPos NbBombs GetID Action}
            else
                {Show 'ERROR : bomber has nowhere to move'#ID} %normalement il peut toujours revenir d'ou il vient!
            end
        else % has to choose between moves
            WhatToDo in
            WhatToDo = {Best @BomberPos PossibleMoves PosPlayers Map NbBombs}
            %{Show whatToDo#WhatToDo}
            {DoAction WhatToDo ID BomberPos NbBombs GetID Action} %ici choix prefere
            % if {Record.width PossibleMoves} == 2 andthen @NbBombs > 0 then % go back or bomb
            %     {Show ID.id#executeAction#goBackOrBomb}
            %     {DoAction @BomberPos ID BomberPos NbBombs GetID Action} % bomb
            % else
            %     WhatToDo in
            %     WhatToDo = {Best @BomberPos PossibleMoves PosPlayers Map NbBombs}
            %     {Show whatToDo#WhatToDo}
            %     {Show ID.id#executeAction#goToSafestPlace}
            %     {DoAction WhatToDo ID BomberPos NbBombs GetID Action} %ici choix prefere
            %     %{DoAction {ComputeSafestPlace BomberPos PossibleMoves Map PosPlayers} ID BomberPos NbBombs GetID Action}
            % end
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

    fun {SafestPlaceOrRandom PossibleMoves Map}
        SafestMoves = {Cell.new safePlaces()}
    in
        for I in 1..{Record.width PossibleMoves} do
            if @{List.nth Map {Pos2Index PossibleMoves.I}} < 100 then 
                SafestMoves := {Tuple.append add(PossibleMoves.I) @SafestMoves}
            end
        end
        
        if {Record.width @SafestMoves} == 1 then (@SafestMoves).1
        elseif {Record.width @SafestMoves} > 1 then % Random between safe places
            (@SafestMoves).(({Rand} mod {Record.width @SafestMoves}) + 1)
        else % choseLessDangerousPlace
            (@PossibleMoves).(({Rand} mod {Record.width @PossibleMoves}) + 1)
        end
    end

    fun{Best Pos PossibleMoves PosPlayers Map NbBombs}
        MaximumDistance = 2*Input.fire
        BestMovesForObjective
    in
        if @{List.nth Map {Pos2Index Pos}} > 100 then 
            BestMovesForObjective = {GoNearestAll Map Pos MaximumDistance PossibleMoves false} %AvoidDanger = false --> voir meilleur chemin meme si danger
        else BestMovesForObjective = {GoNearestAll Map Pos MaximumDistance PossibleMoves true} %AvoidDanger = true --> evite toute possibilite de danger
        end
        %{Show bestMovesForObjective#BestMovesForObjective}
        %1) : safePlace
        %2) : si dist==1 d'une box --> boom
        %3) : bonus puis point puis boxbonus puis boxpoint

        if @{List.nth Map {Pos2Index Pos}} > 100 andthen BestMovesForObjective.safePlace.move \= 0 then %danger --> 1) safePlace
            BestMovesForObjective.safePlace.move
        elseif BestMovesForObjective.boxBonus.dist == 1 andthen @NbBombs > 0 then Pos % 2) BOOM
        elseif BestMovesForObjective.boxPoint.dist == 1 andthen @NbBombs > 0 then Pos
        elseif BestMovesForObjective.bonus.move \= 0 then 
            BestMovesForObjective.bonus.move
        elseif BestMovesForObjective.point.move \= 0 then 
            BestMovesForObjective.point.move
        elseif BestMovesForObjective.boxBonus.move \= 0 andthen BestMovesForObjective.boxBonus.dist \= 1 then
            BestMovesForObjective.boxBonus.move                 
        elseif BestMovesForObjective.boxPoint.move \= 0 andthen BestMovesForObjective.boxPoint.dist \= 1 then
            BestMovesForObjective.boxPoint.move                 
        else
            {SafestPlaceOrRandom PossibleMoves Map}
        end
    end

    fun {GoNearestAll Map Pos MaximumDistance PossibleMoves AvoidDanger}
        InitialDist = Input.nbRow+Input.nbColumn+1
        Nearest = {Cell.new near(boxPoint:bP(dist:InitialDist pos:0 move:0) boxBonus:bB(dist:InitialDist pos:1 move:0) point:p(dist:InitialDist pos:0 move:0) bonus:b(dist:InitialDist pos:0 move:0) safePlace:sP(dist:InitialDist pos:0 move:0))} 
        
        proc {Propagate Dir Pos MaxDist FirstMove} %MaxDist pour pas qu'il traverse toute la map pour une box
            if MaxDist > 0 then
                NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus FoundSafePlace in
                case Dir %Pour ne pas revenr d'ou on vient
                of north then 
                    NewPos = 'pt'(x:Pos.x y:Pos.y-1)
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus FoundSafePlace} then 
                        {Propagate north NewPos MaxDist-1 FirstMove}
                        {Propagate east NewPos MaxDist-1 FirstMove}
                        {Propagate west NewPos MaxDist-1 FirstMove}
                    end
                    if FoundSafePlace then
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases)
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in  
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                        end
                    end
                [] south then
                    NewPos = 'pt'(x:Pos.x y:Pos.y+1) 
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus FoundSafePlace} then 
                        {Propagate east NewPos MaxDist-1 FirstMove}
                        {Propagate south NewPos MaxDist-1 FirstMove}
                        {Propagate west NewPos MaxDist-1 FirstMove}
                    end
                    if FoundSafePlace then
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                        end
                    end
                [] west then
                    NewPos = 'pt'(x:Pos.x-1 y:Pos.y)
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus FoundSafePlace} then 
                        {Propagate north NewPos MaxDist-1 FirstMove}
                        {Propagate south NewPos MaxDist-1 FirstMove}
                        {Propagate west NewPos MaxDist-1 FirstMove}
                    end
                    if FoundSafePlace then
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in 
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in 
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                        end
                    end
                [] east then 
                    NewPos = 'pt'(x:Pos.x+1 y:Pos.y)
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus FoundSafePlace} then 
                        {Propagate north NewPos MaxDist-1 FirstMove}
                        {Propagate east NewPos MaxDist-1 FirstMove}
                        {Propagate south NewPos MaxDist-1 FirstMove}
                    end
                    if FoundSafePlace then
                        NewDist = MaximumDistance + 1 - MaxDist in 
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in 
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in 
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in 
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in 
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                        end
                    end
                end                
            end
        end
        fun {ValidPath NewPos ?FoundBoxPoint ?FoundBoxBonus ?FoundPoint ?FoundBonus ?FoundSafePlace}
            MapValue =  @{List.nth Map {Pos2Index NewPos}}
        in
            if MapValue < 10 andthen MapValue mod 10 \= 1 andthen MapValue mod 10 \= 2 andthen MapValue mod 10 \= 3 then %depends de nos valeurs 
                FoundSafePlace = true
            else
                FoundSafePlace = false
            end
            if MapValue mod 10 == 1 then 
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = false
                false % wall --> stop trying that path
            elseif MapValue mod 10 == 2 then 
                FoundBoxPoint = true 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = false
                false % box -->cannot go through
            elseif MapValue mod 10 == 3 then
                FoundBoxPoint = false 
                FoundBoxBonus = true 
                FoundPoint = false
                FoundBonus = false
                false % box -->cannot go through
            elseif MapValue mod 10 == 5 then
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = true
                FoundBonus = false
                true %--> peut continuer a marcher
            elseif MapValue mod 10 == 6 then
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = true
                true
            else
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = false
                true % -->continue trying
            end
        end
        MapValueNorth = @{List.nth Map {Pos2Index 'pt'(x:Pos.x y:Pos.y-1)}}
        MapValueEast = @{List.nth Map {Pos2Index 'pt'(x:Pos.x+1 y:Pos.y)}}
        MapValueSouth = @{List.nth Map {Pos2Index 'pt'(x:Pos.x y:Pos.y+1)}}
        MapValueWest = @{List.nth Map {Pos2Index 'pt'(x:Pos.x-1 y:Pos.y)}}
    in
        %on se propage si pas de danger ou si une box (car si box en danger on s'en fout et doit venir dans le compte pour la boomer) 
        if AvoidDanger == true then 
            if MapValueNorth < 100 orelse MapValueNorth mod 10 == 3 orelse MapValueNorth mod 10 == 2 then {Propagate north Pos MaximumDistance 'pt'(x:Pos.x y:Pos.y-1)} end
            if MapValueEast < 100 orelse MapValueEast mod 10 == 3 orelse MapValueEast mod 10 == 2 then {Propagate east Pos MaximumDistance 'pt'(x:Pos.x+1 y:Pos.y)} end
            if MapValueSouth < 100 orelse MapValueSouth mod 10 == 3 orelse MapValueSouth mod 10 == 2 then {Propagate south Pos MaximumDistance 'pt'(x:Pos.x y:Pos.y+1)} end
            if MapValueWest < 100 orelse MapValueWest mod 10 == 3 orelse MapValueWest mod 10 == 2 then {Propagate west Pos MaximumDistance 'pt'(x:Pos.x-1 y:Pos.y)} end
        else 
            {Propagate north Pos MaximumDistance 'pt'(x:Pos.x y:Pos.y-1)}
            {Propagate east Pos MaximumDistance 'pt'(x:Pos.x+1 y:Pos.y)}
            {Propagate south Pos MaximumDistance 'pt'(x:Pos.x y:Pos.y+1)}
            {Propagate west Pos MaximumDistance 'pt'(x:Pos.x-1 y:Pos.y)}
        end
        @Nearest
        %Ainsi si @Nearest.*.move == 0 c'est que il n'y a pas de ce qu'on cherche dans MaximumDistance cases
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
            OutputStream = {Projet2019util.portPlayerChecker 'Umberto' ID Stream}
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

        %thread {DebugMap Map} end

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
                    {ExecuteAction ID BomberPos Map NbBombs PosPlayers GetID Action}
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
                [] spawnPlayer(ID Pos) then % TODO : tant que pas d'extension ok 
                    (PosPlayers.(ID.id).pos) := Pos
                [] movePlayer(ID Pos) then 
                    MapValue = @{List.nth Map {Pos2Index Pos}} in
                    if MapValue mod 10 == 5 then % point
                        {List.nth Map {Pos2Index Pos}} := MapValue - 5
                    elseif MapValue mod 10 == 6 then % bonus
                        {List.nth Map {Pos2Index Pos}} := MapValue - 6
                    end
                    (PosPlayers.(ID.id).pos) := Pos
                [] deadPlayer(ID) then
                    (PosPlayers.(ID.id).pos) := pt(x:~1 y:~1)
                [] bombPlanted(Pos) then
                    {ComputeDangerZone Map Pos}
                [] bombExploded(Pos) then
                    {ComputeNoDangerZone Map Pos}
                [] boxRemoved(Pos) then MapValue = @{List.nth Map {Pos2Index Pos}} in
                    if MapValue mod 10 == 2 then % box with point
                        {List.nth Map {Pos2Index Pos}} := MapValue + 3
                    elseif MapValue mod 10 == 3 then % box with bonus
                        {List.nth Map {Pos2Index Pos}} := MapValue + 3
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
