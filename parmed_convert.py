#!/usr/bin/env python
# convert amber topology to gromacs
import parmed as pmd
import sys
if len(sys.argv) < 2:
    print("Error, please input at least the topology\n")
    exit(1)
top = sys.argv[1]

if len(sys.argv) == 3:
    crd = sys.argv[2]
    parm = pmd.load_file(top, crd)
    parm.save(top.split('.')[0] + '.top', format='gromacs')
    parm.save(crd.split('.')[0] + '.gro')
else:
    parm = pmd.load_file(top)
    parm.save(top.split('.')[0] + '.top', format='gromacs')


