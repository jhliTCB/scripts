#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# inputs come from the ASCII matrix data generated by VMD (viewing the trajectories)

#import sys
#distances = open(sys.argv[(1)], 'r')
#angles = open(sys.argv[(2)], 'r')
distances = open('hydrogen_distances.dat', 'r')
angles = open('hydrogen_angles.dat', 'r')
dihedral = open('hydrogen_dihedrals.dat', 'r')
min_dist = 2.8
min_angl = 125.0
max_angl = 155.0
    
for i, j, k in zip(distances, angles, dihedral):
    dsl = [float(ii) for ii in i.split()]
    agl = [float(jj) for jj in j.split()]
    dhl = [float(kk) for kk in k.split()]
    dist_min = min(dsl)
    # To drop those non-som type snapshots    
    if dist_min > min_dist:
        continue
    ind = dsl.index(dist_min)
    if  agl[ind] < min_angl or agl[ind] > max_angl:
        continue
    # to remove the non-conformer2 snapshots!
    #if dhl[1] < -67.5 or dhl[1] > 67.5:
    #    continue
    #if dhl[2] < -67.5 or dhl[2] > 67.5:
    #    continue
    
    if ind in range(1,7):
        #print type frame angle minmum_distance vkk_dihedral
        print ('w %d %f %f %f %f' % (dsl[0], agl[ind], dist_min, dhl[1], dhl[2]))
    elif ind == 7:
        print ('w-1 %d %f %f %f %f' % (dsl[0], agl[ind], dist_min, dhl[1], dhl[2]))
#    elif ind == 8 or ind == 9:
#        print ('w-2 %d %f %f %f %f' % (dsl[0], agl[ind], dist_min, dhl[1], dhl[2]))
    elif ind == 8:
         print ('w-2S %d %f %f %f %f' % (dsl[0], agl[ind], dist_min, dhl[1], dhl[2]))
    elif ind == 9:
         print ('w-2R %d %f %f %f %f' % (dsl[0], agl[ind], dist_min, dhl[1], dhl[2]))
    elif ind == 10 or ind == 11:
        print ('w-3 %d %f %f %f %f' % (dsl[0], agl[ind], dist_min, dhl[1], dhl[2]))