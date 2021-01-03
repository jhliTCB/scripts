#!/bin/bash
module load amber/16
var0=''
var1='center :1-471\nimage familiar'
var2='center :1-471\nimage center familiar'
var3='center :1-471 origin\nimage center familiar'
var4='center :1-471 origin\nimage origin center familiar'
var5='center\nimage center familiar'
var6='center origin\nimage origin center familiar'
var7='center\nimage familiar'
var8='center *\nimage center familiar'

for i in $(seq 0 8)
do
   echo -e "trajin ../md9/md9.nc 5000 5000" > final_test${i}.in
   f=var${i}
   eval ff=$(echo \$$f)
   echo -e "$ff" >> final_test${i}.in
   echo -e "trajout md9_test${i}.pdb pdb\ngo" >> final_test${i}.in
   
   k=final_test${i}.in
   cpptraj -p ../leap/p_sol.top < $k >& log_${k%.in}.log
  
done

# var2 is the best to handle the box information
