#!/bin/bash
# MASKS
       # prog+hem+lig prog hem  lig   loop
   P_2V0M=('1-471' '1-469' '470' '471' '253-256')
   # ('2V0M') # 30-498, hem499, lig500 loop: 282-285, minus 29
   P_3UA1=('1-471' '1-469' '470' '471' '232-241 | :253-259')
   # ('3UA1') # 28-496, hem497, lig498, loop: 259-268, 280-286, minus 27
   P_4K9V=('1-471' '1-469' '470' '471' '238-241 | :253-261')
   # ('4K9V') # 28-496, hem497, lig498, loop: 265-268, 280-288, minus 27
   P_4K9T=('1-471' '1-469' '470' '471' '237-241 | :252-260')
   # ('4K9T') # 29-497, hem498, lig499 loop: 265-269, 280-288, minus 28
   P_4I4G=('1-472' '1-470' '471' '472' '239-241 | :255-262')
   # ('4I4G') # 27-496, hem497, lig498, loop: 265-267, 281-288, minus 26
   P_4D78=('1-472' '1-470' '471' '472' '239-240 | :254-262')
   # ('4D78') # 27-496, hem497, lig498, loop: 265-266, 280-288, minus 26

for sys in TES* DHT*
do
   f=${sys%.pdb}
   mkdir -p ${f}
   LIG=${f:0:3}
   PRO=$(echo $f | cut -f 4 -d_)
   cp -r amber_md_files/* $f
   cp lig_gaussian/${LIG}_resp/${LIG}.prepc ${f}/leap
   cp lig_gaussian/${LIG}_resp/${LIG}.frcmod ${f}/leap

   sed /END/d recps_noH_dry_protonated/${PRO,,}-pka3_NH_mod.pdb  > ${f}/leap/${PRO}_${LIG}.pdb
   echo -e "TER" >> ${f}/leap/${PRO}_${LIG}.pdb
   grep "$LIG\ " $sys | sed "s/${LIG}\ \ /${LIG}\ A/g" >> ${f}/leap/${PRO}_${LIG}.pdb
   echo -e "TER" >> ${f}/leap/${PRO}_${LIG}.pdb
   grep "HOH" ${PRO,,}_water.pdb | sed 's/HOH/WAT/g; /ANISOU/d' >> ${f}/leap/${PRO}_${LIG}.pdb
   sed -i "s/LIGAND/${LIG}/g; s/COMPLEX/${PRO}_${LIG}/g"  ${f}/leap/leap.in

   # Change the mask
   for mask in P_2V0M P_3UA1 P_4K9V P_4K9T P_4I4G P_4D78
   do
      if [ ${mask:2:4} = ${PRO} ]
      then
         #eval alst=(\${$mask[*]}) # should be @
         #eval alst=(\${$mask[@]}) # eval is slow!
         alst=${!mask}
         break
      fi
   done

   MASK=${alst[0]}; MASK2=${alst[1]}; HEM_MASK=${alst[2]}; LIG_MASK=${alst[3]}; LOOP_MASK=${alst[4]}
   sed -i "s/MASK/${MASK}/g" ${f}/heat/pr2.in ${f}/heat/pr1.in ${f}/min2/min2.in ${f}/min2/min1.in 
   sed -i "s/LOOP_MASK/${LOOP_MASK}/g" ${f}/min2/min2_0.in
   sed -i "s/MASK2/${MASK2}/g; s/LIG_MASK/${LIG_MASK}/g; s/HEM_MASK/${HEM_MASK}/g" ${f}/min2/min3.in
done
