
################################################################
#----------these parameters need to be input manually-----------
fin='fes.dat'
fout='fes.png'
STEP=25
bin1=1001
bin2=1001
N=1  #because there is 11 replica
#################################################################

import sys
import os
import math
import matplotlib.pyplot as plt
from pylab import *
import matplotlib.tri as tri
import numpy as np
import matplotlib.font_manager
hfont = {'fontname':'Helvetica'}

fin = sys.argv[1]
fout = fin+".png"

data = np.genfromtxt(fin)
allX=data[:,0]
allY=data[:,1]
allZ=data[:,2]/N            #kcal/mol
#allZ=data[:,2]                 #kJ/mol, by default

zmax=0
allZ0=allZ                  #Let the upper limit to be 0


X=allX[0:bin1]
Y=allY[range(1,len(allY),bin1)]
Z= allZ0.reshape(bin2,bin1)

levels=np.linspace(Z.min(),0,STEP)
#print "zmin is :\n" ,Z.min()
#print "zmax is :\n" ,zmax



#Z = 0 - Z

#extent = (-180,180,-180,180)

plt.contourf(X,Y,Z, levels= levels, cmap=cm.jet)

#plt.xlabel('CV1 (distance(nm))', fontsize=12,  **hfont)

#plt.xticks(np.arange(X.min(),X.max(),5), fontsize=14)
#plt.ylabel('CV2 (water molecule )', fontsize=12, **hfont)

#plt.yticks(np.arange(Y.min(),Y.max(),5), fontsize=14)
cbar = plt.colorbar(format='%2d')   #color bar
cbar.set_label('Free energy (kcal/mol)',fontsize=14, **hfont) # color bar set
for t in cbar.ax.get_yticklabels():
         t.set_fontsize(14)


fig = plt.gcf()

from matplotlib.ticker import FormatStrFormatter

ax = fig.add_subplot(111)
ax.xaxis.set_major_formatter(FormatStrFormatter('%2.1f'))
ax.yaxis.set_major_formatter(FormatStrFormatter('%2.1f'))
for axis in ['top','bottom','left','right']:
    ax.spines[axis].set_linewidth(1.5)
ax.tick_params(axis='both', which='major', width=0.7, length=3, color='k', labelsize=12)

fig.set_size_inches(5.5, 4, forward=True)
fig.savefig('figure.pdf', bbox_inches='tight', format='pdf', transparent='Ture')



#plt.show()

