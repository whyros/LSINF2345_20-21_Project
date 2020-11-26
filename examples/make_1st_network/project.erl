- module(project).
- import(bootstrap_server, [listen/2]).
- import(node, [join/2, isItTime/2 ,getNeigs/3, listen/3]).
- export([launch/1]).

makeNet(N, BootServerPid) -> makeNet(N, BootServerPid, [], 0).

makeNet(N, BootServerPid, Net, Counter) ->
  NodePid = spawn(node, listen, [BootServerPid, {-1, [], 3}]),
  spawn(node, isItTime, [2999, NodePid]),
  NodeId = node:join(BootServerPid),
  NodePid ! {info, {id=NodeId, view=[], c=3},
  Node = { NodeId, NodePid },
  if
    N =/= Counter + 1 ->
      makeNet(N, BootServerPid, Net ++ [ Node ], Counter + 1);
    N =:= Counter + 1 ->
      Net ++ [ Node ]
  end.

launch(N) ->
  % Creates server with an empty tree
  BootServerPid = spawn(bootstrap_server, listen, [ 0, {} ]),
  makeNet(N, BootServerPid).
