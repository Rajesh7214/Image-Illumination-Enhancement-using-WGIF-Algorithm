# Project Presentation Deck Outline (12 - 15 Slides)

### Slide 1: Title Slide
- **Title:** Image Illumination Enhancement using WGIF Algorithm
- **Subtitle:** Edge-Preserving Halo-Free Retinex Architecture for Industrial Visual Inspection
- **Author / Presenter:** [Your Name / Team]
- **Key Concepts:** Computer Vision, Weighted Guided Filter, Retinex Model, Defect Detection

---

### Slide 2: Problem Definition & Motivation
- Automated Optical Inspection (AOI) fails under low-light, shadowed, or non-uniform factory illumination.
- Surface micro-defects (cracks, scratches, voids) disappear into darkness.
- Existing enhancement methods either amplify sensor noise (Histogram Equalization) or produce unsightly halo rings around components (Standard Guided Filter).

---

### Slide 3: Shortcomings of Conventional Approaches
- **Global Histogram Equalization:** Over-amplifies background noise, washes out highlights.
- **Bilateral Filter:** Slow $O(N r^2)$ complexity, suffers from gradient reversal.
- **Standard Guided Filter (GIF):** Constant regularization $\epsilon$ creates noticeable halo glow around high-contrast edges.

---

### Slide 4: Proposed Solution: The WGIF Paradigm
- Proposed by Zhengguo Li et al. (IEEE TIP 2015).
- Replaces static regularization $\epsilon$ with an **edge-aware weighting factor $\Gamma_G(k)$**.
- Adapts smoothing dynamically: preserves sharp structural edges while aggressively smoothing shadows.

---

### Slide 5: Mathematical Formulation
- Local Linear Model: $q_i = a_k I_i + b_k$
- Cost function with adaptive penalty: $E = \sum ((a_k I_i + b_k - p_i)^2 + \frac{\lambda}{\Gamma(k)} a_k^2)$
- Edge weight $\Gamma(k) = (\sigma_1^2(k) + \varepsilon) \cdot \text{HarmonicMean}^{-1}$
- Closed-form optimal coefficients: $a_k = \frac{\sigma_{Ip}}{\sigma_I^2 + \lambda / \Gamma(k)}$

---

### Slide 6: Retinex Illumination-Reflectance Decomposition Pipeline
- Image Model: $S(x, y) = L(x, y) \cdot R(x, y)$
- Illumination Map: $L = \text{WGIF}(I_{init}, I_{init}, r, \lambda)$
- Reflectance: $R = S / (L + \epsilon)$
- Detail Extraction: $D = I_{init} - L$
- Tone Mapping: $L_{enh} = L^\gamma$
- Recombination: $S_{enh} = S \cdot (L_{enh} / L)^\beta + (\kappa - 1) D$

---

### Slide 7: Visual Defect Inspection Engine
- Automated contour extraction using Sobel and Canny operators.
- Defect sensitivity thresholding.
- Revealed Edge Contour Ratio (RECR) metric to quantify visibility improvement.

---

### Slide 8: System Architecture & Workflow Diagram
- High-level block diagram: Raw Image $\to$ Initial Luminance $\to$ WGIF Filtering $\to$ Retinex Enhancement $\to$ Defect Highlight Overlay $\to$ Output & Metrics.

---

### Slide 9: Experimental Results: PCB Solder Inspection
- Visual comparison side-by-side:
  - Original Dark (obscured traces)
  - Standard GIF (noticeable white halo around chip)
  - WGIF (crisp boundaries, halo eliminated, solder bridges visible)

---

### Slide 10: Experimental Results: Metal Surface Cracks
- Side-by-side crack inspection.
- Micro-scratch detection improved from undetectable to high-contrast red contour overlay.

---

### Slide 11: Quantitative Evaluation Table
- Comparison table across: Shannon Entropy, Average Gradient, EME Contrast, and Lightness Order Error (LOE).
- 2.9x increase in detectable structural contours.

---

### Slide 12: Computational Performance & Complexity
- $O(N)$ linear complexity via 2D Integral Images.
- Under 20 ms per frame on CPU (suitable for 50+ FPS real-time manufacturing lines).

---

### Slide 13: Interactive Demonstration System
- Dual delivery:
  - Python CLI & batch processing engine
  - Interactive Browser GUI with real-time sliders and split-view comparison

---

### Slide 14: Industrial Applications
- Electronics PCBA inspection
- Automotive sheet metal scanning
- Pharmaceutical packaging OCR & seal inspection
- Night surveillance & low-light robotics

---

### Slide 15: Conclusion & Future Scope
- **Conclusion:** WGIF completely eliminates halo artifacts while dramatically recovering low-light structural information.
- **Future Scope:** Deep guidance integration, GPU hardware acceleration for 4K 120 FPS cameras.
