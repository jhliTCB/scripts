#!/usr/bin/env python
import sys
import argparse

def own_parse():
    parser = argparse.ArgumentParser(description='Get xyz summary from a PDB, default print minmax',
    formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-i','--input_pdb',type=str,required=True,help=
    '''    A PDB file for processing, 
    str, Required;       e.g. -i step5_assembly.pdb
     ''')
    parser.add_argument('-s', '--res_selection',type=str,default='all',help=
    '''    residue selection expression seperated by comma, default is 'all'
    str, optional; e.g. -s water; -s protein; -s protein,LIG; -s PA,PC,OL
    ''')
    parser.add_argument('-d', '--dimension',action='store_true',help=
    '''    print the dimension of the selected residues
    optional, no parameters required, e.g. -d; --dimension
    ''')
    parser.add_argument('-c', '--center',action='store_true',help=
    '''    print the geometrical center of the selected residues
    optional, no parameters required, e.g. -c; --center
    ''')
    return parser

def lmean(lst):
    sum = 0
    for x in lst:
        sum += x
    return sum/len(lst)

def main():
    parses = own_parse()
    args = parses.parse_args()
    pdb = args.input_pdb
    sele = args.res_selection
    X, Y, Z = [], [], []
    for line in open(pdb, 'r'):
        if line[0:4] in ['ATOM', 'HETA']:
            if sele == 'all':
                X.append(float(line[30:38].strip()))
                Y.append(float(line[38:46].strip()))
                Z.append(float(line[46:54].strip()))
            else:
                res_lst = gen_res_list(sele)
                if line[17:21].strip() in res_lst:
                    X.append(float(line[30:38].strip()))
                    Y.append(float(line[38:46].strip()))
                    Z.append(float(line[46:54].strip()))
    if len(X) == 0:
        sys.stdout.write('selection \'%s\' not found in the pdb!\n\n' % sele)
        sys.stdout.flust()
        sys.exit(1)

    #sys.stdout.write('\n'.join([str(x) for x in out]))
    sys.stdout.write('\n%10s %10s %10s\n%10s %10s %10s\n\n' % (min(X), min(Y), min(Z), max(X), max(Y), max(Z)))
    if args.center:
        sys.stdout.write('%10.4f %10.4f %10.4f\n\n' % (lmean(X), lmean(Y), lmean(Z)))
    if args.dimension:
        sys.stdout.write('%10s %10s %10s\n\n' % (max(X)-min(X), max(Y)-min(Y), max(Z)-min(Z)))
    sys.stdout.flush()

def gen_res_list(sele):
    # For amber memberane, sele = 'PA,PC,OL'
    out = []
    for text in sele.split(','):
        if text in ['water', 'WATER', 'solvent', 'SOLVENT']:
            out += ['WAT', 'HOH', 'TIP3', 'SOL']
        elif text in ['protein', 'Protein', 'PROTEIN']:
            out += ["ALA", "ARG", "ASN", "ASP", "CYS", "GLN",
                    "GLU", "GLY", "HIS", "ILE", "LEU", "LYS",
                    "MET", "PHE", "PRO", "SER", "THR", "TRP", "CYS2",
                    "TYR", "VAL", "HID", "HIE", "HIP", "GLH", "CYI",
                    "ASH", "HSD", "HSE", "HSP", "GLUP", "ASPP"]
        else:
            out.append(text)
    return out
    
if __name__ == '__main__':
    main()
