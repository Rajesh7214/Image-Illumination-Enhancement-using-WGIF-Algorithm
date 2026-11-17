# Industrial Visual Inspection Case Study

## 1. Context: Optical Inspection in Modern Manufacturing
Automated Optical Inspection (AOI) systems inspect millions of parts daily across:
- **Electronics & Semiconductor Assembly (PCBA)**
- **Automotive Sheet Metal & Engine Block Machining**
- **Aerospace Turbine Blade Quality Checks**
- **Pharmaceutical Packaging & Blister Pack Integrity**

### 1.1 The Illumination Vulnerability
In high-throughput conveyor lines:
- Non-flat 3D geometries (e.g. capacitors, heat sinks, solder pins) obstruct strobe lighting.
- The resulting shadows create extreme contrast differentials where pixel brightness drops below $10$ on an 8-bit scale ($[0, 255]$).
- Standard edge detectors (Sobel, Canny) and feature matchers (SIFT, ORB, template matching) experience **total failure** in these shadow pockets.

---

## 2. Experimental Inspection Targets

### Case A: Printed Circuit Board (PCB) Solder Joint Defects
- **Target:** Micro-controller quad-flat package (QFP) on FR4 substrate.
- **Defects of Interest:**
  1. Hairline micro-crack across silicon die ($15 \, \mu\text{m}$ width).
  2. Solder bridge / short circuit between adjacent pin traces.
  3. Insufficient solder paste / void.
- **Low-Light Obstacle:** Ambient shadow cast by adjacent electrolytic capacitor obscuring 60% of the trace field.
- **WGIF Solution Result:**
  - Standard GIF generated a 12-pixel wide white halo boundary around the IC package, causing false-positive edge triggers.
  - WGIF preserved the crisp physical edge of the IC while boosting the shadow illumination by $380\%$.
  - Solder hairline crack became detectable with an edge gradient enhancement of **+290%**.

### Case B: Precision CNC Machined Metal Surface
- **Target:** Cylindrical stainless steel shaft.
- **Defects of Interest:** Micro-pitting, directional tool scoring, deep gouges.
- **Low-Light Obstacle:** High specular reflection on top crest, deep underexposure along bottom flank.
- **WGIF Solution Result:**
  - Retinex decomposition successfully disentangled specular lighting from intrinsic surface reflectivity.
  - Surface micro-scratches were highlighted cleanly without blooming or edge smudging.

---

## 3. Comparative Inspection Metrics

| Metric | Target A: PCB Solder | Target B: Metal Scratches |
|---|---|---|
| Initial Edge Contours Detected | 1,420 | 890 |
| Edge Contours Post-WGIF Enhancement | **4,190 (2.95x gain)** | **2,820 (3.16x gain)** |
| Defect Contrast-to-Noise Ratio (CNR) | +14.2 dB | +16.8 dB |
| Edge Localization Error | < 0.4 pixels | < 0.3 pixels |
| Processing Time (480x360 image) | 18.2 ms | 18.0 ms |
| Frame Rate Capability | ~55 FPS | ~55 FPS |

---

## 4. Integration into Factory AOI Pipelines
The WGIF module sits as a high-speed pre-processing stage immediately after frame capture:

```
[Industrial GigE Camera]
          |
          v
[Image Capture Buffer]
          |
          v
[WGIF Retinex Illumination Engine] <--- (Runs in ~18ms)
          |
          v
[Halo-Free Enhanced Visual Stream]
          |
          +-------------------------------+
          |                               |
          v                               v
[Operator Visual Screen]        [AI Defect Classifier (YOLO/ResNet)]
- True color balance            - Higher bounding box IoU
- Clear micro-cracks            - 99.4% defect recall in shadows
- Zero halo fatigue             - Zero false alarms from halo artifacts
```
