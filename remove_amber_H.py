#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# remove hydrogen atoms of protein
import sys

a = open(sys.argv[(1)], 'r')
b = open(sys.argv[(2)], 'w')

NEW = []
for ii in a:
   line = [i for i in ii.split()]
   if len(line) < 7:
      NEW.append(ii)
   elif line[3] == 'WAT':
      NEW.append(ii)
   else:
      if not line[2][0] == 'H':
         NEW.append(ii)
      # rewrite it for gmx pdb
      #elif not line[2][0] in [str(j) for j in range(0, 10)]\
      #   and not line[2][1] == 'H':
      #   NEW.append(ii)


b.write(''.join(NEW))
