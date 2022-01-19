#!/usr/bin/env python
# processing sdf output from glide docking
import argparse
import os, sys

def get_parser():
    parser = argparse.ArgumentParser(description='processing sdf output from glide docking',
    formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-l','--list_file',type=str,required=True,help=
    '''    A list file for the docking directories, 
    str, Required;       e.g. -l successed_docked.lst
     ''')
    parser.add_argument('-s','--score_threshold',type=float,default=None,help=
    '''    A score threadhold for filtering poses, 
    float, optional;     e.g. -s -4
    ''')
    parser.add_argument('-top','--top_n_ranked',type=int,default=None,help=
    '''    Filtering poses by top i ranking,
    int, optional;       e.g. -top 1
    ''')
    parser.add_argument('-pdb','--centroid_pdb',type=str,default=None,help=
    '''    Output the centroids of the filtered poses in PDB format,
    str, optional;       e.g. -pdb centroids.pdb
    ''')
    parser.add_argument('-o','--output_sdf',type=str,required=True,help=
    '''    File name for the filtered sdf,
    str, Required;       e.g. -o filtered_poses.sdf
    ''')
    parser.add_argument('-q','--totQ',type=int,default=None,help=
    '''    Filtering poses by total Charge,
    int, optional;       e.g. -q 0
    ''')
    parser.add_argument('-csv','--output_csv',required=True,help=
    '''    File name for the filtered csv,
    str, Required;       e.g. -o filtered_poses.csv
    ''')
    return parser

def lmean(lst):
    #numpy is faster for huge list! but ligand number is small
    sum = 0
    for x in lst:
        sum += x
    return sum/len(lst)

def getxyz(lst):
    num_atom = int(lst[3].split()[0][0:3].strip())
    x, y, z = [], [], []
    #for i in range(4, 4 + num_atom):
    for i in range(4, len(lst)):
        if len(lst[i].split()) > 8 and len(lst[i]) > 48:
            x.append(float(lst[i][0:10].strip()))
            y.append(float(lst[i][10:20].strip()))
            z.append(float(lst[i][20:30].strip()))
        else:
            break
    return [lmean(x), lmean(y), lmean(z)]

def read_sdf(sdf):
    # return 1: {00000molname1:[charge, score, site, X, Y, Z], 00001molname2:...} # for filtering
    # return 2: [molname1, molname2, molname3, ...]                               # for filtering
    # return 3: [[mol1_sdf_lines], [mol2_sdf_lines], ...]            # for sdf export
    # return 4: [[csv_line1], [csv_line2], ...]                      # for csv export
    out_csv_prop = []
    flag, num_mol = 0, 0
    out = {}
    mol_list = []
    all_molecules = []
    csv_titles, csv_data, csv_out = ['Title'], [], []
    for line in open(sdf, 'r'):
        if flag == 0:
            mol = line.strip()
            csv_data = [mol]
            #all_mol_list.append(mol)
            if mol not in mol_list:
                mol_list.append(mol)
            temp= []
            flag = 1
        if flag == 1:
            temp.append(line)
            if line.startswith('> <'):
                titles = line.strip('> <').strip('>\n')
                if titles not in csv_titles:
                    csv_titles.append(titles)

        if '$$$$' in line:
            #all_molecules.append(temp)
            id_mol = ("%05d" % num_mol) + mol # same index as all_molecules!
            row_score = '> <r_i_docking_score>\n'
            row_totQ = '> <i_epik_Tot_Q>\n'
            row_site = '> <s_i_glide_gridfile>\n'
            score = temp[temp.index(row_score) + 1].strip()
            totQ = temp[temp.index(row_totQ) + 1].strip()
            site = temp[temp.index(row_site) + 1].strip().split('_')[-1]
            temp[temp.index(row_site) + 1] = site + '\n'
            for x in csv_titles[1:]:
                xline = "> <{}>\n".format(x)
                if xline not in temp:
                    csv_data.append('NO_RECORD')
                else:
                    csv_data.append(temp[temp.index(xline)+1].strip('\n'))

            all_molecules.append(temp)
            xyzinfo = getxyz(temp)
            out[id_mol] = [int(totQ), float(score), site] + xyzinfo
            if num_mol == 0:
                csv_out.append(csv_titles)
            csv_out.append(csv_data)
            flag = 0
            num_mol += 1

    return out, mol_list, all_molecules, csv_out

def filter_poses(mol, outinfo, score, flag):
    # score: float or 'top%d'
    out = []
    i = 0
    if flag:
        if flag == 'Q':
            j = 1
        elif flag == 'S':
            j = 0
    else:
        flag = 'NONE'
    for x, y in outinfo.items():
        if x[5:] == mol:
            if flag != 'QS':
                if 'top' not in str(score) and y[j] < float(score):
                    out.append({x:y})
                else:
                    n = score[3:]
                    if i < int(n):
                        out.append({x:y})
            else:
                if y[0] == score[0] and y[1] < score[1]:
                    out.append({x:y}) 
        i += 1

    return out

def main():
    parser = get_parser()
    args = parser.parse_args()   
    ScoThr = args.score_threshold
    TopNRa = args.top_n_ranked
    totQ = args.totQ
    if ScoThr == None and TopNRa == None:
        sys.stdout.write('either score_threshold or top_n_ranked filter should be given\nStop...\n')
        sys.stdout.flush()
        exit(1)

    if args.centroid_pdb != None:
        PdbCen = open(args.centroid_pdb, 'w')
        pdb_format = "%-6s%5d  %-4s%-4s%5d%12.3f%8.3f%8.3f%6.2f%6.2f%12s\n"
        pdb_aid = 1
    pdb_aid = 1
    output_sdf = open(args.output_sdf, 'w')
    output_csv = open(args.output_csv, 'w')
    output_csv_all = open(''.join(args.output_csv.split('.')[:-1] + ['_all.csv']), 'w')
    dockings = [x.strip('\n') for x in open(args.list_file, 'r')]
    num_sdf = 0
    for a_dock in dockings:
        sys.stdout.write('Processing %s\n' % a_dock)
        #sdf = '%s/%s/%s_lib.sdf' % (os.getcwd(), a_dock, a_dock)
        sdf = a_dock
        sdf_dict, mol_list, all_molecules, out_csv = read_sdf(sdf)
        #sys.stdout.write('top 1 ranked ligand in %s is %s, score: %f\n' % (a_dock, mol_list[0], sdf_dict['00000'+mol_list[0]][0]))
        #sys.stdout.flush()
        output_csv_all.write('\n'.join([','.join([y for y in x]) for x in out_csv]))
        fil_sdf_dict = []
        if totQ != None and ScoThr == None and TopNRa == None:
            score = totQ
            flat = 'Q'
        elif ScoThr != None and totQ == None and TopNRa == None:
            score = args.score_threshold
            flag = 'S'
        elif TopNRa != None and ScoThr == None and TopNRa == None:
            score = 'top' + str(args.top_n_ranked)
            flag = None
        elif totQ != None and ScoThr != None and TopNRa == None:
            score = [int(totQ), float(ScoThr)]
            flag = 'QS'
        elif totQ != None and ScoThr == None and TopNRa == None:
            score = [int(totQ), float(ScoThr), 'top' + str(args.top_n_ranked)]
            flag = 'QStop'
        elif totQ == None and ScoThr != None and TopNRa != None:
            score = [float(ScoThr), 'top' + str(args.top_n_ranked)]
            flag = 'Stop'
        for mol in mol_list:
            fil_sdf_dict.append(filter_poses(mol, sdf_dict, score, flag))

        for mols in fil_sdf_dict:
            if len(mols) > 0:
                for mol_dict in mols: # len(mol_dict) always =1
                    (ind, y), = mol_dict.items()
                    if ScoThr != None and TopNRa != None:
                        if y[1] > args.score_threshold:
                            continue
                    mol_out = all_molecules[int(ind[0:5])]
                    output_sdf.write(''.join([xx for xx in mol_out]))
                    if num_sdf == 0 and pdb_aid == 1:
                        csv_out = out_csv[0]
                        output_csv.write(','.join([xx for xx in csv_out]+['\n']))
                    csv_out = out_csv[int(ind[0:5])+1]                    
                    output_csv.write(','.join([xx for xx in csv_out]+['\n']))

                    if args.centroid_pdb != None:
                        dum = ('ATOM', pdb_aid, 'N', 'DUM', 1, y[1], y[2], y[3], 1.0, y[0], 'N')
                        pdbline = pdb_format % dum
                        PdbCen.write(pdbline)
                        pdb_aid += 1
        num_sdf += 1
    output_sdf.close()
    output_csv.close()
    output_csv_all.close()
    if args.centroid_pdb != None:
        PdbCen.close()
        

if __name__ == '__main__':
    main()
