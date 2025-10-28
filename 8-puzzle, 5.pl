/* ===========================
   PROBLEM-SPECIFIC PART
   =========================== */

% ----- Move operations -----
move(S, Snew) :- right(S, Snew).
move(S, Snew) :- left(S, Snew).
move(S, Snew) :- up(S, Snew).
move(S, Snew) :- down(S, Snew).

/* ---------- Move Right ---------- */
right([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew) :-
    R3 > 0, R6 > 0, R9 > 0,
    blank_right([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew).

blank_right(State, S) :-
    nth0(N, State, 0),
    Z is N + 1,
    nth0(Z, State, R),
    substitute(R, State, 10, Q),
    substitute(0, Q, R, V),
    substitute(10, V, 0, S).

/* ---------- Move Left ---------- */
left([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew) :-
    R1 > 0, R4 > 0, R7 > 0,
    blank_left([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew).

blank_left(State, S) :-
    nth0(N, State, 0),
    Z is N - 1,
    nth0(Z, State, R),
    substitute(R, State, 10, Q),
    substitute(0, Q, R, V),
    substitute(10, V, 0, S).

/* ---------- Move Down ---------- */
down([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew) :-
    R7 > 0, R8 > 0, R9 > 0,
    blank_down([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew).

blank_down(State, S) :-
    nth0(N, State, 0),
    Z is N + 3,
    nth0(Z, State, R),
    substitute(R, State, 10, Q),
    substitute(0, Q, R, V),
    substitute(10, V, 0, S).

/* ---------- Move Up ---------- */
up([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew) :-
    R1 > 0, R2 > 0, R3 > 0,
    blank_up([R1,R2,R3,R4,R5,R6,R7,R8,R9], Snew).

blank_up(State, S) :-
    nth0(N, State, 0),
    Z is N - 3,
    nth0(Z, State, R),
    substitute(R, State, 10, Q),
    substitute(0, Q, R, V),
    substitute(10, V, 0, S).

/* ---------- Substitute Helper ---------- */
% substitute(X, List, Y, Result)
% Swaps all occurrences of X with Y and vice versa in List.
substitute(_, [], _, []) :- !.
substitute(X, [X|T], Y, [Y|T1]) :- substitute(X, T, Y, T1), !.
substitute(X, [Y|T], Y, [X|T1]) :- substitute(X, T, Y, T1), !.
substitute(X, [H|T], Y, [H|T1]) :- substitute(X, T, Y, T1).



/* ===========================
   GENERAL A* SEARCH ALGORITHM
   =========================== */

% ----- Main entry point -----
go(Start, Goal) :-
    getHeuristic(Start, H, Goal),
    path([[Start, null, 0, H, H]], [], Goal).   % [State, Parent, PathCost, Heuristic, TotalCost]


% ----- Path Expansion -----
path([], _, _) :-
    write('No solution found.'), nl, !.

path(Open, Closed, Goal) :-
    getBestChild(Open, [Goal, Parent, PC, H, TC], _),
    write('✅ Solution found!'), nl,
    printsolution([Goal, Parent, PC, H, TC], Closed), !.

path(Open, Closed, Goal) :-
    getBestChild(Open, [State, Parent, PC, H, TC], RestOpen),
    getchildren(State, Open, Closed, Children, PC, Goal),
    addListToOpen(Children, RestOpen, NewOpen),
    path(NewOpen, [[State, Parent, PC, H, TC] | Closed], Goal).


% ----- Generate Children -----
getchildren(State, Open, Closed, Children, PC, Goal) :-
    bagof(X, moves(State, Open, Closed, X, PC, Goal), Children), !.
getchildren(_, _, _, [], _, _).


% ----- Add new states to Open List -----
addListToOpen(Children, [], Children).
addListToOpen(Children, [H|Open], [H|NewOpen]) :-
    addListToOpen(Children, Open, NewOpen).


% ----- Get Best (Lowest TC) Node -----
getBestChild([Child], Child, []).
getBestChild(Open, Best, RestOpen) :-
    getBestChild1(Open, Best),
    removeFromList(Best, Open, RestOpen).

getBestChild1([State], State).
getBestChild1([State|Rest], Best) :-
    getBestChild1(Rest, Temp),
    getBest(State, Temp, Best).

getBest([S, P, PC, H, TC], [_, _, _, _, TC1], [S, P, PC, H, TC]) :-
    TC < TC1, !.
getBest(_, [S1, P1, PC1, H1, TC1], [S1, P1, PC1, H1, TC1]).


% ----- Remove node from list -----
removeFromList(_, [], []).
removeFromList(H, [H|T], V) :- !, removeFromList(H, T, V).
removeFromList(H, [H1|T], [H1|T1]) :- removeFromList(H, T, T1).


% ----- Generate valid moves -----
moves(State, Open, Closed, [Next, State, NPC, H, TC], PC, Goal) :-
    move(State, Next),
    \+ member([Next, _, _, _, _], Open),
    \+ member([Next, _, _, _, _], Closed),
    NPC is PC + 1,
    getHeuristic(Next, H, Goal),
    TC is NPC + H.


/* ---------- Heuristic Function ---------- */
% Number of misplaced tiles
getHeuristic([], 0, []) :- !.
getHeuristic([H|T1], V, [H|T2]) :- !, getHeuristic(T1, V, T2).
getHeuristic([_|T1], H, [_|T2]) :-
    getHeuristic(T1, TH, T2),
    H is TH + 1.


/* ---------- Print Solution Path ---------- */
printsolution([State, null, PC, H, TC], _) :-
    write(State), write('  PC:'), write(PC),
    write('  H:'), write(H), write('  TC:'), write(TC), nl.

printsolution([State, Parent, PC, H, TC], Closed) :-
    member([Parent, GrandParent, PC1, H1, TC1], Closed),
    printsolution([Parent, GrandParent, PC1, H1, TC1], Closed),
    write(State), write('  PC:'), write(PC),
    write('  H:'), write(H), write('  TC:'), write(TC), nl.


?- go([1,2,3,4,0,6,7,5,8],[1,2,3,4,5,6,7,8,0]).
