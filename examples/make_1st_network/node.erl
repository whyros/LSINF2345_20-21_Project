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
  % State = #state(id, view)
  %  q = SelectPeer(State.view)
%   push S to q 
%   pull Sq from q
%   S= Update(S,Sq)
%   doActiveThread.

%Bientôt fini
doPassiveThread(PID, StateP, State)->
  WithIn= [State.id, self(), 0]++State.view
  PID ! {doActiveThread, WithIn}.
  NoDup=duplicate(State.view++StateP, State.h)
%On doit s'assurer qu'il y a pas trop de noeud.


listen(Tuple) -> %Tuple = [id:ID, view:View, c=C , h:H]  & View = [[id, PID, H], [], [] , ... ]
  receive
    {info, tuple} -> 
      listen(tuple);
    {time} -> 
      randomNeig=getNeigs(BootServerPid, Tuple.id),
      PID = randomNeig[random:uniform(length(randomNeig))],
      State -> doActiveThread(State, PID),
      listen(State)
    {push, From, Buffer} -> 
      State -> doPassiveThread(From, Buffer, State)
      listen(State)
  
  
  % callToPassiveThread 
  % doPassiveThread(StateP, V)
  % {activate_thread, V, S, H} -> doActivateThread()
  % create descriptor
  % select one v in V
  % v.PID ! { exted(V)}
  % recieve
  end.

OldestRemvoe(View, H, I) ->
  if 
    I+1 == length(View) -> % Cas de base
      View
    I+1 /= length(View) ->
        First=lists:nth(I,View),
    Second=lists:nth(I+1,View),
    if 
      hd(First)==hd(Second) and lists:nth(3, First) < lists:nth(3, Second) ->
        newView = list:delete(Second, View)
        OldestRemove(newView, H, I+1)
      hd(First)==hd(Second) and lists:nth(3, First) >= lists:nth(3, Second) -> 
        newView = list:delete(First, View)
        OldestRemove(newView, H, I+1)
    end
  end
      

duplicate(View, H) -> 
  Sort = lists:sort(fun([_,X], [_,Y]) -> 
                      X=<Y
                    end, View),
  OldestRemove(Sort, H, 0)
  