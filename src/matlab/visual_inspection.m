function insp = visual_inspection(orig_img, enh_img, edge_threshold)
% VISUAL_INSPECTION   Automated Defect & Edge Contour Detection
%
% Syntax:
%   insp = visual_inspection(orig_img, enh_img, edge_threshold)
%
% Inputs:
%   orig_img       - Original low-light image (RGB or Grayscale, uint8)
%   enh_img        - WGIF enhanced image (RGB or Grayscale, uint8)
%   edge_threshold - Sensitivity threshold for edge detection (default = 25)
%
% Output:
%   insp - Structure containing:
%          .edges_original  - Count of detectable edges in dark image
%          .edges_enhanced  - Count of detectable edges in enhanced image
%          .gain_factor     - Multiplier of revealed inspection details
%          .defect_mask     - Binary defect/contour map (uint8 0 or 255)
%          .overlay_image   - Enhanced image with detected contours highlighted in red

    if nargin < 3 || isempty(edge_threshold)
        edge_threshold = 25;
    end

    % Convert to grayscale double
    if ndims(orig_img) == 3
        g_orig = double(rgb2gray(orig_img));
    else
        g_orig = double(orig_img);
    end

    if ndims(enh_img) == 3
        g_enh = double(rgb2gray(enh_img));
    else
        g_enh = double(enh_img);
    end

    % Sobel gradient computation
    sobel_h = [-1 0 1; -2 0 2; -1 0 1];
    sobel_v = [-1 -2 -1; 0 0 0; 1 2 1];

    gx_orig = imfilter(g_orig, sobel_h, 'replicate');
    gy_orig = imfilter(g_orig, sobel_v, 'replicate');
    mag_orig = sqrt(gx_orig.^2 + gy_orig.^2);

    gx_enh = imfilter(g_enh, sobel_h, 'replicate');
    gy_enh = imfilter(g_enh, sobel_v, 'replicate');
    mag_enh = sqrt(gx_enh.^2 + gy_enh.^2);

    % Detect edges above threshold
    mask_orig = (mag_orig > edge_threshold);
    mask_enh = (mag_enh > edge_threshold);

    edges_orig = sum(mask_orig(:));
    edges_enh = sum(mask_enh(:));

    gain = (edges_enh + 1) / (edges_orig + 1);

    % Red overlay generation on enhanced image
    overlay = enh_img;
    if ndims(overlay) == 2
        overlay = repmat(overlay, [1 1 3]);
    end

    r_ch = overlay(:, :, 1);
    g_ch = overlay(:, :, 2);
    b_ch = overlay(:, :, 3);

    % Color defect contours red
    r_ch(mask_enh) = 255;
    g_ch(mask_enh) = 40;
    b_ch(mask_enh) = 40;

    overlay(:, :, 1) = r_ch;
    overlay(:, :, 2) = g_ch;
    overlay(:, :, 3) = b_ch;

    % Output struct
    insp.edges_original = edges_orig;
    insp.edges_enhanced = edges_enh;
    insp.gain_factor = round(gain, 2);
    insp.improvement_pct = round((gain - 1) * 100, 1);
    insp.defect_mask = uint8(mask_enh * 255);
    insp.overlay_image = overlay;
    insp.gradient_enhanced = mag_enh;
end
