"""
Retinex Illumination Enhancement using Weighted Guided Image Filter (WGIF)
Designed for low-light image enhancement and visual defect inspection.
"""

import numpy as np
from wgif import weighted_guided_filter, guided_filter

class WGIFIlluminationEnhancer:
    """
    Image illumination enhancement engine using WGIF-based Retinex decomposition.
    Separates image into Illumination and Reflectance components, enhances the
    illumination layer without halo artifacts, and amplifies edge details for visual inspection.
    """
    def __init__(self, r: int = 15, eps: float = 0.01, gamma: float = 0.5, detail_boost: float = 1.3):
        """
        Parameters:
            r: Filter radius for illumination estimation (default: 15)
            eps: Regularization parameter lambda for WGIF (default: 0.01)
            gamma: Illumination tone-mapping factor (< 1.0 brightens underexposed regions)
            detail_boost: Amplification factor for surface texture and defect details
        """
        self.r = r
        self.eps = eps
        self.gamma = gamma
        self.detail_boost = detail_boost

    def enhance(self, image: np.ndarray, method: str = "wgif") -> dict:
        """
        Enhances the input image using the illumination-reflectance decomposition pipeline.

        Parameters:
            image: Input image (RGB or Grayscale), values in [0, 255] uint8 or [0, 1] float
            method: 'wgif' (Weighted Guided Filter) or 'standard_gif' (Standard Guided Filter)

        Returns:
            dict containing:
                - 'enhanced': Final enhanced color/grayscale image
                - 'illumination_orig': Estimated raw illumination map
                - 'illumination_enh': Enhanced illumination map
                - 'reflectance': True surface reflectance component
                - 'details': Extracted high-frequency defect & texture layer
        """
        # Normalize to float [0, 1]
        is_uint8 = (image.dtype == np.uint8)
        img_float = image.astype(np.float64) / 255.0 if is_uint8 else image.astype(np.float64)
        is_color = (img_float.ndim == 3 and img_float.shape[2] == 3)

        # 1. Initial Illumination Estimation
        if is_color:
            # Maximum channel representation preserves color boundaries and avoids oversaturation
            I_init = np.max(img_float, axis=2)
        else:
            I_init = img_float.copy()

        # 2. Edge-Preserving Illumination Smoothing
        if method == "wgif":
            L_orig = weighted_guided_filter(p=I_init, I=I_init, r=self.r, eps=self.eps)
        else:
            L_orig = guided_filter(p=I_init, I=I_init, r=self.r, eps=self.eps)

        L_orig = np.clip(L_orig, 1e-4, 1.0)

        # 3. High-Frequency Surface Detail / Defect Extraction
        detail_layer = I_init - L_orig

        # 4. Adaptive Tone Mapping of Illumination
        # Nonlinear Gamma + S-curve dynamic range compression
        L_enh = np.power(L_orig, self.gamma)
        
        # Local adaptive enhancement: brighten severe shadows more while preventing burnout
        local_contrast_weight = 1.0 / (1.0 + np.exp(-10.0 * (L_orig - 0.2)))
        L_enh = (1.0 - local_contrast_weight) * np.power(L_orig, self.gamma * 0.8) + local_contrast_weight * L_enh

        # 5. Reflectance Extraction & Color Reconstruction
        # Retinex model: S = R * L => R = S / L
        # Recombined: S_enh = R * L_enh = S * (L_enh / L)
        ratio = L_enh / (L_orig + 1e-6)

        if is_color:
            # Color restoration with chroma preservation
            enhanced = np.zeros_like(img_float)
            for c in range(3):
                # Scale each channel by the illumination ratio with gentle saturation compression
                enhanced[:, :, c] = img_float[:, :, c] * np.power(ratio, 0.85)

            # Boost high-frequency details (critical for scratch, crack, and solder inspection)
            if self.detail_boost > 0.0:
                for c in range(3):
                    enhanced[:, :, c] += (self.detail_boost - 1.0) * detail_layer
        else:
            enhanced = img_float * ratio
            if self.detail_boost > 0.0:
                enhanced += (self.detail_boost - 1.0) * detail_layer

        enhanced = np.clip(enhanced, 0.0, 1.0)
        
        # Format outputs for analysis and visualization
        if is_uint8:
            output_img = (enhanced * 255.0).astype(np.uint8)
        else:
            output_img = enhanced

        return {
            "enhanced": output_img,
            "illumination_orig": (L_orig * 255.0).astype(np.uint8),
            "illumination_enh": (L_enh * 255.0).astype(np.uint8),
            "reflectance": (np.clip(I_init / (L_orig + 1e-6), 0, 1) * 255.0).astype(np.uint8),
            "details": (np.clip((detail_layer + 0.5), 0, 1) * 255.0).astype(np.uint8),
            "ratio_map": ratio
        }
