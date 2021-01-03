LIG=$1
pro=$2
module load gromacs/5.0.4
#echo 0 | gmx genrestr -f $lig -o posre_${lig:0:3}.itp
GMX='gmx_mpi'
#./re-return_pdb.py temp.pdb $pro noH_$pro
#PRO="noH_$pro"
PRO=$pro
echo 1 | $GMX pdb2gmx -f $PRO -water tip3p -o rec.gro >& log_pdb2gmx
check1=`grep Linking log_pdb2gmx | wc -l`
if [ $check1 -lt 2 ]
then
   echo something wrong in definding bonds!
   exit
fi

sed -i '/posre.itp/a #endif\n#ifdef em1_wat\n#include "posre_em1.itp"\n#endif\n#ifdef em2_h\n#include "posre_em2.itp"\n#endif\n#ifdef em3_sc\n#include "posre_em3.itp"' topol.top
sed -i '/posre_em3.itp/a #endif\n\n; Ligand\n#include "vkk.itp"\n#ifdef POSRES\n#include "posre_vkk.itp"\n#endif\n#ifdef em1_wat\n#include "posre_vkk.itp"\n#endif\n#ifdef em2_h\n#include "posre_vkk.itp"\n#endif\n#ifdef em3_sc\n#include "posre_vkk.itp"' topol.top
sed -i '/forcefield.itp/a  #include "vkk.prm"' topol.top
echo -e "VKK                 1" >> topol.top

${GMX} editconf -f rec.gro -o rec.pdb
cat rec.pdb $LIG | sed s/UNK/VKK/g | grep "^ATOM\|^HETATM" > com.pdb

$GMX editconf -f com.pdb -o com.gro
$GMX editconf -f com.gro -o com_newbox.gro -bt dodecahedron -d 1.0
$GMX solvate -cp com_newbox.gro -cs spc216.gro -p topol.top -o com_solv.gro
$GMX grompp -f ions.mdp -c com_solv.gro -p topol.top -o ions.tpr
echo SOL | $GMX genion -s ions.tpr -o com_solv_ions.gro -p topol.top -neutral
$GMX make_ndx -f com_solv_ions.gro >& /dev/null <<_EOF
1|13
!a H* & 24
6 | 13
1|13|14
q
_EOF

#echo -e "${PWD##*/}\n`grep "\[" index.ndx | tail -5`"
echo KKKDSKSD | $GMX make_ndx -f com_solv_ions.gro -n index.ndx 2> /dev/null | grep HEME

echo 24 | $GMX genrestr -f com_solv_ions.gro -n index.ndx -o posre_em1.itp
echo 25 | $GMX genrestr -f com_solv_ions.gro -n index.ndx -o posre_em2.itp
echo 26 | $GMX genrestr -f com_solv_ions.gro -n index.ndx -o posre_em3.itp

$GMX grompp -f em1_wat.mdp -c com_solv_ions.gro -p topol.top -o em1_wat.tpr
$GMX mdrun -deffnm em1_wat
$GMX grompp -f em2_h.mdp -c em1_wat.gro -p topol.top -o em2_h.tpr
$GMX mdrun -deffnm em2_h
$GMX grompp -f em3_sc.mdp -c em2_h.gro -p topol.top -o em3_sc.tpr
$GMX mdrun -deffnm em3_sc
$GMX grompp -f em4_mc.mdp -c em3_sc.gro -p topol.top -o em4_mc.tpr
$GMX mdrun -deffnm em4_mc
#$GMX grompp -f nvt.mdp -c em4_mc.gro  -p topol.top -o nvt.tpr -n index.ndx
#$GMX mdrun -deffnm nvt
#$GMX grompp -f npt.mdp -c nvt.gro -p topol.top -o npt.tpr -n index.ndx
#$GMX mdrun -deffnm npt
echo 0 | $GMX trjcat -f em[1-4]*trr -o em_all.trr -n index.ndx 2> /dev/null
echo 0 | $GMX trjconv -s em1_wat.tpr -f em_all.trr -o em_all_noPBC.trr -pbc mol -ur compact -n index.ndx  2> /dev/null
echo 27 | $GMX trjconv -s em1_wat.tpr -f em_all_noPBC.trr -o em_${PWD##*/}_all.pdb -n index.ndx -sep  2> /dev/null
