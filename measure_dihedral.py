#!/usr/bin/env python
import math
import sys
import MDAnalysis
import numpy as np

if len(sys.argv) < 4:
   print('\nUsage: ' + sys.argv[0] + ' topology trajectory output\n')
   exit(1)


u = MDAnalysis.Universe(sys.argv[1], sys.argv[2])

dih1_lst = ['H58', 'C15', 'C11', 'C10']
dih2_lst = ['C15', 'C11', 'C10', 'C8']


def calc_dihd(dih_lst, traj, lig_sele):
   AST = [traj.select_atoms(lig_sele + dih_lst[x]) for x in range(0,4)]
   VBA = AST[0].centroid() - AST[1].centroid()
   VBC = AST[2].centroid() - AST[1].centroid()
   VCB = AST[1].centroid() - AST[2].centroid()
   VCD = AST[3].centroid() - AST[2].centroid()
   n1  = np.cross(VBA, VBC)
   n2  = np.cross(VCB, VCD)
   coD = np.dot(n1, n2) / (np.linalg.norm(n1) * np.linalg.norm(n2))
   cod = float('%.6f' % coD)
   if np.dot(n1, VCD) < 0:
      DEG = math.degrees(math.acos(cod))
   else:
      DEG = -1.0 * math.degrees(math.acos(cod))
   return('%.4f' % DEG)

title = ['#Frame', 'Time(ps)', 'D1', 'D2', 'conf', '\n']

OUT = open(sys.argv[3], 'w')
OUT.write(' '.join(str(x) for x in title))
#OUT = open(sys.argv[3], 'a')
lig_sele = 'resname VKK and name '

for ts in u.trajectory:
   dih1 = float(calc_dihd(dih1_lst, u, lig_sele))
   dih2 = float(calc_dihd(dih2_lst, u, lig_sele))
   if -90.0 < dih1 < -30.0 or 30.0 < dih1 < 90.0:
      if -180.0 < dih2 < -150.0 or 150.0 < dih2 < 180.0:
         att = 'CONF1'
      elif -90.0 < dih2 < -30.0 or 30.0 < dih2 < 90.0:
         att = 'CONF2'
      else:
         att = 'other'
   else:
         att = 'other'

   TEMP = [ts.frame, ts.time, dih1, dih2, att, '\n']
   OUT.write(' '.join(str(x) for x in TEMP))

OUT.close()
