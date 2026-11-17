"""
Test Pipeline & Synthetic Sample Image Generator
Generates realistic underexposed industrial inspection targets:
- PCB board with subtle micro-cracks and solder traces
- Metal surface with dark scratches and non-uniform shadowing
Runs both standard Guided Filter and Weighted Guided Filter (WGIF),
evaluates metrics, and validates visual defect inspection clarity.
"""

import os
import numpy as np
from PIL import Image, ImageDraw
from retinex_enhancer import WGIFIlluminationEnhancer
from visual_inspector import VisualInspector
from metrics import evaluate_image_enhancement

def generate_synthetic_industrial_sample(output_path: str = "sample_images/low_light_pcb_inspection.png"):
    """Creates a synthetic underexposed PCB circuit image with hidden surface defects."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    w, h = 400, 300
    
    # Base PCB board (dark green)
    img = Image.new("RGB", (w, h), color=(15, 35, 20))
    draw = ImageDraw.Draw(img)

    # Copper traces & components
    for y in range(40, 260, 35):
        draw.line([(30, y), (370, y)], fill=(80, 110, 40), width=4)
        draw.rectangle([60, y - 10, 80, y + 10], fill=(140, 130, 60))
        draw.rectangle([180, y - 8, 220, y + 8], fill=(120, 120, 130))
        draw.rectangle([300, y - 10, 320, y + 10], fill=(140, 130, 60))

    # IC chip in center
    draw.rectangle([140, 100, 260, 200], fill=(25, 25, 25), outline=(70, 70, 70))
    draw.text((160, 140), "MICRO-MCU", fill=(100, 100, 100))

    # Tiny micro-defects / hairline cracks (very dim, invisible in dark lighting)
    draw.line([(190, 115), (205, 125)], fill=(120, 40, 40), width=1) # hairline crack on chip
    draw.line([(70, 135), (70, 155)], fill=(15, 20, 10), width=2)     # solder bridge / cut trace

    arr = np.array(img, dtype=np.float64)

    # Apply severe non-uniform shadow / low-light vignette
    x = np.linspace(-1, 1, w)
    y = np.linspace(-1, 1, h)
    xx, yy = np.meshgrid(x, y)
    vignette = np.clip(1.0 - 0.75 * np.sqrt(xx**2 + yy**2), 0.15, 1.0)
    
    # Overall underexposure (simulate dark factory chamber)
    illumination_gradient = 0.22 * vignette[:, :, None] * (0.5 + 0.5 * (1.0 - xx[:, :, None]))
    dark_img = np.clip(arr * illumination_gradient, 0, 255).astype(np.uint8)

    Image.fromarray(dark_img).save(output_path)
    print(f"Generated synthetic low-light inspection sample: {output_path}")
    return dark_img

def run_pipeline_test():
    sample_path = "sample_images/low_light_pcb_inspection.png"
    if not os.path.exists(sample_path):
        dark_img = generate_synthetic_industrial_sample(sample_path)
    else:
        dark_img = np.array(Image.open(sample_path))

    enhancer = WGIFIlluminationEnhancer(r=12, eps=0.01, gamma=0.45, detail_boost=1.4)
    inspector = VisualInspector(edge_threshold=25.0)

    print("\n" + "="*60)
    print("RUNNING WGIF ILLUMINATION ENHANCEMENT PIPELINE")
    print("="*60)

    # 1. Run Standard Guided Filter
    res_gif = enhancer.enhance(dark_img, method="standard_gif")
    # 2. Run Weighted Guided Filter (WGIF)
    res_wgif = enhancer.enhance(dark_img, method="wgif")

    # Metrics
    metrics_orig = evaluate_image_enhancement(dark_img, dark_img)
    metrics_gif = evaluate_image_enhancement(dark_img, res_gif["enhanced"])
    metrics_wgif = evaluate_image_enhancement(dark_img, res_wgif["enhanced"])

    # Visual inspection defect analysis
    inspect_wgif = inspector.inspect(dark_img, res_wgif["enhanced"])

    print("\n--- Quantitative Evaluation Comparison ---")
    print(f"{'Metric':<25} | {'Original Dark':<14} | {'Standard GIF':<14} | {'Proposed WGIF':<14}")
    print("-" * 75)
    print(f"{'Entropy (Detail info)':<25} | {metrics_orig['entropy_enhanced']:<14.3f} | {metrics_gif['entropy_enhanced']:<14.3f} | {metrics_wgif['entropy_enhanced']:<14.3f}")
    print(f"{'Avg Gradient (Sharpness)':<25} | {metrics_orig['average_gradient_enhanced']:<14.3f} | {metrics_gif['average_gradient_enhanced']:<14.3f} | {metrics_wgif['average_gradient_enhanced']:<14.3f}")
    print(f"{'EME Contrast Score':<25} | {metrics_orig['eme_contrast_enhanced']:<14.2f} | {metrics_gif['eme_contrast_enhanced']:<14.2f} | {metrics_wgif['eme_contrast_enhanced']:<14.2f}")
    print(f"{'Lightness Order Error':<25} | {'0.00':<14} | {metrics_gif['lightness_order_error']:<14.2f} | {metrics_wgif['lightness_order_error']:<14.2f}")
    
    print("\n--- Visual Inspection Analysis ---")
    print(f"Edges detected in dark image : {inspect_wgif['edges_detected_original']}")
    print(f"Edges detected after WGIF    : {inspect_wgif['edges_detected_enhanced']}")
    print(f"Visibility gain factor       : {inspect_wgif['edge_multiplication_factor']}x ({inspect_wgif['visibility_improvement_pct']}% more details revealed)")

    # Save output comparison
    os.makedirs("results", exist_ok=True)
    Image.fromarray(res_wgif["enhanced"]).save("results/wgif_enhanced.png")
    Image.fromarray(res_gif["enhanced"]).save("results/gif_enhanced.png")
    Image.fromarray(res_wgif["illumination_enh"]).save("results/wgif_illumination_map.png")
    Image.fromarray(inspect_wgif["defect_mask"]).save("results/detected_defects_mask.png")
    print("\nResults successfully saved to 'results/' directory.")

if __name__ == "__main__":
    run_pipeline_test()
