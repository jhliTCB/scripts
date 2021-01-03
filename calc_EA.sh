#!/bin/bash
usage ()
{
>&2 cat << EOF

simple calculator to calculate barriers using basis_set 2

Usage: ./$0 [OPTIONs} logs 

Options:
   -T: Single point log file of TS using BS2, if ommited, TS freq log using BS1 will be used
   -R: Single point log file of RC using BS2, if ommited, RC freq log using BS1 will be used
   -t: freq log file of TS using BS1; must be presented
   -r: freq log file of RC using BS1; must be presented
   -n: don't print title for each column; if ommited, will print a tile for each column
   -e: energy unit, kcal or kj (/mol), if ommited, kcal will be used

EOF
}

if [ $# -eq 0 ]; then usage; exit 0; fi

while getopts :T:R:t:r:nc:e: opt; do
case $opt in
   T)
   TS=$OPTARG
   ;;
   R)
   RC=$OPTARG
   ;;
   t)
   TS_ZPE=$OPTARG
   ;;
   r)
   RC_ZPE=$OPTARG
   ;;
   e)
   unit=$OPTARG
   ;;
   c)
   column=$OPTARG
   ;;
   n)
   notitle='notitle'
   ;;
   ?)
   echo -e unknow arguments; usage
   exit 1
esac
done

if [[ -z $TS ]] || [[ -z $RC ]]; then TS=$TS_ZPE; RC=$RC_ZPE; fi
if [[ -z $TS_ZPE ]] || [[ -z $RC_ZPE ]]; then echo lack of log files: -t or -r; usage; exit 1; fi 
if [[ -z $unit ]]; then unit='kcal'; fi
i=0
for f in $TS $RC $TS_ZPE $RC_ZPE; do
   if [ $(grep "Normal termination" $f | wc -l) -eq 0 ]; then
      echo "Error: $f is not terminated normally or still running!"
      ((i+=1))
   fi
done
if [[ $i -gt 0 ]]; then echo Aborting due to bad input log files..; exit; fi

ETS=$(grep ' E=' $TS | tail -1 | awk '{print $2}')
ERC=$(grep ' E=' $RC | tail -1 | awk '{print $2}')
ZPE_TS=$(grep "correction=" $TS_ZPE | awk '{print $3}' | uniq)
ZPE_RC=$(grep "correction=" $RC_ZPE | awk '{print $3}' | uniq)

if [[ $unit == 'kj' ]]; then
   EA=$(echo $ETS $ERC | awk '{printf "%0.3f\n", ($1-$2)*2625.5}')
   ZPE_EA=$(echo $ETS $ZPE_TS $ERC $ZPE_RC | awk '{printf "%0.3f\n", ($1+$2-$3-$4)*2625.5}')
elif [[ $unit == 'kcal' ]]; then
   EA=$(echo $ETS $ERC | awk '{printf "%0.3f", ($1-$2)*627.509}')
   ZPE_EA=$(echo $ETS $ZPE_TS $ERC $ZPE_RC | awk '{e=($1+$2-$3-$4)*627.509} END {printf "%0.3f", e}')
else
   echo "wrong unit, usage: -e kcal or -e kj"
   exit 1
fi

if [[ -z $notitle ]]; then
   echo -e "TS_log/entry ener_TS ZPE_TS ener_RC ZPE_RC EA ZPE_EA" \
   | awk '{printf "%38s %24s %12s %24s %12s %10s %10s\n", $1,$2,$3,$4,$5,$6,$7}'
fi

if [[ ! -z $column ]]; then TS=$column; fi # set the name of the first column

echo -e "$TS $ETS $ZPE_TS $ERC $ZPE_RC $EA $ZPE_EA" | awk '{printf "%38s %24s %12s %24s %12s %10s %10s\n", $1,$2,$3,$4,$5,$6,$7}'

