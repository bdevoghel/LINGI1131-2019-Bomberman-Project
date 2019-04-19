declare
fun{Best Pos SafestMoves PosPlayers Map} %Pos = pos du bomber mais pas cell
    BestMovesForObjective = {GoNearestAll Map Pos} in 
    %choix de tactique ici
    %pour le moment prend pas en compte les SafestMoves
    %pour le moment privilegie bonus proches (-de MinimumDistance) puis points, puis...
    %est-ce qu'on veut d'abord regarder les box qui sont encore plus proche (genre juste a cote pour les faire boom?)
    %ou autre tactique?
    if BestMovesForObjective.bonus.move \= 0 then 
        BestMovesForObjective.bonus.move
    elseif BestMovesForObjective.point.move \= 0 then 
        BestMovesForObjective.point.move
    elseif BestMovesForObjective.boxBonus.move \= 0 then 
        BestMovesForObjective.boxBonus.move
    elseif BestMovesForObjective.boxPoint.move \= 0 then 
        BestMovesForObjective.boxPoint.move
    else
        GoPlayer = {GoNearestPlayer Pos SafestMoves PosPlayers} in %safestMove >2 --> d'office \=0?
        if GoPlayer == 0 then {Show error#noNearestPlayer} end
        GoPlayer 
    end
end

% fun{BestForObjective Objective Pos SafestMoves PosPlayers Map}
%     case Objective
%     of goNearestPlayer then {GoNearestPlayer Pos SafestMoves PosPlayers}
%     [] goNearestBoxPoint then 
%         BestMovesForObjective = {GoNearestAll Map Pos} in
%         BestMovesForObjective.boxPoint
%     [] goNearestBoxBonus then 
%         BestMovesForObjective = {GoNearestAll Map Pos} in
%         BestMovesForObjective.boxBonus
%     [] goNearestPoint then
%         BestMovesForObjective = {GoNearestAll Map Pos} in
%         BestMovesForObjective.point
%     [] goNearestBonus then
%         BestMovesForObjective = {GoNearestAll Map Pos} in
%         BestMovesForObjective.bonus
%     end
% end
declare
fun{GoNearestPlayer Pos SafestMoves PosPlayers} %Pos = pos de ce bomber
    Nearest = {Cell.new near(dist:NbRow+NbColumn+1 playerPos:0 move:0)}
in
    for I in 1..{Record.width SafestMoves} do
        for I in 1..{Record.width PosPlayers} do
            NewDist = {Abs (PosPlayers.I.x + PosPlayers.I.y) - (SafestMoves.I.x + SafestMoves.I.y)}
        in
            if NewDist < (@Nearest).dist andthen Pos \= SafestMoves.I then %pour pas qu'il reste au meme endroit -->bombe %??OK COMME COMPARAISON????
                Nearest:= near(dist:NewDist playerPos:PosPlayers.I move:SafestMoves.I)
            end
        end
    end
    @(Nearest).move
end

declare
fun {GoNearestAll Map Pos}
    InitialDist = NbRow+NbColumn+1
    Nearest = {Cell.new near(boxPoint:bP(dist:InitialDist pos:0 move:0) boxBonus:bB(dist:InitialDist pos:1 move:0) point:p(dist:InitialDist pos:0 move:0) bonus:b(dist:InitialDist pos:0 move:0))}
    MaximumDistance = 4 %a nous de definir MaxDist!! 
    proc {Propagate Dir Pos MaxDist FirstMove} %MaxDist pour pas qu'il traverse toute la map pour une box
        if MaxDist > 0 then
            NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus in
            case Dir %ATTENTION pas revenr d'ou on vient
            of north then 
                NewPos = 'pt'(x:Pos.x y:Pos.y-1)
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus} then 
                    {Propagate north NewPos MaxDist-1 FirstMove}
                    {Propagate east NewPos MaxDist-1 FirstMove}
                    {Propagate west NewPos MaxDist-1 FirstMove}
                end
                if FoundBoxPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxPoint.dist then
                        Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#north}
                    end
                end
                if FoundBoxBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxBonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#north}
                    end
                end
                if FoundPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).point.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus)
                        {Show @Nearest#north}
                    end
                end
                if FoundBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).bonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove))
                        {Show @Nearest#north}
                    end
                end
            [] south then
                NewPos = 'pt'(x:Pos.x y:Pos.y+1) 
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus} then 
                    {Propagate east NewPos MaxDist-1 FirstMove}
                    {Propagate south NewPos MaxDist-1 FirstMove}
                    {Propagate west NewPos MaxDist-1 FirstMove}
                end
                if FoundBoxPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxPoint.dist then
                        Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#south}
                    end
                end
                if FoundBoxBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxBonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#south}
                    end
                end
                if FoundPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).point.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus)
                        {Show @Nearest#south}
                    end
                end
                if FoundBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).bonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove))
                        {Show @Nearest#south}
                    end
                end
            [] west then
                NewPos = 'pt'(x:Pos.x-1 y:Pos.y)
                    if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus} then 
                    {Propagate north NewPos MaxDist-1 FirstMove}
                    {Propagate south NewPos MaxDist-1 FirstMove}
                    {Propagate west NewPos MaxDist-1 FirstMove}
                end
                if FoundBoxPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxPoint.dist then
                        Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#west}
                    end
                end
                if FoundBoxBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxBonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#west}
                    end
                end
                if FoundPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).point.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus)
                        {Show @Nearest#west}
                    end
                end
                if FoundBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).bonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove))
                        {Show @Nearest#west}
                    end
                end
            [] east then 
                NewPos = 'pt'(x:Pos.x+1 y:Pos.y)
                if {ValidPath NewPos FoundBoxPoint FoundBoxBonus FoundPoint FoundBonus} then 
                    {Propagate north NewPos MaxDist-1 FirstMove}
                    {Propagate east NewPos MaxDist-1 FirstMove}
                    {Propagate south NewPos MaxDist-1 FirstMove}
                end
                if FoundBoxPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxPoint.dist then
                        Nearest:= near(boxPoint:bP(dist:NewDist pos:NewPos move:FirstMove) boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#east}
                    end
                end
                if FoundBoxBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).boxBonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:bB(dist:NewDist pos:NewPos move:FirstMove) point:(@Nearest).point bonus:(@Nearest).bonus)
                        {Show @Nearest#east}
                    end
                end
                if FoundPoint then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).point.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:p(dist:NewDist pos:NewPos move:FirstMove) bonus:(@Nearest).bonus)
                        {Show @Nearest#east}
                    end
                end
                if FoundBonus then 
                    NewDist = MaximumDistance + 1 - MaxDist in %distance a parcourir (en nbr cases) jusque box
                    if NewDist < (@Nearest).bonus.dist then
                        Nearest:= near(boxPoint:(@Nearest).boxPoint boxBonus:(@Nearest).boxBonus point:(@Nearest).point bonus:b(dist:NewDist pos:NewPos move:FirstMove))
                        {Show @Nearest#east}
                    end
                end
            end                
        end
    end
    fun {ValidPath NewPos ?FoundBoxPoint ?FoundBoxBonus ?FoundPoint ?FoundBonus}
        MapValue =  @{List.nth Map {Pos2Index NewPos}}
    in %ATTENTION SI MAP AVEC DES +100 faut ajouter des modulos 10!
        if MapValue == 1 then % wall --> stop trying that path
            {Show foundWall#NewPos}
            FoundBoxPoint = false 
            FoundBoxBonus = false 
            FoundPoint = false
            FoundBonus = false
            false
        elseif MapValue == 2 then 
            {Show foundBoxPoint#NewPos}
            FoundBoxPoint = true 
            FoundBoxBonus = false 
            FoundPoint = false
            FoundBonus = false
            false % box -->cannot go through
        elseif MapValue == 3 then
            {Show foundBoxBonus#NewPos}
            FoundBoxPoint = false 
            FoundBoxBonus = true 
            FoundPoint = false
            FoundBonus = false
            false % box -->cannot go through
        elseif MapValue == 5 then
            {Show foundPoint#NewPos}
            FoundBoxPoint = false 
            FoundBoxBonus = false 
            FoundPoint = true
            FoundBonus = false
            true %--> peut continuer a marcher
        elseif MapValue == 6 then
            {Show foundBonus#NewPos}
            FoundBoxPoint = false 
            FoundBoxBonus = false 
            FoundPoint = false
            FoundBonus = true
            true
        else %=4 ou 0 = spawnPos ou floor
            FoundBoxPoint = false 
            FoundBoxBonus = false 
            FoundPoint = false
            FoundBonus = false
            true % -->continue trying
        end
    end
in
    {Propagate north Pos MaximumDistance north} 
    {Propagate east Pos MaximumDistance east}
    {Propagate south Pos MaximumDistance south}
    {Propagate west Pos MaximumDistance west}
    @Nearest
    %bestmoves(boxPoint:(@Nearest).boxPoint.move boxBonus:(@Nearest).boxBonus.move point:(@Nearest).point.move bonus:(@Nearest).bonus.move)
    %Ainsi si ca renvoie 0 c'est que il n'y a pas de ce qu'on cherche dans MaximumDistance+1 cases
    %il privilegie le nord puis est puis... sinon faut changer pour garder tous et choisir le pref
end

declare
NbRow = 7
NbColumn = 13
InputMap =  [[1 1 1 1 1 1 1 1 1 1 1 1 1]
            [1 4 0 2 0 0 0 0 2 2 3 6 1]
            [1 0 1 0 1 0 1 0 1 0 1 5 1]
            [1 3 2 0 0 0 0 0 0 2 3 0 1]
            [1 0 1 0 1 0 1 0 1 0 1 2 1]
            [1 4 0 3 0 0 0 0 0 0 0 4 1]
            [1 1 1 1 1 1 1 1 1 1 1 1 1]]
proc {InitMap ?Map}
    Map = {List.make NbRow*NbColumn}
    for X in 1..NbColumn do
        for Y in 1..NbRow do
            {List.nth Map {Index X Y}} = {Cell.new {List.nth {List.nth InputMap Y} X}} % mod 4 is for spawnFloor == floor
        end
    end
end
fun {Index X Y}
        X + ((Y-1) * NbColumn)
end
fun {Pos2Index Pos} % Pos :: pt(x:X y:Y)
    Pos.x + ((Pos.y-1) * NbColumn)
end

declare
Pos = pt(x:12 y:4)
SafestMoves = null
PosPlayers = null

Map
FoundBoxPoint
FoundBoxBonus
FoundPoint
FoundBonus

{InitMap Map}

{Browse @({List.nth Map {Index 2 4}})} %X = la colonne Y = la ligne

declare
Pos = pt(x:12 y:4)
{Browse {GoNearestAll Map Pos}}
%{ValidPath NewPos ?FoundBoxPoint ?FoundBoxBonus ?FoundPoint ?FoundBonus}

{Browse {Best Pos SafestMoves PosPlayers Map}}