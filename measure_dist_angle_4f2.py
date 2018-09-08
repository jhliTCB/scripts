#!/usr/bin/env python
import math
import sys
import MDAnalysis
import numpy as np

if len(sys.argv) < 4:
   print('\nUsage: ' + sys.argv[0] + ' topology trajectory output\n')
   exit(1)

min_dist, max_dist = 2.3, 3.0
min_angl, max_angl = 115.0, 165.0

u = MDAnalysis.Universe(sys.argv[1], sys.argv[2])

atoms = {'H61':'w', 'H62':'w', 'H63':'w', 'H64':'w', 'H65':'w', 'H66':'w', \
         'H58':'w-1', 'H48':'w-2S', 'H49':'w-2R', 'H46':'w-3S', 'H47':'w-3R'}

title = ['#Frame', 'Time(ps)'] + ['within?', 'hydro', 'dist', 'angl', '@'] \
         + list(atoms) + ['dist@angl'] + list(atoms) + ['\n']

OUT = open(sys.argv[3], 'w')
OUT.write(' '.join(str(x) for x in title))
#OUT = open(sys.argv[3], 'a')

for ts in u.trajectory:
   OE = u.select_atoms("resname HEME and name OE")
   FE = u.select_atoms("resname HEME and name FE")
   distance, angle = [], []
   #for atom, site in atoms.items():
   for atom in atoms:
      AT   = u.select_atoms('resname VKK and name ' + atom)
      VOAT = AT.centroid() - OE.centroid()
      VOFE = FE.centroid() - OE.centroid()
      DIST = np.linalg.norm(VOAT)
      COST = np.dot(VOFE, VOAT) / (np.linalg.norm(VOFE) * np.linalg.norm(VOAT))
      DEGS = math.degrees(math.acos(COST))
      distance.append('%.4f' % DIST)
      angle.append('%.4f' % DEGS)

   mdis = min(distance)
   clos = list(atoms)[distance.index(mdis)]
   site = atoms[clos]
   angl = angle[distance.index(mdis)]
   if float(mdis) > min_dist and float(mdis) < max_dist:
      if float(angl) > min_angl and float(angl) < max_angl:
         judge = [site, clos, mdis, angl, '@']
      else:
         judge = ['nan', 'nan', 'nan', 'nan', '@']
   else:
      judge = ['nan', 'nan', 'nan', 'nan', '@']
   TEMP = [ts.frame, ts.time] + judge
   print(' '.join(str(x) for x in TEMP))
   TEMP = [ts.frame, ts.time] + judge + distance + ['@'] + angle + ['\n']
   OUT.write(' '.join(str(x) for x in TEMP))

OUT.close()
