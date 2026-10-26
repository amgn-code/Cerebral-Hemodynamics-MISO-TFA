from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from lxml import etree as E
from copy import deepcopy as cp
from difflib import SequenceMatcher
import re, hashlib, json
ROOT=Path(__file__).resolve().parents[2]
WORK=Path(__file__).resolve().parent
SRC=Path('/Users/amoghn/Downloads/sho_misotfa.docx')
BASE=WORK/'sho_misotfa_before_revision.docx'
if not BASE.exists(): BASE.write_bytes(SRC.read_bytes())
NEW=ROOT/'Development and Validation of a Two-Input TFA — Methods Revision (Word).docx'
OUT=ROOT/'sho_misotfa.docx'
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main','m':'http://schemas.openxmlformats.org/officeDocument/2006/math','r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships','w14':'http://schemas.microsoft.com/office/word/2010/wordml','w15':'http://schemas.microsoft.com/office/word/2012/wordml','w16cid':'http://schemas.microsoft.com/office/word/2016/wordml/cid','w16cex':'http://schemas.microsoft.com/office/word/2018/wordml/cex'}
def q(s): a,b=s.split(':'); return '{'+ns[a]+'}'+b
def el(s,**attrs):
 x=E.Element(q(s))
 for k,v in attrs.items():x.set(q(s.split(':')[0]+':'+k),str(v))
 return x
def serialize(x): return E.tostring(x,xml_declaration=True,encoding='UTF-8',standalone=True)
def text(x):return ''.join(x.xpath('.//w:t/text()',namespaces=ns))
def run(s,deleted=False,pr=None):
 r=el('w:r')
 if pr is not None:r.append(cp(pr))
 t=el('w:delText' if deleted else 'w:t');t.set('{http://www.w3.org/XML/1998/namespace}space','preserve');t.text=s;r.append(t);return r
with ZipFile(BASE) as z: parts={n:z.read(n) for n in z.namelist()}
with ZipFile(NEW) as z: srcparts={n:z.read(n) for n in z.namelist()}
doc=E.fromstring(parts['word/document.xml']);body=doc.find('w:body',ns);b=list(body)
original_intro=[text(b[7]),text(b[8])]
ids=[int(x) for x in doc.xpath('//@w:id',namespaces=ns) if x.isdigit()];rid=max(ids)+100
AUTHOR='Naganand, Amogh';DATE='2026-09-17T17:00:00Z'
def change(kind,s,pr=None):
 global rid
 x=el('w:'+kind,id=rid,author=AUTHOR,date=DATE);rid+=1
 if s:x.append(run(s,kind=='del',pr))
 return x
def replace(p,new):
 old=text(p)
 # Keep leading whitespace with the following word or punctuation. This lets
 # Word present a changed phrase as one coherent redline instead of generating
 # a separate deletion balloon for every word separated by an unchanged space.
 a=re.findall(r'\s*(?:\w+|[^\w\s])',old)
 c=re.findall(r'\s*(?:\w+|[^\w\s])',new)
 pp=p.find('w:pPr',ns)
 pr=p.find('w:r/w:rPr',ns)
 starts=[cp(x) for x in p.findall('w:commentRangeStart',ns)]
 ends=[cp(x) for x in p.findall('w:commentRangeEnd',ns)]
 refs=[cp(x) for x in p.findall('w:r',ns) if x.find('w:commentReference',ns)is not None]
 for x in list(p):
  if x is not pp:p.remove(x)
 for x in starts:p.append(x)
 for tag,i,j,k,l in SequenceMatcher(None,a,c,autojunk=False).get_opcodes():
  if tag=='equal':p.append(run(''.join(a[i:j]),pr=pr))
  else:
   if i<j:p.append(change('del',''.join(a[i:j]),pr))
   if k<l:p.append(change('ins',''.join(c[k:l]),pr))
 for x in ends+refs:p.append(x)
def newp(s,heading=False):
 p=el('w:p');pp=el('w:pPr');p.append(pp)
 if heading:pp.append(el('w:keepNext'));rp=el('w:rPr');rp.append(el('w:b'));p.append(run(s,pr=rp))
 else:p.append(run(s))
 return p
# Preserve Sho's insertion objects. An Amogh deletion nested inside an existing insertion
# records the second author's correction without accepting the first author's revision.
def delete_phrase(p,phrase):
 nodes=p.xpath('.//w:t[not(ancestor::w:del)]',namespaces=ns);joined=''.join(n.text or '' for n in nodes);start=joined.index(phrase);end=start+len(phrase);pos=0
 for t in nodes:
  s=t.text or '';a=max(0,start-pos);z=min(len(s),end-pos);pos+=len(s)
  if a>=z:continue
  r=t.getparent();parent=r.getparent();at=parent.index(r);pr=r.find('w:rPr',ns)
  seq=[]
  if a:seq.append(run(s[:a],pr=pr))
  seq.append(change('del',s[a:z],pr))
  if z<len(s):seq.append(run(s[z:],pr=pr))
  parent.remove(r)
  for k,x in enumerate(seq):parent.insert(at+k,x)
# Title and deferred abstract remain reviewable against Sho's original file.
replace(b[0],'Development and Validation of a Two-Input Transfer Function Analysis for Blood Pressure, CO₂, and Cerebral Blood Flow Dynamics')
replace(b[1],'Abstract deferred until the results and interpretation are finalized.')
for i in range(2,6):replace(b[i],'')
# Opening retained, with only proofreading, abbreviation definitions, and citations.
delete_phrase(b[8],'manipulation ')
delete_phrase(b[8],'Importantly, CBF also responds dynamically to fluctuations in arterial CO₂. ')
b[7].append(change('ins',' [1,2]'))
b[8].append(change('ins',' [1–3]'))
# Track the removal of Sho's editorial direction; preserve its exact wording in a comment.
delete_phrase(b[11],text(b[11]))
revisions={
12:'A MAP-only model is useful, but MAP is not the only input that can influence CBFV. In this study, mean arterial pressure (MAP) represents arterial blood pressure (ABP), and cerebral blood flow velocity (CBFV), measured with transcranial Doppler, is used as a surrogate for changes in CBF when the diameter of the insonated artery is sufficiently stable. [1,3] End-tidal CO₂ (PETCO₂) provides a practical breath-to-breath surrogate for changes in arterial carbon dioxide during resting recordings. [2] In a MAP-only SISO model, PETCO₂ is omitted. If MAP and PETCO₂ fluctuate together in a consistent relationship at a given frequency, MAP can carry information about PETCO₂, and part of the PETCO₂-related CBFV response may be attributed to MAP. Having fluctuations in the same frequency range is not sufficient: their relative timing must also be consistent across the segments used to estimate the relationship. The same problem applies to a PETCO₂-only SISO model. Therefore, two separate SISO models describe pairwise relationships, but they do not distinguish the contribution of one measured input from the other. [4,5]',
13:'Previous studies have shown the potential value of modeling MAP and PETCO₂ together. Panerai et al. used multivariate finite impulse response filters to estimate the contributions of beat-to-beat MAP and breath-to-breath PETCO₂ fluctuations to resting CBFV variability. MAP explained a substantial portion of the measured CBFV variability, and adding PETCO₂ reduced the model mean squared error, calculated from the differences between measured and model-reconstructed CBFV. These results suggest that spontaneous PETCO₂ fluctuations can help explain resting CBFV variability that is not captured by pressure alone. [4] Peng et al. also examined multivariable system identification for cerebral autoregulation. Including PETCO₂ and end-tidal oxygen increased multiple coherence below 0.05 Hz relative to an arterial-pressure-only model, supporting the contribution of gas-related fluctuations to CBFV variability. [5]',
14:'However, lower CBFV prediction error does not necessarily mean that the separate MAP and PETCO₂ transfer functions were estimated correctly. First, MAP, PETCO₂, and CBFV can be measured in human recordings, but the true contribution of each input is not independently known. Second, when the inputs are related, a model may predict total CBFV well while assigning part of the response to the wrong input. Model fit therefore describes how well the output is reproduced, but it does not establish that the individual pathways were recovered correctly. Here, a pathway means the response associated with one input in the model; it is not an independently measured anatomical or causal pathway. Previous multivariable studies provide a basis for two-input modeling. The question addressed here is when joint frequency-domain estimation improves recovery of the individual generating responses across recording and input conditions. [4–6]',
15:'A two-input multiple-input, single-output (MISO) TFA model addresses the omission of the second input by estimating the MAP-to-CBFV and PETCO₂-to-CBFV transfer functions together. Each response is estimated while accounting for the other measured input. The coherence measures used with this model answer different questions. Ordinary coherence describes the pairwise relationship between one input and CBFV without accounting for the other input. Partial coherence describes the remaining relationship between one input and CBFV after accounting for the second input. Multiple coherence describes how consistently MAP and PETCO₂ together are related to CBFV. Higher multiple coherence indicates that the two-input model explains the measured output more closely, but it does not show by itself that the individual pathways were estimated accurately. [5,6]',
16:'',
17:'A clear and consistent MISO TFA framework is therefore needed because preprocessing, spectral settings, the joint model solution, and diagnostic criteria can all affect the results. The framework must document these choices, return the MAP- and PETCO₂-related gain and phase estimates, and report the coherence and numerical diagnostics needed to interpret them. The physiological aim is to examine blood-pressure-related CBFV dynamics while accounting for concurrent CO₂ variation, and CO₂-related dynamics while accounting for blood pressure. The computational details of this framework are described in the Methods. [3,5]',
18:'Adding a second input does not automatically produce a more accurate model. MISO must estimate two pathway coefficients at each frequency from the same finite recording. If MAP and PETCO₂ become too similar within a frequency region, the model can have difficulty distinguishing their effects. In this situation, small spectral errors can produce large changes in the estimated transfer functions. Some variation unique to each input is needed to distinguish their responses; the inputs do not have to be completely independent. [6] Short recordings, weak PETCO₂ fluctuations, measurement noise, and signal misalignment may also affect this balance. Even when the inputs are independent, including PETCO₂ can account for CBFV variation that remains unexplained in a MAP-only model. This can reduce variation in the MAP estimate across repeated finite recordings, although improvement is not guaranteed. A separate PETCO₂-only fit does not remove that unexplained variation from the MAP-only fit.',
19:'The two-input framework is applied to resting baseline recordings from cognitively normal (NC) adults. We compare MISO with a conventional MAP-only SISO model by estimating transfer functions from training blocks and evaluating CBFV prediction in a separate, held-out block. This asks whether including measured PETCO₂ improves prediction of an unseen part of the recording. This application provides physiological relevance, but it cannot establish which model is closer to the underlying pathways because those pathways are not known in subject data. Selected NC input properties also inform the simulated input spectra and operating levels; they do not establish the true human transfer functions or calibrate their recovery accuracy.',
20:'Known-truth simulation provides the complementary evaluation. Prespecified MAP-to-output and PETCO₂-to-output transfer functions are defined first. Synthetic input time series are then generated, passed through these model pathways, and combined to create a synthetic output time series. MISO and SISO models are estimated using only the same generated input and output observations, and their gain, phase, and complex transfer functions are compared directly with the prespecified transfer functions. Recording duration, noise, input relationships, pathway strength, and timing alignment are varied to determine how each condition affects pathway recovery. The spectral estimation settings are held fixed so that the comparisons reflect the declared changes in recording and input conditions. Repeated random recordings under each condition assess how consistently each estimator recovers the assigned responses. This follows the general logic of evaluating methods against a known data-generating system; the particular generating rules and parameter values used here are specified study assumptions. [5–8]',
21:'The primary objective of this study is to develop and evaluate a reproducible two-input TFA framework for examining blood-pressure- and CO₂-related CBFV dynamics. We use known-truth simulations to compare MISO and SISO pathway-recovery accuracy across relevant recording and input conditions. In a complementary analysis, we assess whether including PETCO₂ improves CBFV prediction in held-out NC recording blocks. Together, these analyses evaluate when jointly considering blood pressure and CO₂ can support interpretation of cerebral blood flow regulation, while distinguishing accurate recovery in a controlled model from predictive performance in human recordings.'}
for i,s in revisions.items():replace(b[i],s)
# Threaded replies retain every original comment, author, date and thread status.
comments=E.fromstring(parts['word/comments.xml']);ex=E.fromstring(parts['word/commentsExtended.xml']);cids=E.fromstring(parts['word/commentsIds.xml']);cex=E.fromstring(parts['word/commentsExtensible.xml'])
cid=max(int(c.get(q('w:id'))) for c in comments)+1
counter=0

def addcomment(s,parent=None,p=None):
 global cid,counter
 this=cid;cid+=1;counter+=1;pid=f'{0x62100000+counter:08X}';dur=f'{0x73100000+counter:08X}'
 c=el('w:comment',id=this,author=AUTHOR,date=DATE,initials='NA')
 para=el('w:p')
 para.set(q('w14:paraId'),pid);para.set(q('w14:textId'),'77777777')
 para.set(q('w:rsidR'),'00000000');para.set(q('w:rsidRDefault'),'00000000');para.set(q('w:rsidP'),'00F07897')
 ref=el('w:r');ref.append(el('w:annotationRef'));para.append(ref);para.append(run(s))
 c.append(para);comments.append(c)
 x=el('w15:commentEx',paraId=pid,done='0')
 if parent is not None:
  pc=comments.xpath('./w:comment[@w:id="'+str(parent)+'"]',namespaces=ns)[0];x.set(q('w15:paraIdParent'),pc.findall('w:p',ns)[-1].get(q('w14:paraId')))
 ex.append(x);cids.append(el('w16cid:commentId',paraId=pid,durableId=dur));cex.append(el('w16cex:commentExtensible',durableId=dur,dateUtc=DATE))
 if p is not None:
  ix=1 if p.find('w:pPr',ns)is not None else 0;p.insert(ix,el('w:commentRangeStart',id=this));p.append(el('w:commentRangeEnd',id=this));r=el('w:r');r.append(el('w:commentReference',id=this));p.append(r)
 return this
addcomment('I revised the title to name blood pressure and CO₂ explicitly while retaining the original title structure and its focus on cerebral blood flow dynamics.',parent=0)
addcomment('I have deferred the abstract for now. The conclusion will be revisited with the abstract after the results and interpretation are finalized. The earlier wording remains available as a tracked deletion, and I have kept this comment open.',parent=1)
addcomment('I added numbered references and PMIDs where available for the physiological background, conventional TFA, and prior multivariable studies. I retained your first two paragraphs, with only minor proofreading and citation additions. I also clarified that published studies motivate the approach, whereas our exact generating kernels and parameter settings remain study assumptions. The Methods retain the detailed generation explanation and the broader source list.',parent=4)
instruction=addcomment('Inline guidance from Sho in the supplied file: “Next, raise the potential problem with conventional SISO TFA.” The original inline wording is retained as a tracked deletion.',p=b[12])
addcomment('I revised the next paragraph to explain the omitted CO₂ contribution in MAP-only TFA and the corresponding limitation of two separate SISO models. It now distinguishes a consistent relationship between inputs from merely having fluctuations at similar frequencies.',parent=instruction)
addcomment('I preserved your physiological explanation and made two small proofreading corrections: removed the repeated “Importantly…” sentence and the extra word “manipulation” before “interventions.” These corrections are tracked without accepting your earlier revisions. Abbreviations used here are defined in the following paragraph.',p=b[8])
addcomment('I kept the physiological rationale in the Introduction. After reviewing the related papers, I moved the more detailed frequency examples, response equations, kernel construction and repeated-signal explanation into Methods, where subheadings make the development easier to follow. The newer Methods material is included below without blanket bolding.',p=b[17])

# Thread replies must be adjacent to their parent comment in comments.xml for
# desktop Word to display them inside the original thread. The parent relation
# itself is stored in commentsExtended.xml.
comment_by_pid={c.findall('w:p',ns)[-1].get(q('w14:paraId')):c for c in comments}
ex_by_pid={x.get(q('w15:paraId')):x for x in ex}
children={}
for pid,x in ex_by_pid.items():
 parent=x.get(q('w15:paraIdParent'))
 if parent:children.setdefault(parent,[]).append(pid)
ordered=[]
def add_thread(pid):
 if pid in comment_by_pid and pid not in ordered:
  ordered.append(pid)
  for child in children.get(pid,[]):add_thread(child)
for c in list(comments):add_thread(c.findall('w:p',ns)[-1].get(q('w14:paraId')))
for c in list(comments):comments.remove(c)
for pid in ordered:comments.append(comment_by_pid[pid])
for x in list(ex):ex.remove(x)
for pid in ordered:ex.append(ex_by_pid[pid])

# Register the reply author, matching Word's own threaded-comment package.
people=E.fromstring(parts['word/people.xml'])
if not people.xpath('./w15:person[@w15:author="'+AUTHOR+'"]',namespaces=ns):
 source_people=E.fromstring(srcparts['word/people.xml'])
 source_person=source_people.xpath('./w15:person[@w15:author="'+AUTHOR+'"]',namespaces=ns)
 people.append(cp(source_person[0]) if source_person else el('w15:person',author=AUTHOR))
# Read newer Methods without replacing Sho's document or its review metadata.
sdoc=E.fromstring(srcparts['word/document.xml']);sb=list(sdoc.find('w:body',ns))
mapref={1:3,2:2,3:4,4:5,5:7,6:6,7:9,8:8,9:10,10:11,11:12,12:13,13:14}
def citations(s):
 def sub(m):
  out=[]
  for part in re.split(',',m.group(1)):
   ends=re.split('[-–]',part.strip()); nums=range(int(ends[0]),int(ends[-1])+1)
   out.extend(mapref[x] for x in nums)
  return '['+','.join(map(str,sorted(set(out))))+']'
 return re.sub(r'\[([0-9]+(?:\s*[,–-]\s*[0-9]+)*)\]',sub,s)
# Transfer image relationships only; original comment/review parts remain authoritative.
rels=E.fromstring(parts['word/_rels/document.xml.rels']); sr=E.fromstring(srcparts['word/_rels/document.xml.rels']);prns='http://schemas.openxmlformats.org/package/2006/relationships';rmap={}
for rel in sr:
 if rel.get('Type','').endswith('/image'):
  old=rel.get('Id');new='rIdMethods'+old[3:];rmap[old]=new;target=rel.get('Target');newtarget='media/methods_'+Path(target).name
  parts['word/'+newtarget]=srcparts['word/'+target]; rr=cp(rel);rr.set('Id',new);rr.set('Target',newtarget);rels.append(rr)
ct=E.fromstring(parts['[Content_Types].xml']);ctns='http://schemas.openxmlformats.org/package/2006/content-types'
if not any(x.get('Extension')=='png' for x in ct): E.SubElement(ct,'{'+ctns+'}Default',Extension='png',ContentType='image/png')
# Append manuscript Methods on a new page in Sho's single-column review layout.
sect=b[-1];body.remove(sect)
for x in b[22:-1]:
 if x.getparent()is body:body.remove(x)
methods_heading=newp('Methods',True);body.append(methods_heading)
addcomment('This Methods section carries forward the newer Word manuscript, including its signal-generation explanation, equations, figures, code and fixed-reference table. It is new relative to your supplied Introduction and is not bolded throughout. Minor consistency corrections clarify the band-based error normalization and the noise-power scaling; no simulations were rerun.',p=methods_heading)
# Copy source heading styles under distinct IDs so baseline styling is untouched.
styles=E.fromstring(parts['word/styles.xml']);ss=E.fromstring(srcparts['word/styles.xml'])
for name in ['Heading1','Heading2']:
 item=ss.xpath('./w:style[@w:styleId="'+name+'"]',namespaces=ns)
 if item:
  st=cp(item[0]);st.set(q('w:styleId'),'Methods'+name)
  for x in st.findall('w:basedOn',ns):st.remove(x)
  styles.append(st)
# Exact fixes to the carried-forward Methods; all other science and figures remain.
fixes={
25:'For each simulated replicate and frequency, the estimated complex transfer function was compared with the complex transfer function used to generate the recording. This comparison includes both response size and timing. Squared errors were normalized by the mean squared magnitude of the known pathway across the reporting band, then averaged across paired replicates at each frequency. This uses one reference magnitude for the pathway rather than dividing by a potentially very small gain at each frequency. When the entire generating pathway had zero gain, absolute error was used.',
27:'Here H(f) is the known generating transfer function and Ĥᵣ(f) is its estimate from replicate r. The numerator averages squared error across replicates at a fixed frequency; the denominator averages squared true gain across frequencies in the reporting band. The frequency axis is therefore retained. The primary score is the base-10 logarithm of mean SISO error divided by mean MISO error. Positive values indicate lower mean error for MISO, negative values indicate lower mean error for SISO, and zero means equal error. An advantage of 1 means that the mean SISO error is ten times the mean MISO error.',
37:'These response shapes and time constants are prescribed simulation assumptions, not transfer functions learned from NC data. NC data inform the input-spectrum shape and selected operating levels. The simulator converts each time-domain kernel to its frequency response and saves that response before observation noise or alignment error is applied. For every generated record, stored seeds determine the random realization. The requested SNR sets target noise power to signal power divided by 10^(SNR/10); the generated noise is scaled to that power. Thus a noise condition changes the observation without changing the underlying clean pathway. The cited physiological literature motivates the different pressure and CO₂ response patterns; it does not establish these exact numerical constants. [1,2]',
83:'The paired replicate errors were resampled together 2,000 times. The standard deviation of the resampled advantages estimates the Monte Carlo uncertainty caused by using a finite number of replicates. It is a standard-error estimate for the log ratio of the mean errors at each frequency and factor level. The prespecified target was a maximum standard error of 0.05 advantage units in every finite primary heatmap cell. [8]'}
# Native math helper for the clarified denominator and grouping.
def mr(s): r=el('m:r');t=el('m:t');t.text=s;r.append(t);return r
def mathfrac(a,z):
 f=el('m:f');num=el('m:num');num.append(mr(a));den=el('m:den');den.append(mr(z));f.extend([num,den]);return f
order=[23,24,19,20]+list(range(25,90))
for idx in order:
 x=cp(sb[idx])
 if idx in fixes:
  pp=x.find('w:pPr',ns)
  for c in list(x):
   if c is not pp:x.remove(c)
  x.append(run(fixes[idx]))
 for c in x.xpath('.//w:sectPr|.//w:commentRangeStart|.//w:commentRangeEnd|.//w:commentReference|.//w:lastRenderedPageBreak',namespaces=ns):c.getparent().remove(c)
 for t in x.xpath('.//w:t',namespaces=ns):t.text=citations(t.text or '')
 for elem in x.iter():
  for name in ['embed','link','id']:
   attr=q('r:'+name)
   if elem.get(attr) in rmap:elem.set(attr,rmap[elem.get(attr)])
 for st in x.xpath('.//w:pStyle',namespaces=ns):
  if st.get(q('w:val')) in ['Heading1','Heading2']:st.set(q('w:val'),'Methods'+st.get(q('w:val')))
 # Remove arbitrary hard page breaks, preserve native math and syntax colours.
 for bb in x.xpath('.//w:br[@w:type="page"]',namespaces=ns):bb.getparent().remove(bb)
 if idx==26:
  om=x.find('.//m:oMath',ns)
  for c in list(om):om.remove(c)
  om.append(mr('E(f) = '));om.append(mathfrac('meanᵣ |Ĥᵣ(f) − H(f)|²','meanν∈B |H(ν)|²'))
 if idx==56:
  exp=x.find('.//m:sSup/m:e',ns);fraction=exp.find('m:f',ns)
  if fraction is not None:
   exp.remove(fraction);de=el('m:d');dp=el('m:dPr');dp.append(el('m:begChr',val='('));dp.append(el('m:endChr',val=')'));inn=el('m:e');inn.append(fraction);de.extend([dp,inn]);exp.append(de)
 # All equation tables use explicit invisible borders; no decorative boxes.
 if E.QName(x).localname=='tbl' and x.find('.//m:oMath',ns)is not None:
  prop=x.find('w:tblPr',ns);bd=el('w:tblBorders')
  for side in ['top','left','bottom','right','insideH','insideV']:bd.append(el('w:'+side,val='nil'))
  prop.append(bd);prop.append(el('w:jc',val='center'))
  for no in x.xpath('.//w:t',namespaces=ns):
   if re.fullmatch(r'\(\d+\)',no.text or ''):no.text='('+str(int(no.text[1:-1])-1)+')'
 # Keep illustrations at <=6.5 inches and fit source full-width table to baseline.
 for ext in x.xpath('.//*[local-name()="extent" or local-name()="ext"]'):
  if ext.get('cx') and ext.get('cy') and int(ext.get('cx'))>5943600:
   ratio=5943600/int(ext.get('cx'));ext.set('cx','5943600');ext.set('cy',str(round(int(ext.get('cy'))*ratio)))
 if idx==69:
  widths=[1800,1400,3400,2760]
  for col,w in zip(x.findall('w:tblGrid/w:gridCol',ns),widths):col.set(q('w:w'),str(w))
  for row in x.findall('w:tr',ns):
   for cell,w in zip(row.findall('w:tc',ns),widths):cell.find('w:tcPr/w:tcW',ns).set(q('w:w'),str(w))
 if E.QName(x).localname=='p' and not text(x).strip() and x.find('.//w:drawing',ns)is None:continue
 body.append(x)
 if idx==30:
  body.append(newp('Frequency describes how often a fluctuation repeats: 0.10 Hz corresponds to a 10-second cycle and 0.20 Hz to a 5-second cycle. Phase expresses relative timing as a fraction of that cycle. A one-second timing difference is therefore 36 degrees at 0.10 Hz. The sign depends on which signal is taken as the reference.'))
 if idx==38:
  body.append(newp('In this expression, M and C represent the MAP and CO₂ fluctuations at a frequency, Hₘ and H꜀ are their assigned responses, Y is the resulting CBFV fluctuation, and E is the remaining output component. The primary model assumes that this remaining component is not systematically related to either clean input. Otherwise, part of an unmeasured influence could be assigned to an input response. Input recording noise is tested separately by altering what the estimator observes after clean CBFV has been generated.'))
# Retain source bibliography and the broader uncited pool without implying they all support the text.
head=newp('References',True);head.find('w:pPr',ns).append(el('w:pageBreakBefore'));body.append(head)
refs={1:'Claassen JAHR, Thijssen DHJ, Panerai RB, Faraci FM. Regulation of cerebral blood flow in humans: physiology and clinical implications of autoregulation. Physiol Rev. 2021;101:1487–1559. doi:10.1152/physrev.00022.2020. PMID: 33769101.'}
for i in range(91,104):
 s=text(sb[i]);old=int(re.match(r'\[(\d+)\]',s).group(1));refs[mapref[old]]=re.sub(r'^\[\d+\]\s*','',s)
refs[6]+=' PMID: 16378517.'
for i in range(1,15):
 if i==10:body.append(newp('Additional sources retained for later manuscript development',True))
 body.append(newp('['+str(i)+'] '+refs[i]))
body.append(sect)
# Word's legacy compatibility mode only recognizes threaded replies reliably
# when the comment IDs follow the visible parent/reply order.  The supplied
# file used sparse IDs (0, 1, and 4), so renumber the preserved comments and
# every new comment after all anchors have been created.
comment_id_map={c.get(q('w:id')):str(i) for i,c in enumerate(comments)}
for c in comments:c.set(q('w:id'),comment_id_map[c.get(q('w:id'))])
for marker in doc.xpath('//w:commentRangeStart|//w:commentRangeEnd|//w:commentReference',namespaces=ns):
 old=marker.get(q('w:id'))
 if old in comment_id_map:marker.set(q('w:id'),comment_id_map[old])
# Enable further tracking; show revisions rather than flattening prior editorial work.
settings=E.fromstring(parts['word/settings.xml'])
if settings.find('w:trackRevisions',ns)is None:settings.append(el('w:trackRevisions'))
rv=settings.find('w:revisionView',ns)
if rv is None:rv=el('w:revisionView');settings.append(rv)
for k in ['markup','insDel','formatting','comments']:rv.set(q('w:'+k),'1')
for name,root in [('document.xml',doc),('comments.xml',comments),('commentsExtended.xml',ex),('commentsIds.xml',cids),('commentsExtensible.xml',cex),('people.xml',people),('settings.xml',settings),('styles.xml',styles),('_rels/document.xml.rels',rels)]:parts['word/'+name]=serialize(root)
parts['[Content_Types].xml']=serialize(ct)
with ZipFile(OUT,'w',ZIP_DEFLATED) as z:
 for name,data in parts.items():z.writestr(name,data)
# QA: the original comment objects and Sho revision IDs must survive.
base_doc=E.fromstring(ZipFile(BASE).read('word/document.xml'))
sho_ids=set(base_doc.xpath('//*[@w:author="祥太郎 齋藤"]/@w:id',namespaces=ns))
assert sho_ids <= set(doc.xpath('//*[@w:author="祥太郎 齋藤"]/@w:id',namespaces=ns))
assert text(b[7]).removesuffix(' [1,2]')==original_intro[0]
assert text(b[8]).removesuffix(' [1–3]')==original_intro[1].replace('manipulation ','',1).replace('Importantly, CBF also responds dynamically to fluctuations in arterial CO₂. ','',1)
base_comments=E.fromstring(ZipFile(BASE).read('word/comments.xml'))
for c in base_comments:
 matches=[x for x in comments if x.get(q('w:author'))==c.get(q('w:author')) and x.get(q('w:date'))==c.get(q('w:date')) and text(x)==text(c)]
 assert len(matches)==1
report={'baseline_sha256':hashlib.sha256(BASE.read_bytes()).hexdigest(),'original_sho_revision_ids_preserved':len(sho_ids),'original_comments_preserved':len(base_comments),'total_comments_including_replies':len(comments),'new_tracked_insertions':len(doc.xpath('//w:ins[@w:author="'+AUTHOR+'"]',namespaces=ns)),'new_tracked_deletions':len(doc.xpath('//w:del[@w:author="'+AUTHOR+'"]',namespaces=ns)),'native_equations':len(doc.xpath('//m:oMath',namespaces=ns)),'images':len(doc.xpath('//w:drawing',namespaces=ns))}
(WORK/'structural_checks.json').write_text(json.dumps(report,indent=2));print(OUT);print(report)
