function q = guided_filter(p, I, r, eps)
% GUIDED_FILTER   Standard Guided Image Filter (He et al., ECCV 2010 / TPAMI 2013)
%
% Syntax:
%   q = guided_filter(p, I, r, eps)
%
% Inputs:
%   p   - Filtering input target (double in [0, 1])
%   I   - Guidance image (double in [0, 1])
%   r   - Local window radius (default = 15)
%   eps - Regularization parameter (default = 0.01)

    if nargin < 3, r = 15; end
    if nargin < 4, eps = 0.01; end

    [hei, wid] = size(I);
    N = boxfilter(ones(hei, wid), r);

    mean_I = boxfilter(I, r) ./ N;
    mean_p = boxfilter(p, r) ./ N;
    mean_Ip = boxfilter(I .* p, r) ./ N;
    mean_II = boxfilter(I .* I, r) ./ N;

    var_I = mean_II - mean_I .* mean_I;
    cov_Ip = mean_Ip - mean_I .* mean_p;

    a = cov_Ip ./ (var_I + eps);
    b = mean_p - a .* mean_I;

    mean_a = boxfilter(a, r) ./ N;
    mean_b = boxfilter(b, r) ./ N;

    q = mean_a .* I + mean_b;
    q = min(max(q, 0.0), 1.0);
end
