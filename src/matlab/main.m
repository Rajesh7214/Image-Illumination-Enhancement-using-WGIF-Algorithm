%% =========================================================================
% Project: Image Illumination Enhancement using WGIF Algorithm
% Application: Defect Visibility and Object Inspection
% MATLAB Main Runner Script
% =========================================================================
clc;
clear;
close all;

fprintf('========================================================================\n');
fprintf(' Image Illumination Enhancement using WGIF Algorithm\n');
fprintf(' Retinex Illumination-Reflectance Decomposition for Visual Inspection\n');
fprintf('========================================================================\n\n');

% --- Step 1: Load or Generate Sample Low-Light Inspection Image ---
sample_file = fullfile('..', '..', 'sample_images', 'low_light_pcb_matlab.png');
if ~exist(sample_file, 'file')
    fprintf('[1/5] Generating synthetic underexposed PCB inspection sample...\n');
    img_orig = generate_sample_image(sample_file);
else
    fprintf('[1/5] Loading inspection image: %s\n', sample_file);
    img_orig = imread(sample_file);
end

% --- Step 2: Set Algorithm Hyper-parameters ---
r = 15;             % Guided window radius
lambda = 0.01;      % WGIF Regularization parameter
gamma = 0.45;       % Tone-mapping gamma factor (< 1.0 brightens shadows)
detail_boost = 1.4; % High-frequency surface defect boost factor
edge_thresh = 25;   % Inspection edge sensitivity threshold

fprintf('\n[2/5] Running enhancement with parameters:\n');
fprintf('      Radius (r): %d px, Lambda: %.3f, Gamma: %.2f, Detail Boost: %.1fx\n', ...
    r, lambda, gamma, detail_boost);

% --- Step 3: Execute Enhancement ---
% 3.1 Standard Guided Filter (Baseline for comparison)
fprintf('[3/5] Computing Standard Guided Filter (GIF) baseline...\n');
res_gif = retinex_enhancement(img_orig, r, lambda, gamma, detail_boost, false);

% 3.2 Weighted Guided Filter (Proposed WGIF)
fprintf('[4/5] Computing Proposed Weighted Guided Filter (WGIF)...\n');
res_wgif = retinex_enhancement(img_orig, r, lambda, gamma, detail_boost, true);

% --- Step 4: Visual Defect Inspection & Metrics Analysis ---
fprintf('[5/5] Performing automated visual defect inspection and metrics calculation...\n');
insp_orig = visual_inspection(img_orig, img_orig, edge_thresh);
insp_gif  = visual_inspection(img_orig, res_gif.enhanced, edge_thresh);
insp_wgif = visual_inspection(img_orig, res_wgif.enhanced, edge_thresh);

metrics_gif  = compute_metrics(img_orig, res_gif.enhanced);
metrics_wgif = compute_metrics(img_orig, res_wgif.enhanced);

% --- Print Quantitative Results Table ---
fprintf('\n========================================================================\n');
fprintf('                     QUANTITATIVE EVALUATION RESULTS                    \n');
fprintf('========================================================================\n');
fprintf('%-28s | %-12s | %-14s | %-14s\n', 'Metric', 'Original', 'Standard GIF', 'Proposed WGIF');
fprintf('------------------------------------------------------------------------\n');
fprintf('%-28s | %-12.3f | %-14.3f | %-14.3f\n', 'Shannon Entropy', ...
    metrics_wgif.entropy_orig, metrics_gif.entropy_enh, metrics_wgif.entropy_enh);
fprintf('%-28s | %-12.3f | %-14.3f | %-14.3f\n', 'Average Gradient (AG)', ...
    metrics_wgif.ag_orig, metrics_gif.ag_enh, metrics_wgif.ag_enh);
fprintf('%-28s | %-12.2f | %-14.2f | %-14.2f\n', 'EME Contrast (dB)', ...
    metrics_wgif.eme_orig, metrics_gif.eme_enh, metrics_wgif.eme_enh);
fprintf('%-28s | %-12s | %-14.2f | %-14.2f\n', 'Lightness Order Error (LOE)', ...
    '0.00', metrics_gif.loe, metrics_wgif.loe);
fprintf('------------------------------------------------------------------------\n');
fprintf('%-28s | %-12d | %-14d | %-14d\n', 'Detectable Defect Edges', ...
    insp_orig.edges_enhanced, insp_gif.edges_enhanced, insp_wgif.edges_enhanced);
fprintf('%-28s | %-12s | %-14.2fx | %-14.2fx (+%s%%)\n', 'Visibility Gain Factor', ...
    '1.00x', insp_gif.gain_factor, insp_wgif.gain_factor, num2str(insp_wgif.improvement_pct));
fprintf('========================================================================\n\n');

% --- Step 5: Save Output Images ---
results_dir = fullfile('..', '..', 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

imwrite(res_wgif.enhanced, fullfile(results_dir, 'matlab_wgif_enhanced.png'));
imwrite(res_gif.enhanced, fullfile(results_dir, 'matlab_gif_enhanced.png'));
imwrite(res_wgif.illumination, fullfile(results_dir, 'matlab_wgif_illumination.png'));
imwrite(insp_wgif.overlay_image, fullfile(results_dir, 'matlab_detected_defects_overlay.png'));
fprintf('Results saved successfully to folder: %s\n', results_dir);

% --- Step 6: Multi-Panel Visualization Plot ---
fig = figure('Name', 'WGIF Visual Inspection & Illumination Enhancement', ...
             'NumberTitle', 'off', 'Color', [0.1 0.12 0.15], 'Position', [100 80 1200 700]);

subplot(2, 3, 1);
imshow(img_orig);
title('1. Original Underexposed Target', 'Color', 'w', 'FontSize', 11);

subplot(2, 3, 2);
imshow(res_gif.enhanced);
title('2. Standard GIF (Halo Artifacts)', 'Color', [1 0.7 0.7], 'FontSize', 11);

subplot(2, 3, 3);
imshow(res_wgif.enhanced);
title(sprintf('3. Proposed WGIF (Halo-Free, +%s%%)', num2str(insp_wgif.improvement_pct)), ...
    'Color', [0.6 1 0.6], 'FontSize', 11, 'FontWeight', 'bold');

subplot(2, 3, 4);
imshow(res_wgif.illumination);
title('4. Edge-Preserving Illumination L(x, y)', 'Color', 'w', 'FontSize', 11);

subplot(2, 3, 5);
imshow(res_wgif.details);
title('5. Extracted Surface Details D(x, y)', 'Color', 'w', 'FontSize', 11);

subplot(2, 3, 6);
imshow(insp_wgif.overlay_image);
title(sprintf('6. Detected Defect Contours (%dx gain)', round(insp_wgif.gain_factor)), ...
    'Color', [1 0.5 0.5], 'FontSize', 11, 'FontWeight', 'bold');

fprintf('Displaying comparative visualization figure.\nExecution complete!\n');
