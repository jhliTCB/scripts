#!/usr/bin/env python
import sys
import argparse

'''
try to not omit the chains, if there are multiple chains in a protein!
'''

def own_parse():
    parser = argparse.ArgumentParser(description='Get xyz summary from a PDB, default print minmax',
    formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-i','--input_pdb',type=str,required=True,help=
    '''    A PDB file for processing, 
    str, Required;       e.g. -i step5_assembly.pdb
     ''')
    parser.add_argument('-o', '--output_pdb',type=str,required=True,help=
    '''    Output PDB name
    str, Required; e.g. -o step5_assembly4leap.pdb
    ''')
    parser.add_argument('-ln', '--ligand_name',type=str,default="UNK",help=
    '''    residue name(s) for the ligand(s), e.g. UNK | UNK,UCF | UCB,UCD
    ''')
    return parser

def main():
    pro_lst = ["ALA", "ARG", "ASN", "ASP", "CYS", "GLN",
               "GLU", "GLY", "HIS", "ILE", "LEU", "LYS",
               "MET", "PHE", "PRO", "SER", "THR", "TRP", "CYS2",
               "TYR", "VAL", "HID", "HIE", "HIP", "GLH", "CYI",
               "ASH", "HSD", "HSE", "HSP", "GLUP", "ASPP", "CYT"]
    wat_lst = ["T3P", "SPC"]
    ion_lst = ["NA", "CL", "K"]
    parses = own_parse()
    args = parses.parse_args()
    pdb = open(args.input_pdb, 'r')
    out = open(args.output_pdb, 'w')
    lig_lst  = args.ligand_name.split(',')
    tmp_out, tmp_wat, tmp_ion, chain_lst = [], [], [], []
    i, j, k, l = 0, 0, 0, 0
    X, Y, Z = [], [], []
    for line in pdb:
        if 'CRYST' in line:
            continue # will use the dimension of protein and ligand for box!
        if 'TITLE' in line or 'REMARK' in line:
            #tmp_out.append(line)
            continue
        if line[0:4] in ['ATOM', 'HETA']:
            i += 1
            res = line[17:21].strip()
            chain = line[21:23].strip()
            if chain not in chain_lst:
                chain_lst.append(chain)
                j += 1
            if res in pro_lst:
                X.append(float(line[30:38].strip()))
                Y.append(float(line[38:46].strip()))
                Z.append(float(line[46:54].strip()))
                if line.split()[-1] != 'H': # waive if element column not exists
                    if res == 'HIS':
                        line = line.replace('HIS', 'HID')
                    if chain not in chain_lst and i > 0:
                        tmp_out.append('TER\n'+line)
                    else:
                        tmp_out.append(line)
                    k += 1
            elif res in wat_lst:
                line = line.replace('HETATM', 'ATOM  ')
                line = line.replace('T3P', 'WAT')
                line = line.replace('SPC', 'WAT')
                tmp_wat.append(line)
                k += 1
            elif res in ion_lst:
                line = line.replace('HETATM', 'ATOM  ')
                line = line.replace('NA ', 'Na+')
                line = line.replace('CL ', 'Cl-')
                line = line.replace('K  ', 'K+ ')
                tmp_ion.append(line)
                k += 1
            elif res in lig_lst:
                X.append(float(line[30:38].strip()))
                Y.append(float(line[38:46].strip()))
                Z.append(float(line[46:54].strip()))
                line = line.replace('HETATM', 'ATOM  ')
                if l == 0:
                    line = 'TER\n' + line
                tmp_out.append(line)
                l += 1
        elif 'CONECT' in line:
            break
            
    if len(tmp_out) == 0 or len(tmp_wat) == 0 or len(tmp_ion) == 0:
        sys.stdout.write('Some atoms are missing, please check! protein? ligand? water? ions?')
        sys.stdout.flush()
        sys.exit(1)
    sys.stdout.write("mae total atoms: %d; amb total atoms: %d; total chains: %d\n" % (i, k, j))
    sys.stdout.flush()
    tmp_ion.sort(key=GetRes)
    CRYST1 = "CRYST1{:9.3f}{:9.3f}{:9.3f}{:7.2f}{:7.2f}{:7.2f} P 1           0\n".format(
             max(X)-min(X), max(Y)-min(Y), max(Z)-min(Z), 90.0, 90.0, 90.0)
    tmp_out = [CRYST1] + tmp_out + ['TER\n'] + tmp_wat + ['TER\n'] + tmp_ion + ['END\n']
    out.write(''.join(tmp_out))
    out.close()
    pdb.close()

def GetRes(line):
    return line[17:21].strip()

if __name__ == '__main__':
    main()
