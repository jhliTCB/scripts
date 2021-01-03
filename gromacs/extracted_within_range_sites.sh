!/bin/bash
# input comes from ~/scripts/get_H_dist_angl.py
# site: w, w-1 or w-2
site=$2
input=$1

if [ -z $1 ]
then
   exit
fi

vmd_lst=$(grep "$site " $input | awk '{print $2}')
mkdir -p site_snapshots

for vmd_frame in $vmd_lst
do
   frame=$[vmd_frame-1]
   gmx_ps=$[frame*2] # (vmd_frame - 1) * 400 / 200000 * 1000
   echo 27 | gmx_mpi trjconv -s npt.tpr -f run400ns_noPBC.xtc -o ./site_snapshots/${site}_${gmx_ps}_${vmd_frame}.pdb -b $gmx_ps -e $gmx_ps -dt 1 -n index.ndx
   #or less residues
#  echo 28 | gmx_mpi trjconv -s npt.tpr -f run400ns_noPBC.xtc -o ./site_snapshots/${site}_${gmx_ps}_${vmd_frame}.pdb -b $gmx_ps -e $gmx_ps -dt 1 -n heme_vkk.ndx
done
