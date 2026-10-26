import numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
plt.rcParams.update({"font.size":9,"axes.grid":True,"grid.alpha":0.3,
                     "axes.spines.top":False,"axes.spines.right":False,"figure.dpi":150})
BLUE="#1f5fa9"; ORANGE="#d95f02"; GREY="#555555"
fs=4.0

def exp_k(g,tau,delay,ntau=6):
    n=max(int(round(ntau*tau*fs)),1); t=np.arange(n)/fs
    k=np.exp(-t/tau); k=g*k/k.sum(); d=int(round(delay*fs))
    return np.concatenate([np.zeros(d),k])
def map_k(hf,lf,tau,ntau=6):
    n=max(int(round(ntau*tau*fs)),1); t=np.arange(n)/fs
    lp=np.exp(-t/tau); lp/=lp.sum(); imp=np.zeros(n); imp[0]=1
    return hf*(lf*imp+(1-lf)*(imp-lp))
def H(k,fr):
    w=2*np.pi*np.asarray(fr)/fs
    return np.array([np.sum(k*np.exp(-1j*wi*np.arange(len(k)))) for wi in w])

# ---------- FIG 1: band-dependent generating truth ----------
mk=map_k(1.5,0.25,3.0); ck0=exp_k(1.0,5.0,3.0)
def scale(band):
    fg=np.linspace(band[0],band[1],2048)
    return np.sqrt(np.mean(np.abs(H(mk,fg))**2))/np.sqrt(np.mean(np.abs(H(ck0,fg))**2))
fr=np.linspace(0.005,0.5,300)
s1,s2=scale([0.005,0.35]),scale([0.02,0.50])
fig,ax=plt.subplots(figsize=(6.4,3.0))
ax.plot(fr,np.abs(H(mk,fr)),color=GREY,lw=2,label="true MAP pathway (unchanged)")
ax.plot(fr,s1*np.abs(H(ck0,fr)),color=BLUE,lw=2,label=f"true CO$_2$ pathway, band [0.005, 0.35] Hz  (x{s1:.2f})")
ax.plot(fr,s2*np.abs(H(ck0,fr)),color=ORANGE,lw=2,ls="--",label=f"true CO$_2$ pathway, band [0.02, 0.50] Hz  (x{s2:.2f})")
ax.set_xlabel("Frequency (Hz)"); ax.set_ylabel("|H(f)|")
ax.set_title("Same assigned PETCO2:MAP band-gain ratio of 1, two analysis bands\n"
             f"CO$_2$ generating kernel differs by {100*(s2/s1-1):.0f}%", fontsize=9)
ax.legend(fontsize=7.5,frameon=False); fig.tight_layout(); fig.savefig("fig1_band_truth.png"); plt.close(fig)

# ---------- FIG 2: SISO bias is closed form ----------
fg=np.linspace(0.02,0.5,2048)
ck=ck0*(np.sqrt(np.mean(np.abs(H(mk,fg))**2))/np.sqrt(np.mean(np.abs(H(ck0,fg))**2)))
frr=np.linspace(0.02,0.5,60); Hm=H(mk,frr); Hc=H(ck,frr)
N=int(600*fs)+480; f_=np.arange(N)*fs/N; fa=np.minimum(f_,fs-f_)
P=np.exp(-0.5*((fa-0.06)/0.045)**2)+0.01
rs=np.random.default_rng(11)
gam=np.array([0.0,0.25,0.5,0.75,0.95]); emp=[]
for g in gam:
    est=[]
    for _ in range(40):
        s=np.fft.fft(rs.normal(size=N)); n=np.fft.fft(rs.normal(size=N))
        M=np.real(np.fft.ifft(np.sqrt(P)*s)); C=np.real(np.fft.ifft(np.sqrt(P)*(np.sqrt(g)*s+np.sqrt(1-g)*n)))
        M=(M-M.mean())/M.std(); C=(C-C.mean())/C.std()
        y=np.convolve(M,mk)[:N]+np.convolve(C,ck)[:N]
        M,C,y=M[480:],C[480:],y[480:]; L=len(M); w=np.hanning(L)
        FM=np.fft.fft(M*w); FY=np.fft.fft(y*w); ff=np.fft.fftfreq(L,1/fs)
        idx=[np.argmin(np.abs(ff-x)) for x in frr]
        est.append((np.conj(FM)*FY)[idx]/(np.abs(FM)**2)[idx])
    Hs=np.mean(est,axis=0); emp.append(np.mean(np.abs(Hs-Hm))/np.mean(np.abs(Hm)))
gg=np.linspace(0,1,100); pred=np.sqrt(gg)*np.mean(np.abs(Hc))/np.mean(np.abs(Hm))
fig,ax=plt.subplots(figsize=(6.4,3.0))
ax.plot(gg,pred,color=BLUE,lw=2,label=r"closed form  $\sqrt{\gamma}\,|H_{CO_2}|/|H_{MAP}|$")
ax.plot(gam,emp,"o",color=ORANGE,ms=7,label="simulated SISO error vs conditional truth")
for g in [0,0.5,0.95]: ax.axvline(g,color=GREY,lw=0.7,ls=":")
ax.text(0.5,0.03,"levels used by the 'simple' profile",fontsize=7,color=GREY,transform=ax.get_xaxis_transform(),ha="center")
ax.set_xlabel(r"MAP-CO$_2$ input coherence  $\gamma$"); ax.set_ylabel("normalised MAP-pathway error")
ax.set_title("The SISO 'failure' the study measures is an algebraic identity,\nnot an empirical finding",fontsize=9)
ax.legend(fontsize=7.5,frameon=False,loc="upper left"); fig.tight_layout(); fig.savefig("fig2_estimand.png"); plt.close(fig)

# ---------- FIG 3: ridge explained-power formula ----------
Sxx=np.array([[1.0,0.9+0.1j],[0.9-0.1j,1.0]]); Hs_=np.array([1.0+0.2j,0.5-0.3j])
Syy=(Hs_.conj()@Sxx@Hs_).real+0.2; Sxy=Sxx@Hs_
D=np.diag(np.sqrt(np.diag(Sxx).real)); Di=np.linalg.inv(D)
lams=np.logspace(-4,0,40); code=[];true=[]
for lam in lams:
    Hn=np.linalg.solve(Di@Sxx@Di+lam*np.eye(2),Di@Sxy); Hh=Di@Hn
    code.append((Sxy.conj()@Hh).real/Syy)
    true.append(1-(Syy-2*(Hh.conj()@Sxy).real+(Hh.conj()@Sxx@Hh).real)/Syy)
fig,ax=plt.subplots(figsize=(6.4,3.0))
ax.semilogx(lams,true,color=BLUE,lw=2,label=r"correct:  $1-(S_{yy}-2\mathrm{Re}(H^HS_{xy})+H^HS_{xx}H)/S_{yy}$")
ax.semilogx(lams,code,color=ORANGE,lw=2,ls="--",label=r"runMISOTFA.m:76:  $\mathrm{Re}(S_{xy}^H H)/S_{yy}$")
ax.fill_between(lams,code,true,color=ORANGE,alpha=0.15)
ax.set_xlabel(r"ridge $\lambda$ (standardised scale)"); ax.set_ylabel("multiple coherence")
ax.set_title("Ridge branch: explained power uses the unregularised identity\nApparent loss of explanatory power is a formula artefact",fontsize=9)
ax.legend(fontsize=7.5,frameon=False,loc="lower left"); fig.tight_layout(); fig.savefig("fig3_ridge.png"); plt.close(fig)

# ---------- FIG 4: null coherence bias ----------
K=np.array([0.25,0.5,0.25]); nf=160
def sm(a): return np.convolve(a,K,mode="same")
rs=np.random.default_rng(5); segs=[2,3,5,8,11,16,25]; MC=[];OC=[]
for ns in segs:
    mc=[];oc=[]
    for _ in range(120):
        X=rs.normal(size=(nf,ns,2))+1j*rs.normal(size=(nf,ns,2))
        y=rs.normal(size=(nf,ns))+1j*rs.normal(size=(nf,ns))
        S11=sm(np.mean(np.conj(X[:,:,0])*X[:,:,0],1).real); S22=sm(np.mean(np.conj(X[:,:,1])*X[:,:,1],1).real)
        S12=sm(np.mean(np.conj(X[:,:,0])*X[:,:,1],1)); S1y=sm(np.mean(np.conj(X[:,:,0])*y,1))
        S2y=sm(np.mean(np.conj(X[:,:,1])*y,1)); Syy=sm(np.mean(np.conj(y)*y,1).real)
        for i in range(3,nf-3):
            A=np.array([[S11[i],S12[i]],[np.conj(S12[i]),S22[i]]]); b=np.array([S1y[i],S2y[i]])
            mc.append((np.conj(b)@np.linalg.solve(A,b)).real/Syy[i])
            oc.append(abs(S1y[i])**2/(S11[i]*Syy[i]))
    MC.append(np.mean(mc)); OC.append(np.mean(oc))
MC=np.array(MC); OC=np.array(OC)
fig,ax=plt.subplots(figsize=(6.4,3.0))
ax.plot(segs,MC,"o-",color=BLUE,lw=2,label="MISO multiple coherence (2 inputs)")
ax.plot(segs,OC,"s-",color=GREY,lw=2,label="SISO ordinary coherence (1 input)")
ax.plot(segs,MC-OC,"^--",color=ORANGE,lw=2,label='"MISO minus MAP pairwise coherence" diagnostic')
for x,lab in [(2,"NC bootstrap\ntraining"),(5,"simple profile\n300 s"),(11,"simple profile\n600 s")]:
    ax.axvline(x,color=GREY,lw=0.7,ls=":")
    ax.annotate(lab,(x,0.52),fontsize=6.5,color=GREY,ha="center")
ax.set_xlabel("number of averaged Welch segments"); ax.set_ylabel("coherence under the null (no true relationship)")
ax.set_title("Coherence bias with no true relationship present.\nThe coherence-gap diagnostic has a built-in positive offset that shrinks with record length",fontsize=9)
ax.set_ylim(0,0.62); ax.legend(fontsize=7.5,frameon=False); fig.tight_layout(); fig.savefig("fig4_coherence_bias.png"); plt.close(fig)
print("figures written")
import numpy as np, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
plt.rcParams.update({"font.size":9,"axes.grid":True,"grid.alpha":0.3,
                     "axes.spines.top":False,"axes.spines.right":False,"figure.dpi":150})
BLUE="#1f5fa9"; ORANGE="#d95f02"; GREY="#555555"
K=np.array([0.25,0.5,0.25]); nf=160
def sm(a): return np.convolve(a,K,mode="same")
rs=np.random.default_rng(5); segs=[2,3,5,8,11,16,25]; MC=[];OC=[]
for ns in segs:
    mc=[];oc=[]
    for _ in range(150):
        X=rs.normal(size=(nf,ns,2))+1j*rs.normal(size=(nf,ns,2))
        y=rs.normal(size=(nf,ns))+1j*rs.normal(size=(nf,ns))
        S11=sm(np.mean(np.conj(X[:,:,0])*X[:,:,0],1).real); S22=sm(np.mean(np.conj(X[:,:,1])*X[:,:,1],1).real)
        S12=sm(np.mean(np.conj(X[:,:,0])*X[:,:,1],1)); S1y=sm(np.mean(np.conj(X[:,:,0])*y,1))
        S2y=sm(np.mean(np.conj(X[:,:,1])*y,1)); Syy=sm(np.mean(np.conj(y)*y,1).real)
        for i in range(3,nf-3):
            A=np.array([[S11[i],S12[i]],[np.conj(S12[i]),S22[i]]]); b=np.array([S1y[i],S2y[i]])
            mc.append((np.conj(b)@np.linalg.solve(A,b)).real/Syy[i])
            oc.append(abs(S1y[i])**2/(S11[i]*Syy[i]))
    MC.append(np.mean(mc)); OC.append(np.mean(oc))
MC=np.array(MC); OC=np.array(OC)
fig,ax=plt.subplots(figsize=(6.4,3.2))
ax.plot(segs,MC,"o-",color=BLUE,lw=2.2,ms=6,label="MISO multiple coherence (2 inputs)")
ax.plot(segs,OC,"s-",color=GREY,lw=2.2,ms=6,label="SISO ordinary coherence (1 input)")
ax.plot(segs,MC-OC,"^",color=ORANGE,ms=9,mfc="none",mew=2,
        label='coherence-gap diagnostic  =  multiple - pairwise')
for x,lab,yy in [(2,"NC bootstrap\ntraining (2)",0.44),(5,"simulation\n300 s (5)",0.44),(11,"simulation\n600 s (11)",0.44)]:
    ax.axvline(x,color=GREY,lw=0.7,ls=":"); ax.annotate(lab,(x,yy),fontsize=6.5,color=GREY,ha="center")
ax.annotate("the gap's null value sits exactly on the\nSISO curve: both equal 1 / effective d.o.f.",
            xy=(8,MC[3]-OC[3]),xytext=(14,0.28),fontsize=7,color=ORANGE,
            arrowprops=dict(arrowstyle="->",color=ORANGE,lw=1))
ax.set_xlabel("number of averaged Welch segments")
ax.set_ylabel("coherence when there is\nno true relationship")
ax.set_title("Coherence bias under the null. MISO's multiple coherence carries roughly twice\n"
             "the upward bias of SISO's ordinary coherence, and neither is corrected in the code",fontsize=8.5)
ax.set_ylim(0,0.56); ax.legend(fontsize=7.5,frameon=False,loc="upper right")
fig.tight_layout(); fig.savefig("fig4_coherence_bias.png"); plt.close(fig)
print("ok")
