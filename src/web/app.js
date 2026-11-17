/**
 * Image Illumination Enhancement using Weighted Guided Image Filter (WGIF)
 * Interactive Client-Side Implementation
 */

// State
let originalImageData = null;
let currentProcessed = null;
let currentWidth = 400;
let currentHeight = 300;

// DOM Elements
const canvasOrig = document.getElementById('canvasOriginal');
const canvasEnh = document.getElementById('canvasEnhanced');
const canvasSplitBefore = document.getElementById('canvasSplitBefore');
const canvasSplitAfter = document.getElementById('canvasSplitAfter');
const canvasIllum = document.getElementById('canvasIllum');
const canvasReflectance = document.getElementById('canvasReflectance');
const canvasDetails = document.getElementById('canvasDetails');
const canvasDefects = document.getElementById('canvasDefects');

const sliderRadius = document.getElementById('paramRadius');
const sliderEps = document.getElementById('paramEps');
const sliderGamma = document.getElementById('paramGamma');
const sliderDetail = document.getElementById('paramDetail');
const sliderEdgeThresh = document.getElementById('paramEdgeThresh');
const chkOverlayDefects = document.getElementById('chkOverlayDefects');
const chkCompareStandard = document.getElementById('chkCompareStandard');

const valRadius = document.getElementById('valRadius');
const valEps = document.getElementById('valEps');
const valGamma = document.getElementById('valGamma');
const valDetail = document.getElementById('valDetail');
const valEdgeThresh = document.getElementById('valEdgeThresh');

const metricGain = document.getElementById('metricGain');
const metricEntropy = document.getElementById('metricEntropy');
const metricAG = document.getElementById('metricAG');
const metricEME = document.getElementById('metricEME');

// Parameter display syncing
sliderRadius.oninput = () => { valRadius.textContent = `${sliderRadius.value} px`; };
sliderEps.oninput = () => { valEps.textContent = Number(sliderEps.value).toFixed(3); };
sliderGamma.oninput = () => { valGamma.textContent = Number(sliderGamma.value).toFixed(2); };
sliderDetail.oninput = () => { valDetail.textContent = `${Number(sliderDetail.value).toFixed(1)}x`; };
sliderEdgeThresh.oninput = () => { valEdgeThresh.textContent = sliderEdgeThresh.value; };

// -------------------------------------------------------------
// Fast Integral Image Box Filter for 2D Grayscale Arrays
// -------------------------------------------------------------
function boxFilter2D(src, width, height, r) {
  const dst = new Float32Array(width * height);
  const intImg = new Float64Array((width + 1) * (height + 1));
  const intW = width + 1;

  // Build 2D Integral Table
  for (let y = 0; y < height; y++) {
    let rowSum = 0;
    const srcOffset = y * width;
    const intOffset = (y + 1) * intW;
    const prevIntOffset = y * intW;

    for (let x = 0; x < width; x++) {
      rowSum += src[srcOffset + x];
      intImg[intOffset + (x + 1)] = intImg[prevIntOffset + (x + 1)] + rowSum;
    }
  }

  // Calculate local averages with boundary clamping
  for (let y = 0; y < height; y++) {
    const y0 = Math.max(0, y - r);
    const y1 = Math.min(height - 1, y + r);
    const dstOffset = y * width;

    for (let x = 0; x < width; x++) {
      const x0 = Math.max(0, x - r);
      const x1 = Math.min(width - 1, x + r);
      const area = (y1 - y0 + 1) * (x1 - x0 + 1);

      const sum = intImg[(y1 + 1) * intW + (x1 + 1)]
                - intImg[y0 * intW + (x1 + 1)]
                - intImg[(y1 + 1) * intW + x0]
                + intImg[y0 * intW + x0];

      dst[dstOffset + x] = sum / area;
    }
  }
  return dst;
}

// -------------------------------------------------------------
// Weighted Guided Image Filter (WGIF) Algorithm
// -------------------------------------------------------------
function applyWGIF(p, I, width, height, r, eps, useStandard = false) {
  const N = width * height;
  
  // 1. Calculate Edge-Aware Weight Gamma (if WGIF)
  const gamma = new Float32Array(N);
  if (!useStandard) {
    const r1 = 1;
    const meanI1 = boxFilter2D(I, width, height, r1);
    const II1 = new Float32Array(N);
    for (let i = 0; i < N; i++) II1[i] = I[i] * I[i];
    const meanII1 = boxFilter2D(II1, width, height, r1);

    const epsWeight = 0.0001;
    let invSum = 0;
    const varI1 = new Float32Array(N);
    for (let i = 0; i < N; i++) {
      const v = Math.max(0, meanII1[i] - meanI1[i] * meanI1[i]) + epsWeight;
      varI1[i] = v;
      invSum += 1.0 / v;
    }
    const invMean = invSum / N;
    for (let i = 0; i < N; i++) {
      gamma[i] = varI1[i] * invMean;
    }
  }

  // 2. Local statistics over window radius r
  const meanI = boxFilter2D(I, width, height, r);
  const meanP = boxFilter2D(p, width, height, r);

  const Ip = new Float32Array(N);
  const II = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    Ip[i] = I[i] * p[i];
    II[i] = I[i] * I[i];
  }

  const meanIp = boxFilter2D(Ip, width, height, r);
  const meanII = boxFilter2D(II, width, height, r);

  const a = new Float32Array(N);
  const b = new Float32Array(N);

  for (let i = 0; i < N; i++) {
    const varI = Math.max(0, meanII[i] - meanI[i] * meanI[i]);
    const covIp = meanIp[i] - meanI[i] * meanP[i];

    const reg = useStandard ? eps : (eps / (gamma[i] + 1e-6));
    const ak = covIp / (varI + reg);
    const bk = meanP[i] - ak * meanI[i];

    a[i] = ak;
    b[i] = bk;
  }

  const meanA = boxFilter2D(a, width, height, r);
  const meanB = boxFilter2D(b, width, height, r);

  const q = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    q[i] = Math.max(0, Math.min(1, meanA[i] * I[i] + meanB[i]));
  }
  return q;
}

// -------------------------------------------------------------
// Full Retinex Pipeline for Illumination & Defect Enhancement
// -------------------------------------------------------------
function processIlluminationEnhancement(imageData, opts) {
  const { width, height } = imageData;
  const N = width * height;
  const data = imageData.data;

  // Extract initial luminance / max channel (normalized to [0, 1])
  const I_init = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    const idx = i * 4;
    const r = data[idx] / 255;
    const g = data[idx + 1] / 255;
    const b = data[idx + 2] / 255;
    I_init[i] = Math.max(r, Math.max(g, b));
  }

  // Edge-preserving smooth illumination extraction
  const L = applyWGIF(I_init, I_init, width, height, opts.radius, opts.eps, opts.useStandard);

  // Surface details
  const D = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    D[i] = I_init[i] - L[i];
  }

  // Enhanced illumination via Gamma tone-mapping
  const L_enh = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    L_enh[i] = Math.pow(Math.max(1e-4, L[i]), opts.gamma);
  }

  // Recombine Retinex: S_enh = S * (L_enh / L) + detail_boost * D
  const enhancedData = new Uint8ClampedArray(N * 4);
  const illumData = new Uint8ClampedArray(N * 4);
  const reflData = new Uint8ClampedArray(N * 4);
  const detailData = new Uint8ClampedArray(N * 4);

  const detailBoost = opts.detailBoost - 1.0;

  for (let i = 0; i < N; i++) {
    const idx = i * 4;
    const ratio = Math.pow(L_enh[i] / (L[i] + 1e-4), 0.85);
    const boost = detailBoost * D[i] * 255;

    for (let c = 0; c < 3; c++) {
      let val = (data[idx + c] * ratio) + boost;
      enhancedData[idx + c] = Math.max(0, Math.min(255, val));
    }
    enhancedData[idx + 3] = 255;

    // Visualization buffers
    const lVal = Math.round(L_enh[i] * 255);
    illumData[idx] = lVal;
    illumData[idx + 1] = lVal;
    illumData[idx + 2] = lVal;
    illumData[idx + 3] = 255;

    const rVal = Math.round(Math.min(1, I_init[i] / (L[i] + 1e-4)) * 255);
    reflData[idx] = rVal;
    reflData[idx + 1] = rVal;
    reflData[idx + 2] = rVal;
    reflData[idx + 3] = 255;

    const dVal = Math.round(Math.max(0, Math.min(1, D[i] + 0.5)) * 255);
    detailData[idx] = dVal;
    detailData[idx + 1] = dVal;
    detailData[idx + 2] = dVal;
    detailData[idx + 3] = 255;
  }

  return {
    enhanced: new ImageData(enhancedData, width, height),
    illumination: new ImageData(illumData, width, height),
    reflectance: new ImageData(reflData, width, height),
    details: new ImageData(detailData, width, height),
    width,
    height
  };
}

// -------------------------------------------------------------
// Visual Defect & Edge Inspection Analysis
// -------------------------------------------------------------
function analyzeVisualInspection(origImg, enhImg, edgeThresh, overlayDefects) {
  const { width, height } = origImg;
  const N = width * height;
  const origData = origImg.data;
  const enhData = enhImg.data;

  // Sobel Edge Detection
  const gradOrig = computeSobelMagnitude(origData, width, height);
  const gradEnh = computeSobelMagnitude(enhData, width, height);

  let edgesOrig = 0;
  let edgesEnh = 0;
  const defectData = new Uint8ClampedArray(N * 4);
  const displayEnh = new Uint8ClampedArray(enhData);

  for (let i = 0; i < N; i++) {
    if (gradOrig[i] > edgeThresh) edgesOrig++;
    
    const idx = i * 4;
    if (gradEnh[i] > edgeThresh) {
      edgesEnh++;
      // High contrast defect mask (bright cyan / red)
      defectData[idx] = 255;
      defectData[idx + 1] = 50;
      defectData[idx + 2] = 50;
      defectData[idx + 3] = 255;

      // Overlay on enhanced image if enabled
      if (overlayDefects) {
        displayEnh[idx] = 255;
        displayEnh[idx + 1] = 70;
        displayEnh[idx + 2] = 70;
      }
    } else {
      defectData[idx + 3] = 255;
    }
  }

  const gainFactor = (edgesEnh + 1) / (edgesOrig + 1);

  // Metrics
  const entropy = computeEntropy(enhData);
  const ag = computeAverageGradient(gradEnh);
  const eme = computeEME(enhData, width, height);

  return {
    annotatedEnhanced: new ImageData(displayEnh, width, height),
    defectMask: new ImageData(defectData, width, height),
    gainFactor: gainFactor.toFixed(2),
    entropy: entropy.toFixed(3),
    ag: ag.toFixed(2),
    eme: eme.toFixed(2),
    edgesOrig,
    edgesEnh
  };
}

function computeSobelMagnitude(data, width, height) {
  const mag = new Float32Array(width * height);
  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      const getGray = (px, py) => {
        const i = (py * width + px) * 4;
        return (data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114);
      };

      const gx = (-getGray(x-1, y-1) + getGray(x+1, y-1))
               + (-2 * getGray(x-1, y) + 2 * getGray(x+1, y))
               + (-getGray(x-1, y+1) + getGray(x+1, y+1));

      const gy = (-getGray(x-1, y-1) - 2 * getGray(x, y-1) - getGray(x+1, y-1))
               + ( getGray(x-1, y+1) + 2 * getGray(x, y+1) + getGray(x+1, y+1));

      mag[y * width + x] = Math.sqrt(gx * gx + gy * gy);
    }
  }
  return mag;
}

function computeEntropy(data) {
  const hist = new Int32Array(256);
  const total = data.length / 4;
  for (let i = 0; i < data.length; i += 4) {
    const gray = Math.round(data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114);
    hist[gray]++;
  }
  let ent = 0;
  for (let i = 0; i < 256; i++) {
    if (hist[i] > 0) {
      const p = hist[i] / total;
      ent -= p * Math.log2(p);
    }
  }
  return ent;
}

function computeAverageGradient(mag) {
  let sum = 0;
  for (let i = 0; i < mag.length; i++) sum += mag[i];
  return sum / mag.length;
}

function computeEME(data, width, height, blockSize = 8) {
  const k1 = Math.floor(height / blockSize);
  const k2 = Math.floor(width / blockSize);
  if (k1 === 0 || k2 === 0) return 0;

  let sum = 0;
  let count = 0;

  for (let by = 0; by < k1; by++) {
    for (let bx = 0; bx < k2; bx++) {
      let minVal = 255;
      let maxVal = 0;

      for (let y = by * blockSize; y < (by + 1) * blockSize; y++) {
        for (let x = bx * blockSize; x < (bx + 1) * blockSize; x++) {
          const i = (y * width + x) * 4;
          const g = data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114;
          if (g < minVal) minVal = g;
          if (g > maxVal) maxVal = g;
        }
      }

      if (minVal > 0 && maxVal > minVal) {
        sum += 20 * Math.log10(maxVal / (minVal + 0.001));
        count++;
      }
    }
  }
  return count > 0 ? (sum / count) : 0;
}

// -------------------------------------------------------------
// Synthetic Inspection Sample Generator
// -------------------------------------------------------------
function generateSyntheticSample() {
  const w = 480;
  const h = 360;
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d');

  // Background PCB substrate
  ctx.fillStyle = '#163820';
  ctx.fillRect(0, 0, w, h);

  // Copper tracks
  ctx.strokeStyle = '#c5a04f';
  ctx.lineWidth = 3;
  for (let y = 50; y < h; y += 45) {
    ctx.beginPath();
    ctx.moveTo(30, y);
    ctx.lineTo(w - 30, y);
    ctx.stroke();

    // Solder pads
    ctx.fillStyle = '#b0b5bd';
    ctx.fillRect(80, y - 8, 20, 16);
    ctx.fillRect(240, y - 8, 20, 16);
    ctx.fillRect(380, y - 8, 20, 16);
  }

  // Central IC Processor
  ctx.fillStyle = '#1c1f24';
  ctx.strokeStyle = '#4b5563';
  ctx.lineWidth = 2;
  ctx.fillRect(160, 120, 160, 120);
  ctx.strokeRect(160, 120, 160, 120);

  ctx.fillStyle = '#9ca3af';
  ctx.font = 'bold 14px JetBrains Mono, monospace';
  ctx.fillText('MCU-ARM64', 190, 175);
  ctx.font = '10px Inter, sans-serif';
  ctx.fillText('SN: 8940-DEF-X', 195, 195);

  // Hidden Defects (Defect 1: hairline scratch, Defect 2: broken trace)
  ctx.strokeStyle = '#8f2323';
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.moveTo(210, 130);
  ctx.lineTo(235, 150); // hairline crack across chip surface
  ctx.stroke();

  ctx.strokeStyle = '#0e2314'; // cut trace notch
  ctx.lineWidth = 4;
  ctx.beginPath();
  ctx.moveTo(250, 95);
  ctx.lineTo(250, 105);
  ctx.stroke();

  // Severe non-uniform low-light degradation (shadowing / poor industrial lighting)
  const imgData = ctx.getImageData(0, 0, w, h);
  const data = imgData.data;

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4;
      const nx = (x - w / 2) / (w / 2);
      const ny = (y - h / 2) / (h / 2);
      const dist = Math.sqrt(nx * nx + ny * ny);

      // Vignette + directional shadow
      const falloff = Math.max(0.1, 1.0 - 0.7 * dist);
      const lighting = 0.25 * falloff * (0.6 + 0.4 * (1.0 - x / w));

      data[i] = Math.round(data[i] * lighting);
      data[i + 1] = Math.round(data[i + 1] * lighting);
      data[i + 2] = Math.round(data[i + 2] * lighting);
    }
  }

  return imgData;
}

// -------------------------------------------------------------
// Pipeline Trigger & Render
// -------------------------------------------------------------
function runEnhancement() {
  if (!originalImageData) return;

  const opts = {
    radius: parseInt(sliderRadius.value, 10),
    eps: parseFloat(sliderEps.value),
    gamma: parseFloat(sliderGamma.value),
    detailBoost: parseFloat(sliderDetail.value),
    useStandard: chkCompareStandard.checked
  };

  const results = processIlluminationEnhancement(originalImageData, opts);
  currentProcessed = results;

  const edgeThresh = parseFloat(sliderEdgeThresh.value);
  const inspection = analyzeVisualInspection(originalImageData, results.enhanced, edgeThresh, chkOverlayDefects.checked);

  // Render to canvases
  renderToCanvas(canvasOrig, originalImageData);
  renderToCanvas(canvasEnh, inspection.annotatedEnhanced);
  renderToCanvas(canvasSplitBefore, originalImageData);
  renderToCanvas(canvasSplitAfter, inspection.annotatedEnhanced);

  renderToCanvas(canvasIllum, results.illumination);
  renderToCanvas(canvasReflectance, results.reflectance);
  renderToCanvas(canvasDetails, results.details);
  renderToCanvas(canvasDefects, inspection.defectMask);

  // Update UI Metrics
  metricGain.textContent = `${inspection.gainFactor}x`;
  metricEntropy.textContent = inspection.entropy;
  metricAG.textContent = inspection.ag;
  metricEME.textContent = inspection.eme;
}

function renderToCanvas(canvas, imgData) {
  canvas.width = imgData.width;
  canvas.height = imgData.height;
  const ctx = canvas.getContext('2d');
  ctx.putImageData(imgData, 0, 0);
}

// -------------------------------------------------------------
// Interactive Split Slider Logic
// -------------------------------------------------------------
const splitContainer = document.getElementById('splitSliderContainer');
const splitAfterWrapper = document.getElementById('splitAfterWrapper');
const sliderHandle = document.getElementById('sliderHandle');

let isDragging = false;

function updateSplitPosition(clientX) {
  const rect = splitContainer.getBoundingClientRect();
  let x = clientX - rect.left;
  x = Math.max(0, Math.min(x, rect.width));
  const pct = (x / rect.width) * 100;

  splitAfterWrapper.style.width = `${pct}%`;
  sliderHandle.style.left = `${pct}%`;
}

sliderHandle.addEventListener('mousedown', () => { isDragging = true; });
window.addEventListener('mouseup', () => { isDragging = false; });
window.addEventListener('mousemove', (e) => {
  if (isDragging) updateSplitPosition(e.clientX);
});

splitContainer.addEventListener('click', (e) => {
  updateSplitPosition(e.clientX);
});

// -------------------------------------------------------------
// Tabs Switching
// -------------------------------------------------------------
const tabButtons = document.querySelectorAll('.tab-btn');
const tabViews = {
  'side-by-side': document.getElementById('tabContentSide'),
  'split-slider': document.getElementById('tabContentSplit'),
  'decomposition': document.getElementById('tabContentDecomp')
};

tabButtons.forEach(btn => {
  btn.addEventListener('click', () => {
    tabButtons.forEach(b => b.classList.remove('active'));
    Object.values(tabViews).forEach(v => v.classList.remove('active'));

    btn.classList.add('active');
    const tabKey = btn.dataset.tab;
    tabViews[tabKey].classList.add('active');
  });
});

// -------------------------------------------------------------
// Image Upload & Actions
// -------------------------------------------------------------
const fileInput = document.getElementById('fileInput');
fileInput.addEventListener('change', (e) => {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (event) => {
    const img = new Image();
    img.onload = () => {
      const maxDim = 800;
      let w = img.width;
      let h = img.height;
      if (w > maxDim || h > maxDim) {
        if (w > h) {
          h = Math.round((h * maxDim) / w);
          w = maxDim;
        } else {
          w = Math.round((w * maxDim) / h);
          h = maxDim;
        }
      }
      const c = document.createElement('canvas');
      c.width = w;
      c.height = h;
      const ctx = c.getContext('2d');
      ctx.drawImage(img, 0, 0, w, h);
      originalImageData = ctx.getImageData(0, 0, w, h);
      runEnhancement();
    };
    img.src = event.target.result;
  };
  reader.readAsDataURL(file);
});

document.getElementById('btnLoadSample').addEventListener('click', () => {
  originalImageData = generateSyntheticSample();
  runEnhancement();
});

document.getElementById('btnProcess').addEventListener('click', runEnhancement);
chkOverlayDefects.addEventListener('change', runEnhancement);
chkCompareStandard.addEventListener('change', runEnhancement);

// Downloads
document.getElementById('btnDownload').addEventListener('click', () => {
  const link = document.createElement('a');
  link.download = 'wgif_enhanced_inspection.png';
  link.href = canvasEnh.toDataURL('image/png');
  link.click();
});

document.getElementById('btnDownloadReport').addEventListener('click', () => {
  const report = `Image Illumination Enhancement using WGIF Algorithm - Inspection Summary
========================================================================
Algorithm: Weighted Guided Image Filter (WGIF)
Window Radius: ${sliderRadius.value} px
Regularization (Lambda): ${sliderEps.value}
Gamma Factor: ${sliderGamma.value}
Detail Boost: ${sliderDetail.value}x

Quantitative Results:
------------------------------------------------------------------------
Revealed Feature Gain Factor: ${metricGain.textContent}
Shannon Information Entropy : ${metricEntropy.textContent}
Average Gradient (Sharpness): ${metricAG.textContent}
Measure of Enhancement (EME): ${metricEME.textContent}
Timestamp: ${new Date().toISOString()}
`;
  const blob = new Blob([report], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.download = 'wgif_inspection_report.txt';
  link.href = url;
  link.click();
  URL.revokeObjectURL(url);
});

// Initialize on page load
window.addEventListener('DOMContentLoaded', () => {
  originalImageData = generateSyntheticSample();
  runEnhancement();
});
