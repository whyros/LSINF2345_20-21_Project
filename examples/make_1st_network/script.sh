!/bin/bash
echo "Launch of the Project:"
echo "Which launch do you want between healer policy, swapper policy or custom ?  valid input : [healer, swapper or custom]"
read choice
if [ "$choice" == "healer" ] || [ "$choice" == "Healer" ]; then 
    echo "What Select-Peer do you want \(rand or tail\)?"
    read sp
    ( echo "c(node)."; echo "c(project)."; echo "c(bootstrap_server)."; echo "c(tree).";) | erl
    spl="\"$sp\""
    nbr=128
    c=7
    h=4
    s=3
    erl -pa ebin -eval "project:launch($nbr, $spl, $c, $s, $h)."
else
if [ "$choice" == "swapper" ] || [ "$choice" == "Swapper" ]; then 
    echo "What Select-Peer do you want \(rand or tail\)?"
    read sp
    ( echo "c(node)."; echo "c(project)."; echo "c(bootstrap_server)."; echo "c(tree).";) | erl
    spl="\"$sp\""
    nbr=128
    c=7
    h=3
    s=4
    erl -pa ebin -eval "project:launch($nbr, $spl, $c, $s, $h)."
else 
echo "What Select-Peer do you want \(rand or tail\)?"
read sp
echo "How much Node voulez-vous ?"
read nbr
echo "Which value do you want for C ?"
read c
echo "Which value do you want for Healer ? "
read h
echo "Which value do you want for Swapper ? "
read s
( echo "c(node)."; echo "c(project)."; echo "c(bootstrap_server)."; echo "c(tree).";) | erl
spl="\"$sp\""
erl -pa ebin -eval "project:launch($nbr, $spl, $c, $s, $h)."
fi
fi