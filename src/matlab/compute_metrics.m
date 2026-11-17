function metrics = compute_metrics(orig_img, enh_img)
% COMPUTE_METRICS   Evaluates quantitative image enhancement metrics
%
% Syntax:
%   metrics = compute_metrics(orig_img, enh_img)
%
% Calculates:
%   - Shannon Information Entropy
%   - Average Gradient (AG - Edge sharpness)
%   - Measure of Enhancement (EME - Local contrast)
%   - Lightness Order Error (LOE - Natural lightness ordering)

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

    % 1. Shannon Information Entropy
    metrics.entropy_orig = round(calculate_entropy(g_orig), 3);
    metrics.entropy_enh = round(calculate_entropy(g_enh), 3);

    % 2. Average Gradient (AG)
    metrics.ag_orig = round(calculate_ag(g_orig), 3);
    metrics.ag_enh = round(calculate_ag(g_enh), 3);

    % 3. Measure of Enhancement (EME)
    metrics.eme_orig = round(calculate_eme(g_orig, 8), 2);
    metrics.eme_enh = round(calculate_eme(g_enh, 8), 2);

    % 4. Lightness Order Error (LOE)
    metrics.loe = round(calculate_loe(g_orig, g_enh, 50), 2);
end

% Sub-functions
function ent = calculate_entropy(g)
    counts = histcounts(g(:), 0:256);
    p = counts(counts > 0) / numel(g);
    ent = -sum(p .* log2(p));
end

function ag = calculate_ag(g)
    [gx, gy] = gradient(g);
    mag = sqrt((gx.^2 + gy.^2) / 2);
    ag = mean(mag(:));
end

function eme = calculate_eme(g, block_size)
    [h, w] = size(g);
    k1 = floor(h / block_size);
    k2 = floor(w / block_size);
    if k1 == 0 || k2 == 0
        eme = 0;
        return;
    end

    sum_val = 0;
    count = 0;
    for i = 1:k1
        for j = 1:k2
            block = g((i-1)*block_size + 1 : i*block_size, (j-1)*block_size + 1 : j*block_size);
            b_min = min(block(:));
            b_max = max(block(:));
            if b_min > 0 && b_max > b_min
                sum_val = sum_val + 20 * log10(b_max / (b_min + 1e-4));
                count = count + 1;
            end
        end
    end
    if count > 0
        eme = sum_val / count;
    else
        eme = 0;
    end
end

function loe_val = calculate_loe(orig_g, enh_g, grid_size)
    [h, w] = size(orig_g);
    step_y = max(1, floor(h / grid_size));
    step_x = max(1, floor(w / grid_size));

    d_orig = orig_g(1:step_y:end, 1:step_x:end);
    d_enh  = enh_g(1:step_y:end, 1:step_x:end);

    v_orig = d_orig(:);
    v_enh = d_enh(:);
    n = length(v_orig);

    order_orig = bsxfun(@ge, v_orig, v_orig');
    order_enh  = bsxfun(@ge, v_enh, v_enh');

    mismatches = sum(sum(order_orig ~= order_enh));
    loe_val = (mismatches / (n * n)) * 1000.0;
end
