# Comments

- first of all, congratulations for your excellent work!
- your sources are easy to read and provide comments that allows one to follow the logic in your algorithms
- the additional scenario (random) also allows to justify your results
- it is indeed easier to plot the in-degree within the erlang code !
- I also appreciate the brief discussion about the curves you present, although, it is clear that there is a lack of argumentation that explain the behavior of curves, you describe how the curves behave with no further details. Here one example of how you might do so: *the observed variance of in-degree when nodes recover reflects that the in-degree is not equally balanced among all nodes in the network (as shown before nodes crash); or even simpler, there are partitions where one observe that certain clusters contain more nodes than others*

- with a healer selection, the following error stops the execution (you might handle an exception while getting a sublist as used in LOC 80 in `project.erl`)

```
{"init terminating in do_boot",{function_clause,[{lists,nthtail,[1,[]],[{file,"lists.erl"},{line,180}]},{lists,sublist,3,[{file,"lists.erl"},{line,345}]},{project,bigFill,8,[{file,"project.erl"},{line,80}]},{project,listenProject,10,[{file,"project.erl"},{line,237}]},{erl_eval,do_apply,6,[{file,"erl_eval.erl"},{line,670}]},{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]}}
init terminating in do_boot ()

Crash dump is being written to: erl_crash.dump...done
```

# Grade
| Bootstrap network (20%) | PS service implementation (50%) | Experimental scenario (30%) | Grade in % | Points (up to 5) |
|---|---|---|---|---|
|20 |	50 |25 |95 |	4.75|
