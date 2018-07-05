#!/usr/bin/env python2
import sys
xyz, REM = {}, {}
stat_ind = {}
OP, SP   = -1, 0
# add more atoms if your system has
atm_dict = {'1':'H', '6':'C', '7':'N', '8':'O', '16':'S', '26':'Fe'}
flag     = 'NULL'
#ONIOM energy key word:
# 'extrapolated energy'
# SCF energy:
# 'SCF Done'

def out_pdb(ATNB, atom, resn, resi, XYZ, ltom, j):
   format1  = '%-6s%5d %-5s%-4s%5d%12.3f%8.3f%8.3f%6.2f%6.2f%12s\n'
   format2  = '%-6s%5d  %-4s%-4s%5d%12.3f%8.3f%8.3f%6.2f%6.2f%12s\n'
   if atom == 'Fe':
      PDB  = tuple(['ATOM', ATNB, 'FE', resn, int(resi)]) + XYZ + tuple([0, 0, ltom])
      return(format1 % PDB)
   else:
      PDB  = tuple(['ATOM', ATNB, atom, resn, int(resi)]) + XYZ + tuple([0, 0, ltom])
      return(format2 % PDB)

if len(sys.argv) == 4:
   mod = open(sys.argv[1], 'r')
   log = open(sys.argv[2], 'r')
   eOP = sys.argv[3]
   ATOM, RESN, RESI = [], [], []
   for line in mod:
      lin_lst = line.split()
      if lin_lst[0] in ['ATOM', 'HETATM']:
         ATOM.append(lin_lst[2])
         RESN.append(lin_lst[3])
         RESI.append(lin_lst[4])
elif len(sys.argv) == 3:
   ATOM = []
   log = open(sys.argv[1], 'r')
   eOP = sys.argv[2]

for line in log:
   # make flags for the corrdinates
   if len(line) > 60:
      if line[43:66] == 'Coordinates (Angstroms)':
         OP += 1
         abc, mrk, j = [], [], 0
         abc.append('%5s%9s\n' % tuple(['MODEL', OP]))
         if not flag == 'STATIONARY_POINT':
            flag = 'COORD_START'
         else:
            SP += 1
            stat_ind[str(SP)] = str(OP)
            flag = 'STAT_COORD_START'
      if flag == 'COORD_START' and line[7:11] == 'Link':
         flag = 'COORD_END'
      if flag == 'STAT_COORD_START' and line[7:11] == 'Link':
         flag = 'STAT_COORD_END'
   # make flags for the energies
   if len(line) > 17:
      if line[1:6] == 'ONIOM':
         ONIO = '1'
      if line[1:17] == 'ONIOM: gridpoint':
         flag = 'ONIOM_ENERGY_START'
      elif line[1:15] == '--------------' and flag == 'ONIOM_ENERGY_START':
         flag = 'ONIOM_ENERGY_END'
      elif line[1:9] == 'SCF Done':
         flag = 'SCF_DONE'
      elif line[7:11] == 'Link' and flag == 'SCF_DONE':
         flag = 'SCF_DONE_END'
      elif line[4:17] == '-- Stationary':
         flag = 'STATIONARY_POINT'
   # Record the needed data
   if flag == 'COORD_START' or flag == 'STAT_COORD_START':
      if line.strip()[0] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']:
         atom = atm_dict[line[11:20].strip()]
         XYZ  = tuple(float(x) for x in line[33:70].split())
         ATNB = int(line[0:10].strip())
         if len(ATOM) == 0:
            myPDB = out_pdb(ATNB, atom, 1, 1, XYZ, atom, j)
         else:
            myPDB = out_pdb(ATNB, ATOM[j], RESN[j], RESI[j], XYZ, atom, j)
         abc.append(myPDB)
         j += 1
   elif flag == 'COORD_END' or flag == 'STAT_COORD_END':
      xyz[str(OP)] = abc
   
   if vars().has_key('ONIO'):
      if flag == 'ONIOM_ENERGY_START':
         if line[1:7] == 'ONIOM:':
            mrk.append('REMARK ' + line)
      if flag == 'ONIOM_ENERGY_END':
         REM[str(OP)] = mrk
   else:
      if flag == 'SCF_DONE':
         mrk.append('REMARK ' + line)
      elif flag == 'SCF_DONE_END':
         REM[str(OP)] = mrk
     
   #print(flag)

print('REMARK ONIOM?: ' + str(vars().has_key('ONIO')))
print('REMARK stationary_points, opt_steps: ' + str(SP) + ', ' + str(OP))
print(tuple(['REMARK', len(REM), len(xyz), len(stat_ind), SP, OP, vars().has_key('ONIO')]))

if eOP == 'all':
   for i in range(0, len(REM)):
      print(''.join(tuple(REM[str(i)] + xyz[str(i)])).rstrip('\n'))
#     print(''.join(tuple(xyz[str(i)])).rstrip('\n'))
      print('TER\nENDMDL')
elif eOP == 'end':
   print(''.join(tuple(REM[str(OP - 1)] + xyz[str(OP)])))
elif eOP == 'steps':
   print('The optimization/scan went through: ' + str(OP) + ' Steps')
   print('There is ' + str(SP) + ' Stationary points')

elif eOP == 'all_stats':
   for i in range(1, len(stat_ind) + 1):
      ind = int(stat_ind[str(i)])
      print(''.join(tuple(REM[str(ind - 1)] + xyz[str(ind)])).rstrip('\n'))
      print('TER\nENDMDL')
elif eOP.startswith('stat'):
   i = eOP.replace('stat', '')
   ind = int(stat_ind[i])
   print(''.join(tuple(REM[str(ind - 1)] + xyz[str(ind)])))
else:
#      print(''.join(tuple(xyz[eOP])))
   eop = str(int(eOP) - 1)
   print(''.join(tuple(REM[eop] + xyz[eop])).rstrip('\n'))

