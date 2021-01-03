ml amber/16
prefix=$1
antechamber -fi gout -fo ac -i ${prefix}.log -o ${prefix}_resp.ac -c resp -ge ${prefix}.esp -pf y
antechamber -fi ac -i ${prefix}_resp.ac -c wc -cf ${prefix}.crg -pf y
antechamber -fi pdb -i ${prefix}.pdb -c rc -cf ${prefix}.crg -fo ac -o ${prefix}_resp_pdb.ac -pf y
#atomtype -i ${prefix}_resp_pdb.ac -o ${prefix}_resp_pdb_gaff.ac -p gaff
prepgen -i ${prefix}_resp_pdb.ac -o ${prefix}.prepc -f car -rn $2
parmchk2 -i ${prefix}.prepc -o ${prefix}.frcmod -f prepc
