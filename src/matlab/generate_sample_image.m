function img = generate_sample_image(output_path)
% GENERATE_SAMPLE_IMAGE   Creates a synthetic underexposed PCB inspection sample
%
% Usage:
%   img = generate_sample_image(output_path)

    if nargin < 1 || isempty(output_path)
        output_path = fullfile('..', '..', 'sample_images', 'low_light_pcb_matlab.png');
    end

    w = 480;
    h = 360;

    % Substrate dark green
    img_rgb = zeros(h, w, 3);
    img_rgb(:, :, 1) = 22 / 255;
    img_rgb(:, :, 2) = 56 / 255;
    img_rgb(:, :, 3) = 32 / 255;

    % Copper traces
    for y = 50:45:320
        img_rgb(y:y+3, 30:w-30, 1) = 197 / 255;
        img_rgb(y:y+3, 30:w-30, 2) = 160 / 255;
        img_rgb(y:y+3, 30:w-30, 3) = 79 / 255;

        % Solder pads
        img_rgb(y-8:y+8, 80:100, :) = 0.72;
        img_rgb(y-8:y+8, 240:260, :) = 0.72;
        img_rgb(y-8:y+8, 380:400, :) = 0.72;
    end

    % IC Chip package in center
    img_rgb(120:240, 160:320, :) = 0.12;

    % Micro-defect: Hairline crack across chip (very faint)
    for t = 0:30
        px = 200 + t;
        py = 140 + round(t * 0.8);
        img_rgb(py, px, 1) = 0.45;
        img_rgb(py, px, 2) = 0.15;
        img_rgb(py, px, 3) = 0.15;
    end

    % Micro-defect: Trace bridge notch
    img_rgb(90:105, 248:252, 1) = 0.05;
    img_rgb(90:105, 248:252, 2) = 0.12;
    img_rgb(90:105, 248:252, 3) = 0.05;

    % Severe non-uniform shadow / low-light vignette
    [X, Y] = meshgrid(linspace(-1, 1, w), linspace(-1, 1, h));
    dist = sqrt(X.^2 + Y.^2);
    vignette = max(0.12, 1.0 - 0.75 * dist);
    illumination = 0.22 * vignette .* (0.6 + 0.4 * (1.0 - X));

    for c = 1:3
        img_rgb(:, :, c) = img_rgb(:, :, c) .* illumination;
    end

    img = uint8(round(min(max(img_rgb, 0), 1) * 255));

    % Save if directory exists or create
    [dir_name, ~, ~] = fileparts(output_path);
    if ~isempty(dir_name) && ~exist(dir_name, 'dir')
        mkdir(dir_name);
    end
    imwrite(img, output_path);
    fprintf('Synthetic inspection image generated: %s\n', output_path);
end
