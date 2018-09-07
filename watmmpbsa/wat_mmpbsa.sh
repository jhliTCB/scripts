#!/bin/bash
# WAT_MMPBSA.sh version 2 for amber 16
# by jhli, 2018-09-07
# tree -d $OUT_DIR
# -|  wat-mmpbsa_py
#    -|  respdb/
#    -|  running_dir/
#       -|  public_dry_leap/
#       -|  ${LIG}_${KT}/
#          -|  GB_${igb}_wat${cutoff}/
#          -|  ...
#       -|  ${LIG}_${KT}/
#          -|  GB_${igb}_wat${cutoff}/
#          -|  nmode_dry/
#          -|  ...
#       -|  ${LIG}_${KT}/
#          -|  
#           ...


#Global parameters for job control
source /home/jhli/Program/amber16/rc4amber16_nv8
#source /home/jhli/Program/amber16/rc4amber16_gcc5.4        # for Dell workstation
#export LD_LIBRARY_PATH=/home/jhli/Program:$LD_LIBRARY_PATH # for changepdb on Dell workstation
MD_DIR='/home/yhxue/Select/5veu_SEH_autodock/'  #base dir of the amber MD run
LIG='SEH'                                       #The residue name of the ligand
LIG_NUM='468'                                   #The residue ID of the ligand
inter1='50'                                     #interval of snapshot extraction for wat-mmgbsa
inter2='500'                                    #interval of snapshot extraction for nmode
frame0='50001'                                  #starting_frame
frame1='75000'                                  #ending_frame
TRAJ="${MD_DIR}/anal/process.nc"                #Could be changed for other crd
SOL_TOP="${MD_DIR}/leap/5veu_SEH_sol.top"       #Topology name of the system in the leap dir
WOK_DIR=$PWD                                    #The working directory of this script
OUT_DIR=$WOK_DIR/wat-mmpbsa_py                  #The output directory of all outputs
LIG_prep="$MD_DIR/leap/${LIG}.prepc"            #change if it is not named ${LIG}.prepc
LIG_frcm="$MD_DIR/leap/${LIG}.frcmod"           #change if it is not named ${LIG}.frcmod             
HEME_lib="$MD_DIR/leap/HEC_new2009.lib"         #change if it is not named HEC_new2009.lib
HEM_frcm="$MD_DIR/leap/frcmod.hec2009"          #change if it is not named frcmod.hec2009
CYI_flag='0'                                    #while using other heme parameters, it is 1
load_CYI_prep=''                                #load the CYI's prep file, empty when no CYI
NP='12'                                         #Number of processors for evenly dividing the jobs
rerun_flag='1'                                  #controling flag, if 1 means reruning the script
                                                   #   and ommit the extraction of snapshots
nmflag='1'                                      #if 0, won't perform the nmode calculations
mmflag='1'                                      #if 0, won't perform the MM/GBSA calculations
                                                   #   desired only for re-run the nmode
# Re-run with different igb models and cutoffs using rerun_flag=1
# Re-run with different intervals using rerun_flag=0

#Global mm/pbsa parameters:
sander_use='1'                                  #if 1, will use sander for calculations
igb='7'                                         #GB model for mm/gbsa, igb=1, 2, 5 or 7
saltcon='0.150'                                 #implicit salt concentration, M, mol/L
cutoff='7'                                      #WAT (oxygen) within the cutoff of ligand
ligmask="(:${LIG}@C=,O=)<@${cutoff}&(:WAT@O=)"  #If the ligand contains orther atoms, e.g. N, S
                                                #   then (:${LIG_NUM}@C=,O=,N=,S=)
nmwat='1'                                       #if 0, won't consider any wat in nmode calculations
nmcut='12'                                      #cutoff value for the nmode truncation
nm_igb='1'                                      #The igb parm. for nmode calculations
nm_ist='0.15'                                   #The string strenth used in nmode calculations
FF='leaprc.protein.ff14SB'                      #The force field used in the simulation
gaff='leaprc.gaff2'                             #The GAFF version

# Examples:
# 1). igb=7, cutoff=4, mmflag=1, nmflag=1, nmwat=0, rerun_flag=0
# 2). igb=7, cutoff=4, mmflag=0, nmflag=1, nmwat=1, rerun_flag=1
# 3). igb=5, cutoff=4, mmflag=1, nmflag=0, nmwat=1, rerun_flag=1
# 4). igb=5, cutoff=7, mmflag=1, nmflag=0, nmwat=1, rerun_flag=1
# 5). igb=5, cutoff=7, mmflag=0, nmflag=1, nmwat=1, rerun_flag=1

# Amber modules
CPPTRAJ="$AMBERHOME/bin/cpptraj"
TLEAP="$AMBERHOME/bin/tleap"
AMBPDB="$AMBERHOME/bin/ambpdb"
MMPBSA="$AMBERHOME/bin/MMPBSA.py"
AMBMASK="$AMBERHOME/bin/ambmask"
CHANGEPDB="/home/jhli/Program/changepdb"


### input files were inserted inside the functions
### EXTRC_RES(); PBSA_IN(); LEAP_IN(); MM_IN;

EXTRC_RES () {
LL=$[LIG_NUM-1]
# Change the start_frame,  the end_frame, or the interval for the other needs
cat <<_EOF
trajin $TRAJ $frame0 $frame1 $inter1
rms first mass :1-${LL}@CA,C,N
trajout ${LIG}.res restart
_EOF
}

PBSA_IN () {
# GB: igb=1,2,5 or 7; or igb=2,saltcon=0.100
# PB: istrng=0.100; or istrng=0.150
cat <<_EOF
Input file for running PB and GB in serial
&general
   startframe=SSS
   endframe=SSS
   keep_files=2, use_sander=${sander_use},
   strip_mask=':Na+|:Cl-|:WAT&!(@WWW)'
   strip_mask=':Na+|:Cl-|:DRY'
/
&gb
  igb=$igb, saltcon=$saltcon,
/
_EOF
}

LEAP_IN () {
# be carefull of the name of HEC parameter files
cat <<_EOF

addAtomTypes {
        { "SP"  "S" "sp3" }
        { "CX"  "C" "sp2" }
        { "CY"  "C" "sp2" }
        { "NO"  "N" "sp2" }
        { "NP"  "N" "sp2" }
        { "HX"  "H" "sp3" }
        { "FE"  "Fe" "sp3" }
}

source $FF
source $gaff
source leaprc.water.tip3p

loadamberprep ${LIG_prep}
loadamberparams ${LIG_frcm}
loadamberparams ${HEM_frcm}
loadoff ${HEME_lib}
$load_CYI_prep
set default PBradii mbondi2
p=loadpdb SSS.pdb
saveamberparm p SSS.top SSS.crd
quit
_EOF
}

MM_IN () {
cat <<_EOF
Input file for running PB and GB in serial
&general
   startframe=1
   endframe=1
   keep_files=2,
   use_sander=${sander_use},
/
&nmode
   nmode_igb=${nm_igb}, nmode_istrng=${nm_ist},
/
_EOF
}

### The changepdb module and SLEEP

TRUNCATION() {
PDB=$1
#LIG=$2; The ligand residue name is already global
$CHANGEPDB <<_EOF
$PDB
fix
temp_auto
m
n
y


$LIG
$nmcut
n
y
com_auto_tr${nmcut}.pdb
y
n
q
_EOF

if [ $nmwat -eq 0 ]; then
   sed -i /WAT/d com_auto_tr${nmcut}.pdb
fi

$CHANGEPDB <<_EOF
com_auto_tr${nmcut}.pdb
ter
1
w

q
_EOF

(($((`grep $LIG com_auto_tr${nmcut}.pdb | wc -l`%2))==0)) && \
sed "/${LIG}/{n;n;d}" com_auto_tr${nmcut}.pdb > rec_temp.$USER || \
sed "/${LIG}/{n;d}"   com_auto_tr${nmcut}.pdb > rec_temp.$USER

sed /${LIG}/d rec_temp.$USER > rec_auto_tr${nmcut}.pdb
grep "${LIG}" rec_temp.$USER > lig_auto_tr${nmcut}.pdb

rm rec_temp.$USER
}

SLEEP() {
a=$1
b=$2
np=$3
sleep $a
CPU=`ps -ef | grep ${USER} | grep FINAL | grep energy | wc -l`
while [ $CPU -ge $np ]; do
   sleep $b
   CPU=`ps -ef | grep ${USER} | grep FINAL | grep energy | wc -l`
done
}

### The script starts here
mkdir -p $OUT_DIR/
cd $OUT_DIR/
mkdir -p respdb running_dir

# extract snapshots and WAT info.
cd $OUT_DIR/respdb
if [ $rerun_flag -eq 0 ]; then
   EXTRC_RES > $OUT_DIR/extract-res.in
   $CPPTRAJ -p $SOL_TOP < $OUT_DIR/extract-res.in >& $OUT_DIR/log_cpptraj
   
   snpnum=$(ls -l | grep "^-" | wc -l)
   frameid=$frame0
   for i in $(seq -w 1 $snpnum); do
      j=$(echo $i | sed 's/^000//g; s/^00//g; s/^0//g')
      mv ${LIG}.res.${j} ${LIG}_${frameid}_res.${i}
      ((frameid+=$inter1))
   done
   
   for f in *res*; do
      pdbnam=$(echo $f | sed s/res/RES/g)
      echo -e "${PWD}/${pdbnam}.pdb" >> $OUT_DIR/pdb.lst
      ambpdb -aatm -p ${SOL_TOP} -c $f > ${pdbnam}.pdb
   done
fi

#Find the wat using ambmask
if [ $cutoff -gt 0 ]; then
   j=0
   rm -f ${OUT_DIR}/mask_at_wat${cutoff}.dat >& /dev/null
   for f in *res*; do
      mask=''
      watnum=0
      WO=$($AMBMASK -p ${SOL_TOP} -c $f -prnlev 0 -out amber -find "$ligmask" 2> /dev/null | awk '{print $3}')
      echo $WO
      if [ $(echo $WO | wc -w) -gt 0 ]; then
         for i in $WO; do
            if [ $watnum -eq 0 ]; then
               mask=${i}",$[i+1],$[i+2]"
            else
               mask=${mask}",${i},$[i+1],$[i+2]"
            fi
            ((watnum+=1))
         done
      fi 
      ((j+=1))
      #Note that there is "_" in the $f
      echo -e "frame-${j}_${f}_${watnum}_${mask}" >> ${OUT_DIR}/mask_at_wat${cutoff}.dat
   done
fi


cd ${OUT_DIR}/running_dir
echo "# Dry snpshot list at igb${igb}_wat${cutoff}" > DRY_igb${igb}_wat${cutoff}.lst

# Run the MMPBSA:
j=0
for KT in $(seq -w $frame0 ${inter1} $frame1); do
   echo ${LIG}_${KT} 
   if [ $mmflag -eq 0 ]; then break; fi
   
   frameID=$(echo -e $KT | sed 's/^000//g; s/^00//g; s/^0//g')
   ((j+=1))
   SOLPDB=$(sed -n ${j}p $OUT_DIR/pdb.lst)
   watnum=$(grep "frame-${j}_${LIG}" ${OUT_DIR}/mask_at_wat${cutoff}.dat | cut -f5 -d'_') && echo $watnum
   ((watnum*=3))  # include the wat's hydrogen into account
   
   mkdir -p ${LIG}_${KT}   
   cd ${LIG}_${KT}
   mkdir -p GB_igb${igb}_wat${cutoff}
   cd GB_igb${igb}_wat${cutoff}
   
   if [ $watnum -eq 0 ]; then
      echo -e "${LIG}_${KT}" >> $OUT_DIR/running_dir/DRY_igb${igb}_wat${cutoff}.lst #note there is dry snapshot
      PBSA_IN | sed "s/SSS/$frameID/g; /WWW/d; s/DRY/WAT/g" > mmpbsa.in
      
      if [ ! -d ${OUT_DIR}/running_dir/public_dry_leap ] || [ ! -f ${OUT_DIR}/running_dir/public_dry_leap/lig.top ]; then
         mkdir -p ${OUT_DIR}/running_dir/public_dry_leap
         cd ${OUT_DIR}/running_dir/public_dry_leap
         sed "/WAT/d; /Cl/d; /Na/d; /$LIG/d; /END/d; /REMARK/d" $SOLPDB > rec.pdb
         echo -e "$(grep -w $LIG $SOLPDB)" > lig.pdb
         cat rec.pdb lig.pdb > com.pdb
         for f in com rec lig; do
            LEAP_IN | sed s/SSS/$f/g > leap.mm.pbsa.in
            $TLEAP -f leap.mm.pbsa.in >& /dev/null
         done
         cd ${OUT_DIR}/running_dir/${LIG}_${KT}/GB_igb${igb}_wat${cutoff}
      fi
      # Run the mm/pbsa for no WAT found snapshots
      DRY="${OUT_DIR}/running_dir/public_dry_leap"
      $MMPBSA -O -i mmpbsa.in -o FINAL_MMPBSA.dat -eo energy.csv -sp $SOL_TOP -cp $DRY/com.top -rp $DRY/rec.top -lp $DRY/lig.top -y $TRAJ >& log &
      cd ${OUT_DIR}/running_dir
      
   else
      mask=$(grep "frame-${j}_${LIG}" ${OUT_DIR}/mask_at_wat${cutoff}.dat | cut -f6 -d'_')
      PBSA_IN | sed "s/SSS/$frameID/g; s/WWW/$mask/g; /DRY/d" > mmpbsa.in
      
      WAT=''
      for k in $(seq 1 $watnum); do
         aid=$(echo $mask | cut -f${k} -d',')
         #echo $SOLPDB $aid
         ind=$(awk '{printf " %s \n", $2}' $SOLPDB | grep -n " $aid " | cut -f 1 -d':')
         WAT=${WAT}"$(sed -n ${ind}p $SOLPDB)"'\n'
      done
      echo -e "$(sed "/WAT/d; /Cl/d; /Na/d; /$LIG/d; /END/d; /REMARK/d" $SOLPDB)\n${WAT}" > rec.pdb
      echo -e "$(grep -w $LIG $SOLPDB)" > lig.pdb
      echo -e "$(sed "/WAT/d; /Cl/d; /Na/d; /END/d; /REMARK/d" $SOLPDB)\n${WAT}" > com.pdb
      for f in com rec lig; do
         LEAP_IN | sed s/SSS/${f}/g > leap.mm.pbsa.in
         $TLEAP -f leap.mm.pbsa.in >& /dev/null
      done
      # Run the mm/pbsa for WAT found snapshots
      cd ${OUT_DIR}/running_dir/${LIG}_${KT}/GB_igb${igb}_wat${cutoff}
      time $MMPBSA -O -i mmpbsa.in -o FINAL_MMPBSA.dat -eo energy.csv -sp $SOL_TOP -cp com.top -rp rec.top -lp lig.top -y $TRAJ >& log &
      cd ${OUT_DIR}/running_dir
   fi
   
   echo "Running MM/PB/GBSA at ${LIG}_${KT}/GB_igb${igb}_wat${cutoff}"
   SLEEP 1 2 $NP
done

SLEEP 1 5 1

# Run  nmode:
cd ${OUT_DIR}/running_dir
if [ $nmwat -eq 1 ]; then
   NM_DIR="nmode_wat${cutoff}"
else
   NM_DIR="nmode_dry"
fi

echo "# nmode directories at $NM_DIR" > ${NM_DIR}.lst

if [ $nmflag -eq 1 ]; then
   j=1
   for KT in $(seq -w $frame0 ${inter2} $frame1); do
      #mv ${LIG}_${KT} ${LIG}_${KT}_nmode
      if [ ! -d ${LIG}_${KT} ]; then
         echo -e "The nmode interaval is not set propaly\n"
         exit 1
      fi
      cd ${LIG}_${KT}
      mkdir -p $NM_DIR
      echo -e "${LIG}_${KT}/${NM_DIR}" >> ${OUT_DIR}/running_dir/${NM_DIR}.lst
      cd $NM_DIR
      ((delta=$inter2 / $inter1))
      if [ -f ../GB_igb${igb}_wat${cutoff}/com.pdb ] || [ -f ../GB_igb${igb}_wat${cutoff}/com.pdb.bz2 ]; then
         bzip2 -d ../GB_igb${igb}_wat${cutoff}/com.pdb.bz2 >& /dev/null
         PDBNAME="../GB_igb${igb}_wat${cutoff}/com.pdb"
      else
         SOLPDB=$(sed -n ${j}p $OUT_DIR/pdb.lst)
         echo $SOLPDB
         sed "/WAT/d; /Cl/d; /Na/d; /$LIG/d; /END/d; /REMARK/d" $SOLPDB > rec.pdb
         echo -e "$(grep -w $LIG $SOLPDB)" > lig.pdb
         cat rec.pdb lig.pdb > com.pdb         
         PDBNAME="com.pdb"
      fi
      echo $PDBNAME
      TRUNCATION $PDBNAME | grep -A 5 Overwrite | sed /^$/d | sed /Overwrite/d >& trim_atoms_ress
      for i in com_auto_tr${nmcut} rec_auto_tr${nmcut} lig_auto_tr${nmcut}; do
         /home/jhli/Program/remove_amber_H.py ${i}.pdb TEMPPDB
         mv TEMPPDB ${i}.pdb
         LEAP_IN | sed s/SSS/${i}/g > leap.mm.pbsa.in 
         $TLEAP -f leap.mm.pbsa.in >& /dev/null
      done
   
      MM_IN > mmpbsa.in
      # Run the nmode in background
      time MMPBSA.py -O -i mmpbsa.in -o FINAL.dat -eo energy.csv -cp com_auto_tr${nmcut}.top -rp rec_auto_tr${nmcut}.top -lp lig_auto_tr${nmcut}.top -y com_auto_tr${nmcut}.crd >& log &
      echo "${LIG}_${KT} nmoding: $NM_DIR" 
      SLEEP 1 10 $NP
      ((j+=$delta))
      cd ${OUT_DIR}/running_dir
   done
fi

SLEEP 1 10 1

#bzip2 the temp files:
cd ${OUT_DIR}/running_dir
find | grep "_MMPBSA_\|/com\|/rec\|/lig\|log$" | sed /bz2/d | xargs bzip2 &

# Summary
cd ${OUT_DIR}/running_dir
if [ $mmflag -eq 1 ]; then
   /home/jhli/Program/summary.py GB_igb${igb}_wat${cutoff} ${LIG}_*
elif [ $nmflag -eq 1 ]; then
   /home/jhli/Program/summary.py $NM_DIR ${LIG}_*
#else
   # Run the py script alone!
fi
