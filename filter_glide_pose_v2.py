#!/usr/bin/env python3
# processing sdf output from glide docking
import argparse
import os, sys

def get_parser():
    less_indent = lambda prog: argparse.RawTextHelpFormatter(prog, max_help_position=4)
    parser = argparse.ArgumentParser(description='processing sdf output from glide docking',
    formatter_class=less_indent)
    #formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-l','--list_file',type=str,required=True,help=
    '''    A list of the docking outputs (the .sdf file list), 
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
    parser.add_argument('-site','--siteXYZ',type=str,default=None,help=
    '''    Provide a list of sites with their xyz coordination centers and ranges.
    str, optional;       e.g. -site site_list.csv (name, xyz centers, xyz range)
                         giving a 2-site example: site_S1,26.0,-42.0,0.0,2.0,2.0,3.5
                                                  site_E1,0.0,-38.0,0.0,2.0,2.0,3.5
                    will return 1 more sdf files: filtered_poses_sites_labeled.sdf
                                                  filtered_poses_site_E1_poses.sdf
    ''')
    parser.add_argument('--split', action='store_true', help=
    '''    split the sites_labeled.sdf, in the case of 2-site example, it return 
    2 more sdf files: filtered_poses_site_S1_poses.sdf and filtered_poses_site_E1_poses.sdf
    --split must be used together with -site; i.e. script -site site_list.csv --split -s xxx
    ''')
    return parser

def lmean(lst):
    #numpy is faster for huge list! but ligand number is small
    sum = 0
    for x in lst:
        sum += x
    return sum/len(lst)

def getxyz(lst):
    num_atom = int(lst[3].split()[0])
    x, y, z = [], [], []
    for i in range(4, 4 + num_atom):
        x.append(float(lst[i][0:10].strip()))
        y.append(float(lst[i][10:20].strip()))
        z.append(float(lst[i][20:30].strip()))
    return [lmean(x), lmean(y), lmean(z)]

def read_sdf(sdf):
    # return tuple, ({mol:[properties]}, ...)
    # properties: {mol:[score, cord_center, cord_minmax, ...]}
    # present: {mol:[score, xave, yave, zave]}
    flag, num_mol = 0, 0
    out = {}
    mol_list = []
    all_molecules = []
    for line in open(sdf, 'r'):
        if flag == 0:
            mol = line.strip()
            #all_mol_list.append(mol)
            if mol not in mol_list:
                mol_list.append(mol)
            temp= []
            flag = 1
        if flag == 1:          
            temp.append(line)
        if '$$$$' in line:
            all_molecules.append(temp)
            id_mol = ("%05d" % num_mol) + mol # same index as all_molecules!
            row_score = '> <r_i_docking_score>\n'
            score = temp[temp.index(row_score) + 1].strip()
            xyzinfo = getxyz(temp)
            out[id_mol] = [float(score)] + xyzinfo
            flag = 0
            num_mol += 1

    return out, mol_list, all_molecules

def filter_poses(mol, outinfo, score):
    # score: float or 'top%d'
    out = []
    i = 0
    for x, y in outinfo.items():
        if x[5:] == mol:
            if 'top' not in str(score) and y[0] < float(score):
                out.append({x:y})
            elif 'top' in str(score):
                n = score[3:]
                if i < int(n):
                    out.append({x:y})
        i += 1

    return out

def process_sites(sites=None, sdf=None, sxyz=None, prefix=None, sperate=None):
    # Check if the centroid of a pose is within the range of a certain site
    total_out_name = "{}_all_sites.sdf".format(prefix.split('.')[0])
    if sdf:
        for line in open(sites, 'r'):
            line = line.split(',')
            name = line[0]
            minX, maxX = [], []
            for j in range(1, 4):
                minX.append(float(line[j])-float(line[j+3]))
                maxX.append(float(line[j])+float(line[j+3]))
            if     minX[0]<sxyz[1]<maxX[0] and minX[1]<sxyz[2]<maxX[1] and minX[2]<sxyz[3]<maxX[2]:
                insert_ind = sdf.index('$$$$\n')
                sdf.insert(insert_ind, "> <s_s_SITE_NAME\n{}\n\n".format(name))
                if sperate:
                    out_sdf_name = "{}_site_{}_poeses.sdf".format(prefix.split('.')[0], name)
                    if not os.path.isfile(out_sdf_name):
                        out_sdf = open(out_sdf_name, 'w')
                    else:
                        out_sdf = open(out_sdf_name, 'a')
                    out_sdf.write(''.join(sdf))
                if not os.path.isfile(total_out_name):
                    total_out = open(total_out_name, 'w')
                else:
                    total_out = open(total_out_name, 'a')
                total_out.write(''.join(sdf))
                mol_name = sdf[0].strip('\n')
                sinfo = "Found {} located at site {}!\n".format(mol_name, name)
                return sinfo
    else:
        for line in open(sites, 'r'):
            name = line.split(',')[0]
            out_sdf_name = "{}_site_{}_poese.sdf".format(prefix.split('.')[0], name)
            if os.path.isfile(out_sdf_name):
                out_sdf.close()
        if os.path.isfile(total_out_name):
            total_out.close()
        return None
    return None

def main():
    parser = get_parser()
    args = parser.parse_args()   
    ScoThr = args.score_threshold
    TopNRa = args.top_n_ranked
    if ScoThr == None and TopNRa == None:
        sys.stdout.write('At least one filter (-top or -s) is needed\nStop...\n')
        sys.stdout.flush()
        exit(1)

    if args.centroid_pdb != None:
        PdbCen = open(args.centroid_pdb, 'w')
        pdb_format = "%-6s%5d  %-4s%-4s%5d%12.3f%8.3f%8.3f%6.2f%6.2f%12s\n"
        pdb_aid = 1
    
    OutPut = open(args.output_sdf, 'w')
    dockings = [x.strip('\n') for x in open(args.list_file, 'r')]
    for a_dock in dockings:
        sys.stdout.write('Processing %s\n' % a_dock)
        #sdf = '%s/%s/%s_lib.sdf' % (os.getcwd(), a_dock, a_dock)
        sdf = a_dock
        sdf_dict, mol_list, all_molecules = read_sdf(sdf)
        sys.stdout.write('top 1 ranked ligand in %s is %s, score: %f\n' 
                         % (a_dock, mol_list[0], sdf_dict['00000'+mol_list[0]][0]))
        sys.stdout.flush()
        fil_sdf_dict = []
        if ScoThr != None:
            score = args.score_threshold
            for mol in mol_list:
                fil_sdf_dict.append(filter_poses(mol, sdf_dict, score))
        elif TopNRa != None:
            score = 'top' + str(args.top_n_ranked)
            for mol in mol_list:
                fil_sdf_dict.append(filter_poses(mol, sdf_dict, score))

        for mols in fil_sdf_dict:
            if len(mols) > 0:
                for mol_dict in mols: # len(mol_dict) always =1
                    (ind, y), = mol_dict.items()
                    if ScoThr != None and TopNRa != None:
                        if y[0] > args.score_threshold:
                            continue
                    mol_out = all_molecules[int(ind[0:5])]
                    OutPut.write(''.join([xx for xx in mol_out]))

                    if args.siteXYZ != None:
                        split_mol_out = process_sites(sites=args.siteXYZ, sdf=mol_out, 
                                                sxyz=y, prefix=args.output_sdf, sperate=args.split)
                        if split_mol_out:
                            sys.stdout.write(split_mol_out)
                            sys.stdout.flush()

                    if args.centroid_pdb != None:
                        dum = ('ATOM', pdb_aid, 'N', 'DUM', 1, y[1], y[2], y[3], 1.0, y[0], 'N')
                        pdbline = pdb_format % dum
                        PdbCen.write(pdbline)
                        pdb_aid += 1

    OutPut.close()
    if args.centroid_pdb != None:
        PdbCen.close()
    if args.siteXYZ != None:
        close_sites_sdf = process_sites(sites=args.siteXYZ, prefix=args.output_sdf)    

if __name__ == '__main__':
    main()
