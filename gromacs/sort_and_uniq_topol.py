#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import os
import sys

# card1 from ffbonded.itp, card2 from topol.top
card1 = ['bondtypes', 'constrainttypes', 'angletypes', 'dihedraltypes', 'dihedraltypes']
card2 = ['moleculetype', 'atoms', 'bonds', 'pairs', 'angles', 'dihedrals', 'dihedrals', 'position_restraints', 'system']

i, j = 0, 0
ffbond, gmx_top, ffbond_ind, gmx_top_ind = [], [], [], []
for line in open(sys.argv[1], 'r'):
   if line[0] not in [';', '#']:
      for x in list(set(card1)):
         if x in line.split():
            ffbond_ind.append(i)
      ffbond.append([x for x in line.split()])
      i += 1
    
for line in open(sys.argv[2], 'r'):
   if line[0] not in [';', '#']:
      for x in list(set(card2)):
         if x in line.split():
            gmx_top_ind.append(j)
      gmx_top.append([x for x in line.split()])
      j += 1

#print(ffbond_ind, gmx_top_ind)
# dihedraltypes_fn4 (improper), dihedraltypes_fn9 (propers)'
bondtypes         = [ffbond[x] for x in range(ffbond_ind[0] + 1, ffbond_ind[1]) if len(ffbond[x]) > 0]
angletypes        = [ffbond[x] for x in range(ffbond_ind[2] + 1, ffbond_ind[3]) if len(ffbond[x]) > 0]
dihedraltypes_fn4 = [ffbond[x] for x in range(ffbond_ind[3] + 1, ffbond_ind[4]) if len(ffbond[x]) > 0]
dihedraltypes_fn9 = [ffbond[x] for x in range(ffbond_ind[4] + 1, len(ffbond)) if len(ffbond[x]) > 4]

#  'atoms', 'bonds', 'pairs', 'angles', 'dihedrals_fn9', 'dihedrals_fn4'
atoms             = [gmx_top[x] for x in range(gmx_top_ind[1] + 1, gmx_top_ind[2]) if len(gmx_top[x]) > 0]
bonds             = [gmx_top[x] for x in range(gmx_top_ind[2] + 1, gmx_top_ind[3]) if len(gmx_top[x]) > 0]
angles            = [gmx_top[x] for x in range(gmx_top_ind[4] + 1, gmx_top_ind[5]) if len(gmx_top[x]) > 0]
dihedrals_fn9     = [gmx_top[x] for x in range(gmx_top_ind[5] + 1, gmx_top_ind[6]) if len(gmx_top[x]) > 0]
dihedrals_fn4     = [gmx_top[x] for x in range(gmx_top_ind[6] + 1, gmx_top_ind[7]) if len(gmx_top[x]) > 0]

#print('\n'.join([str(x) for x in dihedraltypes_fn4]))
#print('\n'.join([str(x) for x in dihedraltypes_fn9]))
# The atom id, type, and name in the gmx_top
atm_id = [x[0] for x in atoms]
atm_typ = [x[1] for x in atoms] # it is a lower case
atm_nam = [x[4] for x in atoms]

# Notice that there is an X in dihedrals!
ffbond_bond_atm  = [tuple(sorted([x[0], x[1]])) for x in bondtypes]
ffbond_angl_atm  = [tuple(sorted([x[0], x[1], x[2]])) for x in angletypes]
ffbond_dihd_atm1 = [tuple(sorted([x[0], x[1], x[2], x[3]])) for x in dihedraltypes_fn4]
ffbond_dihd_atm2 = [tuple(sorted([x[0], x[1], x[2], x[3]])) for x in dihedraltypes_fn9]
ffbond_atm_lst   = ffbond_bond_atm + ffbond_angl_atm + ffbond_dihd_atm1 + ffbond_dihd_atm2

def APPD_SORT(f, ran, sortype):
   global terms_APPD
   if sortype == 'bonds':
      findex = [2, -1]
   elif sortype == 'angles':
      findex = [3, -1]
   elif sortype == 'dihedrals_fn9' or sortype == 'dihedrals_fn4':
      findex = [4, -1]
   atm_inds = [atm_id.index(f[x]) for x in ran]
   atm_nams =  tuple(atm_nam[atm_inds[x]] for x in ran)
   atm_typs = tuple(atm_typ[atm_inds[x]] for x in ran)
   atm_typ_sorted = tuple(sorted(atm_typs))
   atm_typ_labled = atm_typ_sorted
   if atm_typ_sorted in ffbond_atm_lst:
      atm_typ_labled = atm_typ_sorted + tuple([sortype + '_found'])
   f.append(atm_nams)
   f.append(atm_typ_labled)
   terms_APPD.append([f[x] for x in findex])

def DEL_DUPLE(parM):
   global ids_DEL
   global terms_APPD
   ids_DEL = []
   [ids_DEL.append(i) for i in parM if not i in ids_DEL]
   terms_APPD = [] 

terms_APPD = []
i = 2
for var in ['bonds', 'angles', 'dihedrals_fn9', 'dihedrals_fn4']:
   [APPD_SORT(f, range(0, i), var) for f in globals()[var]]
   DEL_DUPLE(terms_APPD)
   print(var + '_infomations:')
   print('\n'.join([str(x) for x in ids_DEL]))
   i += 1

#new_bond = [APPD_SORT(f, range(0, 2), 'bonds') for f in bonds]
#DEL_DUPLE(terms_APPD)
#uni_bond = ids_DEL
#new_dihd = [APPD_SORT(f, range(0, 4), 'dihedrals') for f in dihedrals]
#DEL_DUPLE(terms_APPD)
#uni_dihd = ids_DEL

#old_var = ['bonds', 'angles', 'dihedrals']
#new_var = ['uni_bond', 'uni_angl', 'uni_dihd']
#chk_var = ['chk_bond', 'chk_angl', 'chk_dihd']
#for var1, var2, var3 in zip(old_var, new_var, chk_var):
#   chk_var = [APPD_SORT(f, range(0, i), var1) for f in globals()[var1]]
#   DEL_DUPLE(terms_APPD)
#   globals()[var2] = ids_DEL
#   i += 1

#print('\n'.join([str(x) for x in uni_bond]))
#print('\n'.join([str(x) for x in uni_angl]))
#print('\n'.join([str(x) for x in uni_dihd]))
