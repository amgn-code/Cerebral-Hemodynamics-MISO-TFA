import numpy as np, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
plt.rcParams.update({"font.size":9,"axes.grid":True,"grid.alpha":0.3,
  "axes.spines.top":False,"axes.spines.right":False,"figure.dpi":150})
BLUE="#1f5fa9"; ORANGE="#d95f02"; GREY="#555555"; RED="#b3261e"; GREEN="#2b7a3d"

fig,ax=plt.subplots(figsize=(6.6,3.3))
for s in [0,0.50,0.95]:
    ax.axvline(s,color=BLUE,lw=2.5,alpha=.85)
    ax.text(s,0.965,f"{s:g}",ha="center",va="bottom",fontsize=8.5,color=BLUE,
            fontweight="bold",transform=ax.get_xaxis_transform())
ax.text(0.50,0.90,"simulation levels",ha="center",fontsize=8,color=BLUE,
        transform=ax.transAxes)
raw=[0.1812,0.2395,0.2822]; corr=[0.064,0.131,0.180]
ax.axvspan(corr[0],corr[2],color=GREEN,alpha=.16,zorder=0)
ax.plot(corr,[0.52]*3,"o-",color=GREEN,lw=2.5,ms=8,zorder=5)
ax.text(0.205,0.52,"  NC, bias-corrected\n  10th / 50th / 90th",fontsize=8,color=GREEN,va="center")
ax.plot(raw,[0.26]*3,"s--",color=GREY,lw=1.6,ms=6,alpha=.9,zorder=4)
ax.text(0.30,0.26,"  NC, raw estimate",fontsize=8,color=GREY,va="center")
ax.axvline(0.125,color=RED,ls=":",lw=1.6)
ax.text(0.135,0.70,"estimator null\n1/8 = 0.125",fontsize=7.5,color=RED,va="center")
ax.set_xlim(-0.02,1.0); ax.set_ylim(0,0.86); ax.set_yticks([])
ax.set_xlabel(r"MAP$-$PETCO$_2$ ordinary coherence  $\gamma^2$")
ax.set_title("The NC recordings sit between the two lowest simulation levels.\n"
             "No level covers the regime the data actually occupies.",fontsize=9.5,pad=22)
fig.tight_layout(); fig.savefig("f1_operating_point.png"); plt.close(fig)

f=np.linspace(0.02,0.35,200)
gen=np.exp(-0.5*((f-0.06)/0.045)**2)+0.01; gen_db=10*np.log10(gen/gen.max())
fm=np.array([0.02,0.033,0.05,0.07,0.09,0.10,0.125,0.145,0.167,0.20,0.23,0.255,0.28,0.30,0.325,0.345])
mp=np.array([47.5,21.5,20,17.5,12,10.5,7.5,3.3,2.7,4.7,5.0,6.2,3.2,-1.5,-0.8,-4])
cp=np.array([40,12.8,9.5,6,4.5,5.0,1.0,-2.0,-0.2,-4,-7,-6,-9,-7.8,-13.2,-12.3])
fig,ax=plt.subplots(figsize=(6.6,3.4))
ax.axvspan(0.20,0.35,color=ORANGE,alpha=.10,zorder=0)
ax.text(0.275,-56,"HF band",ha="center",fontsize=8,color=ORANGE)
ax.plot(fm[1:],mp[1:]-mp[1],"-o",color=BLUE,lw=2,ms=3.5,label="NC MAP (measured median)")
ax.plot(fm[1:],cp[1:]-cp[1],"-o",color=RED,lw=2,ms=3.5,label=r"NC PETCO$_2$ (measured median)")
ax.plot(f,gen_db,color=GREY,lw=2.5,ls="--",label="generator (Gaussian, both inputs)")
ax.plot(fm[0],mp[0]-mp[1],"o",color=BLUE,ms=7,mfc="none",mew=2)
ax.plot(fm[0],cp[0]-cp[1],"o",color=RED,ms=7,mfc="none",mew=2)
ax.annotate("0.02 Hz bin: +26 dB above its\nneighbour, and coherence ~1.0 there.\nResidual-trend leakage, not signal.",
            xy=(0.021,mp[0]-mp[1]),xytext=(0.085,21),fontsize=7.5,color=RED,
            arrowprops=dict(arrowstyle="->",color=RED,lw=1.1))
ax.set_xlabel("Frequency (Hz)"); ax.set_ylabel("power relative to the 0.033 Hz bin (dB)")
ax.set_title("Measured NC inputs fall ~30 dB across 0.033-0.35 Hz; the generator falls ~20 dB\n"
             "and peaks at 0.06 Hz, where the real spectra are already decaying",fontsize=9)
ax.legend(fontsize=7.5,frameon=False,loc="lower left"); ax.set_ylim(-60,32)
fig.tight_layout(); fig.savefig("f2_spectra.png"); plt.close(fig)
print("ok")
