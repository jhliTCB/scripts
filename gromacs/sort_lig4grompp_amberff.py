#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import sys
# Usage: python script.py LIG_GMX.itp LIG_old.pdb LIG_new.pdb
COM = [line for line in open(sys.argv[2], 'r') if line.split()[0] in ['ATOM', 'HETATM']]
RES = COM[0].split()[3]
ITP = [[x for x in line.split()] for line in open(sys.argv[1], 'r') if RES in line and len(line.split()) > 8]
OUT = open(sys.argv[3], 'w')

ITP_ATM = [x[4] for x in ITP]
COM_ATM = [x.split()[2] for x in COM]

if len(ITP_ATM) != len(COM_ATM):
    print('Number of atoms not match!')
    exit(1)

NEW = [COM[COM_ATM.index(ITP_ATM[x])] for x in range(0, len(ITP_ATM))]
OUT.write(''.join([x for x in NEW]))
