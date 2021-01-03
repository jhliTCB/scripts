import sys

def USAGE():
    msg = "USAGE: %s protein.pdb\n" % sys.argv[0]
    sys.stdout.write(msg)
    sys.stdout.flush()
    exit()

def lmean(lst):
    sum = 0
    for x in lst:
        sum += x
    return sum/len(lst)

def main(pdb):
    out = []
    X, Y, Z = [], [], []
    for line in open(pdb, 'r'):
        if line[0:4] in ['ATOM', 'HETA']:
            X.append(float(line[30:38].strip()))
            Y.append(float(line[38:46].strip()))
            Z.append(float(line[46:54].strip()))
    out.append([min(X), min(Y), min(Z)])
    out.append([max(X), max(Y), max(Z)])
    xb, yb, zb = lmean(X), lmean(Y), lmean(Z)
    sys.stdout.write('minmax:\n')
    sys.stdout.write('\n'.join([str(x) for x in out]))
    sys.stdout.write('\n\npdb centroid:\n')
    sys.stdout.write('%s %s %s\n\n' % (xb, yb, zb))
    sys.stdout.flush()
    
if __name__ == '__main__':
    if len(sys.argv) < 2:
        USAGE()
    main(sys.argv[1])
