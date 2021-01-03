#!/bin/bash
# index copied from internet
search_array() {
    index=0
    while [ "$index" -lt "${#myArray[@]}" ]; do
        if [ "${myArray[$index]}" = "$1" ]; then
            echo $index
            break
        fi
        ((index+=1))
    done
    #echo ""
}

ITP=$1
COM=$2
RES=$3
NEWPDB=$4
NUM=$(grep "ATOM\|HETATM" $COM | wc -l)
ITP_ATM=($(grep $RES $ITP | awk '{if (NF>10) print}' | awk '{print $5}'))
COM_ATM=($(grep "ATOM\|HETATM" $COM | awk '{print $3}'))

myArray=(${COM_ATM[@]})
rm -f NEWPDB >& /dev/null
for i in $(seq 0 $[NUM-1])
do
   value=${ITP_ATM[$i]}
   line_num=$(search_array $value)
   echo -e "$i\t$value\t$line_num"
   sed -n $[line_num+1]p $COM >> $NEWPDB
done
