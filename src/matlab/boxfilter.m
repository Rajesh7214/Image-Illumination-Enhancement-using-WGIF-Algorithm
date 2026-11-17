function imDst = boxfilter(imSrc, r)
% BOXFILTER   O(1) 2D Box Filter using cumulative sums (Integral Image)
%
% Usage:
%   imDst = boxfilter(imSrc, r)
%
% Inputs:
%   imSrc - 2D matrix (double or single)
%   r     - Radius of the square box window (size = 2*r + 1)
%
% Output:
%   imDst - Filtered 2D matrix (sum of values in local window)
%
% Reference:
%   Kaiming He et al., "Guided Image Filtering", TPAMI 2013.

    [hei, wid] = size(imSrc);
    imDst = zeros(hei, wid);

    % Cumulative sum along columns (dimension 1)
    imCum = cumsum(imSrc, 1);
    
    % Difference along columns
    imDst(1:r+1, :) = imCum(1+r:2*r+1, :);
    imDst(r+2:hei-r, :) = imCum(2*r+2:hei, :) - imCum(1:hei-2*r-1, :);
    imDst(hei-r+1:hei, :) = repmat(imCum(hei, :), [r, 1]) - imCum(hei-2*r:hei-r-1, :);

    % Cumulative sum along rows (dimension 2)
    imCum = cumsum(imDst, 2);
    
    % Difference along rows
    imDst(:, 1:r+1) = imCum(:, 1+r:2*r+1);
    imDst(:, r+2:wid-r) = imCum(:, 2*r+2:wid) - imCum(:, 1:wid-2*r-1);
    imDst(:, wid-r+1:wid) = repmat(imCum(:, wid), [1, r]) - imCum(:, wid-2*r:wid-r-1);
end
