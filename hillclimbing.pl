initial_state([1, 2, 3, 4]).

evaluate(State, Value) :-
    sum_list(State, Value).

generate_neighbor(State, Neighbor) :-
    select(X, State, Rest),
    member(Y, [1, 2, 3, 4]),
    X \= Y,
    permutation([Y|Rest], Neighbor).

hill_climb(BestState) :-
    initial_state(StartState),
    hill_climb(StartState, BestState).

hill_climb(State, BestState) :-
    evaluate(State, Value),
    write('Starting state: '), write(State), write(' | Value: '), write(Value), nl,
    hill_climb(State, Value, BestState).

hill_climb(State, Value, BestState) :-
    findall(NV-N, (generate_neighbor(State, N), evaluate(N, NV)), Pairs),
    sort(Pairs, Sorted),
    reverse(Sorted, [BestValue-BestNeighbor | _]),
    (BestValue > Value ->
        write('Better neighbor found: '), write(BestNeighbor),
        write(' | Value: '), write(BestValue), nl,
        hill_climb(BestNeighbor, BestValue, BestState)
    ;
        write('Reached local optimum at: '), write(State),
        write(' | Value: '), write(Value), nl,
        BestState = State
    ).

%?- hill_climb(Best).
