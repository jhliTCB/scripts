#for f in *.log; do echo -e "${f}\t$(grep Frequencies $f | head -1)\t$(grep ' E= ' $f | tail -1)\t$(grep 'correction=' $f | awk '{print $3}')"; done | sort -k1

if [ -z $1 ]
then
   echo log file needed
   exit
fi

if [ ! -z $2 ] && [ $2 = 'Title' ]
then
   echo -e "\n#Log_name freq1 freq2 freq3 ZPE ONIOM_low-model ONIOM_high-model ONIOM_low-real ONIOM_extr" | awk '{printf "%20s%10s%7s%7s%12s%18s%24s%18s%24s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9}'
fi

log=$1
Freq=$(grep Frequencies $log | head -1 | awk '{print $3,$4,$5}')
ZPE=$(grep 'correction=' $log | awk '{print $3}')

grep -A1 -B5 "ONIOM: extr" $log | tail -6 > tmp.tmp

OLM=$(sed -n 2p tmp.tmp | awk '{print $NF}')
OHM=$(sed -n 3p tmp.tmp | awk '{print $NF}')
OLR=$(sed -n 4p tmp.tmp | awk '{print $NF}')
OE=$(sed -n 5p tmp.tmp | awk '{print $NF}')

echo -e "$log $Freq $ZPE $OLM $OHM $OLR $OE" | awk '{printf "%20s%10.1f%7.1f%7.1f%12.6f%18.12f%24.12f%18.12f%24.12f\n", $1,$2,$3,$4,$5,$6,$7,$8,$9}'
rm -f tmp.tmp
