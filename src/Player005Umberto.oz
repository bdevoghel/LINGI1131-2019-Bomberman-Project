functor
import
    Input
    Projet2019util
    System(show:Show print:Print)
    Browser(browse:Browse)
    OS(rand:Rand)
    Number(abs:Abs)
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
            %ok si simultane, sinon thinkmin/max?
                {List.nth Map {Pos2Index PosExplosions.I}} := @({List.nth Map {Pos2Index PosExplosions.I}})+100*Input.timingBomb % TODO : quid bonus ? quid info precedente ? --> gardee
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
            for X in 1..Input.nbColumn do Val = @(@M.1) in
                if Val < 0 then {Print Val} {Print ' '}
                elseif Val > 9 then {Print ' '} {Print Val} {Print ' '}
                else {Print '  '} {Print Val} {Print '  '}
                end

                M := @M.2
            end
            {Show ' '}
        end
        {Delay 2000}
        {DebugMap Map}
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    proc {ExecuteAction ID BomberPos Map NbBombs PosPlayers ?GetID ?Action}
        PossibleMoves = {GetPossibleMoves Map NbBombs BomberPos} % tuple of where the bomber could move (or bomb if current position)
    in
        % for choosing random (like Player000bomber)
        % PossibleMoves.(({Rand} mod {Record.width PossibleMoves}) + 1)
        {Show ID.id#executeAction#possibleMoves#{Record.width PossibleMoves}}

        if {Record.width PossibleMoves} < 2 then
            if {Record.width PossibleMoves} == 1 then %revenir d'ou il vient --> il peut pas rester a sa place car n'a pas de bombe
                {Show ID.id#executeAction#onlyOption}
                {DoAction PossibleMoves.1 ID BomberPos NbBombs GetID Action}
            else
                {Show 'ERROR : bomber has nowhere to move'#ID} %peut toujours revenir d'ou il vient!
            end
        else % has to choose between moves
            if {Record.width PossibleMoves} == 2 andthen @NbBombs > 0 then % go back or bomb
                {Show ID.id#executeAction#goBackOrBomb}
                {DoAction @BomberPos ID BomberPos NbBombs GetID Action} % bomb
            else
                WhatToDo in
                WhatToDo = {Best @BomberPos PossibleMoves PosPlayers Map NbBombs}
                {Show whatToDo#WhatToDo}
                {Show ID.id#executeAction#goToSafestPlace}
                {DoAction WhatToDo ID BomberPos NbBombs GetID Action} %ici choix prefere
                %{DoAction {ComputeSafestPlace BomberPos PossibleMoves Map PosPlayers} ID BomberPos NbBombs GetID Action}
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

    fun {ComputeSafestPlace BomberPos PossibleMoves Map PosPlayers}
        SafestMoves = {Cell.new safePlaces()}
    in
        for I in 1..{Record.width PossibleMoves} do
            if @{List.nth Map {Pos2Index PossibleMoves.I}} < 100 then %ici
                SafestMoves := {Tuple.append add(PossibleMoves.I) @SafestMoves}
            end
        end
        
        if {Record.width @SafestMoves} == 1 then
            {Show onlyOneSafeMove#@SafestMoves}
            (@SafestMoves).1
        elseif {Record.width @SafestMoves} > 1 then Best = {Cell.new (@SafestMoves).2} in % choseBestSafePlace
            for I in 1..{Record.width @SafestMoves} do
                if (@SafestMoves).I \= @BomberPos then
                    Best := {RandLocation Map (@SafestMoves).I @Best}
                end
            end
            
            %Best := {Best @BomberPos @SafestMoves PosPlayers Map} %rien n'est dangereux --> peut rester a son endroit et mettre une bombe
            
            {Show choseBestSafePlace#@Best}
            %{Show choseBestSafePlaceForOBJECTIVE#@Best}
            @Best
        else Best = {Cell.new PossibleMoves.1} in % choseLessDangerousPlace
            for I in 2..{Record.width PossibleMoves} do
                Best := {RandLocation Map PossibleMoves.I @Best}
            end
            {Show choseLessDangerousPlace#@Best}
            @Best
        end
    end

    fun {RandLocation Map Option1 Option2}
        if {Rand} mod 2 == 0 then
            Option1
        else
            Option2
        end
        % if @{List.nth Map {Pos2Index Option1}} > @{List.nth Map {Pos2Index Option2}} then
        %     Option1
        % else
        %     Option2
        % end
    end

    fun{Best Pos PossibleMoves PosPlayers Map NbBombs} %Pos = pos du bomber mais pas cell
        MaximumDistance = Input.fire + 1
        BestMovesForObjective = {GoNearestAll Map Pos MaximumDistance}
    in 
        {Show bestMovesForObjective#BestMovesForObjective}
        %choix de tactique ici
        %pour le moment prend pas en compte les PossibleMoves --> pris dans GoNearestAll
        %pour le moment privilegie bonus proches (-de MinimumDistance) puis points, puis...
        %est-ce qu'on veut d'abord regarder les box qui sont encore plus proche (genre juste a cote pour les faire boom?)
        %ou autre tactique?
        
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
        elseif BestMovesForObjective.boxBonus.move \= 0 then
            BestMovesForObjective.boxBonus.move                 
        elseif BestMovesForObjective.boxPoint.move \= 0 then 
            BestMovesForObjective.boxPoint.move                 
        else
            %a voir ce qu'on veut! 
            %GoPlayer = {GoNearestPlayer Pos SafestMoves PosPlayers} in %safestMove >2 --> d'office \=0?
            %if GoPlayer == 0 then {Show error#noNearestPlayer} end
            %GoPlayer 
            {ComputeSafestPlace {Cell.new Pos} PossibleMoves Map PosPlayers} %a optimiser cell.new
        end
        %return type pt(x:(@BomberPos).x+1 y:(@BomberPos).y)
    end


    % %pas testee
    % %car si on veut le mettre dans goNearestAll, pour avoir le chemin qui va avec aussi...
    % fun{GoNearestPlayer Pos SafestMoves PosPlayers} %Pos = pos de ce bomber
    %     Nearest = {Cell.new near(dist:Input.nbRow+Input.nbColumn+1 playerPos:0 move:0)}
    % in
    %     for I in 1..{Record.width SafestMoves} do
    %         for I in 1..{Record.width PosPlayers} do
    %             NewDist = {Abs (PosPlayers.I.x + PosPlayers.I.y) - (SafestMoves.I.x + SafestMoves.I.y)}
    %         in
    %             if NewDist < (@Nearest).dist andthen Pos \= SafestMoves.I then %pour pas qu'il reste au meme endroit -->bombe %??OK COMME COMPARAISON????
    %                 Nearest:= near(dist:NewDist playerPos:PosPlayers.I move:SafestMoves.I)
    %             end
    %         end
    %     end
    %     @(Nearest).move
    % end

    fun {GoNearestAll Map Pos MaximumDistance}
        InitialDist = Input.nbRow+Input.nbColumn+1
        Nearest = {Cell.new near(boxPoint:bP(dist:InitialDist pos:0 move:0) boxBonus:bB(dist:InitialDist pos:1 move:0) point:p(dist:InitialDist pos:0 move:0) bonus:b(dist:InitialDist pos:0 move:0) safePlace:sP(dist:InitialDist pos:0 move:0))} 
        proc {Propagate Dir Pos MaxDist FirstMove} %MaxDist pour pas qu'il traverse toute la map pour une box
            if MaxDist > 0 then
                NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus FoundSafePlace in
                case Dir %ATTENTION pas revenr d'ou on vient
                of north then 
                    NewPos = 'pt'(x:Pos.x y:Pos.y-1)
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus FoundSafePlace} then 
                        {Propagate north NewPos MaxDist-1 FirstMove}
                        {Propagate east NewPos MaxDist-1 FirstMove}
                        {Propagate west NewPos MaxDist-1 FirstMove}
                    end
                    if FoundSafePlace then
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                            %{Show @Nearest#north}
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#north}
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#north}
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#north}
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#north}
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
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                            %{Show @Nearest#north}
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#south}
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#south}
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#south}
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#south}
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
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                            %{Show @Nearest#north}
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#west}
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#west}
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#west}
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#west}
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
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).safePlace.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:sP(dist:NewDist pos:NewPos move:FirstMove))
                            %{Show @Nearest#north}
                        end
                    end
                    if FoundBoxPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxPoint.dist then
                            Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#east}
                        end
                    end
                    if FoundBoxBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).boxBonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#east}
                        end
                    end
                    if FoundPoint then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).point.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#east}
                        end
                    end
                    if FoundBonus then 
                        NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                        if NewDist < (@Nearest).bonus.dist then
                            Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove) safePlace:(@Nearest).safePlace)
                            %{Show @Nearest#east}
                        end
                    end
                end                
            end
        end
        fun {ValidPath NewPos ?FoundBoxPoint ?FoundBoxBonus ?FoundPoint ?FoundBonus ?FoundSafePlace}
            MapValue =  @{List.nth Map {Pos2Index NewPos}}
        in %ATTENTION SI MAP AVEC DES +100 faut ajouter des modulos 10! Oui ou bien non parce que on va pas sur les zones en danger??
            if MapValue < 10 andthen MapValue mod 10 \= 1 andthen MapValue mod 10 \= 2 andthen MapValue mod 10 \= 3 then %depends de nos valeurs 
                FoundSafePlace = true
            else
                FoundSafePlace = false
            end
            if MapValue mod 10 == 1 then % wall --> stop trying that path
                %{Show foundWall#NewPos}
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = false
                false
            elseif MapValue mod 10 == 2 then 
                %{Show foundBoxPoint#NewPos}
                FoundBoxPoint = true 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = false
                false % box -->cannot go through
            elseif MapValue mod 10 == 3 then
                %{Show foundBoxBonus#NewPos}
                FoundBoxPoint = false 
                FoundBoxBonus = true 
                FoundPoint = false
                FoundBonus = false
                false % box -->cannot go through
            elseif MapValue mod 10 == 5 then
                %{Show foundPoint#NewPos}
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = true
                FoundBonus = false
                true %--> peut continuer a marcher
            elseif MapValue mod 10 == 6 then
                %{Show foundBonus#NewPos}
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = true
                true
            else %=4 ou 0 ou 104 ou 100 ou ... = spawnPos ou floor
                FoundBoxPoint = false 
                FoundBoxBonus = false 
                FoundPoint = false
                FoundBonus = false
                true % -->continue trying
            end
        end
    in
        {Propagate north Pos MaximumDistance 'pt'(x:Pos.x y:Pos.y-1)}  %difference entre 'pt'() et pt()??
        {Propagate east Pos MaximumDistance 'pt'(x:Pos.x+1 y:Pos.y)}
        {Propagate south Pos MaximumDistance 'pt'(x:Pos.x y:Pos.y+1)}
        {Propagate west Pos MaximumDistance 'pt'(x:Pos.x-1 y:Pos.y)}
        @Nearest
        %bestmoves(boxPoint:(@Nearest).boxPoint.move boxBonus:(@Nearest).boxBonus.move point:(@Nearest).point.move bonus:(@Nearest).bonus.move)
        %Ainsi si move renvoie 0 c'est que il n'y a pas de ce qu'on cherche dans MaximumDistance+1 cases
        %il privilegie le nord puis est puis... sinon faut changer pour garder tous et choisir le pref
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

        thread {DebugMap Map} end

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
            %un nouveau tour est joue --> mettre a jour MAP : bombe timing + si bonus ou point sur meme case que joueur
                if @State == on then
                    {ExecuteAction ID BomberPos Map NbBombs PosPlayers GetID Action}
                else
                    GetID = null
                    Action = null
                end
            [] add(Type Option ?Result) then
                case Type of nil then skip
                [] bomb then
                    {List.nth Map {Pos2Index @BomberPos}} := 0 %POUR LE MOMENT MODIF QUE LES SIENS -5!!
                    NbBombs := @NbBombs + Option
                    Result = @NbBombs
                [] point then
                    {List.nth Map {Pos2Index @BomberPos}} := 0
                    NbPoints := @NbPoints + Option
                    Result = @NbPoints
                [] life then
                    {List.nth Map {Pos2Index @BomberPos}} := 0
                    NbLives := @NbLives + Option
                    Result = @NbLives
                [] shield then
                    {List.nth Map {Pos2Index @BomberPos}} := 0
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
                    {List.nth Map {Pos2Index Pos}} := @{List.nth Map {Pos2Index Pos}} - @{List.nth Map {Pos2Index Pos}} mod 10 % TODO : ne marche pas si triche !!
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
