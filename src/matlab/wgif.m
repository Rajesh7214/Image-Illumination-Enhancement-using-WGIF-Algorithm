function [q, gamma] = wgif(p, I, r, lambda, r1)
% WGIF   Weighted Guided Image Filter
%
% Syntax:
%   [q, gamma] = wgif(p, I, r, lambda, r1)
%
% Inputs:
%   p      - Filtering input target (2D grayscale image, double in [0, 1])
%   I      - Guidance image (2D grayscale image, double in [0, 1])
%   r      - Local window radius for guided filtering (default = 15)
%   lambda - Regularization parameter (default = 0.01)
%   r1     - Local window radius for edge-weight variance (default = 1)
%
% Outputs:
%   q      - Edge-preserved filtered output image
%   gamma  - Edge-aware weighting factor map
%
% Reference:
%   Zhengguo Li, Jinghong Zheng, Zijian Zhu, Wei Yao, and Shenghao Wu,
%   "Weighted Guided Image Filter", IEEE Transactions on Image Processing (TIP),
%   Vol. 24, No. 1, pp. 120-129, Jan. 2015.

    if nargin < 3, r = 15; end
    if nargin < 4, lambda = 0.01; end
    if nargin < 5, r1 = 1; end

    [hei, wid] = size(I);
    N = hei * wid;

    p = double(p);
    I = double(I);

    % --- Step 1: Compute Edge-Aware Weighting Factor Gamma_G(k) ---
    % Window of radius r1 (size (2*r1+1) x (2*r1+1))
    N1 = boxfilter(ones(hei, wid), r1);
    mean_I1 = boxfilter(I, r1) ./ N1;
    mean_II1 = boxfilter(I .* I, r1) ./ N1;
    var_I1 = max(0, mean_II1 - mean_I1 .* mean_I1);

    % Epsilon to prevent division by zero (scaled by dynamic range L = 1.0)
    eps_weight = (0.001)^2;
    w_k = var_I1 + eps_weight;
    
    % Harmonic mean normalization
    inv_mean = mean(1.0 ./ w_k(:));
    gamma = w_k .* inv_mean;

    % --- Step 2: Local Statistics over Filtering Window of Radius r ---
    N_r = boxfilter(ones(hei, wid), r);
    mean_I = boxfilter(I, r) ./ N_r;
    mean_p = boxfilter(p, r) ./ N_r;
    mean_Ip = boxfilter(I .* p, r) ./ N_r;
    mean_II = boxfilter(I .* I, r) ./ N_r;

    var_I = mean_II - mean_I .* mean_I;
    cov_Ip = mean_Ip - mean_I .* mean_p;

    % --- Step 3: Adaptive Linear Coefficients ---
    % In WGIF, the regularization penalty is lambda / gamma(k)
    reg_term = lambda ./ (gamma + 1e-8);
    a = cov_Ip ./ (var_I + reg_term);
    b = mean_p - a .* mean_I;

    % --- Step 4: Average Linear Coefficients ---
    mean_a = boxfilter(a, r) ./ N_r;
    mean_b = boxfilter(b, r) ./ N_r;

    % --- Step 5: Filtered Output Signal ---
    q = mean_a .* I + mean_b;
    q = min(max(q, 0.0), 1.0);
end
