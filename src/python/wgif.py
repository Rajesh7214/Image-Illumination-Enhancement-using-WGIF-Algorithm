"""
Weighted Guided Image Filter (WGIF) Implementation
Based on the paper:
"Weighted Guided Image Filter" by Zhengguo Li, Jinghong Zheng, Zijian Zhu, Wei Yao, and Shenghao Wu
IEEE Transactions on Image Processing (TIP), Vol. 24, No. 1, 2015.
"""

import numpy as np

def _box_filter(image: np.ndarray, r: int) -> np.ndarray:
    """
    Computes box filter (local mean smoothing) over a square window of radius r.
    Uses OpenCV if available for maximum speed, otherwise falls back to pure NumPy integral image.
    """
    try:
        import cv2
        return cv2.boxFilter(image, ddepth=-1, ksize=(2 * r + 1, 2 * r + 1), borderType=cv2.BORDER_REFLECT)
    except ImportError:
        pass

    # Pure NumPy implementation using 2D integral image
    h, w = image.shape[:2]
    out = np.zeros_like(image, dtype=np.float64)
    k = 2 * r + 1
    
    # Handle single channel or multi-channel
    if image.ndim == 2:
        pad_img = np.pad(image, ((r, r), (r, r)), mode='reflect')
        cum = np.cumsum(np.cumsum(pad_img, axis=0), axis=1)
        
        # Integral area calculation
        # sum = cum[y2, x2] - cum[y1-1, x2] - cum[y2, x1-1] + cum[y1-1, x1-1]
        out = (cum[k:, k:] - cum[:-k, k:] - cum[k:, :-k] + cum[:-k, :-k]) / (k * k)
        return out.astype(image.dtype)
    else:
        channels = []
        for c in range(image.shape[2]):
            channels.append(_box_filter(image[:, :, c], r))
        return np.stack(channels, axis=-1)

def guided_filter(p: np.ndarray, I: np.ndarray, r: int = 15, eps: float = 1e-3) -> np.ndarray:
    """
    Standard Guided Image Filter (He et al., ECCV 2010 / TPAMI 2013).
    
    Parameters:
        p: Input filtering target image (normalized to [0, 1] float)
        I: Guidance image (normalized to [0, 1] float)
        r: Local window radius
        eps: Regularization parameter
    
    Returns:
        Filtered image q
    """
    p = p.astype(np.float64)
    I = I.astype(np.float64)

    mean_I = _box_filter(I, r)
    mean_p = _box_filter(p, r)
    mean_Ip = _box_filter(I * p, r)
    mean_II = _box_filter(I * I, r)

    var_I = mean_II - mean_I * mean_I
    cov_Ip = mean_Ip - mean_I * mean_p

    a = cov_Ip / (var_I + eps)
    b = mean_p - a * mean_I

    mean_a = _box_filter(a, r)
    mean_b = _box_filter(b, r)

    q = mean_a * I + mean_b
    return q

def compute_edge_weight(I: np.ndarray, r1: int = 1, eps_weight: float = 1e-4) -> np.ndarray:
    """
    Computes the edge-aware weighting factor Gamma_G(k) for WGIF.
    
    Gamma_G(k) = (sigma_{I, r1}^2(k) + eps_weight) * ( (1/N) * sum(1 / (sigma_{I, r1}^2(i) + eps_weight)) )
    """
    mean_I = _box_filter(I, r1)
    mean_II = _box_filter(I * I, r1)
    var_I = np.maximum(mean_II - mean_I * mean_I, 0.0)

    # Local variance plus small epsilon
    w_k = var_I + eps_weight
    
    # Harmonic mean normalization across all pixels
    inv_w_mean = np.mean(1.0 / w_k)
    gamma = w_k * inv_w_mean
    return gamma

def weighted_guided_filter(p: np.ndarray, I: np.ndarray, r: int = 15, eps: float = 1e-3, r1: int = 1) -> np.ndarray:
    """
    Weighted Guided Image Filter (WGIF) (Li et al., IEEE TIP 2015).
    
    Applies edge-aware weighting to the regularization parameter:
    lambda / Gamma(k)
    
    - Near sharp edges: Gamma(k) > 1 => lower regularization => sharper edges preserved, halo artifacts eliminated.
    - In flat regions: Gamma(k) < 1 => higher regularization => flat areas smoothly filtered, noise suppressed.

    Parameters:
        p: Input image to filter (grayscale or single channel, [0, 1] float)
        I: Guidance image (grayscale or single channel, [0, 1] float)
        r: Window radius for guided filtering (default: 15)
        eps: Regularization parameter lambda (default: 1e-3)
        r1: Window radius for calculating edge-weight variance (default: 1)

    Returns:
        Filtered image q ([0, 1] float)
    """
    p = p.astype(np.float64)
    I = I.astype(np.float64)

    # 1. Edge-aware weight computation
    gamma = compute_edge_weight(I, r1=r1, eps_weight=(0.001 ** 2))

    # 2. Local statistics over window r
    mean_I = _box_filter(I, r)
    mean_p = _box_filter(p, r)
    mean_Ip = _box_filter(I * p, r)
    mean_II = _box_filter(I * I, r)

    var_I = mean_II - mean_I * mean_I
    cov_Ip = mean_Ip - mean_I * mean_p

    # 3. Weighted linear regression coefficients
    # In WGIF, the regularization penalty is eps / gamma
    reg_term = eps / (gamma + 1e-8)
    a = cov_Ip / (var_I + reg_term)
    b = mean_p - a * mean_I

    # 4. Filter linear coefficients
    mean_a = _box_filter(a, r)
    mean_b = _box_filter(b, r)

    # 5. Reconstructed filtered signal
    q = mean_a * I + mean_b
    return np.clip(q, 0.0, 1.0)
