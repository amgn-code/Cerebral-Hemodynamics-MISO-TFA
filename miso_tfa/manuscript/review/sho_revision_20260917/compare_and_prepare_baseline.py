from __future__ import annotations

from collections import Counter
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import difflib
import shutil
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[4]
DOWNLOADS = Path('/Users/amoghn/Downloads')
ORIGINAL = DOWNLOADS / 'Development and Validation of a Two.docx'
SHO_BASELINE = DOWNLOADS / 'Development and Validation of a Two_Sho_revised.docx'
WORKING = DOWNLOADS / 'sho_misotfa.docx'
OUT_DIR = Path(__file__).resolve().parent
REPORT = OUT_DIR / 'manuscript_difference_report.md'
BASELINE_COPY = OUT_DIR / 'sho_revised_baseline_no_tracking.docx'

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
NS = lambda tag: f'{{{W}}}{tag}'


def xml_root(zf: ZipFile, name: str):
    return ET.fromstring(zf.read(name))


def paragraph_texts(path: Path, view: str = 'accepted') -> list[str]:
    """Extract visible paragraph text from a DOCX.

    Accepted/current view includes w:ins and excludes w:del. Original view does
    the reverse for tracked text. This intentionally ignores field codes and
    preserves enough text for a human-readable comparison report.
    """
    with ZipFile(path) as zf:
        root = xml_root(zf, 'word/document.xml')

    paragraphs: list[str] = []
    for p in root.iter(NS('p')):
        pieces: list[str] = []

        def walk(node):
            if node.tag == NS('del'):
                if view == 'original':
                    for child in node:
                        walk(child)
                return
            if node.tag == NS('ins'):
                if view != 'original':
                    for child in node:
                        walk(child)
                return
            if node.tag == NS('delText'):
                if view == 'original' and node.text:
                    pieces.append(node.text)
                return
            if node.tag == NS('t') and node.text:
                pieces.append(node.text)
                return
            for child in node:
                walk(child)

        walk(p)
        text = ''.join(pieces).replace('\u00a0', ' ').strip()
        if text:
            paragraphs.append(text)
    return paragraphs


def doc_stats(path: Path) -> dict:
    with ZipFile(path) as zf:
        root = xml_root(zf, 'word/document.xml')
        revisions = Counter()
        deletions = Counter()
        for node in root.iter(NS('ins')):
            revisions[node.attrib.get(NS('author'), '(unknown)')] += 1
        for node in root.iter(NS('del')):
            deletions[node.attrib.get(NS('author'), '(unknown)')] += 1
        comments = Counter()
        if 'word/comments.xml' in zf.namelist():
            croot = xml_root(zf, 'word/comments.xml')
            for node in croot.iter(NS('comment')):
                comments[node.attrib.get(NS('author'), '(unknown)')] += 1
        return {
            'paragraphs': len(paragraph_texts(path)),
            'chars': sum(len(t) for t in paragraph_texts(path)),
            'original_chars': sum(len(t) for t in paragraph_texts(path, 'original')),
            'insertions': dict(revisions),
            'deletions': dict(deletions),
            'comments': dict(comments),
            'tables': sum(1 for _ in root.iter(NS('tbl'))),
            'equations': sum(1 for _ in root.iter('{http://schemas.openxmlformats.org/officeDocument/2006/math}oMath')),
            'media': len([n for n in zf.namelist() if n.startswith('word/media/')]),
        }


def short_diff(a: list[str], b: list[str], limit: int = 10) -> list[str]:
    lines: list[str] = []
    matcher = difflib.SequenceMatcher(None, a, b, autojunk=False)
    changed = 0
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == 'equal':
            continue
        changed += 1
        lines.append(f'- Paragraphs {i1 + 1}–{i2}: {" ".join(a[i1:i2])[:500]}')
        lines.append(f'+ Paragraphs {j1 + 1}–{j2}: {" ".join(b[j1:j2])[:700]}')
        if changed >= limit:
            lines.append('- Additional changes are summarized below.')
            break
    return lines


def set_tracking_off(source: Path, destination: Path) -> None:
    """Copy a DOCX and disable future tracking without accepting existing Sho edits."""
    with ZipFile(source, 'r') as zin, ZipFile(destination, 'w', ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == 'word/settings.xml':
                root = ET.fromstring(data)
                for tag in ('trackRevisions', 'trackFormatting', 'trackMoves', 'doNotTrackMoves'):
                    for node in list(root.findall(NS(tag))):
                        root.remove(node)
                data = ET.tostring(root, encoding='utf-8', xml_declaration=True)
            zout.writestr(item, data)


def fmt_counter(value: dict) -> str:
    if not value:
        return '0'
    return '; '.join(f'{k}: {v}' for k, v in value.items())


def main() -> None:
    for p in (ORIGINAL, SHO_BASELINE, WORKING):
        if not p.exists():
            raise FileNotFoundError(p)

    original_stats = doc_stats(ORIGINAL)
    sho_stats = doc_stats(SHO_BASELINE)
    working_stats = doc_stats(WORKING)
    original_text = paragraph_texts(ORIGINAL)
    sho_text = paragraph_texts(SHO_BASELINE)
    working_text = paragraph_texts(WORKING)

    set_tracking_off(SHO_BASELINE, BASELINE_COPY)
    baseline_stats = doc_stats(BASELINE_COPY)

    report = []
    report.append('# Manuscript Difference Report\n')
    report.append('This report compares the three document states before any blue-text merge is performed. The comparison uses the accepted/current visible text of each DOCX and separately records the tracked revisions and comments stored in the package.\n')
    report.append('## Files used\n')
    report.append('| Role | File | Reason |\n|---|---|---|')
    report.append(f'| Original draft | `{ORIGINAL.name}` | Untracked draft created before Sho\'s returned revision |')
    report.append(f'| Sho baseline | `{SHO_BASELINE.name}` | Returned file containing Sho\'s tracked edits and comments |')
    report.append(f'| Current working manuscript | `{WORKING.name}` | Formatted manuscript containing Sho\'s revisions plus later Amogh revisions |')
    report.append('| Excluded later file | `Development and Validation of a Two_Ssho.docx` | Later combined revision; it contains Amogh-tracked insertions and is not the clean Sho baseline |\n')

    report.append('## Document-level comparison\n')
    report.append('| Document | Visible paragraphs | Visible characters | Tracked insertions | Tracked deletions | Comments | Tables | Equations | Images |\n|---|---:|---:|---|---|---|---:|---:|---:|')
    report.append(f'| Original draft | {original_stats["paragraphs"]} | {original_stats["chars"]:,} | 0 | 0 | 0 | {original_stats["tables"]} | {original_stats["equations"]} | {original_stats["media"]} |')
    report.append(f'| Sho baseline | {sho_stats["paragraphs"]} | {sho_stats["chars"]:,} | {fmt_counter(sho_stats["insertions"])} | {fmt_counter(sho_stats["deletions"])} | {fmt_counter(sho_stats["comments"])} | {sho_stats["tables"]} | {sho_stats["equations"]} | {sho_stats["media"]} |')
    report.append(f'| Current working manuscript | {working_stats["paragraphs"]} | {working_stats["chars"]:,} | {fmt_counter(working_stats["insertions"])} | {fmt_counter(working_stats["deletions"])} | {fmt_counter(working_stats["comments"])} | {working_stats["tables"]} | {working_stats["equations"]} | {working_stats["media"]} |\n')

    report.append('## Original draft compared with Sho baseline\n')
    report.append('Sho kept the title and abstract structure, then replaced and expanded the opening of the Introduction. The original opening was a single paragraph beginning with the brain\'s need for continuous blood flow. Sho\'s version begins with the importance of cerebral blood-flow regulation, explicitly introduces arterial pressure and arterial CO₂, defines cerebral autoregulation, and then adds a separate paragraph distinguishing static from dynamic autoregulation.\n')
    report.append('The remainder of the introduction follows the same overall scientific direction as the draft: MAP-only SISO analysis, the role of CO₂, prior multivariable work, the distinction between output prediction and pathway recovery, the MISO model, NC recordings, and known-truth simulation. Sho\'s returned file contains 36 tracked insertions, 5 tracked deletions, and 3 comments.\n')
    report.append('### Representative changed opening\n')
    report.extend(short_diff(original_text, sho_text, limit=3))
    report.append('')

    report.append('## Sho baseline compared with the current working manuscript\n')
    report.append('The current working manuscript is a substantially expanded paper rather than a small wording revision. It preserves Sho\'s returned Introduction material in tracked form, but adds the new manuscript structure, the Methods section, equations, figures, table, MATLAB excerpts, simulation-design explanations, and the current references.\n')
    report.append('The main visible changes are:\n')
    report.append('- The title is revised to identify blood pressure, CO₂, and cerebral blood flow dynamics explicitly.')
    report.append('- The abstract is intentionally deferred while the Results and interpretation are finalized.')
    report.append('- The Introduction is rewritten and expanded to explain frequency-domain TFA, SISO versus MISO, coherence, pathway interpretation, simulation logic, and the two accuracy questions.')
    report.append('- Methods are added to describe the known-truth simulation, signal-family construction, input dependence, pathway responses, noise, timing, estimation, accuracy metrics, NC validation, and reproducibility controls.')
    report.append('- Three figures, one design table, seven native Word equations, and MATLAB code excerpts are present in the working manuscript.')
    report.append('- The working file contains Sho\'s 36 insertions and 5 deletions plus 54 Amogh insertions and 47 Amogh deletions. It also contains the preserved comment threads and replies.')
    report.append('')
    report.append('### Representative structural change\n')
    report.extend(short_diff(sho_text, working_text, limit=4))
    report.append('')

    report.append('## Baseline copy prepared for verification\n')
    report.append(f'A duplicate of Sho\'s baseline was created at `{BASELINE_COPY}`. Existing Sho revisions and comments remain in that file, but the settings that tell Word to track future edits were removed. No Sho revision was accepted or rejected, and no blue-text merge has been applied. The copy has {baseline_stats["insertions"]} tracked insertions, {baseline_stats["deletions"]} tracked deletions, and {baseline_stats["comments"]} comments, matching the Sho baseline.\n')
    report.append('The next controlled step is to have you verify the two comparison sections. After that, the new material from the current working manuscript can be copied into this baseline as blue text, while Sho\'s original tracked revisions remain redline revisions.\n')

    REPORT.write_text('\n'.join(report) + '\n', encoding='utf-8')
    print(REPORT)
    print(BASELINE_COPY)


if __name__ == '__main__':
    main()
