"""
Command Line Interface (CLI) for WGIF Illumination Enhancement
Usage:
    python run_enhancement.py --input sample_images/dark.png --output results/enhanced.png --gamma 0.45 --inspect
"""

import argparse
import os
import numpy as np
from PIL import Image
from retinex_enhancer import WGIFIlluminationEnhancer
from visual_inspector import VisualInspector
from metrics import evaluate_image_enhancement

def main():
    parser = argparse.ArgumentParser(description="Image Illumination Enhancement using Weighted Guided Image Filter (WGIF)")
    parser.add_argument("--input", "-i", type=str, required=True, help="Path to input low-light image")
    parser.add_argument("--output", "-o", type=str, default="results/wgif_enhanced.png", help="Path to save enhanced image")
    parser.add_argument("--radius", "-r", type=int, default=15, help="WGIF window radius (default: 15)")
    parser.add_argument("--eps", "-e", type=float, default=0.01, help="Regularization lambda (default: 0.01)")
    parser.add_argument("--gamma", "-g", type=float, default=0.45, help="Gamma factor for tone mapping (< 1.0 brightens) (default: 0.45)")
    parser.add_argument("--detail", "-d", type=float, default=1.3, help="Detail enhancement boost factor (default: 1.3)")
    parser.add_argument("--inspect", action="store_true", help="Run visual defect inspection analysis and save defect mask")

    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"Error: Input file '{args.input}' not found.")
        return

    img = np.array(Image.open(args.input))
    print(f"Loaded '{args.input}' (shape: {img.shape})")

    enhancer = WGIFIlluminationEnhancer(r=args.radius, eps=args.eps, gamma=args.gamma, detail_boost=args.detail)
    res = enhancer.enhance(img, method="wgif")

    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    Image.fromarray(res["enhanced"]).save(args.output)
    print(f"Enhanced image saved to: {args.output}")

    # Metrics
    m = evaluate_image_enhancement(img, res["enhanced"])
    print("\n--- Image Enhancement Metrics ---")
    print(f"Entropy: {m['entropy_original']} -> {m['entropy_enhanced']} (+{m['entropy_enhanced'] - m['entropy_original']:.2f})")
    print(f"Average Gradient (Sharpness): {m['average_gradient_original']} -> {m['average_gradient_enhanced']}")
    print(f"EME Contrast Score: {m['eme_contrast_original']} -> {m['eme_contrast_enhanced']}")
    print(f"Lightness Order Error: {m['lightness_order_error']}")

    if args.inspect:
        inspector = VisualInspector(edge_threshold=25.0)
        insp = inspector.inspect(img, res["enhanced"])
        defect_out = os.path.splitext(args.output)[0] + "_defects.png"
        Image.fromarray(insp["defect_mask"]).save(defect_out)
        print(f"\n--- Visual Inspection Analysis ---")
        print(f"Visibility improvement: +{insp['visibility_improvement_pct']}% ({insp['edge_multiplication_factor']}x edge contours)")
        print(f"Defect contour mask saved to: {defect_out}")

if __name__ == "__main__":
    main()
