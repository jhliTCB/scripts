#!/usr/bin/env python2

# load the anaconda first, module load python/anaconda2
import parmed as pmd
import sys
MyTop = sys.argv[(1)]
MyCrd = sys.argv[(2)]
out_top = sys.argv[(3)]
out_gro = sys.argv[(4)]
parm = pmd.load_file(MyTop, MyCrd)
parm.save(out_top, format='gromacs')
parm.save(out_gro)
