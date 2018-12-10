#for f in *.log; do echo -e "${f}\t$(grep Frequencies $f | head -1)\t$(grep ' E= ' $f | tail -1)\t$(grep 'correction=' $f | awk '{print $3}')"; done | sort -k1

if [ -z $1 ]
then
   echo log file needed
   exit
fi

for f in $(echo $*); do
   if [ $f = 'SP' ]; then
      flag='SP'
   elif [ $f = 'freq' ]; then
      flag='freq'
   fi
done

echo $flag
if [ $flag != 'SP' ] && [ $flag != 'freq' ]; then
   echo "please tell the type of log: SP | freq; could be in any position of the arguments"
   exit
fi

get_ener()
{
log=$1
flag=$2
if [ $flag = 'SP' ]; then
   Title=$(echo -e "#Log_name ONIOM_low-model ONIOM_high-model ONIOM_low-real ONIOM_extr" | awk '{printf "%24s%18s%24s%18s%24s\n", $1,$2,$3,$4,$5}')
elif [ $flag = 'freq' ]; then
   Title=$(echo -e "#Log_name freq1 freq2 freq3 ZPE ONIOM_low-model ONIOM_high-model ONIOM_low-real ONIOM_extr" | awk '{printf "%24s%10s%7s%7s%12s%18s%24s%18s%24s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9}')
   Freq=$(grep Frequencies $log | head -1 | awk '{print $3,$4,$5}')
   ZPE=$(grep 'correction=' $log | awk '{print $3}')
fi

if [ ! -z $3 ] && [ $3 = 'Title' ]
then
   echo "$Title"
fi

grep -A1 -B5 "ONIOM: extr" $log | tail -6 > .tmp4_get_oniom_ener.tmp
OLM=$(sed -n 2p .tmp4_get_oniom_ener.tmp | awk '{print $NF}')
OHM=$(sed -n 3p .tmp4_get_oniom_ener.tmp | awk '{print $NF}')
OLR=$(sed -n 4p .tmp4_get_oniom_ener.tmp | awk '{print $NF}')
OE=$(sed -n 5p .tmp4_get_oniom_ener.tmp | awk '{print $NF}')

if [ $flag = 'SP' ]; then
   echo -e "$log $OLM $OHM $OLR $OE" | awk '{printf "%24s%18.12f%24.12f%18.12f%24.12f\n", $1,$2,$3,$4,$5}'
elif [ $flag = 'freq' ]; then
   echo -e "$log $Freq $ZPE $OLM $OHM $OLR $OE" | awk '{printf "%24s%10.1f%7.1f%7.1f%12.6f%18.12f%24.12f%18.12f%24.12f\n", $1,$2,$3,$4,$5,$6,$7,$8,$9}'
fi
#rm -f .tmp4_get_oniom_ener.tmp
}

i=1
for f in $(echo $*); do
   if [ ! -f $f ]; then
      echo "$f not found!"
      continue
   fi
   if [ $f != $flag ] && [ $i -eq 1 ]; then
      get_ener $f $flag 'Title'
      ((i+=1))
   elif [ $f != $flag ]; then
      get_ener $f $flag
   fi
done
