- module(node).
- export([join/1, getNeigs/2, listen/2, moveOldest/2]).
- record(state, {view, c, h, s, select, id}).


% spec : Add the node to the Tree and send back the Id.
% pre : PID 
% post : Int
join(BootServerPid) ->
  BootServerPid ! { join, self() },
  receive
    { joinOk, NodeId } ->
      NodeId
  end.


% Send back one of the Neighbours 
% pre : PID, Int
% post : Int
getNeigs(BootServerPid, NodeId) ->
  BootServerPid ! { getPeers, { self(), NodeId } },
  receive
    { getPeersOk, Neigs } -> Neigs
  end.


% Sort a list randomly
% pre : List
% post : List
shuffle(List) ->
    Random_list = [{rand:uniform(), X} || X <- List],
    [X || {_,X} <- lists:sort(Random_list)].


% Remove the duplicate Node according to the PID
% pre : List[List[âge, PID]], Integer
% post : List[List[âge, PID]] whitout duplicate
removeDuplicate(View, I) ->
   if 
    I =:= length(View) -> 
      View;
    I =/= length(View) ->
      First = lists:nth(I,View),
      Second = lists:nth(I+1,View),
      if 
        (hd(tl(First)) =:= hd(tl(Second))) ->
          NewView = lists:delete(Second, View),
          removeDuplicate(NewView, I);
        (hd(tl(First)) =/= hd(tl(Second))) -> 
          removeDuplicate(View, I+1)
      end
  end.


% Remove the duplicate Node according to the PID
% pre : List[List[âge, PID]]
% post : List[List[âge, PID]] whitout duplicate
noDuplicate(View) -> 
  Sort = lists:sort(fun([_,X,_], [_,Y,_]) -> X=<Y end, View),
  removeDuplicate(Sort, 1).


% Remove the N oldest element
% pre : Int, List[List[âge, PID]]
% post : List[List[âge, PID]] without the N oldest
removeOldItems(N, View) -> 
  Sort = lists:sort(fun([X,_,_], [Y,_,_]) -> X>=Y end, View),
  if 
    N=<0 -> View;
    N>0 -> 
      Deleted = lists:delete(hd(Sort), Sort), 
      removeOldItems(N-1,Deleted)
  end.


% Remove the "Last"'s item from the "View"
% pre : List[List[age, List]], List[List[age, List]]
% post : List[List[age, List]] without "Last"'s item
removeItems(Last, View) ->
  if 
    length(Last) =:= 0 -> % Cas de base
      View;
    length(Last) =/= 0 -> 
      NewView = lists:delete(hd(Last), View), % Supprime les vieux éléments
      removeItems(tl(Last), NewView) % Ajoute l'élément supprimé à la fin
  end.


% Move the H oldest element at the end of "View"
% pre : List[List[age, List]], Int
% post : List[List[age, List]]
moveOldest(View, H) -> 
  Sort = lists:sort(fun([X,_,_], [Y,_,_]) -> X=<Y end, View), % Trie selon l'âge
  if
    length(Sort) > H ->
      Last = lists:sublist(Sort, length(Sort)-H+1, H), % Récupère les H derniers noeuds
      NewView = removeItems(Last, View),
      lists:append(NewView,Last);
    length(Sort) =< H -> 
      View 
  end.


% Remove the S element at the head of "View"
% pre : Int, List[List[age, List]]
% post : List[List[age, List]] 
removeHead(S, View) -> 
  if 
    S=<0 -> View;
    S>0 ->
      First = lists:sublist(View, 1, S), % Récupère les S premiers noeuds
      removeItems(First, View)
  end.


% Remove N element randomly in "View"
% pre : Int, List[List[age, List]]
% post : List[List[age, List]]
removeRandom(N, View)-> 
  if
    N=<0 ->
      View;
    N>0 ->
      NRand = rand:uniform(length(View)),
      ToBeDeleted = lists:nth(NRand,View),
      NewView =lists:delete(ToBeDeleted, View),
      removeRandom(N-1, NewView)
  end.


% Increase the âge of each element
% pre : List[List[age, List]]
% post : List[List[age, List]]
increaseAge(View) ->
  lists:map(fun([X,Z,Y])-> [X+1,Z,Y] end, View).


% React to "pushcall". Send himself and c/2-1 of the newest in the "View" to the PID.
% pre : PID, List[List[age, List]], #state(view=List[List[age, List]], c=Int, h=Int, s=Int, select=String)
% post : #state(view=List[List[age, List]], c=Int, h=Int, s=Int, select=String)
doPassiveThread(PID, StateP, State) -> 
  HimSelf = [[0, State#state.id , self()]], 
  Permuted = shuffle(State#state.view), 
  OldMove = moveOldest(Permuted, State#state.h),
  Buffer = HimSelf ++ lists:sublist(OldMove, 1, round((State#state.c/2)-1)),
  PID ! {pushback, Buffer}, 
  doPullActive(StateP, State).


% React to the trigger of isItTime
% pre : PID,  #state(view=List[List[age, List]], c=Int, h=Int, s=Int, select=String)
% post : #state(view=List[List[age, List]], c=Int, h=Int, s=Int, select=String)
doActiveThread(PID, State) ->
  HimSelf = [[0,State#state.id ,self()]], % Append la view actuelle et le process
  Permuted = shuffle(State#state.view), % Permute
  OldMove = moveOldest(Permuted, State#state.h),
  Buffer = HimSelf ++ lists:sublist(OldMove, 1, round((State#state.c/2)-1)),
  PID ! {pushcall, self(), Buffer}, % Envoie la view
  #state{view=State, c=State#state.c, h=State#state.h, s=State#state.s, select=State#state.select, id=State#state.id}.


% Append the 2 views and manage to get length(view)=<c
% pre : List[List[age, List]], #state(view=List[List[age, List]], c=Int, h=Int, s=Int, select=String)
% post : #state(view=List[List[age, List]], c=Int, h=Int, s=Int, select=String)
doPullActive(StateP, State) -> 
  NoDup = noDuplicate(StateP++State#state.view),
  NoOld = removeOldItems( min(State#state.h, length(NoDup)-State#state.c), NoDup),
  NoFirstAndNoOld = removeHead( min(State#state.s, length(NoOld)-State#state.c), NoOld),
  NoRandAndNoFirstAndNoOld = removeRandom(length(NoFirstAndNoOld)-State#state.c, NoFirstAndNoOld),
  Increased = increaseAge(NoRandAndNoFirstAndNoOld),
  #state{view=Increased, c=State#state.c, h=State#state.h, s=State#state.s, select=State#state.select, id=State#state.id}.


% Instantiate de Neighbours at the start of a Node
% pre : List, PID of the main thread
infoAboutNeighbours(Neighs, PID_p) ->
  if 
    length(Neighs) =:= 0 -> 
      -1;
    length(Neighs) =/= 0 -> 
      if 
        hd(Neighs) =/= nil ->
          PID_p ! {info, hd(Neighs)+1, self()},
          infoAboutNeighbours(tl(Neighs), PID_p);
        hd(Neighs) =:= nil -> 
          infoAboutNeighbours(tl(Neighs), PID_p)
      end
  end.

% Manage the message receive to the thread to pass in the passive and in the active. 
% pre : #state(view=List[List[age, List]], c=Int, h=Int, s=Int, select=String)
listen(Tuple, PID_p) -> %Tuple = [view:View, c=C , h:H, s=S, select:Select, id:NodeId]  & View = [[PID, H], [], [] , ... ]
  receive

    % Ask for information about a Node
    {info, NodeId, BootstrapServer, C, S, H, Select} -> 
      State = #state{view=[], c=C, h=H, s=S, select=Select, id=NodeId},
      Number = getNeigs(BootstrapServer, NodeId),
      infoAboutNeighbours(element(1, Number), PID_p),
      listen(State, PID_p);
    
    {info2, Node, NodeId, C, S, H, Select} ->
       State = #state{view=[], c=C, h=H, s=S, select=Select, id=NodeId},
       PID_p ! {info, Node, self()},
       listen(State, PID_p);
    % Receive the information from the main thread
    {ok, GetPID, ID} -> 
      State = #state{view=Tuple#state.view++[[0, ID-1,GetPID]], c=Tuple#state.c, h=Tuple#state.h, s=Tuple#state.s, select=Tuple#state.select, id=Tuple#state.id},
      listen(State, PID_p);
    
    % Call the active thread
    {time} ->  
      PID_p ! {console, Tuple#state.view, Tuple#state.id, self()},
      if
        Tuple#state.select =:= "rand" ->
          RandNum = rand:uniform(length(Tuple#state.view)),
          PID = lists:last(lists:nth(RandNum, Tuple#state.view));
        Tuple#state.select =:= "tail" ->
          Sort = lists:sort(fun([X,_,_], [Y,_,_]) -> X >= Y end, Tuple#state.view),
          PID = lists:last(lists:last(Sort))
      end,
      doActiveThread(PID, Tuple),
      listen(Tuple, PID_p);
    
    % React when a passive callback the active thread
    {pushback, Buffer} -> 
      State = doPullActive(Buffer, Tuple),
      PID_p ! {log, State#state.view, self()},
      listen(State, PID_p);

    % Call the passive thread
    {pushcall, From, Buffer} -> 
      State = doPassiveThread(From, Buffer, Tuple),
      listen(State, PID_p)
  end.