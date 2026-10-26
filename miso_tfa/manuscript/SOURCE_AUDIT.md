# Manuscript source audit

This ledger records the sources selected for the Methods-only Word draft and the role each source is expected to play. It separates published evidence from choices made by this simulation.

| ID | Source | Intended use | Status |
|---|---|---|---|
| [1] | Panerai RB, Brassard P, Burma JS, et al. CARNet white paper 2022 update. *J Cereb Blood Flow Metab*. 2023;43:3-25. DOI: 10.1177/0271678X221119760. PMID: 35962478. | TFA terminology, dynamic cerebral autoregulation, MAP-CBFV interpretation, coherence and reporting context | Selected |
| [2] | Hoiland RL, Fisher JA, Ainslie PN. Regulation of the cerebral circulation by arterial carbon dioxide. *Compr Physiol*. 2019;9:1101-1154. DOI: 10.1002/cphy.c180021. PMID: 31187899. | Physiological role of arterial CO2 and PETCO2 interpretation | Selected |
| [3] | Panerai RB, Simpson DM, Deverson ST, et al. Multivariate dynamic analysis of cerebral blood flow regulation in humans. *IEEE Trans Biomed Eng*. 2000;47:419-423. DOI: 10.1109/10.827312. PMID: 10743786. | Prior multivariate MAP and CO2 analysis in human CBFV recordings | Selected |
| [4] | Peng T, Rowley AB, Ainslie PN, et al. Multivariate system identification for cerebral autoregulation. *Ann Biomed Eng*. 2008;36:308-320. DOI: 10.1007/s10439-007-9412-9. PMID: 18066666. | Multiple-input modeling and coherence interpretation | Selected |
| [5] | Chertoff ME, Billinger SA, Perdomo SJ, et al. A novel nonlinear system identification for cerebral autoregulation in human: computer simulation and validation. *Ann Biomed Eng*. 2020;48:1207-1217. DOI: 10.1007/s10439-019-02442-7. PMID: 31873829. | Example of known-truth simulation and validation logic | Selected |
| [6] | Westwick DT, Pohlmeyer EA, Solla SA, et al. Identification of multiple-input systems with highly coupled inputs. *Neural Comput*. 2006;18:329-355. DOI: 10.1162/089976606775093855. | General identifiability context when measured inputs are coupled | Selected |
| [7] | Welch PD. The use of fast Fourier transform for the estimation of power spectra. *IEEE Trans Audio Electroacoust*. 1967;15:70-73. DOI: 10.1109/TAU.1967.1161901. | Welch spectral estimation | Selected |
| [8] | Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate statistical methods. *Stat Med*. 2019;38:2074-2102. DOI: 10.1002/sim.8086. PMID: 30652356. | Simulation-study reporting, estimands, performance measures, and Monte Carlo error | Selected |

## Additional relevant local sources reviewed

These papers were found in the local Zhang/IEEM, Wavelet TFA, Downloads, and prior paper folders. They are kept here as a broad source pool; the formal manuscript bibliography should include a source only when the manuscript makes a claim that it supports. Metadata marked “verify” should be checked against the final published record before submission.

| Candidate source | Local provenance | Potential use in this paper | Decision |
|---|---|---|---|
| Perreault EJ, Kirsch RF, Acosta AM. Multiple-input, multiple-output system identification for characterization of limb stiffness dynamics. *Biol Cybern*. 1999;80:327–337. | `Desktop/IEEM Dr. Zhang/Research Papers to Preview/Perreault - Biol Cybern 1999...pdf` | General explanation of identifying dynamic systems with several measured inputs and outputs. | Included as [12] for general multiple-input identification context. |
| Diehl RR, Linden D, Lücke D, Berlit P. Phase relationship between cerebral blood flow velocity and blood pressure: a clinical test of autoregulation. *Stroke*. 1995;26:1801–1804. DOI: 10.1161/01.STR.26.10.1801. | `Downloads/Phase Relationship Between Cerebral Blood Flow Velocity and Blood Pressure.pdf` | Historical clinical use of CBFV–pressure phase and why phase is interpreted as a timing relationship. | Included as [9] for phase interpretation context. |
| Claassen JAHR, Zhang R, Fu Q, Witkowski S, Levine BD. Transcranial Doppler estimation of cerebral blood flow and cerebrovascular conductance during modified rebreathing. 2007. | `Downloads/Transcranial Doppler Estimation of Cerebral Blood Flow and Cerebrovascular Conductance During Modified Rebreathing.pdf` | Physiological basis for interpreting CO₂ changes with transcranial Doppler. | Verify journal metadata before citation. |
| Latka M, Turalska M, Glaubic-Latka M, et al. Phase dynamics in cerebral autoregulation. *Am J Physiol Heart Circ Physiol*. 2005;289:H2272–H2279. DOI: 10.1152/ajpheart.01307.2004. | `Downloads/latka-et-al-2005-phase-dynamics-in-cerebral-autoregulation.pdf` and `Desktop/IEEM Dr. Zhang/Wavelet TFA/Phase dynamics in cerebral autoregulation.pdf` | Additional physiological context for frequency-dependent phase dynamics. | Included as [10] for phase-dynamics context; not presented as validation of the estimator. |
| Tian F, Tarumi T, Liu H, et al. Wavelet coherence analysis of dynamic cerebral autoregulation in neonatal hypoxic–ischemic encephalopathy. *NeuroImage Clin*. 2016;11:124–132. | `Desktop/IEEM Dr. Zhang/Research Papers to Preview/Fenghua Tian - Neuroimage Clinical 2016.pdf` | Alternative time–frequency coherence approach and clinical application. | Optional related-method citation; current study uses Welch spectra. |
| Torrence C, Compo GP. A practical guide to wavelet analysis. *Bull Am Meteorol Soc*. 1998;79:61–78. | `Desktop/IEEM Dr. Zhang/Research Papers to Preview/Torrence 1998 A practical guide to wavelet analysis.pdf` | General wavelet reference if the discussion compares frequency-domain methods. | Included as [11] as a related frequency-domain method; not used to define the present Welch analysis. |
| Tarumi T, Dunsky DI, Khan MA, et al. Dynamic cerebral autoregulation and tissue oxygenation in amnestic mild cognitive impairment. *J Alzheimers Dis*. 2014. DOI: 10.3233/JAD-132018. | `Downloads/Dynamic_cerebral_autoregulation_and_tiss.pdf` | Example of applying dynamic autoregulation measures to a physiological cohort. | Optional application citation. |
| Marmarelis VZ, Shin DC, Orme ME, Zhang R. Model-based physiomarkers of cerebral hemodynamics in patients with mild cognitive impairment. *Med Eng Phys*. 2014;36:628–637. DOI: 10.1016/j.medengphy.2014.02.025. | `Downloads/nihms578802.pdf` | Model-based cerebral-hemodynamic interpretation and physiological application. | Included as [13] as related physiological modeling context. |
| Das Y, et al. Wavelet-based neurovascular coupling analysis. 2021. | `Desktop/IEEM Dr. Zhang/Research Papers to Preview/Yudhajit Das - Neuroimage 2021 (Wavelet based NVC).pdf` | Related frequency/time–frequency analysis of neurovascular signals. | Verify complete citation; optional background. |
| Kurazumi T, Sharma K, Wennekers RRJ, et al. A cascade model of dynamic cerebral autoregulation. *J Physiol*. 2026;604:3763–3785. | `Downloads/The Journal of Physiology - 2026 - Kurazumi - A cascade model of dynamic cerebral autoregulation.pdf` | Recent mechanistic modeling context for dynamic autoregulation. | Verify final metadata and publication status before citing. |
| Chertoff ME, Billinger SA, Perdomo SJ, et al. A novel nonlinear system identification for cerebral autoregulation in human: computer simulation and validation. *Ann Biomed Eng*. 2020;48:1207–1217. DOI: 10.1007/s10439-019-02442-7. | `Downloads/nihms-1743684.pdf` | Known-truth simulation and validation precedent. | Already selected as [5]. |
| Westwick DT, Pohlmeyer EA, Solla SA, et al. Identification of multiple-input systems with highly coupled inputs. *Neural Comput*. 2006;18:329–355. | `Downloads/nihms78743.pdf` | Identifiability when measured inputs share information. | Already selected as [6]. |

Duplicate CARNet, Peng, and generated-plot PDFs were screened as provenance duplicates or study outputs rather than additional references. The finance wavelet paper `Downloads/journal.pone.0324599.pdf` was excluded as unrelated.

## Evidence boundaries

The MAP and CO2 response kernels, the fitted input-spectrum shape, the factor levels, and the random-signal construction are study-design choices. The cited papers motivate the physiological variables and the use of multivariate or known-truth analyses; they do not establish the exact numerical constants used here. The final Methods text should preserve that distinction.

The “family” term refers to one fixed generating system with repeated random realizations. It does not claim that the recordings represent discovered biological subgroups.

## Local source locations reviewed

- `/Users/amoghn/Desktop/IEEM Dr. Zhang/Research Papers to Preview`
- `/Users/amoghn/Desktop/IEEM Dr. Zhang/Wavelet TFA`
- `/Users/amoghn/Downloads` (files dated from May 2026 onward, with duplicate and generated-output screening)
- `/Users/amoghn/LaTex Documents/MISO Approach for TFA Analysis`
- The current repository and its `archive/reference_material` folder

This audit is a working source map. Each citation should be checked against the paper itself before submission, especially where a sentence describes a specific numerical result or methodological detail.
