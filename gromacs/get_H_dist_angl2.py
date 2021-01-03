#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import sys
data               = open(sys.argv[1], 'r')
OUT                = open(sys.argv[2], 'w')
min_dist, max_dist = 2.3, 3.3
min_angl, max_angl = 115.0, 175.0
for f in data:
    if f[0] == '#':
        site_lst = ['Time(ps)'] + f.split()[2:16]
    else:
        dsl = [float(x) for x in f.split()[1:16]]
        agl = [float(x) for x in [f.split()[1]] + f.split()[18:33]]
        dist_min = min(dsl[1:14])
        if dist_min < min_dist or dist_min > max_dist:
            continue
        ind = dsl.index(dist_min)
        if agl[ind] < min_angl or agl[ind] > max_angl:
            continue
        site = site_lst[ind]
        #         site time angl dist
        OUT.write('%8s %10.3f %10.4f %8.4f\n' % (site, dsl[0] / 1000, agl[ind], dist_min))

data.close()
OUT.close()
