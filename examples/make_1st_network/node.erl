- module(node).
- export([join/1, getNeigs/2, listen/3, isItTime/2]).
% - record(state, {id, view, c}).


join(BootServerPid) ->
  BootServerPid ! { join, self() },
  receive
    { joinOk, NodeId } ->
      NodeId
  end.

getNeigs(BootServerPid, NodeId) ->
  BootServerPid ! { getPeers, { self(), NodeId } },
  receive
    { getPeersOk, Neigs } -> Neigs
  end.

isItTime(TimeLeft, Pid) ->
    chrono:sleep(TimeLeft),
    Pid ! {time},
    isItTime(TimeLeft, Pid).

% Update(S, Sq)->

doActiveThread(State, PID)->
%  wait(T)
  % State = #state(id, view)
  %  q = SelectPeer(State.view)
%   push S to q 
%   pull Sq from q
%   S= Update(S,Sq)
%   doActiveThread.


doPassiveThread(StateP, PID)->
  State = #state {id=1},
  State ! {doActiveThread, PID, S, H}.


listen(Tuple) ->
  receive
    {info, tuple} -> 
      listen(tuple);
    {time} -> 
      randomNeig=getNeigs(BootServerPid, 1),
      PID = randomNeig[random:uniform(length(randomNeig))],
      doActiveThread(State, PID),
    % callToPassiveThread
    
    % doPassiveThread(StateP, V)
  % {activate_thread, V, S, H} -> doActivateThread()
  % create descriptor
  % select one v in V
  % v.PID ! { exted(V)}
  % recieve
  end.

