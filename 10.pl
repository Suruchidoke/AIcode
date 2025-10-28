% Initial state
on(a, table).
on(b, table).
on(c, a).

% Goal state
on(a, b).
on(b, table).
on(c, table).

% Define the pickup action
pickup(Block, From, State, NewState) :-
    % Preconditions
    on(Block, From),
    clear(Block, State),
    % Effects
    remove(Block, From, State, TempState),
    assert(on(Block, agent)),
    assert(holding(Block, TempState)),
    retract(State, TempState).

% Define the putdown action
putdown(Block, To, State, NewState) :-
    % Preconditions
    holding(Block, State),
    % Effects
    remove(holding(Block, State), State, TempState),
    assert(on(Block, To)),
    assert(clear(Block, TempState)),
    retract(State, TempState).

% Helper predicate to remove a fact from the state
remove(Fact, State, NewState) :-
    select(Fact, State, NewState).

% Helper predicate to check if a block is clear
clear(Block, State) :-
    \+ on(_, Block, State).

% Depth-first search
dfs(State, Goal, _, []) :- State = Goal.
dfs(State, Goal, Visited, [Action | Plan]) :-
    move(State, Action, NewState),
    \+ member(NewState, Visited), % Avoid revisiting states
    dfs(NewState, Goal, [NewState | Visited], Plan).

% Main planning predicate
plan(Plan) :-
    initial_state(InitialState),
    goal_state(GoalState),
    dfs(InitialState, GoalState, [InitialState], Plan).

?- [blocks].
?- plan(Plan).
 
