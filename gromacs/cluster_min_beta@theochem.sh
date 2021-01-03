#!/bin/bash
# Argument 1 is the major_cluster.pdb (or second, third, ...)
module load gromacs/5.0.4
GMX='gmx_mpi'
#MDRUN='mdrun -nb cpu'
MDRUN='mdrun'
export OMP_NUM_THREADS=2

echo 1 | $GMX pdb2gmx -f $1 -water tip3p -o rec.gro >& log_pdb2gmx

check1=$(grep Linking log_pdb2gmx | wc -l)
if [ $check1 -lt 2 ]
then
   echo something wrong in definding bonds!
   exit
fi

sed -i '/posre.itp/a #endif\n#ifdef em1_wat\n#include "posre_em1.itp"\n#endif\n#ifdef em2_h\n#include "posre_em2.itp"\n#endif\n#ifdef em3_sc\n#include "posre_em3.itp"' topol.top

$GMX editconf -f rec.gro -o rec_newbox.gro -bt dodecahedron -d 1.0 2> /dev/null
$GMX solvate -cp rec_newbox.gro -cs spc216.gro -p topol.top -o rec_solv.gro 2> /dev/null
$GMX grompp -f ions.mdp -c rec_solv.gro -p topol.top -o ions.tpr 2> /dev/null
echo SOL | $GMX genion -s ions.tpr -o rec_solv_ions.gro -p topol.top -neutral >& solvate.log

$GMX make_ndx -f rec_solv_ions.gro >& /dev/null <<_EOF
1|13
!a H* & 22
6 | 13
q
_EOF

#echo -e "${PWD##*/}\n`grep "\[" index.ndx | tail -5`"
echo kkk | $GMX make_ndx -f rec_solv_ions.gro -n index.ndx 2> /dev/null | grep HEME

echo 22 | $GMX genrestr -f rec_solv_ions.gro -n index.ndx -o posre_em1.itp 2> /dev/null
echo 23 | $GMX genrestr -f rec_solv_ions.gro -n index.ndx -o posre_em2.itp 2> /dev/null
echo 24 | $GMX genrestr -f rec_solv_ions.gro -n index.ndx -o posre_em3.itp

$GMX grompp -f em1_wat.mdp -c rec_solv_ions.gro -p topol.top -o em1_wat.tpr
  $GMX $MDRUN -v -deffnm em1_wat
$GMX grompp -f em2_h.mdp -c em1_wat.gro -p topol.top -o em2_h.tpr 
  $GMX $MDRUN -v -deffnm em2_h
$GMX grompp -f em3_sc.mdp -c em2_h.gro -p topol.top -o em3_sc.tpr 
  $GMX $MDRUN -v -deffnm em3_sc
$GMX grompp -f em4_mc.mdp -c em3_sc.gro -p topol.top -o em4_mc.tpr 
  $GMX $MDRUN -v -deffnm em4_mc

echo 0 | $GMX trjcat -f em[1-4]*trr -o em_all.trr -n index.ndx 2> /dev/null
echo 0 | $GMX trjconv -s em1_wat.tpr -f em_all.trr -o em_all_noPBC.trr -pbc mol -ur compact -n index.ndx  2> /dev/null
echo 22 | $GMX trjconv -s em1_wat.tpr -f em_all_noPBC.trr -o em_${1%.pdb}_all.pdb -n index.ndx -sep  2> /dev/null
