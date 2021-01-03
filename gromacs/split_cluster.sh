#!/bin/bash
sed -n '/MODEL        1/, /MODEL        2/p' ${2} | sed '/TITLE/d;/END/d;/MODEL/d;/TER/d' > ${1}_1major.pdb
sed -n '/MODEL        2/, /MODEL        3/p' ${2} | sed '/TITLE/d;/END/d;/MODEL/d;/TER/d' > ${1}_2second.pdb
sed -n '/MODEL        3/, /MODEL        4/p' ${2} | sed '/TITLE/d;/END/d;/MODEL/d;/TER/d' > ${1}_3third.pdb
