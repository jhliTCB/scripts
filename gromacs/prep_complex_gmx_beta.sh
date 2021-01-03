# runnig pwd: /data/4F2/1-new_redo/MD/model_based_on_rabbit_4B1/cut_N20_charmm36/mod268_rigid_docking_cpd1_beskow_r1.0
SYS=${PWD##*/}
lig=${SYS:5:3}
grep ${lig^^} /data/4F2/1-new_redo/MD/model_based_on_rabbit_4B1/mod268_rigid_docking_cpd1_MDs_rackham/${SYS}/com.pdb > ${SYS}.pdb
cp ../new_mdps_r1.0/*.mdp .
sed -i s/LIG/${lig^^}/g nvt.mdp
sed -i s/LIG/${lig^^}/g npt.mdp
sed -i s/LIG/${lig^^}/g md.mdp
cp ../ligands_gen_by_Cgenff/${lig}* .
cp ../rec* ../topol.top ../posre.itp ../*.dat .
cp -r ../charmm36-nov2016-cpdI_GUU.ff  .
sed -i s/lig/${lig}/g topol.top
sed -i s/LIG/${lig^^}/g topol.top
lig_name="${lig}_ini.pdb"

module load gromacs/2016-3-plumed
GMX='gmx_mpi'

echo 0 | $GMX genrestr -f $lig_name -o posre_${lig_name:0:3}.itp

cat rec.pdb ${SYS}.pdb > com.pdb

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
$GMX grompp -f nvt.mdp -c em4_mc.gro  -p topol.top -o nvt.tpr -n index.ndx
#$GMX mdrun -deffnm nvt
#$GMX grompp -f npt.mdp -c nvt.gro -p topol.top -o npt.tpr -n index.ndx
#$GMX mdrun -deffnm npt

