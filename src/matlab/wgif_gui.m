function wgif_gui()
% WGIF_GUI   Interactive MATLAB Graphical User Interface
%
% Launch:
%   wgif_gui
%
% Features:
%   - Interactive slider parameter adjustment (r, lambda, gamma, detail boost)
%   - Load custom images or built-in synthetic PCB inspection sample
%   - Side-by-side Before/After inspection visualizer
%   - Real-time quantitative metrics panel (Entropy, Sharpness, Contrast, Gain)
%   - Defect contour red overlay toggle
%   - Image export capability

    % Main Figure Window
    hFig = figure('Name', 'WGIF Image Illumination & Visual Inspection GUI', ...
                  'NumberTitle', 'off', 'MenuBar', 'none', ...
                  'Color', [0.08 0.11 0.16], 'Position', [150 100 1100 680], ...
                  'Resize', 'on');

    % State variables
    state.orig_img = [];
    state.enhanced_img = [];
    state.overlay_img = [];

    % Title Banner
    uicontrol('Style', 'text', 'String', 'IMAGE ILLUMINATION ENHANCEMENT USING WGIF ALGORITHM', ...
              'Units', 'normalized', 'Position', [0.03 0.93 0.94 0.05], ...
              'BackgroundColor', [0.08 0.11 0.16], 'ForegroundColor', [0.35 0.65 1.0], ...
              'FontSize', 13, 'FontWeight', 'bold');

    % Left Control Panel
    hPanel = uipanel('Parent', hFig, 'Title', 'INSPECTION CONTROLS', ...
                     'Units', 'normalized', 'Position', [0.03 0.05 0.28 0.86], ...
                     'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', [0.7 0.8 0.9], ...
                     'FontSize', 10, 'FontWeight', 'bold');

    % Buttons: Load Image & Load Sample
    uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Load Custom Image', ...
              'Units', 'normalized', 'Position', [0.05 0.91 0.90 0.06], ...
              'BackgroundColor', [0.2 0.45 0.8], 'ForegroundColor', 'w', ...
              'FontWeight', 'bold', 'Callback', @onLoadImage);

    uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Load Inspection Sample', ...
              'Units', 'normalized', 'Position', [0.05 0.84 0.90 0.06], ...
              'BackgroundColor', [0.2 0.25 0.35], 'ForegroundColor', 'w', ...
              'Callback', @onLoadSample);

    % Slider 1: Radius
    uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Filter Radius (r):', ...
              'Units', 'normalized', 'Position', [0.05 0.77 0.60 0.04], ...
              'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', 'w', 'HorizontalAlignment', 'left');
    lblR = uicontrol('Parent', hPanel, 'Style', 'text', 'String', '15 px', ...
                     'Units', 'normalized', 'Position', [0.65 0.77 0.30 0.04], ...
                     'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', [0.4 0.8 1.0]);
    sldR = uicontrol('Parent', hPanel, 'Style', 'slider', 'Min', 3, 'Max', 30, 'Value', 15, ...
                     'Units', 'normalized', 'Position', [0.05 0.73 0.90 0.035], ...
                     'Callback', @(s, e) set(lblR, 'String', sprintf('%d px', round(get(s, 'Value')))));

    % Slider 2: Regularization Lambda
    uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Regularization (Lambda):', ...
              'Units', 'normalized', 'Position', [0.05 0.67 0.60 0.04], ...
              'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', 'w', 'HorizontalAlignment', 'left');
    lblLam = uicontrol('Parent', hPanel, 'Style', 'text', 'String', '0.010', ...
                       'Units', 'normalized', 'Position', [0.65 0.67 0.30 0.04], ...
                       'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', [0.4 0.8 1.0]);
    sldLam = uicontrol('Parent', hPanel, 'Style', 'slider', 'Min', 0.001, 'Max', 0.05, 'Value', 0.01, ...
                       'Units', 'normalized', 'Position', [0.05 0.63 0.90 0.035], ...
                       'Callback', @(s, e) set(lblLam, 'String', sprintf('%.3f', get(s, 'Value'))));

    % Slider 3: Gamma
    uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Tone Gamma (Gamma):', ...
              'Units', 'normalized', 'Position', [0.05 0.57 0.60 0.04], ...
              'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', 'w', 'HorizontalAlignment', 'left');
    lblGam = uicontrol('Parent', hPanel, 'Style', 'text', 'String', '0.45', ...
                       'Units', 'normalized', 'Position', [0.65 0.57 0.30 0.04], ...
                       'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', [0.4 0.8 1.0]);
    sldGam = uicontrol('Parent', hPanel, 'Style', 'slider', 'Min', 0.2, 'Max', 0.9, 'Value', 0.45, ...
                       'Units', 'normalized', 'Position', [0.05 0.53 0.90 0.035], ...
                       'Callback', @(s, e) set(lblGam, 'String', sprintf('%.2f', get(s, 'Value'))));

    % Slider 4: Detail Boost
    uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Detail Boost (Kappa):', ...
              'Units', 'normalized', 'Position', [0.05 0.47 0.60 0.04], ...
              'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', 'w', 'HorizontalAlignment', 'left');
    lblDet = uicontrol('Parent', hPanel, 'Style', 'text', 'String', '1.4x', ...
                       'Units', 'normalized', 'Position', [0.65 0.47 0.30 0.04], ...
                       'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', [0.4 0.8 1.0]);
    sldDet = uicontrol('Parent', hPanel, 'Style', 'slider', 'Min', 1.0, 'Max', 2.5, 'Value', 1.4, ...
                       'Units', 'normalized', 'Position', [0.05 0.43 0.90 0.035], ...
                       'Callback', @(s, e) set(lblDet, 'String', sprintf('%.1fx', get(s, 'Value'))));

    % Checkbox: Highlight Defect Contours
    chkDefect = uicontrol('Parent', hPanel, 'Style', 'checkbox', 'String', 'Highlight Defect Contours', ...
                          'Value', 1, 'Units', 'normalized', 'Position', [0.05 0.37 0.90 0.04], ...
                          'BackgroundColor', [0.12 0.15 0.22], 'ForegroundColor', [1 0.7 0.7], ...
                          'FontWeight', 'bold');

    % Execute Button
    uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Execute WGIF Enhancement', ...
              'Units', 'normalized', 'Position', [0.05 0.28 0.90 0.07], ...
              'BackgroundColor', [0.1 0.6 0.4], 'ForegroundColor', 'w', ...
              'FontWeight', 'bold', 'FontSize', 10, 'Callback', @onProcess);

    % Save Button
    uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Export Enhanced Image', ...
              'Units', 'normalized', 'Position', [0.05 0.20 0.90 0.06], ...
              'BackgroundColor', [0.2 0.25 0.35], 'ForegroundColor', 'w', ...
              'Callback', @onSaveImage);

    % Metrics Display Box
    txtMetrics = uicontrol('Parent', hPanel, 'Style', 'text', ...
                           'String', sprintf('METRICS:\nVisibility Gain: --\nEntropy: --\nAvg Gradient: --\nEME Contrast: --'), ...
                           'Units', 'normalized', 'Position', [0.05 0.02 0.90 0.16], ...
                           'BackgroundColor', [0.07 0.09 0.13], 'ForegroundColor', [0.6 0.9 0.7], ...
                           'FontSize', 9, 'HorizontalAlignment', 'left');

    % Image Display Axes (Right Panel)
    axOrig = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.35 0.12 0.29 0.75]);
    title(axOrig, 'Original Underexposed Inspection Target', 'Color', 'w', 'FontSize', 11);
    axis(axOrig, 'off');

    axEnh = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.67 0.12 0.29 0.75]);
    title(axEnh, 'WGIF Enhanced & Defect Highlighted', 'Color', [0.5 0.8 1.0], 'FontSize', 11);
    axis(axEnh, 'off');

    % --- Nested Callback Functions ---
    function onLoadSample(~, ~)
        sample_path = fullfile('..', '..', 'sample_images', 'low_light_pcb_matlab.png');
        if ~exist(sample_path, 'file')
            state.orig_img = generate_sample_image(sample_path);
        else
            state.orig_img = imread(sample_path);
        end
        imshow(state.orig_img, 'Parent', axOrig);
        title(axOrig, 'Original Underexposed Inspection Target', 'Color', 'w');
        onProcess();
    end

    function onLoadImage(~, ~)
        [f, p] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Image Files (*.png, *.jpg, *.bmp)'});
        if isequal(f, 0), return; end
        state.orig_img = imread(fullfile(p, f));
        imshow(state.orig_img, 'Parent', axOrig);
        title(axOrig, sprintf('Original: %s', f), 'Color', 'w');
        onProcess();
    end

    function onProcess(~, ~)
        if isempty(state.orig_img), return; end
        r_val = round(get(sldR, 'Value'));
        lam_val = get(sldLam, 'Value');
        gam_val = get(sldGam, 'Value');
        det_val = get(sldDet, 'Value');

        % Run WGIF Retinex
        res = retinex_enhancement(state.orig_img, r_val, lam_val, gam_val, det_val, true);
        state.enhanced_img = res.enhanced;

        % Run Inspection
        insp = visual_inspection(state.orig_img, state.enhanced_img, 25);
        state.overlay_img = insp.overlay_image;

        % Compute metrics
        m = compute_metrics(state.orig_img, state.enhanced_img);

        % Display
        if get(chkDefect, 'Value')
            imshow(state.overlay_img, 'Parent', axEnh);
            title(axEnh, sprintf('WGIF Enhanced + Defect Overlay (+%.1f%%)', insp.improvement_pct), ...
                  'Color', [1 0.7 0.7], 'FontWeight', 'bold');
        else
            imshow(state.enhanced_img, 'Parent', axEnh);
            title(axEnh, 'WGIF Enhanced (Halo-Free)', 'Color', [0.5 0.8 1.0], 'FontWeight', 'bold');
        end

        % Update metrics text
        set(txtMetrics, 'String', sprintf(...
            'METRICS:\nVisibility Gain: %.2fx (+%.1f%%)\nEntropy: %.3f -> %.3f\nAvg Gradient: %.2f -> %.2f\nEME Contrast: %.1f -> %.1f dB', ...
            insp.gain_factor, insp.improvement_pct, ...
            m.entropy_orig, m.entropy_enh, ...
            m.ag_orig, m.ag_enh, ...
            m.eme_orig, m.eme_enh));
    end

    function onSaveImage(~, ~)
        if isempty(state.enhanced_img)
            warndlg('Please load an image and run enhancement first.');
            return;
        end
        [f, p] = uiputfile('*.png', 'Save Enhanced Image', 'matlab_wgif_result.png');
        if isequal(f, 0), return; end
        if get(chkDefect, 'Value') && ~isempty(state.overlay_img)
            imwrite(state.overlay_img, fullfile(p, f));
        else
            imwrite(state.enhanced_img, fullfile(p, f));
        end
        msgbox('Enhanced image exported successfully!', 'Success');
    end

    % Auto-load sample on startup
    onLoadSample();
end
