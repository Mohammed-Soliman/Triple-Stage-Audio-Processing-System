% Integrated Triple-Stage Audio Processing System

function IntegratedAudioProcessorGUI()
    fig = uifigure('Name', 'Integrated Audio Processing System', ...
                   'Position', [50 50 1500 900], ...
                   'Color', [0.95 0.95 0.97]);
    
    inputSignal = [];
    processedSignal = [];
    Fs = 44100;
    audioPlayer = [];
    
    mainGrid = uigridlayout(fig, [4 3]);
    mainGrid.RowHeight = {90, 280, 280, 180};
    mainGrid.ColumnWidth = {'1x', '1x', '1.2x'};
    mainGrid.Padding = [15 15 15 15];
    mainGrid.RowSpacing = 12;
    mainGrid.ColumnSpacing = 12;
    
    controlPanel = uipanel(mainGrid, 'Title', '', ...
                           'BackgroundColor', [0.88 0.92 0.96], ...
                           'BorderType', 'none');
    controlPanel.Layout.Row = 1;
    controlPanel.Layout.Column = [1 3];
    
    controlGrid = uigridlayout(controlPanel, [2 5]);
    controlGrid.RowHeight = {40, 35};
    controlGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
    controlGrid.RowSpacing = 8;
    controlGrid.ColumnSpacing = 10;
    controlGrid.Padding = [10 10 10 10];
    
    btnLoad = uibutton(controlGrid, 'Text', '📁 LOAD FILE', ...
                       'FontSize', 15, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.2 0.5 0.8], ...
                       'FontColor', 'white', ...
                       'ButtonPushedFcn', @(btn,event) loadAudio());
    btnLoad.Layout.Row = 1;
    btnLoad.Layout.Column = 1;
    
    btnPlayOriginal = uibutton(controlGrid, 'Text', '▶️ PLAY ORIGINAL', ...
                               'FontSize', 15, 'FontWeight', 'bold', ...
                               'BackgroundColor', [0.3 0.7 0.3], ...
                               'FontColor', 'white', ...
                               'Enable', 'off', ...
                               'ButtonPushedFcn', @(btn,event) playOriginal());
    btnPlayOriginal.Layout.Row = 1;
    btnPlayOriginal.Layout.Column = 2;
    
    btnPlayResult = uibutton(controlGrid, 'Text', '▶️ PLAY RESULT', ...
                             'FontSize', 15, 'FontWeight', 'bold', ...
                             'BackgroundColor', [0.9 0.5 0.1], ...
                             'FontColor', 'white', ...
                             'Enable', 'off', ...
                             'ButtonPushedFcn', @(btn,event) playProcessed());
    btnPlayResult.Layout.Row = 1;
    btnPlayResult.Layout.Column = 3;
    
    btnStop = uibutton(controlGrid, 'Text', '⏹️ STOP', ...
                       'FontSize', 15, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.8 0.2 0.2], ...
                       'FontColor', 'white', ...
                       'Enable', 'off', ...
                       'ButtonPushedFcn', @(btn,event) stopPlaying());
    btnStop.Layout.Row = 1;
    btnStop.Layout.Column = 4;
    
    btnSave = uibutton(controlGrid, 'Text', '💾 SAVE FILE', ...
                       'FontSize', 15, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.6 0.2 0.6], ...
                       'FontColor', 'white', ...
                       'Enable', 'off', ...
                       'ButtonPushedFcn', @(btn,event) saveAudio());
    btnSave.Layout.Row = 1;
    btnSave.Layout.Column = 5;
    
    lblStatus = uilabel(controlGrid, 'Text', 'Status: No file loaded', ...
                        'FontSize', 12, ...
                        'HorizontalAlignment', 'left', ...
                        'FontColor', [0.3 0.3 0.3]);
    lblStatus.Layout.Row = 2;
    lblStatus.Layout.Column = [1 3];
    
    btnProcess = uibutton(controlGrid, 'Text', '⚙️ PROCESS AUDIO', ...
                          'FontSize', 15, 'FontWeight', 'bold', ...
                          'BackgroundColor', [0.1 0.6 0.2], ...
                          'FontColor', 'white', ...
                          'Enable', 'off', ...
                          'ButtonPushedFcn', @(btn,event) processAudio());
    btnProcess.Layout.Row = 2;
    btnProcess.Layout.Column = [4 5];
    
    panel1 = uipanel(mainGrid, 'Title', 'PROJECT 1: Distortion Meter', ...
                     'FontSize', 12, 'FontWeight', 'bold', ...
                     'BackgroundColor', [1 0.96 0.96]);
    panel1.Layout.Row = 2;
    panel1.Layout.Column = 1;
    
    grid1 = uigridlayout(panel1, [5 2]);
    grid1.RowHeight = {35, 35, 35, 35, '1x'};
    grid1.ColumnWidth = {140, '1x'};
    grid1.RowSpacing = 8;
    grid1.Padding = [15 15 15 15];
    
    chkDistortion = uicheckbox(grid1, 'Text', '✓ Enable Distortion Analysis', ...
                               'FontSize', 11, 'FontWeight', 'bold');
    chkDistortion.Layout.Row = 1;
    chkDistortion.Layout.Column = [1 2];
    chkDistortion.ValueChangedFcn = @(src,event) updateSummary();
    
    uilabel(grid1, 'Text', 'Clip Level:', 'FontSize', 10);
    editClipLevel = uieditfield(grid1, 'numeric', 'Value', 0.8, 'Limits', [0 1]);
    editClipLevel.ValueChangedFcn = @(src,event) updateSummary();
    
    uilabel(grid1, 'Text', ' ', 'FontSize', 1);
    uilabel(grid1, 'Text', ' ', 'FontSize', 1);
    
    uilabel(grid1, 'Text', '📊 THD Result:', ...
            'FontSize', 11, 'FontWeight', 'bold');
    lblDistortion = uilabel(grid1, 'Text', 'N/A', ...
                            'FontSize', 13, 'FontWeight', 'bold', ...
                            'FontColor', [0.8 0 0]);
    
    panel2 = uipanel(mainGrid, 'Title', 'PROJECT 2: Bass Amplifier', ...
                     'FontSize', 12, 'FontWeight', 'bold', ...
                     'BackgroundColor', [0.96 1 0.96]);
    panel2.Layout.Row = 2;
    panel2.Layout.Column = 2;
    
    grid2 = uigridlayout(panel2, [7 2]);
    grid2.RowHeight = {35, 35, 35, 35, 35, 35, '1x'};
    grid2.ColumnWidth = {140, '1x'};
    grid2.RowSpacing = 8;
    grid2.Padding = [15 15 15 15];
    
    chkBass = uicheckbox(grid2, 'Text', '✓ Enable Bass Boost', ...
                         'FontSize', 11, 'FontWeight', 'bold');
    chkBass.Layout.Row = 1;
    chkBass.Layout.Column = [1 2];
    chkBass.ValueChangedFcn = @(src,event) updateSummary();
    
    uilabel(grid2, 'Text', 'LPF Cutoff (Hz):', 'FontSize', 10);
    editCutoff = uieditfield(grid2, 'numeric', 'Value', 250, 'Limits', [20 1000]);
    editCutoff.ValueChangedFcn = @(src,event) updateSummary();
    
    uilabel(grid2, 'Text', 'Filter Order:', 'FontSize', 10);
    editOrder = uieditfield(grid2, 'numeric', 'Value', 20, 'Limits', [10 100]);
    editOrder.ValueChangedFcn = @(src,event) updateSummary();
    
    uilabel(grid2, 'Text', 'Bass Gain:', 'FontSize', 10);
    lblGain = uilabel(grid2, 'Text', '30.0', ...
                      'FontSize', 12, 'FontWeight', 'bold', ...
                      'HorizontalAlignment', 'center');
    
    uilabel(grid2, 'Text', 'Gain Slider:', 'FontSize', 10);
    sliderGain = uislider(grid2, 'Limits', [0 40], 'Value', 30);
    sliderGain.ValueChangedFcn = @(sld,event) updateGainDisplay();
    
    panel3 = uipanel(mainGrid, 'Title', 'PROJECT 3: Echo Generator', ...
                     'FontSize', 12, 'FontWeight', 'bold', ...
                     'BackgroundColor', [0.96 0.96 1]);
    panel3.Layout.Row = 3;
    panel3.Layout.Column = 1;
    
    grid3 = uigridlayout(panel3, [6 2]);
    grid3.RowHeight = {35, 35, 35, 35, 35, '1x'};
    grid3.ColumnWidth = {140, '1x'};
    grid3.RowSpacing = 8;
    grid3.Padding = [15 15 15 15];
    
    chkEcho = uicheckbox(grid3, 'Text', '✓ Enable Echo Effect', ...
                         'FontSize', 11, 'FontWeight', 'bold');
    chkEcho.Layout.Row = 1;
    chkEcho.Layout.Column = [1 2];
    chkEcho.ValueChangedFcn = @(src,event) updateSummary();
    
    uilabel(grid3, 'Text', 'Echo Delay (ms):', 'FontSize', 10);
    editDelay = uieditfield(grid3, 'numeric', 'Value', 500, 'Limits', [50 2000]);
    editDelay.ValueChangedFcn = @(src,event) updateSummary();
    
    uilabel(grid3, 'Text', 'Echo Alpha:', 'FontSize', 10);
    lblAlpha = uilabel(grid3, 'Text', '0.60', ...
                       'FontSize', 12, 'FontWeight', 'bold', ...
                       'HorizontalAlignment', 'center');
    
    uilabel(grid3, 'Text', 'Alpha Slider:', 'FontSize', 10);
    sliderAlpha = uislider(grid3, 'Limits', [0 1], 'Value', 0.6);
    sliderAlpha.ValueChangedFcn = @(sld,event) updateAlphaDisplay();
    
    panelViz = uipanel(mainGrid, 'Title', 'Signal Visualization', ...
                       'FontSize', 12, 'FontWeight', 'bold', ...
                       'BackgroundColor', [1 1 0.96]);
    panelViz.Layout.Row = [2 3];
    panelViz.Layout.Column = 3;
    
    gridViz = uigridlayout(panelViz, [2 1]);
    gridViz.RowHeight = {'1x', '1x'};
    gridViz.Padding = [10 10 10 10];
    
    ax1 = uiaxes(gridViz);
    title(ax1, 'Time Domain Signal', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(ax1, 'Time (s)');
    ylabel(ax1, 'Amplitude');
    grid(ax1, 'on');
    
    ax2 = uiaxes(gridViz);
    title(ax2, 'Frequency Spectrum', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(ax2, 'Frequency (Hz)');
    ylabel(ax2, 'Magnitude (dB)');
    grid(ax2, 'on');
    
    summaryPanel = uipanel(mainGrid, 'Title', 'Current Parameters', ...
                           'FontSize', 11, 'FontWeight', 'bold', ...
                           'BackgroundColor', [1 0.98 0.96]);
    summaryPanel.Layout.Row = 3;
    summaryPanel.Layout.Column = 2;
    
    gridSummary = uigridlayout(summaryPanel, [9 1]);
    gridSummary.RowHeight = repmat({25}, 1, 9);
    gridSummary.Padding = [15 10 15 10];
    gridSummary.RowSpacing = 5;
    
    uilabel(gridSummary, 'Text', '📊 SAMPLE RATE:', ...
            'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0.3 0.3 0.3]);
    lblSumSampleRate = uilabel(gridSummary, 'Text', '  N/A', 'FontSize', 9);
    
    uilabel(gridSummary, 'Text', '⚙️ DISTORTION SETTINGS:', ...
            'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0.6 0 0]);
    lblSumDist = uilabel(gridSummary, 'Text', '  Disabled', 'FontSize', 9);
    
    uilabel(gridSummary, 'Text', '⚙️ BASS BOOST SETTINGS:', ...
            'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0 0.5 0]);
    lblSumBass = uilabel(gridSummary, 'Text', '  Disabled', 'FontSize', 9);
    
    uilabel(gridSummary, 'Text', '⚙️ ECHO SETTINGS:', ...
            'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0 0 0.6]);
    lblSumEcho = uilabel(gridSummary, 'Text', '  Disabled', 'FontSize', 9);
    
    function updateGainDisplay()
        lblGain.Text = sprintf('%.1f', sliderGain.Value);
        updateSummary();
    end
    
    function updateAlphaDisplay()
        lblAlpha.Text = sprintf('%.2f', sliderAlpha.Value);
        updateSummary();
    end
    
    function updateSummary()
        if chkDistortion.Value
            lblSumDist.Text = sprintf('  Clip Level=%.2f', editClipLevel.Value);
        else
            lblSumDist.Text = '  Disabled';
        end
        
        if chkBass.Value
            lblSumBass.Text = sprintf('  Cutoff=%dHz, Order=%d, Gain=%.1f', ...
                editCutoff.Value, editOrder.Value, sliderGain.Value);
        else
            lblSumBass.Text = '  Disabled';
        end
        
        if chkEcho.Value
            lblSumEcho.Text = sprintf('  Delay=%dms, Alpha=%.2f', ...
                editDelay.Value, sliderAlpha.Value);
        else
            lblSumEcho.Text = '  Disabled';
        end
    end
    
    function stopPlaying()
        if ~isempty(audioPlayer)
            stop(audioPlayer);
            clear sound;
        end
        lblStatus.Text = 'Status: ⏹️ Playback stopped';
        btnStop.Enable = 'off';
    end
    
    function loadAudio()
        [filename, pathname] = uigetfile({'*.mp3;*.wav;*.m4a', 'Audio Files (*.mp3, *.wav, *.m4a)'}, ...
                                         'Select Audio File');
        if filename == 0
            return;
        end
        
        try
            lblStatus.Text = 'Status: ⏳ Loading file...';
            drawnow;
            
            [inputSignal, Fs] = audioread(fullfile(pathname, filename));
            
            if size(inputSignal, 2) > 1
                inputSignal = mean(inputSignal, 2);
            end
            
            btnPlayOriginal.Enable = 'on';
            btnProcess.Enable = 'on';
            
            duration = length(inputSignal) / Fs;
            lblStatus.Text = sprintf('Status: ✅ Loaded "%s" (%.2f sec @ %d Hz)', filename, duration, Fs);
            lblDuration.Text = sprintf('%.2f seconds', duration);
            lblInputSamples.Text = sprintf('%d samples', length(inputSignal));
            lblOutputSamples.Text = 'N/A (not processed yet)';
            lblPeakAmplitude.Text = sprintf('±%.4f (original)', max(abs(inputSignal)));
            lblSampleRate.Text = sprintf('%d Hz', Fs);
            lblSumSampleRate.Text = sprintf('  %d Hz', Fs);
            
            t = (0:length(inputSignal)-1)/Fs;
            plot(ax1, t, inputSignal, 'b', 'LineWidth', 1);
            title(ax1, 'Original Signal - Time Domain', 'FontWeight', 'bold');
            
            plotSpectrum(inputSignal, Fs, ax2, 'Original');
            
            uialert(fig, sprintf('Audio file loaded successfully!\n\nFile: %s\nDuration: %.2f seconds\nSample Rate: %d Hz', ...
                filename, duration, Fs), 'Success', 'Icon', 'success');
        catch ME
            lblStatus.Text = 'Status: ❌ Error loading file';
            uialert(fig, ['Error loading file: ' ME.message], 'Error', 'Icon', 'error');
        end
    end
    
    function processAudio()
        if isempty(inputSignal)
            uialert(fig, 'Please load an audio file first!', 'Warning', 'Icon', 'warning');
            return;
        end
        
        if ~chkDistortion.Value && ~chkBass.Value && ~chkEcho.Value
            uialert(fig, 'Please enable at least one effect!', 'Warning', 'Icon', 'warning');
            return;
        end
        
        lblStatus.Text = 'Status: ⚙️ Processing...';
        drawnow;
        
        processedSignal = inputSignal;
        distortionValue = 0;
        effectsApplied = {};
        
        if chkDistortion.Value
            [processedSignal, distortionValue] = applyDistortion(processedSignal, Fs, editClipLevel.Value);
            lblDistortion.Text = sprintf('%.2f%%', distortionValue);
            effectsApplied{end+1} = sprintf('Distortion (Clip=%.2f, THD=%.2f%%)', ...
                editClipLevel.Value, distortionValue);
        else
            lblDistortion.Text = 'N/A';
        end
        
        if chkBass.Value
            processedSignal = applyBassBoost(processedSignal, Fs, ...
                editCutoff.Value, editOrder.Value, sliderGain.Value);
            effectsApplied{end+1} = sprintf('Bass Boost (Gain=%.1f)', sliderGain.Value);
        end
        
        if chkEcho.Value
            processedSignal = applyEcho(processedSignal, Fs, ...
                editDelay.Value/1000, sliderAlpha.Value);
            effectsApplied{end+1} = sprintf('Echo (Delay=%dms)', round(editDelay.Value));
        end
        
        t = (0:length(processedSignal)-1)/Fs;
        plot(ax1, t, processedSignal, 'r', 'LineWidth', 1);
        title(ax1, 'Processed Signal - Time Domain', 'FontWeight', 'bold');
        
        plotSpectrum(processedSignal, Fs, ax2, 'Processed');
        
        lblOutputSamples.Text = sprintf('%d samples', length(processedSignal));
        
        peakAmp = max(abs(processedSignal));
        lblPeakAmplitude.Text = sprintf('±%.4f (processed)', peakAmp);
        
        btnPlayResult.Enable = 'on';
        btnSave.Enable = 'on';
        
        lblStatus.Text = sprintf('Status: ✅ Processing complete! [%s]', strjoin(effectsApplied, ' + '));
        
        warningMsg = sprintf('Processing complete!\n\nEffects applied:\n• %s\n\nPeak Amplitude: ±%.4f', ...
            strjoin(effectsApplied, '\n• '), peakAmp);
        
        if peakAmp > 1
            warningMsg = sprintf('%s\n\n⚠️ WARNING: Signal amplitude exceeds ±1\nPlayback may be distorted or clipped by audio hardware.', warningMsg);
        end
        
        uialert(fig, warningMsg, 'Success', 'Icon', 'success');
    end
    
    function playOriginal()
        if ~isempty(inputSignal)
            lblStatus.Text = 'Status: ▶️ Playing original...';
            drawnow;
            playSignal = inputSignal;
            if max(abs(playSignal)) > 1
                playSignal = playSignal / max(abs(playSignal));
            end
            audioPlayer = audioplayer(playSignal, Fs);
            play(audioPlayer);
            btnStop.Enable = 'on';
        end
    end
    
    function playProcessed()
        if ~isempty(processedSignal)
            lblStatus.Text = 'Status: ▶️ Playing processed result...';
            drawnow;
            playSignal = processedSignal;
            if max(abs(playSignal)) > 1
                playSignal = playSignal / max(abs(playSignal));
            end
            audioPlayer = audioplayer(playSignal, Fs);
            play(audioPlayer);
            btnStop.Enable = 'on';
        end
    end
    
    function saveAudio()
        if isempty(processedSignal)
            uialert(fig, 'No processed audio to save!', 'Warning', 'Icon', 'warning');
            return;
        end
        
        [filename, pathname] = uiputfile('*.wav', 'Save Processed Audio');
        if filename ~= 0
            try
                audiowrite(fullfile(pathname, filename), processedSignal, Fs);
                lblStatus.Text = sprintf('Status: ✅ Saved to "%s"', filename);
                uialert(fig, sprintf('Audio saved successfully!\n\nFile: %s', filename), ...
                        'Success', 'Icon', 'success');
            catch ME
                lblStatus.Text = 'Status: ❌ Error saving file';
                uialert(fig, ['Error saving file: ' ME.message], 'Error', 'Icon', 'error');
            end
        end
    end
end

% Project 1: Distortion Meter
function [outputSignal, distortionPercent] = applyDistortion(inputSignal, Fs, clipLevel)
    outputSignal = min(max(inputSignal, -clipLevel), clipLevel);
    
    clippedSignal = outputSignal;
    clippedSignal = clippedSignal - mean(clippedSignal);

    N = length(clippedSignal);
    window = hamming(N);
    cg = sum(window)/N;
    xw = clippedSignal .* window;

    Y = fft(xw);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    P1 = P1 / cg;

    f = Fs*(0:N/2)/N;

    [A1, fundIdx] = max(P1(2:end));
    fundIdx = fundIdx + 1;
    f0 = f(fundIdx);
    
    harmonicPower = 0;
    for k = 2:10
        fk = k * f0;
        if fk > Fs/2
            break;
        end
        [~, idx] = min(abs(f - fk));
        harmonicPower = harmonicPower + P1(idx)^2;
    end

    if A1 > 0
        distortionPercent = 100 * sqrt(harmonicPower) / A1;
    else
        distortionPercent = 0;
    end
end

% Project 2: Bass Amplifier
function outputSignal = applyBassBoost(inputSignal, Fs, cutoffFreq, filterOrder, gain)
    cutoff_normalized = cutoffFreq / (Fs/2);
    b = fir1(filterOrder, cutoff_normalized, 'low');
    
    bassFrequencies = filter(b, 1, inputSignal);
    
    amplifiedBass = bassFrequencies * gain;
    
    outputSignal = inputSignal - bassFrequencies + amplifiedBass;
end

% Project 3: Echo Generator
function outputSignal = applyEcho(inputSignal, Fs, delaySeconds, alpha)
    nd = round(delaySeconds * Fs);
    extraSamples = round(3 * Fs);
    N = length(inputSignal) + extraSamples;
    outputSignal = zeros(N, 1);
    outputSignal(1:length(inputSignal)) = inputSignal;
    
    for n = (nd+1):N
        if n <= length(inputSignal)
            outputSignal(n) = inputSignal(n) + alpha * outputSignal(n - nd);
        else
            outputSignal(n) = alpha * outputSignal(n - nd);
        end
    end
    
    outputSignal = outputSignal / max(abs(outputSignal) + 1e-10);
end

% Helper: Plot frequency spectrum
function plotSpectrum(signal, Fs, ax, titlePrefix)
    N = length(signal);
    Y = fft(signal);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(N/2))/N;
    P1_dB = 20*log10(P1 + 1e-10);
    
    plot(ax, f, P1_dB, 'LineWidth', 1.5);
    xlim(ax, [0 5000]);
    title(ax, sprintf('%s - Frequency Spectrum', titlePrefix), 'FontWeight', 'bold');
    xlabel(ax, 'Frequency (Hz)');
    ylabel(ax, 'Magnitude (dB)');
    grid(ax, 'on');
end