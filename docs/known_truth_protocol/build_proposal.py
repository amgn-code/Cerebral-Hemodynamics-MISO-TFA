"""Render the proposal and its original schematics; does not run a simulation."""
from pathlib import Path
import re
import html
import math

from reportlab.pdfgen import canvas
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Preformatted
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.graphics.shapes import Drawing, Rect, Line, String, Polygon, Circle
from reportlab.graphics import renderSVG

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUTPUT = ROOT / 'output/pdf/miso_siso_simulation_proposal.pdf'
WIDTH = 508
INK = colors.HexColor('#202833')
BLUE = colors.HexColor('#254f73')
PALE = colors.HexColor('#edf2f5')
GRAY = colors.HexColor('#67717d')


def words(d, x, y, lines, size=9, anchor='middle', color=INK):
    if isinstance(lines, str):
        lines = lines.split('\n')
    for i, line in enumerate(lines):
        d.add(String(x, y-i*(size+3), line, fontName='Helvetica', fontSize=size,
                     textAnchor=anchor, fillColor=color))


def box(d, x, y, w, h, text, fill=PALE, size=9):
    d.add(Rect(x, y, w, h, fillColor=fill, strokeColor=BLUE, strokeWidth=0.8))
    lines = text.split('\n')
    top = y+h/2+(len(lines)-1)*(size+3)/2-size/3
    words(d, x+w/2, top, lines, size=size)


def arrow(d, pts, color=GRAY):
    for a,b in zip(pts[:-1], pts[1:]):
        d.add(Line(*a,*b,strokeColor=color,strokeWidth=1.1))
    a,b = pts[-2:]
    angle = math.atan2(b[1]-a[1],b[0]-a[0])
    back = (b[0]-6*math.cos(angle), b[1]-6*math.sin(angle))
    offset = (-2.5*math.sin(angle),2.5*math.cos(angle))
    d.add(Polygon([b[0],b[1],back[0]+offset[0],back[1]+offset[1],
                   back[0]-offset[0],back[1]-offset[1]],fillColor=color,strokeColor=color))


def diagram(name):
    if name == 'heatmap':
        d=Drawing(WIDTH,194)
        words(d,254,180,'FIGURE DESIGN ONLY - cells contain no simulated results',size=9,color=BLUE)
        x,y,w,h=101,50,295,99
        for row in range(3):
            for col in range(12):
                d.add(Rect(x+col*w/12,y+row*h/3,w/12,h/3,
                           fillColor=PALE,strokeColor=colors.white,strokeWidth=1))
        for row,label in enumerate(['0','0.50','0.95']):
            words(d,x-10,y+row*h/3+13,label,size=9,anchor='end')
        words(d,0,115,['Assigned','input','coherence'],size=9,anchor='start')
        words(d,x,34,'0.02',size=9)
        words(d,x+w,34,'0.50',size=9)
        words(d,x+w/2,16,'Frequency (Hz)',size=10,color=BLUE)
        for yy,fill,label in [(125,colors.HexColor('#356ca0'),'MISO better'),(94,colors.white,'Equal error'),(63,colors.HexColor('#be7234'),'SISO better')]:
            d.add(Rect(413,yy,14,14,fillColor=fill,strokeColor=GRAY,strokeWidth=0.5))
            words(d,434,yy+4,label,size=8,anchor='start')
        words(d,254,160,'Panel title declares fixed CO2 contribution and noise',size=9)
        return d
    if name == 'realcontrol':
        d=Drawing(WIDTH,145)
        box(d,0,84,125,43,'Keep real MAP\nand CBFV fixed')
        box(d,171,98,148,39,'Second input:\nrecorded CO2')
        box(d,171,26,148,51,'Second input:\nwhite noise / spectrum-\nmatched surrogate',size=8.5)
        box(d,373,66,135,55,'Compare added\nexplanation at\neach frequency',size=9)
        arrow(d,[(125,105),(171,118)])
        arrow(d,[(125,105),(146,105),(146,52),(171,52)])
        arrow(d,[(319,118),(373,103)])
        arrow(d,[(319,52),(345,52),(373,80)])
        words(d,254,8,'MAP-only SISO is the common baseline for every comparison.',size=9)
        return d
    if name == 'overview':
        d=Drawing(WIDTH,205)
        words(d,50,190,'Paired random inputs',size=10,anchor='start',color=BLUE)
        box(d,0,133,88,40,'MAP\nM(t)')
        box(d,0,61,88,40,'CO2\nC(t)')
        box(d,129,133,141,40,'Saved MAP pathway\nhM')
        box(d,129,61,141,40,'Saved CO2 pathway\nhC; strength q')
        arrow(d,[(88,153),(129,153)])
        arrow(d,[(88,81),(129,81)])
        d.add(Circle(326,117,14,strokeColor=BLUE,fillColor=colors.white))
        words(d,326,113,'+',size=15)
        arrow(d,[(270,153),(294,153),(313,126)])
        arrow(d,[(270,81),(294,81),(313,108)])
        box(d,379,97,129,40,'Synthetic CBFV\ny(t)')
        arrow(d,[(340,117),(379,117)])
        box(d,248,0,157,35,'Independent output noise\nSet SNR',size=9)
        arrow(d,[(326,35),(326,103)])
        words(d,1,39,'Coherence c controls',size=9,anchor='start')
        words(d,1,26,'the input relationship.',size=9,anchor='start')
        return d
    if name == 'westwick':
        d=Drawing(WIDTH,125)
        labels=['K independent\nGaussian sources','Random source\nfilters','Mix + private\ninput variation','Known filters\n+ output sum','Output +\nmeasurement noise']
        for i,label in enumerate(labels):
            box(d,i*104,50,92,48,label,size=8.7)
            if i<4: arrow(d,[(i*104+92,74),((i+1)*104,74)])
        words(d,254,111,'10 dB',size=9,color=BLUE)
        words(d,462,111,'10 dB',size=9,color=BLUE)
        words(d,254,25,'Random sources, filters and mixing change across trials.',size=9)
        words(d,254,10,'The known system is evaluated using separate estimation and validation data.',size=9)
        return d
    if name == 'chertoff':
        d=Drawing(WIDTH,184)
        box(d,0,75,86,43,'Gaussian input\nx(t)')
        box(d,145,139,176,40,'High-pass, order 2\nCutoff 0.05 Hz')
        box(d,125,10,110,43,'Cubic transform\n0.1 x(t)^3')
        box(d,267,10,149,43,'Low-pass, order 2\nCutoff 0.1 Hz')
        arrow(d,[(86,97),(106,97),(106,159),(145,159)])
        arrow(d,[(106,97),(106,32),(125,32)])
        arrow(d,[(235,32),(267,32)])
        d.add(Circle(462,98,14,strokeColor=BLUE,fillColor=colors.white))
        words(d,462,94,'+',size=15)
        arrow(d,[(321,159),(435,159),(456,112)])
        arrow(d,[(416,32),(435,32),(456,84)])
        arrow(d,[(476,98),(504,98)])
        words(d,490,118,'y(t)',size=10)
        return d
    if name == 'grid':
        d=Drawing(WIDTH,163)
        labels=['No added noise','10 dB SNR','0 dB SNR']
        for p,label in enumerate(labels):
            x=31+174*p
            words(d,x+48,150,label,size=10,color=BLUE)
            for j,col in enumerate(['0','0.50','0.95']):
                words(d,x+16+32*j,130,col,size=9)
            for i,row in enumerate(['0','0.25','1']):
                y=92-32*i
                words(d,x-8,y+12,row,size=9,anchor='end')
                for j in range(3):
                    d.add(Rect(x+32*j,y,32,32,fillColor=PALE,strokeColor=colors.white,strokeWidth=2))
                    d.add(Circle(x+32*j+16,y+16,2,fillColor=BLUE,strokeColor=BLUE))
        words(d,254,10,'Each dot is one condition: columns = coherence c; rows = contribution ratio q.',size=9)
        return d
    if name == 'validation':
        d=Drawing(WIDTH,208)
        box(d,163,165,182,38,'One fixed scenario\nSaved true hM and hC',size=9)
        box(d,0,100,210,40,'Record A: estimation\nRandom stream A')
        box(d,298,100,210,40,'Record B: validation\nIndependent random stream B')
        arrow(d,[(190,165),(105,140)])
        arrow(d,[(318,165),(403,140)])
        box(d,0,36,210,40,'Estimate SISO and MISO\nFreeze their responses')
        box(d,298,36,210,40,'Evaluate frozen responses\nIndependent-record spectral error')
        arrow(d,[(105,100),(105,76)])
        arrow(d,[(403,100),(403,76)])
        arrow(d,[(210,56),(298,56)])
        words(d,254,14,'Primary accuracy: compare estimated responses with the saved generating filters.',size=9,color=BLUE)
        return d
    raise ValueError(name)


styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='BodyCustom',fontName='Helvetica',fontSize=9.7,leading=12.3,
                          textColor=INK,spaceAfter=6))
styles.add(ParagraphStyle(name='TitleCustom',fontName='Helvetica-Bold',fontSize=25,leading=29,
                          textColor=BLUE,spaceAfter=12))
styles.add(ParagraphStyle(name='H2Custom',fontName='Helvetica-Bold',fontSize=17,leading=21,
                          textColor=BLUE,spaceBefore=2,spaceAfter=10))
styles.add(ParagraphStyle(name='H3Custom',fontName='Helvetica-Bold',fontSize=11.5,leading=15,
                          textColor=INK,spaceBefore=5,spaceAfter=6))
styles.add(ParagraphStyle(name='CellCustom',fontName='Helvetica',fontSize=8.8,leading=10.4,
                          textColor=INK,spaceAfter=0))
styles.add(ParagraphStyle(name='SmallCustom',fontName='Helvetica',fontSize=8.3,leading=11,
                          textColor=GRAY,spaceAfter=6))
styles.add(ParagraphStyle(name='CodeCustom',fontName='Courier',fontSize=8.3,leading=11,
                          textColor=INK,spaceAfter=9))


def inline(s):
    s=html.escape(s)
    s=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#254f73">\1</link>',s)
    s=re.sub(r'\*\*(.*?)\*\*',r'<b>\1</b>',s)
    s=re.sub(r'`([^`]+)`',r'<font name="Courier" size="9">\1</font>',s)
    s=re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)',r'<i>\1</i>',s)
    return s


def table(lines):
    rows=[]
    for line in lines:
        cells=[c.strip() for c in line.strip().strip('|').split('|')]
        if all(re.fullmatch(r':?-+:?',c.replace(' ','')) for c in cells): continue
        rows.append(cells)
    n=len(rows[0])
    if n==2: widths=[150,WIDTH-150]
    else: widths=[99,198,WIDTH-297]
    cooked=[]
    for ri,row in enumerate(rows):
        cooked.append([Paragraph(('<b>'+inline(c)+'</b>') if ri==0 else inline(c),styles['CellCustom']) for c in row])
    t=Table(cooked,colWidths=widths,repeatRows=1,hAlign='LEFT')
    t.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(-1,0),PALE),('VALIGN',(0,0),(-1,-1),'TOP'),
        ('LINEBELOW',(0,0),(-1,0),0.7,BLUE),('LINEBELOW',(0,1),(-1,-1),0.3,colors.HexColor('#d7dde2')),
        ('LEFTPADDING',(0,0),(-1,-1),6),('RIGHTPADDING',(0,0),(-1,-1),6),
        ('TOPPADDING',(0,0),(-1,-1),4),('BOTTOMPADDING',(0,0),(-1,-1),4)
    ]))
    return t


def parse(md):
    lines=md.splitlines(); i=0; result=[]
    while i<len(lines):
        line=lines[i].strip()
        if not line: i+=1; continue
        if line=='<!-- PAGE -->': result.append(PageBreak()); i+=1; continue
        m=re.fullmatch(r'<!-- DIAGRAM:(\w+) -->',line)
        if m:
            d=diagram(m.group(1))
            if m.group(1) in ('grid','validation'):
                d.scale(0.91,0.91)
                d.width*=0.91
                d.height*=0.91
            result.extend([d,Spacer(1,8)]); i+=1; continue
        if line.startswith('!['): i+=1; continue
        if line.startswith('# '): result.append(Paragraph(inline(line[2:]),styles['TitleCustom'])); i+=1; continue
        if line.startswith('## '): result.append(Paragraph(inline(line[3:]),styles['H2Custom'])); i+=1; continue
        if line.startswith('### '): result.append(Paragraph(inline(line[4:]),styles['H3Custom'])); i+=1; continue
        if line.startswith('|'):
            block=[]
            while i<len(lines) and lines[i].strip().startswith('|'): block.append(lines[i]); i+=1
            result.extend([table(block),Spacer(1,10)]); continue
        if line.startswith('```'):
            i+=1; block=[]
            while i<len(lines) and not lines[i].startswith('```'): block.append(lines[i]); i+=1
            result.append(Preformatted('\n'.join(block),styles['CodeCustom'])); i+=1; continue
        block=[line]; i+=1
        while i<len(lines) and lines[i].strip() and not lines[i].startswith(('#','|','<!--','```','![')):
            if re.match(r'\d+\. ',lines[i]): break
            block.append(lines[i].strip()); i+=1
        body=' '.join(block)
        style=styles['SmallCustom'] if body.startswith(('[1]','[2]','[3]','[4]','[5]','[6]','Repository evidence:','Proposed protocol','Shotaro source:')) else styles['BodyCustom']
        result.append(Paragraph(inline(body),style))
    return result


def footer(c,doc):
    c.saveState()
    c.setStrokeColor(colors.HexColor('#cbd3da'))
    c.line(52,41,560,41)
    c.setFont('Helvetica',8)
    c.setFillColor(GRAY)
    c.drawString(52,27,'MISO-SISO simulation | Proposed protocol, not simulated results')
    c.drawRightString(560,27,str(doc.page))
    c.restoreState()


if __name__=='__main__':
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    (HERE/'figures').mkdir(exist_ok=True)
    for name in ['overview','westwick','chertoff','grid','validation','heatmap','realcontrol']:
        renderSVG.drawToFile(diagram(name),str(HERE/'figures'/f'{name}.svg'))
    md=(HERE/'SIMULATION_PROTOCOL.md').read_text()
    doc=SimpleDocTemplate(str(OUTPUT),pagesize=(612,792),leftMargin=52,rightMargin=52,
                          topMargin=45,bottomMargin=56,title='A reproducible MISO-SISO simulation study',
                          author='Research protocol proposal',pageCompression=1)
    doc.build(parse(md),onFirstPage=footer,onLaterPages=footer)
    print(OUTPUT)
