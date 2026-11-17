"""
Visual Inspection Defect Visibility and Object Detection Module
Analyzes images before and after illumination enhancement to verify object visibility,
surface defect detection (cracks, scratches, solder voids, edge sharpness),
and quantitative inspection metrics.
"""

import numpy as np

def compute_gradient_magnitude(img: np.ndarray) -> np.ndarray:
    """Computes Sobel gradient magnitude to measure object contour clarity."""
    try:
        import cv2
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if img.ndim == 3 else img
        gx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        gy = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        mag = np.sqrt(gx**2 + gy**2)
        return mag
    except ImportError:
        gray = np.mean(img, axis=2) if img.ndim == 3 else img.astype(np.float64)
        gx = np.zeros_like(gray)
        gy = np.zeros_like(gray)
        gx[:, 1:-1] = (gray[:, 2:] - gray[:, :-2]) / 2.0
        gy[1:-1, :] = (gray[2:, :] - gray[:-2, :]) / 2.0
        return np.sqrt(gx**2 + gy**2)

class VisualInspector:
    """
    Automated inspection pipeline comparing low-light vs WGIF-enhanced visibility.
    """
    def __init__(self, edge_threshold: float = 30.0):
        self.edge_threshold = edge_threshold

    def inspect(self, original_img: np.ndarray, enhanced_img: np.ndarray) -> dict:
        """
        Runs visual inspection analysis.

        Returns:
            dict containing:
                - 'grad_orig': Gradient edge map of original dark image
                - 'grad_enh': Gradient edge map of WGIF enhanced image
                - 'visible_edge_ratio': Factor of new edge contours revealed (> 1.0 means clearer objects)
                - 'defect_mask': Detected defect/edge mask from enhanced image
                - 'visibility_improvement_pct': Percentage gain in visible structural details
        """
        grad_orig = compute_gradient_magnitude(original_img)
        grad_enh = compute_gradient_magnitude(enhanced_img)

        # Count edges above threshold (detectable features/defects)
        edges_orig = np.sum(grad_orig > self.edge_threshold)
        edges_enh = np.sum(grad_enh > self.edge_threshold)

        edge_ratio = (edges_enh + 1e-5) / (edges_orig + 1e-5)
        improvement_pct = max(0.0, (edge_ratio - 1.0) * 100.0)

        # Defect / Feature mask (high-contrast structural details)
        defect_mask = (grad_enh > self.edge_threshold).astype(np.uint8) * 255

        # Local contrast index
        contrast_orig = float(np.std(original_img))
        contrast_enh = float(np.std(enhanced_img))

        return {
            "edges_detected_original": int(edges_orig),
            "edges_detected_enhanced": int(edges_enh),
            "edge_multiplication_factor": round(float(edge_ratio), 2),
            "visibility_improvement_pct": round(float(improvement_pct), 1),
            "contrast_original": round(contrast_orig, 2),
            "contrast_enhanced": round(contrast_enh, 2),
            "defect_mask": defect_mask,
            "gradient_enhanced": grad_enh
        }
