#!/usr/bin/env python2
# -*- coding: utf-8 -*-
import os
import sys
import math

lig_dir = 'vk1_m1/'
lig_num = 50
prefix = 'ranked_vk1_m1_'
suffix = '.mol2'
si_dict = {'H61':'w', 'H62':'w', 'H63':'w', 'H64':'w', 'H65':'w', 'H66':'w', \
           'H58':'w-1', 'H48':'w-2S', 'H49':'w-2R', 'H46':'w-3R', 'H47':'w-3S'}
atoms = ['H61', 'H62', 'H63', 'H64', 'H65', 'H66', 'H58', 'H48', 'H49', 'H46', 'H47']
dih1_lst = ['H58', 'C15', 'C11', 'C10']
dih2_lst = ['C15', 'C11', 'C10', 'C8']
pro_nam = 'gold_protein.mol2'
pro_atm1 = 'OE'
pro_atm2 = 'FE'
max_dist = 2.80
min_ang = 125.0
max_ang = 155.0
data = []
result = open('within_range.lst', 'w')
result.write('# site_type, dock_score, hydrogen, distance, angle, \
dihedral1, dihedral2, soln_num, pose_path\n') 

def vector(a, b):
    return tuple([b[0] - a[0], b[1] - a[1], b[2] - a[2]])

def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

def cros(a, b):
    return tuple([a[1] * b[2] - a[2] * b[1],  a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]) 

def calc_ang(xo, yo, zo, xf, yf, zf, xl, yl, zl):
    A = tuple([xo, yo, zo])
    B = tuple([xf, yf, zf])
    C = tuple([xl, yl, zl])
    AB, AC = vector(A, B), vector(A, C)
    cosC = dot(AB, AC) / (math.sqrt(dot(AB, AB)) * math.sqrt(dot(AC, AC)))
    radius = math.acos(cosC)
    degrees = math.degrees(radius)
    return degrees

def calc_dih(atm_lst, atm_dic):
    A = tuple([float(x) for x in atm_dic[atm_lst[0]]])
    B = tuple([float(x) for x in atm_dic[atm_lst[1]]])
    C = tuple([float(x) for x in atm_dic[atm_lst[2]]])
    D = tuple([float(x) for x in atm_dic[atm_lst[3]]])
    BA, BC = vector(B, A), vector(B, C)
    CB, CD = vector(C, B), vector(C, D)
    n1, n2 = cros(BA, BC), cros(CB, CD)
    cosD = dot(n1, n2) / (math.sqrt(dot(n1, n1)) * math.sqrt(dot(n2, n2)))
    radius = math.acos(cosD)
    if dot(n1, CD) < 0:
        degrees = math.degrees(radius)
    else:
        degrees = -1.0 * math.degrees(radius)
    return ('%.3f' % degrees)

 
for i in range(1, len(sys.argv)):
    if str(sys.argv[(i)])[-1] == '/':
        root_path = os.getcwd() + '/' + str(sys.argv[(i)])
    else:
        root_path = os.getcwd() + '/' + str(sys.argv[(i)]) + '/'
    protein = root_path + pro_nam
    
    for line in open(protein, 'r'):
        li = [ii for ii in line.split()]
        if len(li) > 1:
            if li[1] == pro_atm1:
                xo, yo, zo = float(li[2]), float(li[3]), float(li[4])
            elif li[1] == pro_atm2:
                xf, yf, zf = float(li[2]), float(li[3]), float(li[4])
    
    for j in range(1, lig_num + 1):
        pose_path = root_path + lig_dir + prefix + str(j) + suffix
        pose = open(pose_path.split('\n')[0], 'r').readlines()
        score_line = pose.index('> <Gold.Chemscore.Fitness>\n') + 1
        dock_score = (pose[score_line]).strip('\n')
        soln_ind = pose.index('@<TRIPOS>MOLECULE\n') + 1
        soln = pose[soln_ind]
        soln_num = 'soln_' + soln[soln.find('dock')+4:soln.find('dock')+10]
        xyz_beg = pose.index('@<TRIPOS>ATOM\n')
        xyz_end = pose.index('@<TRIPOS>BOND\n')
        
        temp1, temp2, temp3 = [], [], {}
        for k in range(xyz_beg, xyz_end):
            pkli = [ii for ii in pose[k].split()]
            if len(pkli) < 2:
                continue
            if pkli[1] in atoms:
                xl, yl, zl = float(pkli[2]), float(pkli[3]), float(pkli[4])
                dist = ((xl - xo) ** 2 + (yl - yo) ** 2 + (zl - zo) ** 2) ** 0.5
                temp1.append(dist)
                            # site_type, hydrogen, xyz of that sie
                temp2.append([si_dict[pkli[1]], pkli[1], xl, yl, zl])
            if pkli[1] in dih1_lst + dih2_lst:
                temp3[pkli[1]] = [pkli[2], pkli[3], pkli[4]]
        
        if len(temp2) < 1:
            continue

        if min(temp1) < max_dist:
            distance = min(temp1)
            info = temp2[temp1.index(distance)]
            site_type, hydrogen = info[0], info[1]
            xl, yl, zl = float(info[2]), float(info[3]), float(info[4])
            angle = calc_ang(xo, yo, zo, xf, yf, zf, xl, yl, zl)
        else:
            continue
        
        if angle < min_ang or angle > max_ang:
            continue
        
        dihedral1 = str(calc_dih(dih1_lst, temp3))
        dihedral2 = str(calc_dih(dih2_lst, temp3))
        
        tupe = tuple([site_type, '%.5s' % dock_score, hydrogen, str('%.3f' % distance),\
               str('%.3f' % angle), dihedral1, dihedral2, soln_num.strip('\n'), pose_path])
        data.append(tupe)

form = [' '.join(s) for s in data]                
result = open('within_range.lst', 'a')                
result.write('\n'.join(form))
