import numpy as np
fs=4.0; N=int(600*fs)+480
rs=np.random.default_rng(11)
# simple profile: maximumCenterSeparationHz=0, spectralSimilarity=1 -> identical input PSD shapes
f=np.arange(N)*fs/N; fa=np.minimum(f,fs-f)
P=np.exp(-0.5*((fa-0.06)/0.045)**2)+0.01   # same shape for MAP and CO2
def exp_k(g,tau,delay,ntau=6):
    n=max(int(round(ntau*tau*fs)),1); t=np.arange(n)/fs
    k=np.exp(-t/tau); k=g*k/k.sum(); d=int(round(delay*fs))
    return np.concatenate([np.zeros(d),k])
def map_k(hf,lf,tau,ntau=6):
    n=max(int(round(ntau*tau*fs)),1); t=np.arange(n)/fs
    lp=np.exp(-t/tau); lp/=lp.sum(); imp=np.zeros(n); imp[0]=1
    return hf*(lf*imp+(1-lf)*(imp-lp))
def H(k,fr): 
    w=2*np.pi*fr/fs
    return np.array([np.sum(k*np.exp(-1j*wi*np.arange(len(k)))) for wi in w])
mk=map_k(1.5,0.25,3.0); ck0=exp_k(1.0,5.0,3.0)
# band scaling to ratio 1 over [0.02,0.50]
fg=np.linspace(0.02,0.5,2048)
ck=ck0*(np.sqrt(np.mean(np.abs(H(mk,fg))**2))/np.sqrt(np.mean(np.abs(H(ck0,fg))**2)))
fr=np.linspace(0.02,0.5,60); Hm=H(mk,fr); Hc=H(ck,fr)

print(" gamma | mean |SISO_map - H_map| / mean|H_map| |  predicted sqrt(g)*|Hc|/|Hm| ")
for g in [0.0,0.5,0.95]:
    est=[]
    for trial in range(60):
        s=np.fft.fft(rs.normal(size=N)); n=np.fft.fft(rs.normal(size=N))
        M=np.real(np.fft.ifft(np.sqrt(P)*s)); C=np.real(np.fft.ifft(np.sqrt(P)*(np.sqrt(g)*s+np.sqrt(1-g)*n)))
        M=(M-M.mean())/M.std(); C=(C-C.mean())/C.std()
        y=np.convolve(M,mk)[:N]+np.convolve(C,ck)[:N]
        M,C,y=M[480:],C[480:],y[480:]
        L=len(M); w=np.hanning(L)
        FM=np.fft.fft(M*w); FC=np.fft.fft(C*w); FY=np.fft.fft(y*w)
        ff=np.fft.fftfreq(L,1/fs)
        idx=[np.argmin(np.abs(ff-x)) for x in fr]
        Smy=(np.conj(FM)*FY)[idx]; Smm=(np.abs(FM)**2)[idx]
        est.append(Smy/Smm)
    Hsiso=np.mean(est,axis=0)
    emp=np.mean(np.abs(Hsiso-Hm))/np.mean(np.abs(Hm))
    pred=np.sqrt(g)*np.mean(np.abs(Hc))/np.mean(np.abs(Hm))
    print(f" {g:<5} |            {emp:<22.4f}|  {pred:.4f}")
