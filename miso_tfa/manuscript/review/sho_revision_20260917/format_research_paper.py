from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import re

from lxml import etree as E


ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "miso_tfa" / "manuscript" / "sho_misotfa.docx"
FORMATTED = ROOT / "miso_tfa" / "manuscript" / "sho_misotfa_research_format.docx"
CLEAN = ROOT / "miso_tfa" / "manuscript" / "sho_misotfa_research_format_clean_preview.docx"

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
M = "http://schemas.openxmlformats.org/officeDocument/2006/math"
PKG_REL = "http://schemas.openxmlformats.org/package/2006/relationships"
CT = "http://schemas.openxmlformats.org/package/2006/content-types"
NS = {"w": W, "r": R, "m": M}


def q(prefix: str, name: str) -> str:
    return E.QName({"w": W, "r": R, "m": M}[prefix], name)


def child(parent, tag: str, **attrs):
    node = E.SubElement(parent, q("w", tag))
    for key, value in attrs.items():
        node.set(q("w", key), str(value))
    return node


def get_or_add(parent, tag: str):
    node = parent.find(f"w:{tag}", NS)
    return node if node is not None else child(parent, tag)


def set_child(parent, tag: str, **attrs):
    for old in parent.findall(f"w:{tag}", NS):
        parent.remove(old)
    return child(parent, tag, **attrs)


def para_text(p) -> str:
    return "".join(p.xpath(".//w:t/text() | .//w:delText/text()", namespaces=NS)).strip()


def load_package(path: Path) -> dict[str, bytes]:
    with ZipFile(path) as z:
        return {name: z.read(name) for name in z.namelist()}


def write_package(path: Path, parts: dict[str, bytes]) -> None:
    with ZipFile(path, "w", ZIP_DEFLATED) as z:
        for name, data in parts.items():
            z.writestr(name, data)


def set_run_defaults(rpr, font: str, size: int, *, bold=None, italic=None):
    fonts = get_or_add(rpr, "rFonts")
    for attr in ("asciiTheme", "hAnsiTheme", "eastAsiaTheme", "cstheme"):
        fonts.attrib.pop(q("w", attr), None)
    for attr in ("ascii", "hAnsi", "eastAsia", "cs"):
        fonts.set(q("w", attr), font)
    set_child(rpr, "sz", val=size)
    set_child(rpr, "szCs", val=size)
    if bold is not None:
        set_child(rpr, "b", val="1" if bold else "0")
        set_child(rpr, "bCs", val="1" if bold else "0")
    if italic is not None:
        set_child(rpr, "i", val="1" if italic else "0")
        set_child(rpr, "iCs", val="1" if italic else "0")


def style_node(styles, style_id: str, name: str, based_on="Normal"):
    matches = styles.xpath(f'./w:style[@w:styleId="{style_id}"]', namespaces=NS)
    if matches:
        style = matches[0]
    else:
        style = E.SubElement(styles, q("w", "style"))
        style.set(q("w", "type"), "paragraph")
        style.set(q("w", "styleId"), style_id)
        child(style, "name", val=name)
        if based_on:
            child(style, "basedOn", val=based_on)
        child(style, "qFormat")
    return style


def configure_style(
    styles,
    style_id: str,
    name: str,
    *,
    font="Times New Roman",
    size=24,
    bold=None,
    italic=None,
    align=None,
    before=0,
    after=80,
    line=240,
    first_line=None,
    left=None,
    hanging=None,
    keep_next=False,
):
    style = style_node(styles, style_id, name, None if style_id == "Normal" else "Normal")
    ppr = get_or_add(style, "pPr")
    set_child(ppr, "spacing", before=before, after=after, line=line, lineRule="auto")
    if align:
        set_child(ppr, "jc", val=align)
    else:
        for old in ppr.findall("w:jc", NS):
            ppr.remove(old)
    if first_line is not None or left is not None or hanging is not None:
        attrs = {}
        if first_line is not None:
            attrs["firstLine"] = first_line
        if left is not None:
            attrs["left"] = left
        if hanging is not None:
            attrs["hanging"] = hanging
        set_child(ppr, "ind", **attrs)
    else:
        for old in ppr.findall("w:ind", NS):
            ppr.remove(old)
    if keep_next and ppr.find("w:keepNext", NS) is None:
        child(ppr, "keepNext")
    if ppr.find("w:widowControl", NS) is None:
        child(ppr, "widowControl")
    rpr = get_or_add(style, "rPr")
    set_run_defaults(rpr, font, size, bold=bold, italic=italic)
    return style


def set_para_style(p, style_id: str):
    ppr = p.find("w:pPr", NS)
    if ppr is None:
        ppr = E.Element(q("w", "pPr"))
        p.insert(0, ppr)
    set_child(ppr, "pStyle", val=style_id)


def clear_para_overrides(p, *, keep_alignment=False):
    ppr = p.find("w:pPr", NS)
    if ppr is None:
        return
    tags = ["spacing", "ind"] + ([] if keep_alignment else ["jc"])
    for tag in tags:
        for old in ppr.findall(f"w:{tag}", NS):
            ppr.remove(old)


def clear_run_font_and_size(p):
    for rpr in p.xpath(".//w:rPr", namespaces=NS):
        for tag in ("rFonts", "sz", "szCs"):
            for old in rpr.findall(f"w:{tag}", NS):
                rpr.remove(old)


def set_table_run_format(tbl, font: str, size: int):
    for run in tbl.xpath(".//w:r[not(ancestor::m:oMath)]", namespaces=NS):
        rpr = run.find("w:rPr", NS)
        if rpr is None:
            rpr = E.Element(q("w", "rPr"))
            run.insert(0, rpr)
        set_run_defaults(rpr, font, size)


def make_section(template, columns: int, footer_id: str):
    sect = deepcopy(template)
    for old in sect.findall("w:type", NS):
        sect.remove(old)
    sect.insert(0, E.Element(q("w", "type")))
    sect[0].set(q("w", "val"), "continuous")
    cols = get_or_add(sect, "cols")
    cols.set(q("w", "num"), str(columns))
    cols.set(q("w", "space"), "360")
    for ref in sect.findall("w:footerReference", NS):
        sect.remove(ref)
    ref = E.Element(q("w", "footerReference"))
    ref.set(q("w", "type"), "default")
    ref.set(q("r", "id"), footer_id)
    sect.insert(1, ref)
    return sect


def section_break(template, columns: int, footer_id: str):
    p = E.Element(q("w", "p"))
    ppr = child(p, "pPr")
    ppr.append(make_section(template, columns, footer_id))
    return p


def insert_before(parent, target, node):
    parent.insert(parent.index(target), node)


def insert_after(parent, target, node):
    parent.insert(parent.index(target) + 1, node)


def add_footer(parts, rels, content_types) -> str:
    ids = {x.get("Id") for x in rels}
    n = 1
    while f"rIdResearchFooter{n}" in ids:
        n += 1
    rid = f"rIdResearchFooter{n}"
    rel = E.SubElement(rels, E.QName(PKG_REL, "Relationship"))
    rel.set("Id", rid)
    rel.set("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer")
    rel.set("Target", "footerResearch.xml")

    if not content_types.xpath('./ct:Override[@PartName="/word/footerResearch.xml"]', namespaces={"ct": CT}):
        override = E.SubElement(content_types, E.QName(CT, "Override"))
        override.set("PartName", "/word/footerResearch.xml")
        override.set("ContentType", "application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml")

    ftr = E.Element(q("w", "ftr"), nsmap={"w": W, "r": R})
    p = child(ftr, "p")
    ppr = child(p, "pPr")
    child(ppr, "jc", val="center")
    run = child(p, "r")
    rpr = child(run, "rPr")
    set_run_defaults(rpr, "Times New Roman", 20)
    t = child(run, "t")
    t.set(E.QName("http://www.w3.org/XML/1998/namespace", "space"), "preserve")
    t.text = "Page "
    begin_run = child(p, "r")
    begin_rpr = child(begin_run, "rPr")
    set_run_defaults(begin_rpr, "Times New Roman", 20)
    child(begin_run, "fldChar", fldCharType="begin")
    instr_run = child(p, "r")
    instr_rpr = child(instr_run, "rPr")
    set_run_defaults(instr_rpr, "Times New Roman", 20)
    instr = child(instr_run, "instrText")
    instr.set(E.QName("http://www.w3.org/XML/1998/namespace", "space"), "preserve")
    instr.text = " PAGE "
    separate_run = child(p, "r")
    separate_rpr = child(separate_run, "rPr")
    set_run_defaults(separate_rpr, "Times New Roman", 20)
    child(separate_run, "fldChar", fldCharType="separate")
    display = child(p, "r")
    display_rpr = child(display, "rPr")
    set_run_defaults(display_rpr, "Times New Roman", 20)
    display_t = child(display, "t")
    display_t.text = "1"
    end_run = child(p, "r")
    end_rpr = child(end_run, "rPr")
    set_run_defaults(end_rpr, "Times New Roman", 20)
    child(end_run, "fldChar", fldCharType="end")
    parts["word/footerResearch.xml"] = E.tostring(ftr, xml_declaration=True, encoding="UTF-8", standalone="yes")
    return rid


def format_document(source: Path, output: Path):
    parts = load_package(source)
    doc = E.fromstring(parts["word/document.xml"])
    styles = E.fromstring(parts["word/styles.xml"])
    rels = E.fromstring(parts["word/_rels/document.xml.rels"])
    cts = E.fromstring(parts["[Content_Types].xml"])
    body = doc.find("w:body", NS)
    final_sect = body.find("w:sectPr", NS)

    footer_id = add_footer(parts, rels, cts)

    # Paper and page geometry: US Letter, 0.75-inch margins, 0.25-inch column gap.
    pg_mar = get_or_add(final_sect, "pgMar")
    for side in ("top", "right", "bottom", "left"):
        pg_mar.set(q("w", side), "1080")
    pg_mar.set(q("w", "header"), "540")
    pg_mar.set(q("w", "footer"), "540")

    # Manuscript defaults and semantic styles.
    defaults = get_or_add(styles, "docDefaults")
    rdef = get_or_add(defaults, "rPrDefault")
    set_run_defaults(get_or_add(rdef, "rPr"), "Times New Roman", 24)
    pdef = get_or_add(defaults, "pPrDefault")
    set_child(get_or_add(pdef, "pPr"), "spacing", after=80, line=240, lineRule="auto")

    configure_style(styles, "Normal", "Normal", size=24, align="both", after=80, line=240, first_line=288)
    configure_style(styles, "Title", "Title", size=32, bold=True, align="center", after=240, line=320, keep_next=True)
    configure_style(styles, "Heading1", "Heading 1", size=26, bold=True, align="left", before=220, after=100, line=260, keep_next=True)
    configure_style(styles, "Heading2", "Heading 2", size=24, bold=True, italic=True, align="left", before=160, after=60, line=240, keep_next=True)
    configure_style(styles, "MethodsHeading1", "Methods Heading 1", size=26, bold=True, align="left", before=220, after=100, line=260, keep_next=True)
    configure_style(styles, "MethodsHeading2", "Methods Heading 2", size=24, bold=True, italic=True, align="left", before=160, after=60, line=240, keep_next=True)
    configure_style(styles, "AbstractNote", "Abstract note", size=22, italic=True, align="center", after=180, line=240)
    configure_style(styles, "Caption", "Caption", size=20, italic=True, align="left", before=60, after=120, line=220, keep_next=False)
    configure_style(styles, "CodeCaption", "Code caption", size=19, italic=True, align="left", before=80, after=30, line=210, keep_next=True)
    configure_style(styles, "ReferencesBody", "References body", size=20, align="left", after=70, line=220, left=360, hanging=360)

    paragraphs = body.xpath("./w:p", namespaces=NS)
    for p in paragraphs:
        text = para_text(p)
        if p.find("w:pPr/w:sectPr", NS) is not None:
            continue
        if p.find(".//w:drawing", NS) is not None:
            ppr = get_or_add(p, "pPr")
            set_child(ppr, "jc", val="center")
            continue
        if not text:
            continue
        if text.startswith("Development and Validation"):
            set_para_style(p, "Title")
        elif text.startswith("Abstract deferred"):
            set_para_style(p, "AbstractNote")
        elif text in {"Introduction", "Methods", "References"}:
            set_para_style(p, "Heading1")
        elif text == "Additional sources retained for later manuscript development":
            set_para_style(p, "Heading2")
        elif re.match(r"^(Figure|Table)\s+\d+\.", text):
            set_para_style(p, "Caption")
        elif text.startswith("Code example"):
            set_para_style(p, "CodeCaption")
        else:
            existing = p.find("w:pPr/w:pStyle", NS)
            if existing is not None and existing.get(q("w", "val")) in {"MethodsHeading1", "MethodsHeading2", "Heading1", "Heading2"}:
                pass
            elif re.match(r"^\[\d+\]", text):
                set_para_style(p, "ReferencesBody")
            else:
                set_para_style(p, "Normal")
        clear_para_overrides(p)
        clear_run_font_and_size(p)

    # Table formatting: code remains syntax-coloured in Consolas; equations remain Cambria Math.
    for tbl in body.xpath("./w:tbl", namespaces=NS):
        text = "".join(tbl.xpath(".//w:t/text()", namespaces=NS))
        if tbl.find(".//m:oMath", NS) is not None:
            set_table_run_format(tbl, "Times New Roman", 20)
            tbl_pr = get_or_add(tbl, "tblPr")
            set_child(tbl_pr, "jc", val="center")
            set_child(tbl_pr, "tblW", w=4860, type="dxa")
            set_child(tbl_pr, "tblLayout", type="fixed")
            grid = tbl.find("w:tblGrid", NS)
            if grid is not None:
                cols = grid.findall("w:gridCol", NS)
                if len(cols) == 2:
                    cols[0].set(q("w", "w"), "4060")
                    cols[1].set(q("w", "w"), "800")
            for row in tbl.findall("w:tr", NS):
                cells = row.findall("w:tc", NS)
                if len(cells) == 2:
                    for cell, width in zip(cells, (4060, 800)):
                        tcpr = get_or_add(cell, "tcPr")
                        set_child(tcpr, "tcW", w=width, type="dxa")
                    number_tcpr = get_or_add(cells[1], "tcPr")
                    if number_tcpr.find("w:noWrap", NS) is None:
                        child(number_tcpr, "noWrap")
                    for p in cells[1].findall("w:p", NS):
                        ppr = get_or_add(p, "pPr")
                        set_child(ppr, "jc", val="right")
                        if ppr.find("w:keepLines", NS) is None:
                            child(ppr, "keepLines")
        elif any(token in text for token in ("replicateIndex", "mapKernel", "estimateWelchSpectra")):
            set_table_run_format(tbl, "Consolas", 15)
            for p in tbl.xpath(".//w:p", namespaces=NS):
                ppr = get_or_add(p, "pPr")
                set_child(ppr, "spacing", before=0, after=0, line=180, lineRule="auto")
                set_child(ppr, "jc", val="left")
                set_child(ppr, "ind", left=0, right=0, firstLine=0)
        elif "Varied quantity" in text and "Tested levels" in text:
            set_table_run_format(tbl, "Times New Roman", 17)
            first_row = tbl.find("w:tr", NS)
            trpr = get_or_add(first_row, "trPr")
            if trpr.find("w:tblHeader", NS) is None:
                child(trpr, "tblHeader")
            for run in first_row.xpath(".//w:r", namespaces=NS):
                rpr = get_or_add(run, "rPr")
                set_child(rpr, "b", val="1")

    # Preserve one-column title/revision area; use two-column article text.
    # Figures and the wide factor table span both columns, while code stays within one column.
    final_cols = get_or_add(final_sect, "cols")
    final_cols.set(q("w", "num"), "2")
    final_cols.set(q("w", "space"), "360")
    for ref in final_sect.findall("w:footerReference", NS):
        final_sect.remove(ref)
    ref = E.Element(q("w", "footerReference"))
    ref.set(q("w", "type"), "default")
    ref.set(q("r", "id"), footer_id)
    final_sect.insert(0, ref)

    intro = next(p for p in body.xpath("./w:p", namespaces=NS) if para_text(p) == "Introduction")
    insert_before(body, intro, section_break(final_sect, 1, footer_id))

    for number in (1, 2, 3):
        caption = next(p for p in body.xpath("./w:p", namespaces=NS) if para_text(p).startswith(f"Figure {number}."))
        image_p = caption.getprevious()
        while image_p is not None and image_p.find(".//w:drawing", NS) is None:
            image_p = image_p.getprevious()
        if image_p is None:
            raise RuntimeError(f"Could not locate Figure {number} image")
        insert_before(body, image_p, section_break(final_sect, 2, footer_id))
        insert_after(body, caption, section_break(final_sect, 1, footer_id))

    table_caption = next(p for p in body.xpath("./w:p", namespaces=NS) if para_text(p).startswith("Table 1."))
    table_caption_ppr = get_or_add(table_caption, "pPr")
    if table_caption_ppr.find("w:pageBreakBefore", NS) is None:
        child(table_caption_ppr, "pageBreakBefore")
    if table_caption_ppr.find("w:keepNext", NS) is None:
        child(table_caption_ppr, "keepNext")
    table_node = table_caption.getnext()
    while table_node is not None and E.QName(table_node).localname != "tbl":
        table_node = table_node.getnext()
    if table_node is None:
        raise RuntimeError("Could not locate Table 1")
    insert_before(body, table_caption, section_break(final_sect, 2, footer_id))
    insert_after(body, table_node, section_break(final_sect, 1, footer_id))

    # A two-column article should continue into References without reserving a mostly empty page.
    references_heading = next(p for p in body.xpath("./w:p", namespaces=NS) if para_text(p) == "References")
    references_ppr = get_or_add(references_heading, "pPr")
    for node in references_ppr.findall("w:pageBreakBefore", NS):
        references_ppr.remove(node)

    parts["word/document.xml"] = E.tostring(doc, xml_declaration=True, encoding="UTF-8", standalone="yes")
    parts["word/styles.xml"] = E.tostring(styles, xml_declaration=True, encoding="UTF-8", standalone="yes")
    parts["word/_rels/document.xml.rels"] = E.tostring(rels, xml_declaration=True, encoding="UTF-8", standalone="yes")
    parts["[Content_Types].xml"] = E.tostring(cts, xml_declaration=True, encoding="UTF-8", standalone="yes")
    write_package(output, parts)


def make_clean_preview(source: Path, output: Path):
    parts = load_package(source)
    doc = E.fromstring(parts["word/document.xml"])

    # Remove deleted material; unwrap insertions so the proof shows the intended manuscript text.
    for node in list(doc.xpath(".//w:del | .//w:moveFrom", namespaces=NS)):
        node.getparent().remove(node)
    for node in list(doc.xpath(".//w:ins | .//w:moveTo", namespaces=NS)):
        parent = node.getparent()
        pos = parent.index(node)
        for item in list(node):
            parent.insert(pos, item)
            pos += 1
        parent.remove(node)
    for node in list(doc.xpath(".//w:commentRangeStart | .//w:commentRangeEnd | .//w:commentReference", namespaces=NS)):
        node.getparent().remove(node)
    for node in list(doc.xpath(".//*[substring(local-name(), string-length(local-name()) - 5) = 'Change']", namespaces=NS)):
        node.getparent().remove(node)
    for node in list(doc.xpath(".//w:highlight", namespaces=NS)):
        node.getparent().remove(node)
    for node in list(doc.xpath(".//w:moveFromRangeStart | .//w:moveFromRangeEnd | .//w:moveToRangeStart | .//w:moveToRangeEnd", namespaces=NS)):
        node.getparent().remove(node)

    settings = E.fromstring(parts["word/settings.xml"])
    for node in settings.findall("w:trackRevisions", NS) + settings.findall("w:revisionView", NS):
        settings.remove(node)
    parts["word/document.xml"] = E.tostring(doc, xml_declaration=True, encoding="UTF-8", standalone="yes")
    parts["word/settings.xml"] = E.tostring(settings, xml_declaration=True, encoding="UTF-8", standalone="yes")
    for name in list(parts):
        if name.startswith("word/comments") or name == "word/people.xml":
            del parts[name]
    rels = E.fromstring(parts["word/_rels/document.xml.rels"])
    for rel in list(rels):
        rel_type = rel.get("Type", "")
        if "comment" in rel_type.lower() or rel_type.endswith("/people"):
            rels.remove(rel)
    parts["word/_rels/document.xml.rels"] = E.tostring(rels, xml_declaration=True, encoding="UTF-8", standalone="yes")
    cts = E.fromstring(parts["[Content_Types].xml"])
    for node in list(cts):
        part_name = node.get("PartName", "")
        if part_name.startswith("/word/comments") or part_name == "/word/people.xml":
            cts.remove(node)
    parts["[Content_Types].xml"] = E.tostring(cts, xml_declaration=True, encoding="UTF-8", standalone="yes")
    write_package(output, parts)


if __name__ == "__main__":
    format_document(SOURCE, FORMATTED)
    make_clean_preview(FORMATTED, CLEAN)
    print(FORMATTED)
    print(CLEAN)
