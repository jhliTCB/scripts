#!/usr/bin/env python3
'''
To process the following csv files:
SP_AD_site-V1.csv  SP_AD_site-V4.csv   SP_CBD_site-s11.csv  SP_PSP_site-C1.csv  SP_PSP_site-E3.csv  SP_PSP_site-S3.csv  SP_PSP_site-S6.csv
SP_AD_site-V2.csv  SP_CBD_site-c1.csv  SP_CBD_site-s6.csv   SP_PSP_site-E1.csv  SP_PSP_site-S1.csv  SP_PSP_site-S4.csv  SP_PSP_site-S7.csv
SP_AD_site-V3.csv  SP_CBD_site-e1.csv  SP_CBD_site-s9.csv   SP_PSP_site-E2.csv  SP_PSP_site-S2.csv  SP_PSP_site-S5.csv
'''

cpds = ['3', '10']
anag = ['a', 'b', 'c', 'd', 'e']
site = {'CBD':['e1', 'c1', 's6', 's9', 's11'], 
        'AD':['V1', 'V2', 'V3', 'V4'],
        'PSP':['C1', 'E1', 'E2', 'E3', 'S1', 
               'S2', 'S3', 'S4', 'S5', 'S6', 'S7']}

def main():
    for i in cpds:
        for j in anag:
            cpd = i+j
            row = get_row(cpd, site)
            row = [cpd] + row
            print(','.join([str(x) for x in row]))

def get_row(cpd, site):
    #SP_{}_site-{}
    scores = []
    for sys in ['CBD', 'AD', 'PSP']:
        tmp = []
        for s in site[sys]:
            csv = "SP_{}_site-{}.csv".format(sys, s)
            for line in open(csv, 'r'):
                if '_'+cpd in line:
                    if line.split(',')[4]:
                        tmp.append(float(line.split(',')[4]))
                    else:
                        tmp.append(999)
        if sys == 'CBD':
            scores = ["{:.1f}".format(x) for x in tmp]
        elif sys == 'AD':
            S = min(tmp)
            V = site[sys][tmp.index(S)]
            if S == 999:
                scores.append('/')
            else:
                scores.append("{:.1f} ({})".format(S, V))
        elif sys == 'PSP':
            tmp1 = tmp[0:4]
            tmp2 = tmp[4:]
            S1, S2 = min(tmp1), min(tmp2)
            V1, V2 = site[sys][tmp1.index(S1)], site[sys][tmp2.index(S2)+4]
            if S2 == 999:
                scores.append('/')
            else:
                scores.append("{:.1f} ({})".format(S2, V2))
            if S1 == 999:
                scores.append('/')
            else:
                scores.append("{:.1f} ({})".format(S1, V1))
    return scores

if __name__ == '__main__':
    main()
