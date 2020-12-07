- module(project).
- import(bootstrap_server, [listen/2]).
- import(node, [join/1, getNeigs/3, listen/1]).
- export([launch/5, isItTime/2]).

makeNet(N,Select, C , S , H , BootServerPid) -> makeNet(N,Select, C, S, H, BootServerPid, [], 0, 1).

makeNet(N,Select, C, S, H, BootServerPid, Net, Counter, NbrCycle) ->
  if
    
    % Stop all the thread 
    NbrCycle >= 180 ->
      if
        length(Net)=:=0 ->
          io:format("Thank you for your time~n",[]),
          exit(self(),kill);
        length(Net)=/=0 ->
          exit(lists:last(hd(Net)),kill),
          makeNet(N, Select, C, S, H, BootServerPid, tl(Net), Counter + 1, NbrCycle)
      end;

    % Launch 60% of network
    NbrCycle =:= 150 ->   
      RandNodeToLink = rand:uniform(length(Net)),
      Node = hd(lists:nth(RandNodeToLink, Net)),
      bigFill(Net,Node, Select, C, S, H, Counter, N);

    % Kill 60% of the network
    NbrCycle =:= 120 ->   
      RandNodeToCrash=rand:uniform(length(Net)),
      exit(lists:last(lists:nth(RandNodeToCrash, Net)),kill),
      if
        round(N*0.6) =/= Counter + 1 ->
          makeNet(N, Select, C, S, H, BootServerPid, lists:sublist(Net, 1, RandNodeToCrash-1) ++ lists:sublist(Net, RandNodeToCrash+1, length(Net)), Counter + 1, NbrCycle);
        round(N*0.6) =:= Counter + 1 ->
          lists:sublist(Net, 1, RandNodeToCrash-1) ++ lists:sublist(Net, RandNodeToCrash+1, length(Net))
      end;

    % Launch 40% of the network
    NbrCycle =:= 1 ->
      NodePid = spawn(node, listen, [Select, self()]),
      NodeId = node:join(BootServerPid),
      Node = [ NodeId, NodePid ],
      if
        round(N*0.4) =/= Counter + 1 ->
          makeNet(N, Select, C, S, H, BootServerPid, Net ++ [ Node ], Counter + 1, NbrCycle);
        round(N*0.4) =:= Counter + 1 ->
          Network=Net ++ [ Node ],
          giveInfo(Network, BootServerPid, Select, C, S, H),
          spawn(project, isItTime, [400, self()]),
          listenProject(Network, [], 0, N,Select, C, S, H, BootServerPid, NbrCycle)
      end;

    % Launch 20% of the network
    (NbrCycle rem 30) =:= 0 -> 
      NodePid = spawn(node, listen, [Select, self()]),
      NodeId = node:join(BootServerPid),
      NodePid ! {info, NodeId, BootServerPid, C, S, H, Select},
      Node = [ NodeId, NodePid ],
      if
        round(N*0.2) =/= Counter + 1 ->
          makeNet(N, Select, C, S, H, BootServerPid, Net ++ [ Node ], Counter + 1, NbrCycle);
        round(N*0.2) =:= Counter + 1 ->
          Network=Net ++ [ Node ],
          Network
      end
  end.


bigFill(Net, NodeLink, Select, C, S, H, Counter, N) ->
  NodePid = spawn(node, listen, [Select, self()]),
  Check = checkNet(Net, 0),
  Node = [ Check, NodePid ],
  NodePid ! {info2, NodeLink, Check, C, S, H, Select},
  FirstPart=lists:sublist(Net, 1 ,Check) ++ [Node],
  if
    round(N*0.6) =/= Counter + 1 ->
      bigFill(FirstPart ++ lists:sublist(Net, Check+1, length(Net)), NodeLink, Select, C, S, H, Counter + 1, N);
    round(N*0.6) =:= Counter + 1 ->
      FirstPart ++ lists:sublist(Net, Check+1, length(Net))
  end.

% Check if a NodeId is not taken in the Network
% pre : List[PID, Integer], Integer
% post : Integer
checkNet(Net, ToCheck) ->
  if
    length(Net) =:= 0 ->
      ToCheck+1;
    length(Net) =/= 0 ->
      if 
        hd(hd(Net)) =:= ToCheck -> 
          checkNet(tl(Net), ToCheck+1);
        hd(hd(Net)) =/= ToCheck ->
          ToCheck
      end
  end.


% giveInfo to each thread (c, H, S, Select)
% pre : List[{Id, PID}], PID, String, Int, Int, Int
giveInfo(Network, BootServerPid, Select, C, S, H) -> 
  if 
    length(Network) =:= 0 ->
      Network;
    length(Network) =/= 0 -> 
      Head=hd(Network),
      NodePid = lists:last(Head),
      NodePid ! {info, hd(Head), BootServerPid, C, S, H, Select},
      % spawn(node, isItTime, [3000, NodePid]),
      giveInfo(tl(Network), BootServerPid, Select, C, S, H)
    end.


% Manage the time for trigger the active thread
% pre : Int, PID
% post : token
isItTime(TimeLeft, Pid) ->
    timer:sleep(TimeLeft),
    Pid ! {time},
    isItTime(TimeLeft, Pid).


% Send the message to launch the active thread of each Node
% pre : List[PID, Integer]
activeAll(Net) ->
  if 
    length(Net) =:= 0 ->
      1;
    length(Net) =/= 0 -> 
      lists:last(hd(Net)) ! {time},
      activeAll(tl(Net))
  end.


% Update the Indegree given the node's view
% pre : List[Integer, Integer, PID], List[Integer, Integer]
checkView(View, IndegreeLog) -> 
  if 
    length(View) =:= 0 ->
      IndegreeLog;
    length(View) =/= 0 -> 
      Id=lists:nth(2,hd(View)),
      Pre = searchList(IndegreeLog, Id, 1),
      if 
        Pre =:= -1 ->
          checkView(tl(View), IndegreeLog++[[Id,"<--ID | Degree-->",  1]]);
        Pre =/= -1 -> 
          Number=lists:last(lists:nth(Pre, IndegreeLog))+1,
          FirstList=lists:sublist(IndegreeLog, 1, Pre-1)++[[Id, "<--ID | Degree-->", Number]],
          
          checkView(tl(View), FirstList++lists:sublist(IndegreeLog, Pre+1, length(IndegreeLog)))
      end
  end.


% Compute the sum of the Indegree
% pre : List[Integer, Integer], Integer
sum(Indegree, Sum) -> 
  if 
    length(Indegree) =:= 0 ->
      Sum;
    length(Indegree) =/= 0 -> 
      sum(tl(Indegree), Sum+lists:last(hd(Indegree)))
  end.


% Compute the denominator of standard deviation
% pre : List[Integer, Integer] , Float, Integer
standardDeviation(Indegree, Average,Sum)->
  if 
    length(Indegree) =:= 0 ->
      Sum;
    length(Indegree) =/= 0 -> 
      standardDeviation(tl(Indegree),Average, math:pow(lists:last(hd(Indegree))-Average,2))
  end.


% Search in the List for a Value and return the position in the list
% pre : List, Integer, Integer
searchList(List , Value, Nth) -> 
  if 
    length(List) =:= 0 ->
      -1;
    length(List) =/= 0 ->
      Pre=hd(hd(List)),
      if 
        Pre=:= Value ->
          Nth;
        Pre =/= Value ->
          searchList(tl(List) , Value, Nth+1)
      end
  end.


% Main Thread that get the view from all the thread
% Trigger the active thread, keep data for the in degree
% Log the view of the thread with the PID
% 
% pre : List[{Id, PID}]
listenProject(Net, InDegreeLog, Count, N,Select, C, S, H, BootServerPid, NbrCycle) -> 
  if 
    length(Net) =:= Count ->
      io:format("Indegree ~p : ~p~n", [NbrCycle, InDegreeLog]),
      if 

        % Print in the file for the first Cycle
        NbrCycle =:= 1 -> 
          Sum=sum(InDegreeLog, 0),
          Average=Sum/length(InDegreeLog),
          Denominator=standardDeviation(InDegreeLog,Average,0),
          StandardDeviation= math:sqrt(Denominator/length(InDegreeLog)),
          file:write_file("node.log", io_lib:fwrite("~w ~w ~w ~n",[NbrCycle, Average, StandardDeviation]),[append]),
          listenProject(Net, [], 0, N,Select, C, S, H, BootServerPid, NbrCycle+1);
        % Print in the file for every 20 cycle
        (NbrCycle rem 20) =:= 0 -> 
          Sum=sum(InDegreeLog, 0),
          Average=Sum/length(InDegreeLog),
          Denominator=standardDeviation(InDegreeLog,Average,0),
          StandardDeviation= math:sqrt(Denominator/length(InDegreeLog)),
          file:write_file("node.log", io_lib:fwrite("~w ~w ~w ~n",[NbrCycle, Average, StandardDeviation]),[append]),
          if 

            % React every 30 cycle with the scenario
            (NbrCycle =:= 180) -> 
              makeNet(N,Select, C, S, H, BootServerPid, Net, 0, NbrCycle);
            (((NbrCycle+1) rem 30) =:= 0) and ((NbrCycle+1) < 180) -> 
              NewNet=makeNet(N,Select, C, S, H, BootServerPid, Net, 0, NbrCycle+1),
              listenProject(NewNet, [], 0, N,Select, C, S, H, BootServerPid, NbrCycle+1);
            ((NbrCycle+1) rem 30) =/= 0 -> 
              listenProject(Net, [], 0, N,Select, C, S, H, BootServerPid, NbrCycle+1)
          end;
        (NbrCycle rem 20) =/= 0 -> 
          if 
            % React every 30 cycle with the scenario
            (((NbrCycle+1) rem 30) =:= 0) and ((NbrCycle+1) < 180) -> 
              NewNet=makeNet(N,Select, C, S, H, BootServerPid, Net, 0, NbrCycle+1),
              listenProject(NewNet, [], 0, N,Select, C, S, H, BootServerPid, NbrCycle+1);
            (((NbrCycle+1) rem 30) =/= 0) or ((NbrCycle+1) =:= 180) -> 
              listenProject(Net, [], 0, N,Select, C, S, H, BootServerPid, NbrCycle+1)
          end
      end;
    
    length(Net) =/= Count ->
      receive 
        % Send the information about the neighbours of a Node
        {info, Ne, PID} -> 
          PID ! {ok, lists:last(lists:nth(Ne, Net)), Ne},
          listenProject(Net,InDegreeLog, Count, N,Select, C, S, H, BootServerPid, NbrCycle);
        
        % Send a message to each Node in order to run each active thread
        {time} -> 
          activeAll(Net),
          listenProject(Net, InDegreeLog, Count, N,Select, C, S, H, BootServerPid, NbrCycle);

        % Get the view to log it and update the Indegree
        {console, View ,ID ,PID} -> 
          io:format("View of ~p - ~p : ~p~n", [ID, PID, View]),
          InDegree = checkView(View, InDegreeLog),
          listenProject(Net, InDegree, Count+1, N,Select, C, S, H, BootServerPid, NbrCycle)
      end
  end.


launch(N, Select, C, S, H) ->
  % Creates server with an empty tree
  BootServerPid = spawn(bootstrap_server, listen, [ 0, {} ]),
  makeNet(N, Select, C, S , H , BootServerPid).