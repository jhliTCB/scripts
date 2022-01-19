#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# remove hydrogen atoms of protein
import sys

#a = open('./step5_assembly_charm2amber.pdb', 'r')
a = open(sys.argv[(1)], 'r')
b = open(sys.argv[(2)], 'w')
water = ['WAT', 'HOH', 'TIP3', 'SOL']
NEW = []
for line in a:
    if line[0:4] in ['ATOM', 'HETA']:
        if line[17:21].strip() == 'HIS':
            line = line.replace('HIS', 'HID')
        if line[17:21].strip() in water:
            NEW.append(line)
        elif line[12:17].strip()[0] != 'H' and line[75:79].strip() != 'H':
            NEW.append(line)
    else:
            NEW.append(line)
      # rewrite it for gmx pdb
      #elif not line[2][0] in [str(j) for j in range(0, 10)]\
      #   and not line[2][1] == 'H':
      #   NEW.append(ii)


b.write(''.join(NEW))
