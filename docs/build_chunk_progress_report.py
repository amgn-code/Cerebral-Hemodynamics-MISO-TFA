"""Build a visual progress report for the simplified MISO-SISO study."""

from pathlib import Path
import csv

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    KeepTogether,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    Flowable,
)
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "output" / "pdf" / "chunk_progress_report_assets"
PLOT_ROOT = (
    ASSET_ROOT
    / "Simple_Simulation_Heatmaps"
    / "Primary_Accuracy_Heatmaps"
    / "Plots"
)
REPORT_PATH = ROOT / "output" / "pdf" / "chunk_progress_report.pdf"
NC_FIGURE = ROOT / "output" / "nc_bootstrap_production" / "nc_bootstrap_advantage.png"
MISO_PAGE_FIGURE = ROOT / "output" / "figures" / "cleanup_chunk14_miso_summary.png"
SISO_PAGE_FIGURE = ROOT / "output" / "figures" / "cleanup_chunk14_siso_summary.png"

NAVY = colors.HexColor("#17324D")
BLUE = colors.HexColor("#2F6FA3")
ORANGE = colors.HexColor("#C8612A")
PALE_BLUE = colors.HexColor("#EAF2F8")
PALE_ORANGE = colors.HexColor("#F8EDE6")
PALE_GRAY = colors.HexColor("#F2F4F5")
MID_GRAY = colors.HexColor("#66727D")
INK = colors.HexColor("#202833")


styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="ReportTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=25,
        leading=29,
        textColor=NAVY,
        alignment=TA_LEFT,
        spaceAfter=9,
    )
)
styles.add(
    ParagraphStyle(
        name="ReportSubtitle",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=11,
        leading=15,
        textColor=MID_GRAY,
        spaceAfter=15,
    )
)
styles.add(
    ParagraphStyle(
        name="SectionTitle",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=16,
        leading=20,
        textColor=NAVY,
        spaceBefore=2,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        name="SubTitle",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=14,
        textColor=BLUE,
        spaceBefore=7,
        spaceAfter=5,
    )
)
styles.add(
    ParagraphStyle(
        name="BodyReport",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=9.3,
        leading=12.7,
        textColor=INK,
        spaceAfter=7,
    )
)
styles.add(
    ParagraphStyle(
        name="SmallReport",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=8.0,
        leading=10.3,
        textColor=INK,
        spaceAfter=4,
    )
)
styles.add(
    ParagraphStyle(
        name="FigureCaption",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=8.2,
        leading=10.6,
        textColor=MID_GRAY,
        spaceBefore=4,
        spaceAfter=5,
    )
)
styles.add(
    ParagraphStyle(
        name="TableText",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=7.4,
        leading=9.3,
        textColor=INK,
        spaceAfter=0,
    )
)
styles.add(
    ParagraphStyle(
        name="TableHeader",
        parent=styles["BodyText"],
        fontName="Helvetica-Bold",
        fontSize=7.5,
        leading=9.2,
        textColor=NAVY,
        spaceAfter=0,
    )
)


def P(text, style="BodyReport"):
    return Paragraph(text, styles[style])


def table_cell(text, header=False):
    return Paragraph(str(text), styles["TableHeader" if header else "TableText"])


def styled_table(rows, widths, header=True):
    cooked = []
    for row_index, row in enumerate(rows):
        cooked.append(
            [table_cell(value, header and row_index == 0) for value in row]
        )
    table = Table(cooked, colWidths=widths, repeatRows=1 if header else 0)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), PALE_BLUE if header else colors.white),
                ("TEXTCOLOR", (0, 0), (-1, 0), NAVY),
                ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#D7DEE4")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return table


class WorkflowDiagram(Flowable):
    """Small vector workflow diagram used in the first report page."""

    def __init__(self, width=510, height=150):
        Flowable.__init__(self)
        self.width = width
        self.height = height

    def wrap(self, available_width, available_height):
        return min(self.width, available_width), self.height

    def draw(self):
        c = self.canv
        x_positions = [0, 105, 215, 325, 435]
        labels = [
            ("Simple settings", "3 assigned factors"),
            ("Paired generator", "known MAP / CO2 truth"),
            ("Observation plans", "same data for SISO/MISO"),
            ("Frequency errors", "truth-only normalization"),
            ("Heatmaps + tables", "advantage and diagnostics"),
        ]
        box_width = 82
        box_height = 54
        y = 66
        for index, (top, bottom) in enumerate(labels):
            x = x_positions[index]
            c.setFillColor(PALE_BLUE if index < 3 else PALE_ORANGE)
            c.setStrokeColor(BLUE if index < 3 else ORANGE)
            c.roundRect(x, y, box_width, box_height, 5, fill=1, stroke=1)
            c.setFillColor(NAVY)
            c.setFont("Helvetica-Bold", 8.4)
            c.drawCentredString(x + box_width / 2, y + 34, top)
            c.setFont("Helvetica", 7.2)
            c.setFillColor(INK)
            c.drawCentredString(x + box_width / 2, y + 20, bottom)
            if index < len(labels) - 1:
                c.setStrokeColor(MID_GRAY)
                c.line(x + box_width, y + box_height / 2, x_positions[index + 1], y + box_height / 2)
                c.line(x_positions[index + 1] - 5, y + box_height / 2 + 3, x_positions[index + 1], y + box_height / 2)
                c.line(x_positions[index + 1] - 5, y + box_height / 2 - 3, x_positions[index + 1], y + box_height / 2)
        c.setFillColor(MID_GRAY)
        c.setFont("Helvetica", 8)
        c.drawCentredString(255, 32, "Same frequency grid and paired observations are carried through every comparison")


class SiblingWorkflowDiagram(Flowable):
    """Show the independent user and simulation entry points."""

    def __init__(self, width=510, height=190):
        Flowable.__init__(self)
        self.width = width
        self.height = height

    def wrap(self, available_width, available_height):
        return min(self.width, available_width), self.height

    def draw(self):
        c = self.canv
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(NAVY)
        c.drawCentredString(130, 170, "USER-FACING WORKFLOW")
        c.drawCentredString(380, 170, "KNOWN-TRUTH SIMULATION")

        branches = [
            (25, 112, 210, 40, "connectTfaData", "file path -> data", PALE_BLUE, BLUE),
            (25, 54, 210, 40, "MISO / SISO runners", "independent settings", PALE_BLUE, BLUE),
            (275, 112, 210, 40, "simulation settings", "assigned factors", PALE_ORANGE, ORANGE),
            (275, 54, 210, 40, "runSimulationInterface", "known-truth runner", PALE_ORANGE, ORANGE),
        ]
        for x, y, width, height, top, bottom, fill, stroke in branches:
            c.setFillColor(fill)
            c.setStrokeColor(stroke)
            c.roundRect(x, y, width, height, 5, fill=1, stroke=1)
            c.setFillColor(NAVY)
            c.setFont("Helvetica-Bold", 8.3)
            c.drawCentredString(x + width / 2, y + 24, top)
            c.setFont("Helvetica", 7.5)
            c.setFillColor(INK)
            c.drawCentredString(x + width / 2, y + 11, bottom)

        c.setStrokeColor(MID_GRAY)
        for x in [130, 380]:
            c.line(x, 112, x, 94)
            c.line(x, 54, x, 34)
        c.line(130, 34, 380, 34)
        c.line(135, 37, 130, 34)
        c.line(135, 31, 130, 34)
        c.line(375, 37, 380, 34)
        c.line(375, 31, 380, 34)
        c.setFillColor(MID_GRAY)
        c.setFont("Helvetica", 8)
        c.drawCentredString(255, 18, "Shared modules: preprocessing  |  Welch spectra  |  SISO  |  MISO  |  diagnostics")


class RealDataConsolidationDiagram(Flowable):
    """Show how the public real-data path was separated from legacy output."""

    def __init__(self, width=510, height=190):
        Flowable.__init__(self)
        self.width = width
        self.height = height

    def wrap(self, available_width, available_height):
        return min(self.width, available_width), self.height

    def draw(self):
        c = self.canv
        c.setFillColor(NAVY)
        c.setFont("Helvetica-Bold", 9)
        c.drawString(0, 170, "BEFORE")
        c.drawString(270, 170, "AFTER CHUNK 13")

        before = [
            (0, 122, 210, 32, "MISO / SISO page"),
            (0, 76, 210, 32, "analyzeSubjectTFA"),
            (0, 30, 210, 32, "batch folders + optional legacy figures"),
        ]
        after = [
            (270, 122, 240, 32, "MISO / SISO page"),
            (270, 76, 240, 32, "analyzeTfaSignals"),
            (270, 30, 240, 32, "preprocess + Welch + requested model"),
        ]
        for x, y, width, height, label in before:
            c.setFillColor(PALE_ORANGE)
            c.setStrokeColor(ORANGE)
            c.roundRect(x, y, width, height, 5, fill=1, stroke=1)
            c.setFillColor(INK)
            c.setFont("Helvetica", 8)
            c.drawCentredString(x + width / 2, y + 12, label)
        for x, y, width, height, label in after:
            c.setFillColor(PALE_BLUE)
            c.setStrokeColor(BLUE)
            c.roundRect(x, y, width, height, 5, fill=1, stroke=1)
            c.setFillColor(INK)
            c.setFont("Helvetica-Bold" if y == 76 else "Helvetica", 8)
            c.drawCentredString(x + width / 2, y + 12, label)

        c.setStrokeColor(MID_GRAY)
        for x in [105, 390]:
            c.line(x, 122, x, 108)
            c.line(x, 76, x, 62)
            c.line(x - 3, 113, x, 108)
            c.line(x + 3, 113, x, 108)
            c.line(x - 3, 67, x, 62)
            c.line(x + 3, 67, x, 62)

        c.setFillColor(MID_GRAY)
        c.setFont("Helvetica", 7.5)
        c.drawCentredString(
            255,
            8,
            "The legacy batch wrapper now calls the same numerical core only for backward compatibility",
        )


class NCDataInspectionDiagram(Flowable):
    """Show the observed NC file handoff and the temporal CV constraint."""

    def __init__(self, width=510, height=184):
        Flowable.__init__(self)
        self.width = width
        self.height = height

    def wrap(self, available_width, available_height):
        return min(self.width, available_width), self.height

    def draw(self):
        c = self.canv
        boxes = [
            (0, 125, 105, 35, "NC/", "23 baseline files"),
            (135, 125, 105, 35, "sheet choice", "16 cleaned / 7 Sheet1"),
            (270, 125, 105, 35, "canonical fields", "Time / MAP / Vmean / CO2"),
            (405, 125, 105, 35, "analysis grid", "irregular -> 4 Hz"),
        ]
        for index, (x, y, width, height, top, bottom) in enumerate(boxes):
            c.setFillColor(PALE_BLUE if index < 3 else PALE_ORANGE)
            c.setStrokeColor(BLUE if index < 3 else ORANGE)
            c.roundRect(x, y, width, height, 5, fill=1, stroke=1)
            c.setFillColor(NAVY)
            c.setFont("Helvetica-Bold", 8.2)
            c.drawCentredString(x + width / 2, y + 22, top)
            c.setFillColor(INK)
            c.setFont("Helvetica", 7.2)
            c.drawCentredString(x + width / 2, y + 10, bottom)
            if index < len(boxes) - 1:
                next_x = boxes[index + 1][0]
                c.setStrokeColor(MID_GRAY)
                c.line(x + width, y + height / 2, next_x, y + height / 2)
                c.line(next_x - 5, y + height / 2 + 3, next_x, y + height / 2)
                c.line(next_x - 5, y + height / 2 - 3, next_x, y + height / 2)

        c.setFillColor(NAVY)
        c.setFont("Helvetica-Bold", 8.5)
        c.drawString(0, 101, "A typical stable recording after preprocessing")
        x0, x1 = 25, 485
        y = 64
        total_seconds = 350
        scale = (x1 - x0) / total_seconds
        c.setStrokeColor(MID_GRAY)
        c.line(x0, y, x1, y)
        for seconds in [0, 90, 180, 270, 350]:
            x = x0 + seconds * scale
            c.line(x, y - 4, x, y + 4)
            c.setFillColor(MID_GRAY)
            c.setFont("Helvetica", 7)
            c.drawCentredString(x, y - 15, f"{seconds} s")
        c.setFillColor(PALE_BLUE)
        c.setStrokeColor(BLUE)
        c.rect(x0, y - 8, 90 * scale, 16, fill=1, stroke=1)
        c.rect(x0 + 90 * scale, y - 8, 90 * scale, 16, fill=1, stroke=1)
        c.rect(x0 + 180 * scale, y - 8, 90 * scale, 16, fill=1, stroke=1)
        c.setFillColor(NAVY)
        c.setFont("Helvetica-Bold", 7.4)
        c.drawCentredString(x0 + 45 * scale, y - 3, "block 1")
        c.drawCentredString(x0 + 135 * scale, y - 3, "block 2")
        c.drawCentredString(x0 + 225 * scale, y - 3, "block 3")
        c.setFillColor(MID_GRAY)
        c.setFont("Helvetica", 7.2)
        c.drawString(310, y + 19, "all 23 files support 3 x 90-s blocks")
        c.drawString(310, y + 8, "two blocks train; one block is held out")

        c.setFillColor(ORANGE)
        c.setStrokeColor(ORANGE)
        c.rect(x0 + 270 * scale, y - 8, (350 - 270) * scale, 16, fill=1, stroke=1)
        c.setFillColor(colors.white)
        c.setFont("Helvetica", 7)
        c.drawCentredString(x0 + (270 + 40) * scale, y - 3, "tail")


def page_header_footer(canvas_obj, document):
    canvas_obj.saveState()
    width, height = letter
    canvas_obj.setStrokeColor(colors.HexColor("#D7DEE4"))
    canvas_obj.line(42, height - 32, width - 42, height - 32)
    canvas_obj.setFillColor(MID_GRAY)
    canvas_obj.setFont("Helvetica", 7.5)
    canvas_obj.drawString(42, height - 24, "MISO-SISO simulation implementation report")
    canvas_obj.drawRightString(width - 42, 24, f"Page {document.page}")
    canvas_obj.restoreState()


def read_manifest():
    manifest_path = ASSET_ROOT / "heatmap_manifest.csv"
    with manifest_path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def figure_path(plot_name):
    return PLOT_ROOT / f"{plot_name}.png"


def figure_block(plot_name, title, caption):
    image = Image(str(figure_path(plot_name)), width=510, height=351)
    return [
        P(title, "SubTitle"),
        image,
        P(caption, "FigureCaption"),
    ]


def build_story():
    manifest = read_manifest()
    family_count = 9
    frequency_count = 49
    story = []

    story.extend(
        [
            P("MISO-SISO simulation study", "ReportTitle"),
            P(
                "Visual implementation report through cleanup chunk 14. "
                "This document consolidates the current simulation and NC outputs with the simplified real-data model pages and their cleanup history.",
                "ReportSubtitle",
            ),
            P("Where the project is now", "SectionTitle"),
            P(
                "The project now has a small, explicit known-truth study that can be run without learned signal generation. "
                "It varies three assigned factors, evaluates both estimators against the saved generating filters, and exports frequency-first figures. "
                "The latest chunk adds two frequency-wise MISO coherence diagnostics as interpretive axes rather than new assigned factors.",
            ),
            WorkflowDiagram(),
            Spacer(1, 8),
        ]
    )

    status_rows = [
        ["Area", "Current status", "Evidence"],
        ["Truth metrics", "Implemented", "Truth-only normalization; zero-pathway handling; tests pass"],
        ["Simple study design", "Implemented", "3 x 3 assigned grid; explicit fixed nuisance settings"],
        ["Primary heatmaps", "Implemented", "Frequency x factor; MISO advantage as color"],
            ["Export workflow", "Implemented", "PNG/PDF, captions, CSV, Excel, readable grids"],
            ["Coherence diagnostics", "Implemented in this chunk", "Two frequency-wise diagnostic maps"],
            ["Real-data and simulation interfaces", "Implemented in this chunk", "Separate data, model, and simulation settings boundaries"],
            ["Real-data report export", "Implemented in this chunk", "Frequency table, diagnostic figure, CSV, and MAT output"],
            ["Clean platform scaffold", "Implemented in this chunk", "Six-page boundary with tested backend adapters"],
            ["Real-data numerical core", "Consolidated in chunk 13", "Public model pages no longer use legacy figure or output execution"],
            ["MISO and SISO page outputs", "Consolidated in chunk 14", "One model-specific frequency table and one compact figure per page"],
            ["NC bootstrap protocol", "Implemented", "3 x 90-s blocked validation with subject-level bootstrap"],
            ["NC bootstrap / cross-validation", "Implemented in this chunk", "Held-out frequency errors, advantage curve, and audit tables"],
            ["NC production export", "Implemented in this chunk", "Figure, frequency CSV, status CSV, subject audit CSV, and MAT archive"],
        ["Learned generator", "Deferred", "Kept separate from the known-truth benchmark"],
    ]
    story.append(styled_table(status_rows, [105, 120, 303]))
    story.append(PageBreak())

    story.extend(
        [
            P("Two sibling interfaces, one shared analysis core", "SectionTitle"),
            P(
                "The real-data and known-truth simulation workflows now have separate interface layers. "
                "The real-data side connects a file once, then exposes independent MISO and SISO runners. "
                "The simulation side exposes an editable settings structure and hands it to the known-truth runner. "
                "Both paths call the same preprocessing, spectral, SISO, MISO, and diagnostic modules.",
            ),
            SiblingWorkflowDiagram(),
            Spacer(1, 5),
            P("Real-data call", "SubTitle"),
            P(
                '<font name="Courier">filePath = "/path/to/recording.xlsx";<br/>'
                'connectedData = connectTfaData(filePath);<br/>'
                'miso = runMisoRealData(connectedData);<br/>'
                'siso = runSisoRealData(connectedData);</font>',
                "SmallReport",
            ),
        ]
    )
    interface_rows = [
        ["Public interface", "Role"],
        ["connectTfaData(filePath)", "Connect and validate one recording; return canonical signal data and subject metadata"],
        ["runMisoRealData(data, settings)", "Run the MISO model with MISO-specific settings"],
        ["runSisoRealData(data, settings)", "Run both independent SISO pathways with SISO-specific settings"],
        ["runMisoSisoRealData(data, settings)", "Run both model interfaces on the same connected recording"],
        ["runSimulationInterface(settings)", "Pass an editable simulation settings structure to the known-truth runner"],
        ["exportRealDataResults(results, folder)", "Write descriptive frequency metrics and diagnostics without truth scoring"],
    ]
    story.append(styled_table(interface_rows, [145, 363]))
    story.extend(
        [
            Spacer(1, 8),
            P(
                "The model pages now return a compact figure and its exact frequency table. "
                "The data connector remains output-free, and the simulation keeps its separate truth-error workflow.",
                "SmallReport",
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            P("Clean platform handoff point", "SectionTitle"),
            P(
                "The new platform folder defines the user-facing boundary without rewriting the tested backend. "
                "Each page returns structured data that later pages can consume. "
                "The data connection page only loads and identifies a recording; model pages perform analysis; the simulation pages define and run the controlled study.",
            ),
            P(
                '<font name="Courier">platform/<br/>'
                '  interfaces/connectData<br/>'
                '  interfaces/misoTesting<br/>'
                '  interfaces/sisoTesting<br/>'
                '  interfaces/ncBootstrap  [implemented]<br/>'
                '  interfaces/simulationSettings<br/>'
                '  interfaces/runSimulation</font>',
                "SmallReport",
            ),
        ]
    )
    platform_rows = [
        ["Page", "Current status", "Returned object"],
        ["connectData", "Implemented", "Canonical signals, source path, metadata, load status"],
        ["misoTesting", "Implemented", "Gain, phase, partial/multiple coherence figure and frequency table"],
        ["sisoTesting", "Implemented", "Gain, phase, ordinary coherence figure and frequency table"],
        ["ncBootstrap", "Implemented", "Held-out errors, advantage curve, CI, counts, and status table"],
        ["simulationSettings", "Implemented", "Editable known-truth design and seed"],
        ["runSimulation", "Implemented", "Truth, observations, errors, diagnostics, and heatmaps"],
    ]
    story.append(styled_table(platform_rows, [115, 115, 283]))
    story.extend(
        [
            Spacer(1, 8),
            P(
                "The bootstrap page now fixes the block unit, holdout design, and accuracy definition in its settings object. The returned means, uncertainty limits, and status table therefore have an explicit interpretation.",
                "SmallReport",
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            P("Cleanup chunk 13: real-data numerical core", "SectionTitle"),
            P(
                "The public MISO and SISO pages previously called the general subject workflow. "
                "That workflow also knew about output folders, batch status, optional subject figures, and legacy exporters. "
                "The new analyzeTfaSignals function contains only preprocessing, recording-length checks, shared Welch spectra, and the requested numerical model.",
            ),
            RealDataConsolidationDiagram(),
            Spacer(1, 5),
        ]
    )
    consolidation_rows = [
        ["Check", "Result", "Meaning"],
        ["Public MISO dependency set", "34 to 26 project files", "Eight legacy plotting/output dependencies removed from the active call path"],
        ["Public SISO dependency set", "34 to 26 project files", "Both model pages now use the same small numerical route"],
        ["Focused regression tests", "21 passed; 0 failed", "Interfaces and the temporary legacy wrapper retain their result contracts"],
        ["Complete MATLAB suite", "152 passed; 0 failed; 0 incomplete", "Simulation, NC bootstrap, legacy compatibility, and numerical modules remain stable"],
        ["MATLAB Code Analyzer", "0 issues in 3 changed files", "No new analyzer warnings introduced"],
    ]
    story.append(styled_table(consolidation_rows, [142, 125, 261]))
    story.extend(
        [
            Spacer(1, 8),
            P(
                "The one remaining plotting dependency is defaultPlotSettings, which currently supplies shared defaults. "
                "It can be moved when the compact user-facing MISO and SISO figures are integrated. No legacy files were deleted in this chunk.",
                "SmallReport",
            ),
            PageBreak(),
        ]
    )

    model_figure_table = Table(
        [
            [
                Image(str(MISO_PAGE_FIGURE), width=252, height=198),
                Image(str(SISO_PAGE_FIGURE), width=252, height=198),
            ],
            [
                P("MISO page: two pathway estimates plus partial and multiple coherence.", "FigureCaption"),
                P("SISO page: two independent pathway estimates plus ordinary coherence.", "FigureCaption"),
            ],
        ],
        colWidths=[264, 264],
    )
    model_figure_table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ]
        )
    )
    story.extend(
        [
            P("Cleanup chunk 14: compact model-page outputs", "SectionTitle"),
            P(
                "Each real-data model page now returns one frequency table and one three-panel figure. "
                "Gain, phase, and coherence remain visible across the retained frequency range without bringing the old batch, group, or statistical plots into the user workflow.",
            ),
            model_figure_table,
        ]
    )
    output_rows = [
        ["Page", "Plotted quantities", "Additional table quantities"],
        ["MISO", "MAP/CO2 gain; wrapped phase; partial and multiple coherence", "MAP-CO2 input coherence and input phase"],
        ["SISO", "MAP/CO2 gain; wrapped phase; ordinary coherence", "The same seven plotted frequency columns"],
        ["Both", "Frequency is the horizontal axis; no truth-based advantage", "Phase is reported in degrees; every plotted value is exported in the returned table"],
    ]
    story.append(styled_table(output_rows, [75, 245, 208]))
    story.extend(
        [
            Spacer(1, 7),
            P(
                "The platform MISO and SISO pages now have 29 project-file dependencies each and zero dependencies under the legacy plotting or output folders. "
                "The older combined MISO-SISO descriptive exporter remains available only as a compatibility path during cleanup.",
                "SmallReport",
            ),
            PageBreak(),
        ]
    )

    story.extend(
        [
            P("Actual NC data inspection", "SectionTitle"),
            P(
                "The NC folder was inspected before defining the bootstrap interface. "
                "It contains one baseline workbook per subject, with a consistent canonical signal set hidden behind small sheet and CO2-header differences. "
                "The raw time values are beat-to-beat timestamps; the existing preprocessing step interpolates them onto the 4 Hz analysis grid.",
            ),
            NCDataInspectionDiagram(),
            Spacer(1, 5),
        ]
    )
    nc_format_rows = [
        ["Observed item", "Finding", "Implementation consequence"],
        ["Location and unit", "/Users/amoghn/Desktop/ieem_data/NC; 23 unique IDs", "Use subject/file as the population resampling unit"],
        ["Workbook selection", "16 files use cleaned; 7 use Sheet1; other first sheets are raw/no-header variants", "Keep sheet selection explicit and record the selected sheet"],
        ["Required columns", "Time, MAP, and Vmean in all 23; CO2 aliases: CO2 15, ETCO2 7, PETCO2 1", "The existing alias loader is appropriate; preserve the alias in QC metadata"],
        ["Raw timing", "Median interval 0.728-1.100 s; stable duration 283.8-347.7 s", "Do not treat raw rows as equally spaced; retain the 4 Hz interpolation step"],
        ["Welch support", "At 4 Hz, three 90-s blocks fit in all 23 recordings; each training split contains two 90-s Welch segments", "Do not bootstrap overlapping windows as independent observations"],
        ["CO2 startup", "Several files contain leading zeros or a transition; one has about 30 s of startup", "Keep startup removal deterministic and expose removed seconds in QC"],
    ]
    story.append(styled_table(nc_format_rows, [105, 218, 145]))
    story.extend(
        [
            Spacer(1, 8),
            P("Recommended NC validation protocol", "SubTitle"),
        ]
    )
    nc_protocol_rows = [
        ["Decision", "Recommendation for this dataset", "Reason"],
        ["Primary bootstrap unit", "Subject-level resampling of the 23 completed per-subject curves", "Each subject has one baseline file; this estimates population uncertainty without pseudoreplication"],
        ["Repeated files", "None in the current NC folder; future files stay grouped by subject ID", "Prevents the same person appearing in both a training and test split"],
        ["Temporal validation", "Three contiguous, non-overlapping 90 s blocks; each fold trains on two blocks and tests on the remaining block", "Two training segments keep the two-input MISO spectral solve estimable while retaining a held-out block"],
        ["Accuracy", "Held-out normalized prediction error; advantage = log10(mean SISO error / mean MISO error)", "Positive values mean lower MISO error; the metric can be computed without a truth transfer function"],
        ["Primary figure", "Frequency x advantage heatmap/curve only; retain errors, N, SD, and CI in source tables", "Keeps the user-facing result interpretable while preserving audit information"],
        ["What to avoid", "Row-wise bootstrap, random sample splits, or treating overlapping Welch windows as independent", "All would understate uncertainty for these autocorrelated recordings"],
    ]
    story.append(styled_table(nc_protocol_rows, [105, 218, 145]))
    story.extend(
        [
            Spacer(1, 8),
            P("Implemented NC production output", "SubTitle"),
            P(
                "This figure is from the 23-recording NC folder using the implemented blocked-validation page and the default deterministic 2,000-resample subject bootstrap. "
                "Positive advantage means lower held-out prediction error for MISO; the shaded interval is the bootstrap percentile interval.",
                "SmallReport",
            ),
            styled_table(
                [
                    ["Production item", "Result"],
                    ["Completed recordings", "23 / 23"],
                    ["Retained frequency bins", "44"],
                    ["Frequency spacing", "1/90 s = 0.011111 Hz"],
                    ["Bootstrap samples", "2,000"],
                    ["Export files", "5"],
                ],
                [180, 338],
            ),
            Spacer(1, 5),
            Image(str(NC_FIGURE), width=500, height=327),
            P(
                "The primary user-facing result is the frequency-wise advantage curve. The underlying frequencyTable retains SISO and MISO mean errors, their SDs, bootstrap SD, confidence limits, and valid subject counts; statusTable retains per-subject completion and QC fields.",
                "FigureCaption",
            ),
            PageBreak(),
        ]
    )
    story.extend(
        [
            P("Current simulation protocol", "SectionTitle"),
            P(
                "The simple profile is deliberately a methods benchmark. It does not claim that every grid point is a normal human physiological range. "
                "Each chosen range is an explicit engineering condition whose role is stated before the comparison.",
            ),
        ]
    )
    protocol_rows = [
        ["Assigned item", "Levels in simple profile", "Why it is varied"],
        ["MAP-CO2 input coherence", "0, 0.50, 0.95", "Separability of the two measured inputs"],
        ["CO2-to-MAP pathway ratio", "0, 0.25, 1", "Whether an omitted CO2 pathway matters"],
        ["CBFV output SNR", "No noise, 10 dB, 0 dB", "Finite-record observation quality"],
        ["Reference duration", "300 s", "Fixed for factor and diagnostic maps"],
        ["Sampling and frequency", "4 Hz; 0.02-0.50 Hz", "Common evaluation grid for all figures"],
        ["Welch analysis", "100 s window; 50% overlap", "Held fixed in the primary comparison"],
        ["Repetition unit", "Paired family realization", "Same observation goes to SISO and MISO"],
    ]
    story.append(styled_table(protocol_rows, [145, 130, 253]))
    story.extend(
        [
            Spacer(1, 8),
            P("Primary score and interpretation", "SubTitle"),
            P(
                "At each frequency and displayed group, the point estimate is "
                "log10(mean SISO truth error / mean MISO truth error). Positive color means MISO has the lower mean error; negative color means SISO has the lower mean error. "
                "The source tables retain paired valid counts, bootstrap standard deviations, and confidence limits.",
            ),
            P(
                "The one-repetition example shown here contains 9 families, 9 paired observation plans per family, 81 primary analyses, and 49 retained frequency bins. "
                "It demonstrates the workflow and figure structure; it is not a final scientific result.",
            ),
            P("Coherence diagnostic definitions", "SubTitle"),
            P(
                "The diagnostic maps use fixed 0.1-wide bins for frequency-wise values. "
                "MISO minus MAP pairwise coherence describes added output coherence obtained by using both inputs. "
                "MISO minus MAP partial coherence given CO2 compares the multiple coherence with MAP coherence after conditioning on CO2. "
                "These are explanatory diagnostics, not additional experimental factors.",
            ),
            PageBreak(),
        ]
    )

    figures = [
        (
            "simple_map_targetinputcoherence",
            "Assigned factor 1: MAP-CO2 input coherence",
            "The heatmap is evaluated at the reference duration and 10 dB CBFV output SNR. Blue indicates lower MISO truth error; orange indicates lower SISO truth error. Gray cells would indicate insufficient valid observations.",
        ),
        (
            "simple_map_assignedpetco2tomapbandgainratio",
            "Assigned factor 2: CO2-to-MAP pathway ratio",
            "The zero level is an explicit omitted-CO2 pathway control. The displayed pathway is MAP, so the score asks whether adding CO2 improves recovery of the MAP pathway.",
        ),
        (
            "simple_map_outputsnrdb",
            "Assigned factor 3: CBFV output SNR",
            "The recording duration is fixed at 300 seconds while output SNR changes. This isolates the effect of output disturbance from the duration experiment.",
        ),
        (
            "simple_map_multipleminusmapcoherence",
            "Diagnostic 1: MISO minus MAP pairwise coherence",
            "The vertical axis is binned from the frequency-wise diagnostic itself. Empty bins remain gray; they are not interpolated or filled.",
        ),
        (
            "simple_map_multipleminuspartialmapcoherence",
            "Diagnostic 2: MISO minus MAP partial coherence given CO2",
            "This is a frequency-wise interpretive diagnostic for the conditional MAP relationship. It is included in the same primary export set without becoming a new generator factor.",
        ),
    ]
    for index, figure in enumerate(figures):
        story.extend(figure_block(*figure))
        if index < len(figures) - 1:
            story.append(PageBreak())

    story.extend(
        [
            PageBreak(),
            P("Source data behind the heatmaps", "SectionTitle"),
            P(
                "Every heatmap is accompanied by a frequencyMap table. The table is the reviewable numerical source for the image, and the workbook also contains a readable frequency grid.",
            ),
        ]
    )
    source_rows = [
        ["Source column", "Meaning"],
        ["FactorValue / FactorGroup", "Exact assigned level or diagnostic bin"],
        ["FrequencyHz", "Native retained Welch frequency bin"],
        ["SISOErrorMean / MISOErrorMean", "Arithmetic means over paired finite records"],
        ["Advantage", "log10(mean SISO error / mean MISO error)"],
        ["PairedValidN", "Records finite for both estimators"],
        ["BootstrapSD, CILower, CIUpper", "Deterministic paired bootstrap uncertainty"],
        ["ScoreVersion", "frequency-ratio-of-mean-errors-v1"],
    ]
    story.append(styled_table(source_rows, [165, 363]))
    story.extend(
        [
            Spacer(1, 10),
            P(
                "The returned tables preserve estimator errors and uncertainty even when the primary paper figure shows advantage alone. This keeps the image simple while retaining an auditable numerical record.",
                "SmallReport",
            ),
            PageBreak(),
            P("Implementation history and next boundary", "SectionTitle"),
        ]
    )
    history_rows = [
        ["Chunk", "What changed", "Why it matters"],
        ["1", "Truth-error normalization and MISO coherence diagnostics", "Makes pathway truth comparisons consistent and saves interpretive coherence quantities"],
        ["2", "Simple full-factorial study profile", "Reduces the primary experiment to three understandable assigned factors"],
        ["3", "Frequency-first advantage score and heatmap", "Matches the requested frequency x metric x advantage figure design"],
        ["4", "Standalone heatmap exporter and source-data grids", "Makes the workflow reviewable and repeatable without changing historical outputs"],
        ["5", "Diagnostic heatmaps and this visual report", "Carries Shotaro's coherence suggestions into the same simulation output"],
        ["6", "Sibling user-facing file entry point", "Allows one recording to use the shared SISO/MISO core without entering the simulation workflow"],
        ["7", "Separate data, MISO, SISO, and simulation interfaces", "Makes file connection, model settings, and simulation design independently readable"],
        ["8", "Real-data frequency report export", "Provides reviewable model and coherence outputs without claiming a truth-based advantage"],
        ["9", "Clean platform scaffold", "Separates user-facing pages from the existing tested backend and keeps simulation independent from real-data analysis"],
        ["10", "NC file inspection and validation protocol", "Grounds the subject bootstrap and blocked-CV design in the actual 23-recording folder"],
        ["11", "NC bootstrap implementation", "Runs all 23 recordings, compares held-out MISO/SISO errors, bootstraps subjects, and returns an audit-ready frequency table"],
        ["12", "NC production run and export", "Freezes the 2,000-resample result and writes the figure plus frequency, status, subject-audit, and MAT files"],
        ["13", "Real-data core consolidation", "Separates numerical MISO/SISO analysis from the old batch plotting and output workflow while preserving compatibility"],
        ["14", "Compact model-page outputs and frequency tables", "Gives each real-data model page one readable output and removes all legacy plotting/output dependencies from its active path"],
    ]
    story.append(styled_table(history_rows, [45, 215, 268]))
    story.extend(
        [
            Spacer(1, 10),
            P("Validation completed", "SubTitle"),
            P(
                "The full MATLAB suite passed after chunk 14: 152 passed, 0 failed, and 0 incomplete. The focused real-data, platform, settings, and compatibility checks also passed, and MATLAB Code Analyzer reported no issues in the changed MATLAB files. Existing expected warnings concern deliberately missing Excel folders and intentionally short synthetic records.",
            ),
            P("Next implementation boundary", "SubTitle"),
            P(
                "The next cleanup boundary is the simplified simulation heatmap exporter and reproducibility manifest. Once those active capabilities are independent, the superseded batch, group, statistics, robustness, and approach-paper orchestration can be removed. Scientific changes to the simulation protocol remain reserved for the Astra review.",
            ),
        ]
    )

    return story


def main():
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(
        str(REPORT_PATH),
        pagesize=letter,
        leftMargin=42,
        rightMargin=42,
        topMargin=48,
        bottomMargin=38,
        title="MISO-SISO simulation implementation report",
        author="Codex",
    )
    frame = Frame(
        doc.leftMargin,
        doc.bottomMargin,
        doc.width,
        doc.height,
        id="normal",
    )
    doc.addPageTemplates([PageTemplate(id="report", frames=[frame], onPage=page_header_footer)])
    doc.build(build_story())
    print(REPORT_PATH)


if __name__ == "__main__":
    main()
