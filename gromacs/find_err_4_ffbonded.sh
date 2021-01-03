#!/bin/bash
# If the topology types were not writen in topol.top, please use the included .itp file
top=$1
log=$2

get_type()
{
for j in $*; do
        LN=$(awk '{print $1}' atm_typ_in_topol | grep -n "^${j}$" | cut -f1 -d":")
        # $1: atom_number; $2 atom_type; $4 residue; $5 atom_name
        sed -n ${LN}p atm_typ_in_topol | awk '{print $1, $2, $4, $5}'
done
}

sed -n "/\[ atoms/, /\[ bonds/"p ${top} | sed /^$/d | sed /"\["/d > atm_typ_in_topol
err_lines=$(grep ERROR ${log} | awk '{print $6}' | sed s/"\]\:"//g)
#err_lines_num=$(echo -e "$err_lines" | wc -l)

echo > err_atm_num.tmp
for i in $err_lines; do
	atom_list=$(sed -n ${i}p ${top} | awk '{$NF=""; print}')
	func_type=$(sed -n ${i}p ${top} | awk '{print $NF}')
	sed -n ${i}p ${top} >> err_atm_num.tmp # for comparing
	get_type $atom_list > entry.tmp
        atm_type=$(awk '{print $2}' entry.tmp | tr "\n" "\ ")
	atm_name=$(awk '{print $4}' entry.tmp | tr "\n" "\ ")
	res_name=$(awk '{print $3}' entry.tmp | tr "\n" "\ ")
	atm_num=$(awk '{print $1}' entry.tmp | tr "\n" "\ ")
	echo -e "${func_type} ${atm_type}_${atm_name}_${res_name}" >> missed_types
done

cat missed_types | cut -f1 -d"_" | sed /^$/d | sort | uniq > temp.temp
awk 'NF==3 {print}' temp.temp > missed_types.uniq
awk 'NF==4 {print}' temp.temp >> missed_types.uniq
awk 'NF==5 {print}' temp.temp >> missed_types.uniq

rm -f atm_typ_in_topol entry.tmp
