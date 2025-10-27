% Sample graph represented by facts.
edge(a, b).
edge(a, c).
edge(b, d).
edge(b, e).
edge(c, f).
edge(c, g).
edge(d, h).
edge(d, i).

% BFS predicate
bfs(Start, Goal) :-
    bfs_queue([[Start]], Goal).
bfs_queue([[Goal|Path]|_], Goal) :-  % Goal found
    reverse([Goal|Path], Solution),
    write('Solution: '), write(Solution), nl.
bfs_queue([Path|Paths], Goal) :-
    extend(Path, NewPaths),
    append(Paths, NewPaths, UpdatedPaths),
    bfs_queue(UpdatedPaths, Goal).
extend([Node|Path], NewPaths) :-
    findall([NewNode, Node|Path],
            (edge(Node, NewNode), \+ member(NewNode, [Node|Path])),
            NewPaths),
    !. % Cut to prevent backtracking
extend(_, []). % No more extensions

% Sample usage:
% ?- bfs(a, f)