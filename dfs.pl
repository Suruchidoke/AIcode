% ----- Graph Representation -----
edge(a, b).
edge(a, c).
edge(b, d).
edge(b, e).
edge(c, f).

% ----- DFS Predicate -----
dfs(Start, End, Path) :-
    dfs_helper(Start, End, [], Path).

% Base case: Reached destination
dfs_helper(Node, Node, Visited, [Node|Visited]).

% Recursive case
dfs_helper(Current, End, Visited, Path) :-
    edge(Current, Next),
    \+ member(Next, Visited),
    dfs_helper(Next, End, [Current|Visited], Path).

% Predicate to start DFS and print result
dfs_start(Start, End) :-
    dfs(Start, End, Path),
    reverse(Path, PathReversed),
    format("DFS path from ~w to ~w: ~w", [Start, End, PathReversed]).

% ----- Query -----
% ?- dfs_start(a, f).
