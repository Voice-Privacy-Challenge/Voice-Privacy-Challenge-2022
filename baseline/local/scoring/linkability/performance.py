import numpy as np
import matplotlib.pyplot as plt
from matplotlib.legend import Legend
import seaborn as sns
# %matplotlib inline


def linkability(matedScores, nonMatedScores, omega):
    omega=1
    nBins = min(int(len(matedScores) / 10), 100)

    # define range of scores to compute D
    bin_edges=np.linspace(min([min(matedScores), min(nonMatedScores)]),  max([max(matedScores), max(nonMatedScores)]), num=nBins + 1, endpoint=True)

    bin_centers = (bin_edges[1:] + bin_edges[:-1]) / 2 # find bin centers

    # compute score distributions (normalised histogram)
    y1 = np.histogram(matedScores, bins = bin_edges, density = True)[0]
    y2 = np.histogram(nonMatedScores, bins = bin_edges, density = True)[0]

    LR = np.divide(y1, y2, out=np.ones_like(y1), where=y2!=0)
    D = 2*(omega*LR/(1 + omega*LR)) - 1
    D[omega*LR <= 1] = 0
    #D[y2 == 0] = 1 # this is the definition of D, and at the same time takes care of inf / nan
    mask =  [True if y2[i]==0 and y1[i]!=0 else False for i in range(len(y1))]
    D[mask] = 1 # this is the definition of D, and at the same time takes care of inf / nan
    # Compute and #print Dsys
    Dsys = np.trapz(x = bin_centers, y = D* y1)
    return Dsys, D, bin_centers, bin_edges


def draw_scores(matedScores, nonMatedScores, Dsys, D, bin_centers, bin_edges, output_file):
    colors=['#1b9e77','#d95f02','#7570b3']
    figureTitle=''
    if figureTitle=='':
     figureTitle='Clean'
    legendLocation='upper left'
    plt.clf()
    #sns.set_context("paper",font_scale=1.7, rc={"lines.linewidth": 2.5})
    #sns.set_context("paper",font_scale=1.7)
    #sns.set_style("white")
    ax = sns.kdeplot(matedScores, shade=False, label='Same User', color=colors[0])
    x1,y1 = ax.get_lines()[0].get_data()
    ax = sns.kdeplot(nonMatedScores, shade=False, label='Not Same User', color=colors[1],linewidth=2, linestyle='--')
    x2,y2 = ax.get_lines()[1].get_data()

    ax2 = ax.twinx()
    lns3, = ax2.plot(bin_centers, D, label='$\mathrm{D}_{\leftrightarrow}(s)$', color=colors[2],linewidth=2)

    # #print omega * LR = 1 lines
    index = np.where(D <= 0)
    ax.axvline(bin_centers[index[0][0]], color='k', linestyle='--')

    # Figure formatting
    ax.spines['top'].set_visible(False)
    ax.set_ylabel("Probability Density")
    ax.set_xlabel("Score")
    #ax.set_title("%s, $\mathrm{D}_{\leftrightarrow}^{\mathit{sys}}$ = %.2f" % (figureTitle, Dsys),  y = 1.02)
    ax.set_title("$\mathrm{D}_{\leftrightarrow}^{\mathit{sys}}$ = %.2f" % (Dsys),  y = 1.02)

    labs = [ax.get_lines()[0].get_label(), ax.get_lines()[1].get_label(), ax2.get_lines()[0].get_label()]
    lns = [ax.get_lines()[0], ax.get_lines()[1], lns3]
    ax.legend(lns, labs, loc = legendLocation)

    ax.set_ylim([0, max(max(y1), max(y2)) * 1.05])
    ax.set_xlim([bin_edges[0]*0.98, bin_edges[-1]*1.02])
    ax2.set_ylim([0, 1.1])
    ax2.set_ylabel("$\mathrm{D}_{\leftrightarrow}(s)$")

    # the replacements of extentions are not a must
    outname= output_file.replace('.pdf', '').replace('.png', '').replace('.csv', '').replace('.txt', '')
    plt.savefig(outname + ".pdf", format="pdf")
    plt.savefig(outname + ".png", format="png")






