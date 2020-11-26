# Question 

De base, on a un problème pour savoir comment se propage l'information, comment est chosis le PID à envoyer l'information.

Les principales question sont avec des gros titres et les autres sont des questions moins importante. 

## Comment se propagent les noeuds avec les PID ? 

Contextualisation: 
https://github.com/raziel-carvajal/LSINF2345_20-21_Project
Dans la partie PS service implementation, on nous dit : "The neighbor to gossip with will be chosen at random among all peers in the view (the so call rand selection) or the chosen neighbor will be the one with the highest age (tail selection)". La "view" est la vue globale du noeud ou est-ce qu'il s'agit de la vue global des différents noeuds. 

Càd qu'on se demande si le noeuds push avec un de ses neighbours ou non. 


### Les neighbours sont les noeuds présent dans la "view" ? 

Contextualisation: 
Dans l'article à lire, on nous parle de "incoming connection". Cela signfie qu'on doit peut être voir les connections comme n'étant pas équivalente. page 7


## Quand est-ce qu'on doit utiliser rand & tail  ? 
Contextualisation: 
Dans l'article à lire, on ne comprend pas quand on doit effectuer un choix random ou prendre le plus vieux parmis les noeuds. On pense qu'il faut faire des choix random lorsqu'on a pas assez de noeud dans notre "view". Lorsque la view est pleine (càd à atteint c de longueur), elle envoie au noeud le plus vieux. Cependant, est-ce que c'est un choix à précier lors du lancement de la procédure ?  

## SELECT & UPDATE
Cette phrase dans l'article est très byzzard: 
- "When the service receives a notification on a view update,
it removes those elements from the queue that are no longer in the current view,
and appends the new elements that were not included in the previous view". Page 8 (When au milieu de 2.4.2)

Contextualisation: On ne comprend pas comment on doit update les différentes "views". Parce qu'on nous dit de supprimer les anciens et en même temps de garder une liste de view = c. De plus, on a le même probleme dans la page 6 avec (3) : 

- "Subsequently,
the method performs a number of removal steps to decrease the size of the
view to c. The parameters of the removal methods are calculated in such a way
that the view size never drops below c"

### PUSH & PUSHPULL
"The node and selected peer exchange descriptors". Cela signifie que si on doit avoir un échange dans pushpull, on échange les noeuds entre les deux noeuds ? Page 7, 2.3.2
