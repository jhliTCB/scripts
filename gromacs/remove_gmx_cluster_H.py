#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import sys

a = open(sys.argv[(1)], 'r')
b = open(sys.argv[(2)], 'w')
#a = open('/home/jhli/cl50_100_1major.pdb', 'r')
#b = open('/home/jhli/ffffffffffffffff.pdb', 'w')

num_hydro = ['1H', '2H', '3H', '4H', '5H', '6H']
pdbformat1 = "%-6s%5s %-5s%-4s %4s    %8s%8s%8s%6s%6s"
pdbformat2 = "%-6s%5s  %-4s%-4s %4s    %8s%8s%8s%6s%6s"

NEW = []

for i in a:
    line = [ ii for ii in i.split()]
    if len(line) < 9:
        continue
    #print (line)
    if not line[3] == 'HEME' and not line[3] == 'HEM':
        #print (line)
        #if 'H' not in line[2]:
        #    print (line)
        if line[2][0] == 'H':
            continue
        elif line[2][0:2] in num_hydro:
            #print line[2][0:2]
            continue
        else:
            if len(line[2]) > 3:
                NEW.append(pdbformat1 % tuple(line))
            else:
            #NEW.append(' '.join(line))
                NEW.append(pdbformat2 % tuple(line))
    else:
        if len(line[2]) > 3:
        #if line[2] in ['FE', 'Fe', 'Fe1']:
            #NEW.append(' '.join(line))
            NEW.append(pdbformat1 % tuple(line))
        else:
            #NEW.append(' '.join(line))
            NEW.append(pdbformat2 % tuple(line))
        
#print (my_pdbformat1 % tuple(NEW))
#print tuple([NEW[-1]])
#print ('\n'.join(NEW))
b.write('\n'.join(NEW))

