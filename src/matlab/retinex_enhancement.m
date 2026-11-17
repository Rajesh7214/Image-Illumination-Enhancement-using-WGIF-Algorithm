function res = retinex_enhancement(img, r, lambda, gamma, detail_boost, use_wgif)
% RETINEX_ENHANCEMENT   Retinex illumination enhancement via WGIF
%
% Syntax:
%   res = retinex_enhancement(img, r, lambda, gamma, detail_boost, use_wgif)
%
% Inputs:
%   img          - Color (RGB) or Grayscale image (uint8 or double)
%   r            - Window radius (default = 15)
%   lambda       - Regularization parameter (default = 0.01)
%   gamma        - Tone-mapping factor (< 1 brightens shadows, default = 0.45)
%   detail_boost - High-frequency detail amplification (default = 1.4)
%   use_wgif     - true for WGIF, false for standard GIF (default = true)
%
% Output:
%   res - Structure containing:
%         .enhanced     - Enhanced RGB/Grayscale image (uint8)
%         .illumination - Estimated enhanced illumination map (uint8)
%         .reflectance  - Surface reflectance component (uint8)
%         .details      - Boosted high-frequency defect & texture layer (uint8)

    if nargin < 2 || isempty(r), r = 15; end
    if nargin < 3 || isempty(lambda), lambda = 0.01; end
    if nargin < 4 || isempty(gamma), gamma = 0.45; end
    if nargin < 5 || isempty(detail_boost), detail_boost = 1.4; end
    if nargin < 6 || isempty(use_wgif), use_wgif = true; end

    % Convert input to double [0, 1]
    if isa(img, 'uint8')
        img_d = double(img) / 255.0;
    else
        img_d = double(img);
    end

    is_color = (ndims(img_d) == 3 && size(img_d, 3) == 3);

    % Step 1: Initial Illumination Estimation (Maximum channel)
    if is_color
        I_init = max(img_d, [], 3);
    else
        I_init = img_d;
    end

    % Step 2: Edge-Preserving Illumination Map via WGIF or Standard GIF
    if use_wgif
        L = wgif(I_init, I_init, r, lambda);
    else
        L = guided_filter(I_init, I_init, r, lambda);
    end
    L = max(L, 1e-4);

    % Step 3: High-Frequency Surface Detail / Defect Extraction
    D = I_init - L;

    % Step 4: Illumination Tone Mapping (Adaptive Gamma)
    L_enh = L .^ gamma;

    % Step 5: Retinex Recombination & Defect Feature Boosting
    ratio = L_enh ./ (L + 1e-4);

    enhanced_d = zeros(size(img_d));
    if is_color
        for c = 1:3
            enhanced_d(:, :, c) = (img_d(:, :, c) .* (ratio .^ 0.85)) + (detail_boost - 1.0) .* D;
        end
    else
        enhanced_d = (img_d .* ratio) + (detail_boost - 1.0) .* D;
    end

    enhanced_d = min(max(enhanced_d, 0.0), 1.0);

    % Package outputs as uint8 for standard MATLAB visualization
    res.enhanced = uint8(round(enhanced_d * 255));
    res.illumination = uint8(round(min(max(L_enh, 0), 1) * 255));
    res.reflectance = uint8(round(min(max(I_init ./ (L + 1e-4), 0), 1) * 255));
    res.details = uint8(round(min(max(D + 0.5, 0), 1) * 255));
    res.ratio = ratio;
end
