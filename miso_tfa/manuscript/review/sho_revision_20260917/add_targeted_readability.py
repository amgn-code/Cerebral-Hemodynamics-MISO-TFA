"""Add two targeted, blue readability clarifications to the merged Word manuscript.

The source document already preserves Sho's tracked revisions/comments and keeps
only targeted Amogh additions in blue.  This script edits only word/document.xml,
leaving all other package parts unchanged.
"""

from copy import deepcopy
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "miso_tfa/manuscript/review/sho_revision_20260917/sho_baseline_with_blue_additions.docx"
OUTPUT = ROOT / "miso_tfa/manuscript/review/sho_revision_20260917/sho_baseline_with_blue_additions_targeted.docx"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
XML_NS = "http://www.w3.org/XML/1998/namespace"
NS = {"w": W_NS}
ET.register_namespace("w", W_NS)


def qn(local: str) -> str:
    return f"{{{W_NS}}}{local}"


def visible_text(paragraph: ET.Element) -> str:
    """Return accepted paragraph text, including Sho's insertions, excluding deletions."""
    pieces = []
    for elem in paragraph.iter():
        if elem.tag == qn("delText"):
            continue
        if elem.tag == qn("t"):
            pieces.append(elem.text or "")
        elif elem.tag == qn("tab"):
            pieces.append("\t")
        elif elem.tag in (qn("br"), qn("cr")):
            pieces.append("\n")
    return "".join(pieces)


def blue_run(text: str) -> ET.Element:
    run = ET.Element(qn("r"))
    rpr = ET.SubElement(run, qn("rPr"))
    ET.SubElement(rpr, qn("color"), {qn("val"): "0000FF"})
    node = ET.SubElement(run, qn("t"))
    node.set(f"{{{XML_NS}}}space", "preserve")
    node.text = text
    return run


def find_paragraphs(root: ET.Element):
    return root.findall(".//w:p", NS)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    if OUTPUT.exists():
        OUTPUT.unlink()

    transition = (
        "These responses motivate the modeling question: when blood pressure and CO₂ vary "
        "together, which input is associated with a change in CBFV? A transfer function "
        "describes its frequency-specific size and timing; coherence describes how consistently "
        "it is observed."
    )
    identifiability = (
        " Here, identifiability means that the recording contains enough input-specific "
        "variation to estimate the two responses without assigning the same fluctuation to both."
    )

    with ZipFile(SOURCE, "r") as zin:
        document_xml = zin.read("word/document.xml")
        root = ET.fromstring(document_xml)
        paragraphs = find_paragraphs(root)

        sho_second = next(
            (p for p in paragraphs if visible_text(p).lstrip().startswith(
                "Cerebral autoregulation can be broadly characterized as static or dynamic"
            )),
            None,
        )
        if sho_second is None:
            raise RuntimeError("Could not find Sho's second substantive Introduction paragraph")

        target_p20 = next(
            (p for p in paragraphs if visible_text(p).lstrip().startswith(
                "Adding a second input does not automatically produce a more accurate model"
            )),
            None,
        )
        if target_p20 is None:
            raise RuntimeError("Could not find the finite-input/identifiability paragraph")

        if transition not in visible_text(root):
            # Keep this transition in the existing MAP paragraph so it does not
            # create an avoidable blank paragraph/page in the two-column layout.
            reference_p = next(
                (p for p in paragraphs if visible_text(p).lstrip().startswith(
                    "A MAP-only model is useful"
                )),
                None,
            )
            if reference_p is None:
                raise RuntimeError("Could not find the MAP-only paragraph")
            children = list(reference_p)
            ppr = reference_p.find("w:pPr", NS)
            insert_at = children.index(ppr) + 1 if ppr is not None else 0
            reference_p.insert(insert_at, blue_run(transition))
            break_run = ET.Element(qn("r"))
            ET.SubElement(break_run, qn("br"))
            reference_p.insert(insert_at + 1, break_run)

        if identifiability.strip() not in visible_text(target_p20):
            target_p20.append(blue_run(identifiability))

        # The added transition can leave a single line before Table 1.  The
        # source caption forced a new page, which would create an almost empty
        # page in this revision.  Let the table follow naturally when space is
        # available; its keep-next setting still keeps the caption with it.
        table_caption = next(
            (p for p in find_paragraphs(root) if visible_text(p).lstrip().startswith(
                "Table 1. Simulation quantities"
            )),
            None,
        )
        if table_caption is not None:
            ppr = table_caption.find("w:pPr", NS)
            if ppr is not None:
                for child in list(ppr):
                    if child.tag == qn("pageBreakBefore"):
                        ppr.remove(child)

        new_document_xml = ET.tostring(root, encoding="utf-8", xml_declaration=True)

        with ZipFile(OUTPUT, "w", ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                data = new_document_xml if item.filename == "word/document.xml" else zin.read(item.filename)
                zout.writestr(item, data)

    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
