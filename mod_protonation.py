#!/usr/bin/env python
## -*- coding: utf-8 -*-

import sys

def USAGE():
    sys.stdout.write('\nNO input!\n')
    sys.stdout.write('USAGE: "%s" PDB_NAME.pdb pka_list_file output_pdb\n' % sys.argv[0])
    sys.stdout.write('pka_list_file example: PDB_NAME HIP28 HIE30 HIP54 HID402 GLH320 CYI442\n\n')
    sys.stdout.flush()

def get_pka(pka, PDB):
    pkalst = 0
    for f in open(pka, 'r'):
        target_pdb = f.strip().split()[0] + '.pdb'
        if target_pdb == PDB:
            pkalst = [x for x in f.split()]
    if pkalst is 0:
        sys.stdout.write('The input "%s" is not in the pka_list file, please check!\n' % PDB)
        sys.stdout.flush()
        exit(1)
    return pkalst


if len(sys.argv) < 4:
    USAGE()
    exit(1)

origin_PDB = sys.argv[1]
pka_list   = sys.argv[2]
newpdb     = sys.argv[3]

ilist = get_pka(pka=pka_list, PDB=origin_PDB)
idlst = [x[0] + x[3:] for x in ilist]

title = 'TITLE     ' + origin_PDB.strip('\.pdb') + '\n'
outpdb = open(newpdb, 'w')
outpdb.write(title)

for line in open(origin_PDB, 'r'):
    if line[0:4] not in ['ATOM', 'HETA']:
        continue
    #rep_line.append(line.rstrip('\n'))
    resname = str(line[17:21]).strip()
    resid = str(line[22:26]).strip()
    res = str(line[17:26]).strip()
    
    if resname[0] + resid in idlst:
        ind = idlst.index(resname[0] + resid)
        newres = ilist[ind][0:3]
        NL = line.replace(resname, newres)
        #print(NL.strip('\n'))
        outpdb.write(NL)
        continue
    
    outpdb.write(line)

outpdb.close()
sys.stdout.write('Done for "%s"\n\n' % origin_PDB)
sys.stdout.flush()
