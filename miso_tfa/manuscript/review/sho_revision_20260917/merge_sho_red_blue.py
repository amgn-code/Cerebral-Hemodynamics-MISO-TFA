from __future__ import annotations

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import shutil
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'miso_tfa/manuscript/sho_misotfa.docx'
OUTPUT = ROOT / 'miso_tfa/manuscript/review/sho_revision_20260917/sho_baseline_with_blue_additions.docx'

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
M = 'http://schemas.openxmlformats.org/officeDocument/2006/math'
NS = lambda tag: f'{{{W}}}{tag}'
MNS = lambda tag: f'{{{M}}}{tag}'
AMOGH = 'Naganand, Amogh'
SHO = '祥太郎 齋藤'
BLUE = '0000FF'
RED = 'FF0000'

ET.register_namespace('w', W)
ET.register_namespace('m', M)


def run_color(run: ET.Element, color: str) -> None:
    rpr = run.find(NS('rPr'))
    if rpr is None:
        rpr = ET.Element(NS('rPr'))
        run.insert(0, rpr)
    color_node = rpr.find(NS('color'))
    if color_node is None:
        color_node = ET.SubElement(rpr, NS('color'))
    color_node.set(NS('val'), color)


def color_runs(node: ET.Element, color: str) -> None:
    for run in node.iter(NS('r')):
        run_color(run, color)
    # Native Word math uses m:r/m:t rather than w:r/w:t.
    for math_run in node.iter(MNS('r')):
        rpr = math_run.find(MNS('rPr'))
        if rpr is None:
            rpr = ET.Element(MNS('rPr'))
            math_run.insert(0, rpr)
        color_node = rpr.find(NS('color'))
        if color_node is None:
            color_node = ET.SubElement(rpr, NS('color'))
        color_node.set(NS('val'), color)


def text_of(node: ET.Element, accepted: bool = True) -> str:
    parts: list[str] = []

    def walk(child: ET.Element) -> None:
        if child.tag == NS('del'):
            if not accepted:
                for grandchild in child:
                    walk(grandchild)
            return
        if child.tag == NS('ins'):
            if accepted:
                for grandchild in child:
                    walk(grandchild)
            return
        if child.tag == NS('delText'):
            if not accepted and child.text:
                parts.append(child.text)
            return
        if child.tag in (NS('t'), MNS('t')) and child.text:
            parts.append(child.text)
            return
        for grandchild in child:
            walk(grandchild)

    walk(node)
    return ''.join(parts).replace('\u00a0', ' ').strip()


def is_sho_opening_paragraph(paragraph: ET.Element) -> bool:
    text = text_of(paragraph, accepted=True)
    return text.startswith('Adequate regulation of cerebral blood flow') or text.startswith('Cerebral autoregulation can be broadly characterized as static or dynamic')


def convert_deleted_text_to_text(node: ET.Element) -> None:
    for child in node.iter():
        if child.tag == NS('delText'):
            child.tag = NS('t')


def unwrap(parent: ET.Element, child: ET.Element, color: str | None = None, restore_deleted_text: bool = False) -> None:
    index = list(parent).index(child)
    descendants = list(child)
    if restore_deleted_text:
        convert_deleted_text_to_text(child)
    for descendant in descendants:
        if color:
            color_runs(descendant, color)
        parent.insert(index, descendant)
        index += 1
    parent.remove(child)


def process_revisions(container: ET.Element, target_paragraph: bool = False) -> None:
    for child in list(container):
        if child.tag == NS('ins'):
            author = child.attrib.get(NS('author'), '')
            if author == AMOGH:
                if target_paragraph:
                    # Reject our later edits inside Sho's two opening paragraphs.
                    container.remove(child)
                else:
                    # Accept our edit as ordinary blue text.
                    unwrap(container, child, BLUE)
            elif author == SHO:
                # Keep Sho's redline wrapper, but give its visible run text a
                # stable red direct colour in addition to Word's author colour.
                color_runs(child, RED)
                # A later edit can be nested inside a Sho insertion. Process
                # those descendants while keeping Sho's outer redline intact.
                process_revisions(child, target_paragraph)
            else:
                color_runs(child, RED)
                process_revisions(child, target_paragraph)
            continue

        if child.tag == NS('del'):
            author = child.attrib.get(NS('author'), '')
            if author == AMOGH:
                if target_paragraph:
                    # Reject our deletion to restore the exact Sho baseline.
                    unwrap(container, child, restore_deleted_text=True)
                else:
                    # Accept our deletion by removing the deleted text.
                    container.remove(child)
            elif author == SHO:
                color_runs(child, RED)
                process_revisions(child, target_paragraph)
            else:
                color_runs(child, RED)
                process_revisions(child, target_paragraph)
            continue

        process_revisions(child, target_paragraph)


def remove_tracking_settings(settings_xml: bytes) -> bytes:
    root = ET.fromstring(settings_xml)
    for tag in ('trackRevisions', 'trackFormatting', 'trackMoves', 'doNotTrackMoves'):
        for node in list(root.findall(NS(tag))):
            root.remove(node)
    return ET.tostring(root, encoding='utf-8', xml_declaration=True)


def main() -> None:
    baseline_texts: set[str] = set()
    baseline_path = Path('/Users/amoghn/Downloads/Development and Validation of a Two_Sho_revised.docx')
    with ZipFile(baseline_path) as zf:
        baseline_root = ET.fromstring(zf.read('word/document.xml'))
        for p in baseline_root.iter(NS('p')):
            text = text_of(p, accepted=True)
            if text:
                baseline_texts.add(text)

    with ZipFile(SOURCE, 'r') as zin, ZipFile(OUTPUT, 'w', ZIP_DEFLATED) as zout:
        document_root = None
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == 'word/document.xml':
                document_root = ET.fromstring(data)
                paragraphs = list(document_root.iter(NS('p')))
                target_ids = {id(p) for p in paragraphs if is_sho_opening_paragraph(p)}

                for paragraph in paragraphs:
                    is_target = id(paragraph) in target_ids
                    had_revision = any(
                        node.tag in (NS('ins'), NS('del'))
                        for node in paragraph.iter()
                    )
                    process_revisions(paragraph, target_paragraph=is_target)

                    text = text_of(paragraph, accepted=True)
                    has_math = any(True for _ in paragraph.iter(MNS('oMath')))
                    # New untracked paragraphs from the working manuscript
                    # (Methods, figures, table, code, references) are blue.
                    # Paragraphs that contain tracked edits keep their
                    # baseline runs black and only the accepted Amogh
                    # insertion runs blue. Unchanged baseline paragraphs
                    # remain black.
                    if not is_target and not had_revision and (text and text not in baseline_texts or has_math and text not in baseline_texts):
                        color_runs(paragraph, BLUE)

                data = ET.tostring(document_root, encoding='utf-8', xml_declaration=True)
            elif item.filename == 'word/settings.xml':
                data = remove_tracking_settings(data)
            zout.writestr(item, data)

    print(OUTPUT)


if __name__ == '__main__':
    main()
