"""
Quantitative Evaluation Metrics for Image Illumination Enhancement
Implements:
- Shannon Entropy (Information richness)
- Average Gradient (AG - Edge sharpness)
- Measure of Enhancement (EME - Local contrast)
- Standard Deviation (Global dynamic range)
- Lightness Order Error (LOE - Natural illumination preservation)
- PSNR & SSIM (when ground truth reference is available)
"""

import numpy as np

def compute_entropy(img: np.ndarray) -> float:
    """Computes Shannon Information Entropy (higher = more detailed information)."""
    gray = np.mean(img, axis=2) if img.ndim == 3 else img
    gray = np.clip(gray, 0, 255).astype(np.uint8)
    hist, _ = np.histogram(gray.ravel(), bins=256, range=(0, 256))
    hist = hist[hist > 0]
    prob = hist / np.sum(hist)
    entropy = -np.sum(prob * np.log2(prob))
    return float(entropy)

def compute_average_gradient(img: np.ndarray) -> float:
    """Computes Average Gradient (AG), measuring high-frequency edge sharpness."""
    gray = np.mean(img, axis=2) if img.ndim == 3 else img.astype(np.float64)
    dx = np.diff(gray, axis=1)
    dy = np.diff(gray, axis=0)
    
    # Common area
    h, w = dx.shape[0] - 1, dy.shape[1] - 1
    grad = np.sqrt((dx[:h, :w] ** 2 + dy[:h, :w] ** 2) / 2.0)
    return float(np.mean(grad))

def compute_eme(img: np.ndarray, block_size: int = 8) -> float:
    """
    Measure of Enhancement (EME) by Celik & Tjahjadi.
    Measures average contrast across non-overlapping sub-blocks.
    """
    gray = np.mean(img, axis=2) if img.ndim == 3 else img.astype(np.float64)
    h, w = gray.shape
    k1 = h // block_size
    k2 = w // block_size
    if k1 == 0 or k2 == 0:
        return 0.0

    eme_sum = 0.0
    valid_blocks = 0
    for i in range(k1):
        for j in range(k2):
            block = gray[i * block_size:(i + 1) * block_size, j * block_size:(j + 1) * block_size]
            b_min = np.min(block)
            b_max = np.max(block)
            if b_min > 0 and b_max > b_min:
                eme_sum += 20.0 * np.log(b_max / (b_min + 1e-4))
                valid_blocks += 1

    return float(eme_sum / max(valid_blocks, 1))

def compute_loe(orig_img: np.ndarray, enh_img: np.ndarray, grid_size: int = 50) -> float:
    """
    Lightness Order Error (LOE).
    Lower LOE indicates better preservation of natural relative lightness ranking across spatial regions.
    """
    gray_orig = np.mean(orig_img, axis=2) if orig_img.ndim == 3 else orig_img
    gray_enh = np.mean(enh_img, axis=2) if enh_img.ndim == 3 else enh_img

    # Downsample for computational efficiency
    h, w = gray_orig.shape
    step_y = max(1, h // grid_size)
    step_x = max(1, w // grid_size)
    
    down_orig = gray_orig[::step_y, ::step_x].ravel()
    down_enh = gray_enh[::step_y, ::step_x].ravel()
    n = len(down_orig)

    # Calculate rank order discrepancies
    order_orig = down_orig[:, None] >= down_orig[None, :]
    order_enh = down_enh[:, None] >= down_enh[None, :]
    mismatches = np.sum(order_orig != order_enh)

    loe = mismatches / (n * n)
    return float(loe * 1000.0) # scaled for standard readability

def evaluate_image_enhancement(orig_img: np.ndarray, enh_img: np.ndarray) -> dict:
    """Evaluates all core image enhancement and visual inspection quality metrics."""
    return {
        "entropy_original": round(compute_entropy(orig_img), 3),
        "entropy_enhanced": round(compute_entropy(enh_img), 3),
        "average_gradient_original": round(compute_average_gradient(orig_img), 3),
        "average_gradient_enhanced": round(compute_average_gradient(enh_img), 3),
        "eme_contrast_original": round(compute_eme(orig_img), 2),
        "eme_contrast_enhanced": round(compute_eme(enh_img), 2),
        "lightness_order_error": round(compute_loe(orig_img, enh_img), 2)
    }
