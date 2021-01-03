#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import os
import sys

ffnonb = [[x for x in line.split()] for line in open(sys.argv[1], 'r') if line[0] not in [';', '[']]
ffbond = [[x for x in line.split()] for line in open(sys.argv[2], 'r') if line[0] != ';']
conv   = [[x for x in line.split()] for line in open(sys.argv[3], 'r') if line[0] != ';']
#card1  = ['defaults', 'atomtypes', 'moleculetype', 'atoms', 'bonds', 'pairs', 'angles', 'dihedrals', 'system', 'molecules']
# card1 is the cards in the converted topology file
card1  = [conv.index(x) for x in conv if len(x) > 0 and x[0] in ['[',']']]
molcar = [x[0] for x in enumerate(conv) if x[1] == ['[', 'moleculetype', ']']]
#print(molcar)
#print(card1)
#print([conv(x) for x in card1])
for f in [conv[x] for x in card1]:
   ind1         = conv.index(f)
   if ind1 < molcar[-1] and len(molcar) > 1:
      ind2      = card1[card1.index(ind1) + 1]
      ind_dihd  = molcar[-1]
   elif card1.index(ind1) < len(card1) - 1:
      ind2      = card1[card1.index(ind1) + 1]
      ind_dihd  = ind2
   if 'atomtypes' in f:
      atomtypes = [conv[x] for x in range(ind1 + 1, ind2) if len(conv[x]) > 0]
   elif 'atoms' in f:
      atoms     = [conv[x] for x in range(ind1 + 1, ind2) if len(conv[x]) > 0]
   elif 'bonds' in f:
      bonds     = [conv[x] for x in range(ind1 + 1, ind2) if len(conv[x]) > 0]
   elif 'angles' in f:
      angles    = [conv[x] for x in range(ind1 + 1, ind2) if len(conv[x]) > 0]
   elif 'dihedrals' in f and len(f) == 3:
      dihedrals = [conv[x] for x in range(ind1 + 1, ind_dihd) if len(conv[x]) > 0]
      break
   elif 'dihedrals' in f and 'impropers' in f: # This option for the acpype cards
      ind      = card1[card1.index(ind1) - 1]
      dihedrals = [conv[x] for x in range(ind + 1, ind_dihd) if len(conv[x]) > 0 and conv[x][0] != '[']
      break

card2  = ['bondtypes', 'constrainttypes', 'angletypes', 'dihedraltypes']
ind_lst         = [ffbond.index(['[', x, ']']) for x in card2]
bondtypes       = [ffbond[x] for x in range(ind_lst[0] + 1, ind_lst[1]) if len(ffbond[x]) > 0]
constrainttypes = [ffbond[x] for x in range(ind_lst[1] + 1, ind_lst[2]) if len(ffbond[x]) > 0]
angletypes      = [ffbond[x] for x in range(ind_lst[2] + 1, ind_lst[3]) if len(ffbond[x]) > 0]
dihedraltypes   = [ffbond[x] for x in range(ind_lst[3] + 1, len(ffbond)) if len(ffbond[x]) > 0 and ffbond[x][0] != '[']

ffnonb_atyp    = [x[0] for x in ffnonb]
conv_atyp    = [x[0] for x in atomtypes]
print('Nonbond info for all molecules')
for f in conv_atyp:
   indd = conv_atyp.index(f)
   sigma1, epsilon1 = float(atomtypes[indd][5]), float(atomtypes[indd][6])
   if f.upper() in ffnonb_atyp:
      ind2 = ffnonb_atyp.index(f.upper())
      sigma2, epsilon2 = float(ffnonb[ind2][5]), float(ffnonb[ind2][6])
      if sigma1 == sigma2 and epsilon1 == epsilon2:
         print(['repeated', f, ffnonb_atyp[ind2], str(sigma1), str(epsilon1)])
      else:
         print(['type found but differed in ffnonbond.itp', f, sigma1, epsilon1, ffnonb_atyp[ind2], str(sigma2), str(epsilon2)]) 
   else:
      print([f, 'not found in ffnonboned.itp', sigma1, epsilon1])

# The three terms are usually have same index and len
atm_id = [x[0] for x in atoms]
atm_typ = [x[1] for x in atoms] # it is a lower case
atm_nam = [x[4] for x in atoms]
ffbond_bond_atm = [tuple(sorted([x[0], x[1]])) for x in bondtypes]
ffbond_angl_atm = [tuple(sorted([x[0], x[1], x[2]])) for x in angletypes]
ffbond_dihd_atm = [tuple(sorted([x[0], x[1], x[2], x[3]])) for x in dihedraltypes]
ffbond_atm_lst  = ffbond_bond_atm + ffbond_angl_atm + ffbond_dihd_atm

def APPD_SORT(f, ran, sortype):
   global terms_sele
   global terms_all
   if sortype == 'bonds':
      findex = [0, 1, 4, 5, 6]
   elif sortype == 'angles':
      findex = [0, 1, 2, 6, 7, 8]
   elif sortype == 'dihedrals':
      if len(f) < 14:
         findex = [0, 1, 2, 3, 8, 9, 10, 11]
      else:
         findex = [0, 5, 6, 7, 8, 9, 10, 11]
   atm_inds = [atm_id.index(f[x]) for x in ran]
   atm_nams = tuple(atm_nam[atm_inds[x]] for x in ran)
#   atm_typs = tuple(atm_typ[atm_inds[x]] for x in ran)
   atm_typs = tuple(atm_typ[atm_inds[x]].upper() for x in ran)
#   atm_typ_sorted = tuple(sorted(atm_typs))
#   if atm_typ_sorted in ffbond_atm_lst or atm_typs in ffbond_atm_lst:
   if atm_typs in ffbond_atm_lst:
      f[-1] = f[-1] + '_repeat_'
   ff = list(atm_typs) + f + list(atm_nams)
   terms_all.append(ff)
   terms_sele.append([ff[x] for x in findex])

def DEL_DUPLE(parM):
   global ids_DEL
   global terms_sele
   global terms_all
   ids_DEL = []
   [ids_DEL.append(i) for i in parM if not i in ids_DEL]
   terms_sele = []
   terms_all = [] 

i = 2
terms_sele, terms_all = [], []
old_var = ['bonds', 'angles', 'dihedrals']
new_var = ['uni_bond', 'uni_angl', 'uni_dihd']
chk_var = ['chk_bond', 'chk_angl', 'chk_dihd']
for var1, var2, var3 in zip(old_var, new_var, chk_var):
   [APPD_SORT(f, range(0, i), var1) for f in globals()[var1]]
   globals()[var3] = terms_all
   DEL_DUPLE(terms_sele)
   globals()[var2] = ids_DEL
   i += 1

binfo = str('\n'.join([str(" %4s%4s%4s%15s%24s" % tuple(x)) for x in uni_bond]))
ainfo = str('\n'.join([str(" %4s%4s%4s%4s%15s%24s" % tuple(x)) for x in uni_angl]))
dinfo = str('\n'.join([str(" %4s%4s%4s%4s%4s%15s%24s%4s" % tuple(x)) for x in uni_dihd]))
out1 = open('uniqed_types.txt', 'w')
out1.write('\n'.join(['BONDINGS', binfo, 'ANGLES', ainfo, 'DIHEDRALS', dinfo]))

ffa = " %4s%4s%4s%4s%4s%8s%28s%5s%5s"
ffb = " %4s%4s%4s%4s%4s%4s%4s%8s%28s%5s%5s%5s"
ffc = " %4s%4s%4s%4s%4s%4s%4s%4s%4s%8s%28s%3s%5s%5s%5s%5s"
a = str('\n'.join([str(ffa % tuple(x)) for x in chk_bond]))
b = str('\n'.join([str(ffb % tuple(x)) for x in chk_angl]))
c = str('\n'.join([str(ffc % tuple(x)) for x in chk_dihd]))
out2 = open('tranformed_top.txt', 'w')
out2.write('\n'.join(['BONDINGS', a, 'ANGLES', b, 'DIHEDRALS', c]))
