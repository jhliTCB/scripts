#!/usr/bin/env python
import os
import sys
import math

def calc(term): # term is a list, len: frames
    sum = 0.0
    for i in term:
        sum += float(i)
    average = sum / len(term)
    sum = 0.0
    for i in term:
        sum = sum + (float(i) - average) * (float(i) - average)
    std = math.sqrt(sum / len(term))
    return([average, std])

#summary.py sub_dir ${LIG}*
subdir = sys.argv[1]

#nmode: 'Translational', 'Rotational', 'Vibrational', 'Total' (dlen = 4 terms)
#GBSA: 'VDWAAALS', 'EEL', 'EGB', 'ESURF', 'G gas', 'G solv', 'Total' (dlen = 7 terms)

data   = {}
result = []
out='energy.csv'

fid  = -1
for i in range(2, len(sys.argv)):
    if os.path.isdir(os.getcwd() + '/' + sys.argv[i] + '/' + subdir):
        fid += 1
    else:
        continue
    
    temp = []
    jj = 0
    
    for j in open(sys.argv[i] + '/' + subdir + '/' + out, 'r'):
        if j[0] == '0':
            jj += 1 
            temp.append(j.split(',')[1:])
            dlen = len(j.split(','))
            
    data[fid] = temp

for i in range(0, jj): # jj is 4
    redic = {}
    for j in range(0, dlen-1):
        redic[j] = calc([data[k][i][j] for k in range(0, fid)])
    result.append(redic)

# Write the result
f = open('FINAL_' + subdir + '.dat', 'w')
if 'GB' in subdir and dlen == 8:
    f.write("GENALIZED BORN:\n")
    components = ['VDWAALS', 'EEL', 'EGB', 'ESURF', 'G_gas', 'G_solv', 'TOTAL']
elif 'nmode' in subdir and dlen == 5:
    f.write("ENTROPY RESULTS (HARMONIC APPROXIMATION) CALCULATED WITH NMODE:\n")
    components = ['Translational', 'Rotational', 'Vibrational', 'Total']

f.write("number of frames " + str(fid+1) + "\n\n")
spec = ['Complex:\n', 'Receptor:\n', 'Ligand:\n', 'Differences (Complex - Receptor - Ligand):\n']
for i in range(0, 4):
    f.write(spec[i] + "Energy Component            Average              Std. Dev.\n")
    f.write("----------------------------------------------------------\n")
    for j in range(0, dlen-1):
        f.write("%-13s%22.4f%22.4f\n" % (components[j], result[i][j][0], result[i][j][1]))
    
    f.write("\n\n")

f.close()
