"""Generate reproducible vector figures for the LaTeX presentation.

The generator intentionally uses only the standard library and ReportLab so it
can run in the bundled workspace Python environment.  The plotted signals and
Fourier spectrum are calculated from sampled data rather than drawn as arbitrary
curves.  Each vector PDF is also rendered to a PNG for convenient inspection.
"""

from __future__ import annotations

import cmath
import math
import random
import subprocess
from pathlib import Path

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white


ACCENT = HexColor("#6E4E8E")
ACCENT_LIGHT = HexColor("#F4F1F7")
INK = HexColor("#151515")
BODY = HexColor("#444444")
MUTED = HexColor("#737373")
LIGHT_LINE = HexColor("#D8D8D8")
MAP_BLUE = HexColor("#0072BD")
CO2_ORANGE = HexColor("#D95319")
CBFV_GREEN = HexColor("#4C956C")

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "figures" / "methods"

ARIAL = "/System/Library/Fonts/Supplemental/Arial.ttf"
ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
ARIAL_ITALIC = "/System/Library/Fonts/Supplemental/Arial Italic.ttf"
ARIAL_UNICODE = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"


def register_fonts() -> None:
    pdfmetrics.registerFont(TTFont("FigureSans", ARIAL))
    pdfmetrics.registerFont(TTFont("FigureSans-Bold", ARIAL_BOLD))
    pdfmetrics.registerFont(TTFont("FigureSans-Italic", ARIAL_ITALIC))
    pdfmetrics.registerFont(TTFont("FigureUnicode", ARIAL_UNICODE))


def moving_average(values: list[float], width: int) -> list[float]:
    radius = width // 2
    smoothed = []
    for index in range(len(values)):
        start = max(0, index - radius)
        stop = min(len(values), index + radius + 1)
        smoothed.append(sum(values[start:stop]) / (stop - start))
    return smoothed


def center_and_scale(values: list[float]) -> list[float]:
    mean_value = sum(values) / len(values)
    centered = [value - mean_value for value in values]
    variance = sum(value * value for value in centered) / len(centered)
    scale = math.sqrt(variance)
    return [value / scale for value in centered]


def convolve_same(signal: list[float], kernel: list[float]) -> list[float]:
    full = [0.0] * (len(signal) + len(kernel) - 1)
    for signal_index, signal_value in enumerate(signal):
        for kernel_index, kernel_value in enumerate(kernel):
            full[signal_index + kernel_index] += signal_value * kernel_value
    start = (len(kernel) - 1) // 2
    return full[start : start + len(signal)]


def calculate_amplitude_spectrum(
    signal: list[float], sampling_frequency_hz: float, maximum_hz: float
) -> tuple[list[float], list[float]]:
    num_samples = len(signal)
    window = [
        0.5 - 0.5 * math.cos(2 * math.pi * index / (num_samples - 1))
        for index in range(num_samples)
    ]
    window_sum = sum(window)
    maximum_bin = int(maximum_hz * num_samples / sampling_frequency_hz)
    frequencies = []
    amplitudes = []
    for frequency_bin in range(maximum_bin + 1):
        coefficient = 0j
        for sample_index, value in enumerate(signal):
            angle = -2 * math.pi * frequency_bin * sample_index / num_samples
            coefficient += value * window[sample_index] * cmath.exp(1j * angle)
        frequencies.append(frequency_bin * sampling_frequency_hz / num_samples)
        amplitudes.append(2 * abs(coefficient) / window_sum)
    return frequencies, amplitudes


def map_values(
    values: list[float], left: float, bottom: float, width: float, height: float
) -> list[tuple[float, float]]:
    minimum = min(values)
    maximum = max(values)
    padding = max((maximum - minimum) * 0.08, 1e-6)
    minimum -= padding
    maximum += padding
    denominator = maximum - minimum
    return [
        (
            left + width * index / max(len(values) - 1, 1),
            bottom + height * (value - minimum) / denominator,
        )
        for index, value in enumerate(values)
    ]


def draw_polyline(
    pdf: canvas.Canvas,
    points: list[tuple[float, float]],
    color,
    line_width: float = 1.2,
) -> None:
    path = pdf.beginPath()
    path.moveTo(*points[0])
    for point in points[1:]:
        path.lineTo(*point)
    pdf.setStrokeColor(color)
    pdf.setLineWidth(line_width)
    pdf.drawPath(path, stroke=1, fill=0)


def draw_arrow(
    pdf: canvas.Canvas,
    start_x: float,
    start_y: float,
    end_x: float,
    end_y: float,
    color=ACCENT,
) -> None:
    pdf.setStrokeColor(color)
    pdf.setFillColor(color)
    pdf.setLineWidth(1.8)
    pdf.line(start_x, start_y, end_x, end_y)
    angle = math.atan2(end_y - start_y, end_x - start_x)
    arrow_length = 9
    arrow_width = 5
    base_x = end_x - arrow_length * math.cos(angle)
    base_y = end_y - arrow_length * math.sin(angle)
    perpendicular_x = arrow_width * math.sin(angle)
    perpendicular_y = -arrow_width * math.cos(angle)
    path = pdf.beginPath()
    path.moveTo(end_x, end_y)
    path.lineTo(base_x + perpendicular_x, base_y + perpendicular_y)
    path.lineTo(base_x - perpendicular_x, base_y - perpendicular_y)
    path.close()
    pdf.drawPath(path, stroke=0, fill=1)


def draw_axis_frame(
    pdf: canvas.Canvas,
    left: float,
    bottom: float,
    width: float,
    height: float,
    x_label: str,
    y_label: str,
    x_ticks: list[tuple[float, str]],
) -> None:
    pdf.setStrokeColor(MUTED)
    pdf.setLineWidth(0.7)
    pdf.line(left, bottom, left + width, bottom)
    pdf.line(left, bottom, left, bottom + height)
    pdf.setFont("FigureSans", 7.5)
    pdf.setFillColor(MUTED)
    for fraction, label in x_ticks:
        tick_x = left + fraction * width
        pdf.line(tick_x, bottom, tick_x, bottom - 3)
        pdf.drawCentredString(tick_x, bottom - 13, label)
    pdf.setFont("FigureSans", 8.5)
    pdf.drawCentredString(left + width / 2, bottom - 28, x_label)
    pdf.saveState()
    pdf.translate(left - 28, bottom + height / 2)
    pdf.rotate(90)
    pdf.drawCentredString(0, 0, y_label)
    pdf.restoreState()


def render_png(pdf_path: Path, dpi: int = 220) -> None:
    output_prefix = pdf_path.with_suffix("")
    subprocess.run(
        [
            "pdftoppm",
            "-singlefile",
            "-png",
            "-r",
            str(dpi),
            str(pdf_path),
            str(output_prefix),
        ],
        check=True,
    )


def create_fourier_transform_visual() -> None:
    random_generator = random.Random(20260823)
    sampling_frequency_hz = 4.0
    duration_seconds = 180.0
    num_samples = int(duration_seconds * sampling_frequency_hz)
    time_seconds = [index / sampling_frequency_hz for index in range(num_samples)]
    raw_noise = [random_generator.gauss(0, 1) for _ in time_seconds]
    smooth_noise = moving_average(raw_noise, 17)
    signal = [
        math.sin(2 * math.pi * 0.035 * time + 0.20)
        + 0.58 * math.sin(2 * math.pi * 0.105 * time + 1.05)
        + 0.24 * math.sin(2 * math.pi * 0.012 * time + 0.70)
        + 0.34 * noise
        for time, noise in zip(time_seconds, smooth_noise)
    ]
    mean_value = sum(signal) / len(signal)
    signal = [value - mean_value for value in signal]
    frequencies, amplitudes = calculate_amplitude_spectrum(
        signal, sampling_frequency_hz, 0.25
    )

    width, height = 980, 315
    output_path = OUTPUT / "fourier_transform_visual.pdf"
    pdf = canvas.Canvas(str(output_path), pagesize=(width, height))
    pdf.setFillColor(white)
    pdf.rect(0, 0, width, height, fill=1, stroke=0)

    left_plot = (45, 72, 340, 172)
    right_plot = (650, 72, 285, 172)
    left, bottom, plot_width, plot_height = left_plot
    draw_axis_frame(
        pdf,
        left,
        bottom,
        plot_width,
        plot_height,
        "Time (s)",
        "Amplitude",
        [(0, "0"), (0.5, "90"), (1, "180")],
    )
    points = map_values(signal, left, bottom, plot_width, plot_height)
    draw_polyline(pdf, points, MAP_BLUE, 1.1)
    pdf.setFont("FigureSans-Bold", 13)
    pdf.setFillColor(INK)
    pdf.drawCentredString(left + plot_width / 2, 273, "Time-domain signal x(t)")

    left, bottom, plot_width, plot_height = right_plot
    draw_axis_frame(
        pdf,
        left,
        bottom,
        plot_width,
        plot_height,
        "Frequency (Hz)",
        "Amplitude",
        [(0, "0"), (0.4, "0.10"), (0.8, "0.20"), (1, "0.25")],
    )
    amplitude_points = map_values(
        amplitudes, left, bottom, plot_width, plot_height
    )
    draw_polyline(pdf, amplitude_points, CO2_ORANGE, 1.45)
    pdf.setFont("FigureSans-Bold", 13)
    pdf.setFillColor(INK)
    pdf.drawCentredString(
        left + plot_width / 2, 273, "Amplitude spectrum |X(f)|"
    )

    draw_arrow(pdf, 418, 157, 615, 157)
    pdf.setFont("FigureUnicode", 11.5)
    pdf.setFillColor(INK)
    pdf.drawCentredString(
        516,
        202,
        "X[k] = Σ x[n] exp(-i 2πkn/N),  n = 0,...,N-1",
    )
    pdf.setFont("FigureSans-Bold", 10.5)
    pdf.setFillColor(ACCENT)
    pdf.drawCentredString(516, 122, "Fourier transform")

    pdf.setFont("FigureSans", 8.5)
    pdf.setFillColor(MUTED)
    pdf.drawCentredString(
        width / 2,
        22,
        "The same finite record is reorganized by frequency; dominant oscillations appear as spectral peaks.",
    )
    pdf.showPage()
    pdf.save()
    render_png(output_path)


def draw_panel(
    pdf: canvas.Canvas, left: float, bottom: float, width: float, height: float
) -> None:
    pdf.setFillColor(ACCENT_LIGHT)
    pdf.setStrokeColor(HexColor("#D9D0E1"))
    pdf.setLineWidth(0.8)
    pdf.roundRect(left, bottom, width, height, 8, fill=1, stroke=1)


def draw_mini_signal(
    pdf: canvas.Canvas,
    values: list[float],
    left: float,
    bottom: float,
    width: float,
    height: float,
    color,
    line_width: float = 0.8,
) -> None:
    pdf.setFillColor(white)
    pdf.roundRect(left, bottom, width, height, 4, fill=1, stroke=0)
    points = map_values(values, left + 5, bottom + 7, width - 10, height - 14)
    draw_polyline(pdf, points, color, line_width)


def create_known_truth_workflow() -> None:
    random_generator = random.Random(1729)
    sampling_frequency_hz = 4.0
    duration_seconds = 160.0
    num_samples = int(duration_seconds * sampling_frequency_hz)
    time_seconds = [index / sampling_frequency_hz for index in range(num_samples)]
    shared = moving_average(
        [random_generator.gauss(0, 1) for _ in time_seconds], 15
    )
    map_signal = center_and_scale(
        [
            0.95 * shared_value
            + 0.55 * math.sin(2 * math.pi * 0.035 * time)
            + 0.20 * random_generator.gauss(0, 1)
            for time, shared_value in zip(time_seconds, shared)
        ]
    )
    co2_signal = center_and_scale(
        [
            0.60 * shared_value
            + 0.58 * math.sin(2 * math.pi * 0.075 * time + 0.85)
            + 0.30 * random_generator.gauss(0, 1)
            for time, shared_value in zip(time_seconds, shared)
        ]
    )

    kernel_time = [index / sampling_frequency_hz for index in range(96)]
    map_kernel = [math.exp(-time / 2.4) for time in kernel_time]
    map_total = sum(map_kernel)
    map_kernel = [value / map_total for value in map_kernel]
    delay_samples = int(3.0 * sampling_frequency_hz)
    co2_kernel = [0.0] * delay_samples + [
        math.exp(-time / 5.0) for time in kernel_time[:-delay_samples]
    ]
    co2_total = sum(co2_kernel)
    co2_kernel = [value / co2_total for value in co2_kernel]

    map_contribution = convolve_same(map_signal, map_kernel)
    co2_contribution = [
        0.85 * value for value in convolve_same(co2_signal, co2_kernel)
    ]
    clean_velocity = [
        map_value + co2_value
        for map_value, co2_value in zip(map_contribution, co2_contribution)
    ]
    observed_velocity = [
        value + 0.42 * random_generator.gauss(0, 1)
        for value in clean_velocity
    ]

    width, height = 1100, 405
    output_path = OUTPUT / "known_truth_simulation_workflow.pdf"
    pdf = canvas.Canvas(str(output_path), pagesize=(width, height))
    pdf.setFillColor(white)
    pdf.rect(0, 0, width, height, fill=1, stroke=0)

    panel_lefts = [18, 235, 452, 669, 886]
    panel_width = 196
    panel_bottom = 55
    panel_height = 315
    headings = [
        "1. Fix one family",
        "2. Generate inputs",
        "3. Create clean CBFV",
        "4. Create an observation",
        "5. Estimate and compare",
    ]
    for panel_left, heading in zip(panel_lefts, headings):
        draw_panel(pdf, panel_left, panel_bottom, panel_width, panel_height)
        pdf.setFont("FigureSans-Bold", 10.5)
        pdf.setFillColor(INK)
        pdf.drawCentredString(
            panel_left + panel_width / 2, panel_bottom + panel_height - 27, heading
        )

    # Family truth: actual frequency-response shaped curves.
    true_frequency = [index * 0.25 / 90 for index in range(91)]
    map_response = [
        1.0 / math.sqrt(1 + (frequency / 0.10) ** 2)
        for frequency in true_frequency
    ]
    co2_response = [
        0.75 / math.sqrt(1 + (frequency / 0.055) ** 2)
        for frequency in true_frequency
    ]
    family_left = panel_lefts[0]
    plot_left = family_left + 22
    plot_bottom = 160
    plot_width = 152
    plot_height = 128
    pdf.setFillColor(white)
    pdf.roundRect(plot_left, plot_bottom, plot_width, plot_height, 4, fill=1, stroke=0)
    map_points = map_values(
        map_response, plot_left + 7, plot_bottom + 12, plot_width - 14, plot_height - 23
    )
    co2_points = map_values(
        co2_response, plot_left + 7, plot_bottom + 12, plot_width - 14, plot_height - 23
    )
    draw_polyline(pdf, map_points, MAP_BLUE, 1.3)
    draw_polyline(pdf, co2_points, CO2_ORANGE, 1.3)
    pdf.setFont("FigureSans-Bold", 8.5)
    pdf.setFillColor(MAP_BLUE)
    pdf.drawString(plot_left + 92, plot_bottom + 95, "H_M")
    pdf.setFillColor(CO2_ORANGE)
    pdf.drawString(plot_left + 92, plot_bottom + 53, "H_C")
    pdf.setFont("FigureSans", 8)
    pdf.setFillColor(BODY)
    pdf.drawCentredString(family_left + 98, 126, "Input spectra and true pathways")
    pdf.drawCentredString(family_left + 98, 113, "remain fixed within the family")

    # Two clean inputs shown at their true sample locations.
    input_left = panel_lefts[1]
    shown_samples = int(80 * sampling_frequency_hz)
    draw_mini_signal(
        pdf, map_signal[:shown_samples], input_left + 21, 218, 154, 68, MAP_BLUE
    )
    draw_mini_signal(
        pdf, co2_signal[:shown_samples], input_left + 21, 142, 154, 68, CO2_ORANGE
    )
    pdf.setFont("FigureSans-Bold", 8.5)
    pdf.setFillColor(MAP_BLUE)
    pdf.drawString(input_left + 28, 272, "M(t)")
    pdf.setFillColor(CO2_ORANGE)
    pdf.drawString(input_left + 28, 196, "C(t)")
    pdf.setFont("FigureSans", 8)
    pdf.setFillColor(BODY)
    pdf.drawCentredString(input_left + 98, 117, "Shared and independent random")
    pdf.drawCentredString(input_left + 98, 104, "fluctuations create the inputs")

    # The clean output is generated through the stored pathway kernels.
    clean_left = panel_lefts[2]
    pdf.setFont("FigureSans", 9)
    pdf.setFillColor(INK)
    pdf.drawCentredString(clean_left + 98, 296, "V_clean = h_M * M + h_C * C")
    draw_mini_signal(
        pdf,
        clean_velocity[:shown_samples],
        clean_left + 21,
        157,
        154,
        119,
        CBFV_GREEN,
        0.9,
    )
    pdf.setFont("FigureSans", 8)
    pdf.setFillColor(BODY)
    pdf.drawCentredString(clean_left + 98, 126, "The generator stores h_M and h_C")
    pdf.drawCentredString(clean_left + 98, 113, "as the pathway truth")

    # Observation quality changes without changing the family truth.
    observation_left = panel_lefts[3]
    pdf.setFont("FigureSans", 9)
    pdf.setFillColor(INK)
    pdf.drawCentredString(observation_left + 98, 296, "Finite duration + noise + timing")
    draw_mini_signal(
        pdf,
        observed_velocity[: int(55 * sampling_frequency_hz)],
        observation_left + 21,
        157,
        154,
        119,
        CBFV_GREEN,
        0.75,
    )
    pdf.setFont("FigureSans", 8)
    pdf.setFillColor(BODY)
    pdf.drawCentredString(observation_left + 98, 126, "The observation changes")
    pdf.drawCentredString(observation_left + 98, 113, "while the true system does not")

    # Estimation is intentionally separated from the stored truth.
    estimate_left = panel_lefts[4]
    pdf.setFont("FigureSans", 9)
    pdf.setFillColor(BODY)
    pdf.drawCentredString(estimate_left + 98, 275, "Observed M, C, and V")
    draw_arrow(pdf, estimate_left + 98, 250, estimate_left + 98, 222)
    pdf.setFont("FigureSans-Bold", 12)
    pdf.setFillColor(INK)
    pdf.drawCentredString(estimate_left + 98, 195, "Estimated H_M and H_C")
    pdf.setFont("FigureSans", 9)
    pdf.setFillColor(BODY)
    pdf.drawCentredString(estimate_left + 98, 163, "Compare the estimates with")
    pdf.drawCentredString(estimate_left + 98, 149, "the stored true H_M and H_C")
    pdf.setFont("FigureSans-Bold", 8.5)
    pdf.setFillColor(ACCENT)
    pdf.drawCentredString(estimate_left + 98, 111, "The estimator never receives truth")

    for first_left, second_left in zip(panel_lefts[:-1], panel_lefts[1:]):
        draw_arrow(
            pdf,
            first_left + panel_width + 4,
            213,
            second_left - 5,
            213,
        )

    pdf.setFont("FigureSans-Bold", 10)
    pdf.setFillColor(ACCENT)
    pdf.drawCentredString(
        width / 2,
        24,
        "One family fixes the generating system; observation and estimator choices test how accurately it can be recovered.",
    )
    pdf.showPage()
    pdf.save()
    render_png(output_path)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    register_fonts()
    create_fourier_transform_visual()
    create_known_truth_workflow()


if __name__ == "__main__":
    main()
