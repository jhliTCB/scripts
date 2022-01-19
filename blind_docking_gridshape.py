# show the shape for successful and failed grids
# b-factor: successful grid 1.00, failed grid 0.00

import sys
import os

if len(sys.argv) < 2:
    print("Usage: {} docking_dir".format(sys.argv[0]))
    exit

dock_dir = sys.argv[1].replace('/', '')
all_dirs = os.listdir(dock_dir)
grid_dir = [x for x in all_dirs if x.startswith('grid_')]

odd_pdb = '%-6s%5d  %-4s%-4s%5d%12.3f%8.3f%8.3f%6.2f%6.2f%12s\n'
out_pdb = open('grid_shape2_{}.pdb'.format(dock_dir), 'w')

for grid in grid_dir:
    grid_name = '{}/{}/{}.zip'.format(dock_dir, grid, grid)
    ii = int(grid.split('_')[1])
    xx = float(grid.split('_')[2])
    yy = float(grid.split('_')[3])
    zz = float(grid.split('_')[4])
    if os.path.isfile(grid_name):
        bft = 1.00
    else:
        bft = 0.00
    out_pdb.write(odd_pdb % ('ATOM', ii, 'N', 'DUM', ii, xx, yy, zz, 1.00, bft, 'N'))

out_pdb.close()
