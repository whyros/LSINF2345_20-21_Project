- module(node).
- export([join/1, getNeigs/2, listen/1, isItTime/2]).
- record(state, {id, view, c, h, s}).


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

% doActiveThread(State, PID)->

  % State = #state(id, view)
  %  q = SelectPeer(State.view)
%   push S to q 
%   pull Sq from q
%   S= Update(S,Sq)
%   doActiveThread.

%Bientôt fini

oldestRemove(View, H, I) ->
   if 
    I+1 == length(View) -> 
      View;
    I+1 /= length(View) ->
      First=lists:nth(I,View),
      Second=lists:nth(I+1,View),
      if 
        (hd(First)==hd(Second)) ->
          newView = lists:delete(Second, View),
          oldestRemove(newView, H, I);
        (hd(First)/=hd(Second)) -> 
          oldestRemove(View, H, I+1)
      end
  end.

noDuplicate(View, H) -> 
  Sort = lists:sort(fun([X,_], [Y,_]) -> X=<Y end, View),
  oldestRemove(Sort, H, 0).

remove(_, []) -> [];
remove(1, [_|T]) -> T;
remove(N, [H|T]) -> [H | remove(N-1, T)]. 

removeOldItems( N, View) -> 
  Sort = lists:sort(fun([_,X], [_,Y]) -> X=<Y end, View),
  remove(N, View)
.

moveOldItems(Last, View) ->
  if 
    length(Last) == 0 -> % Cas de base
      View;
    length(Last) /= 0 -> 
      newView=lists:delete(hd(Last), View), % Supprime les vieux éléments
      moveOldItems(tl(Last), newView++hd(Last)) % Ajoute l'élément supprimé à la fin
  end.

moveOldest(View, H) -> 
  Sort = lists:sort(fun([_,X], [_,Y]) -> X>=Y end, View), % Trie selon l'âge
  Last = lists:sublist(Sort, length(Sort)-H, H), % Récupère les H derniers noeuds
  moveOldItems(Last, View).

%removeHead(View, S) -> 

doPassiveThread(PID, StateP, State) -> 
  Permuted=lists:shuffle(State#state.view), % Permute
  OldMove=moveOldest(Permuted, State#state.h), % Transfert les H vieux éléments à la fin
  WithIn= [self(), 0]++OldMove, % Append la view actuelle et le process
  PID ! {doActiveThread, WithIn}, % Envoie la view
  NoDup = noDuplicate(State#state.view++StateP#state.view, State#state.h),
  % To Do : Remove OldItems
 removeOldItems( min(H,length(State#state.view)-State#state.c), State#state.view)
  % To Do : Remove Head
  % To Do : Remove AtRandom
  % TO Do : Increase Age of the View 


  


%On doit s'assurer qu'il y a pas trop de noeud.


listen(Tuple) -> %Tuple = [iview:View, c=C , h:H, s=S, select:Select]  & View = [[PID, H], [], [] , ... ]
  receive
    {info, tuple} -> 
      View=getNeigs(element(tuple,1), element(tuple,2)),
      State=#state{view=View, c=7, h=4, s=3},
      listen(State);
    %{time} ->  
      % if
      %   % randPID = randomNeig[random:uniform(length(randomNeig))],
      %   % tailPID =
      % end,
      %State = doActiveThread(State, PID),
      %listen(State);
    {push, From, Buffer} -> 
      State = doPassiveThread(From, Buffer, element(Tuple, 2)),
      listen(State)
  end.
  
  % callToPassiveThread 
  % doPassiveThread(StateP, V)
  % {activate_thread, V, S, H} -> doActivateThread()
  % create descriptor
  % select one v in V
  % v.PID ! { exted(V)}
  % reciev