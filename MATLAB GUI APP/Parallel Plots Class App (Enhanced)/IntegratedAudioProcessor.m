classdef IntegratedAudioProcessor < matlab.apps.AppBase

% Properties that correspond to app components
properties (Access = public)
UIFigure matlab.ui.Figure
mainGrid matlab.ui.container.GridLayout
controlPanel matlab.ui.container.Panel
controlGrid matlab.ui.container.GridLayout
btnLoad matlab.ui.control.Button
btnPlayOriginal matlab.ui.control.Button
btnPlayResult matlab.ui.control.Button
btnStop matlab.ui.control.Button
btnSave matlab.ui.control.Button
lblStatus matlab.ui.control.Label
btnProcess matlab.ui.control.Button
panel1 matlab.ui.container.Panel
grid1 matlab.ui.container.GridLayout
chkDistortion matlab.ui.control.CheckBox
editClipLevel matlab.ui.control.NumericEditField
lblDistortion matlab.ui.control.Label
panel2 matlab.ui.container.Panel
grid2 matlab.ui.container.GridLayout
chkBass matlab.ui.control.CheckBox
editCutoff matlab.ui.control.NumericEditField
editOrder matlab.ui.control.NumericEditField
lblGain matlab.ui.control.Label
sliderGain matlab.ui.control.Slider
panel3 matlab.ui.container.Panel
grid3 matlab.ui.container.GridLayout
chkEcho matlab.ui.control.CheckBox
editDelay matlab.ui.control.NumericEditField
lblAlpha matlab.ui.control.Label
sliderAlpha matlab.ui.control.Slider
panelViz matlab.ui.container.Panel
gridViz matlab.ui.container.GridLayout
ax1 matlab.ui.control.UIAxes
ax2 matlab.ui.control.UIAxes
ax3 matlab.ui.control.UIAxes
ax4 matlab.ui.control.UIAxes
summaryPanel matlab.ui.container.Panel
gridSummary matlab.ui.container.GridLayout
lblSumSampleRate matlab.ui.control.Label
lblSumDist matlab.ui.control.Label
lblSumBass matlab.ui.control.Label
lblSumEcho matlab.ui.control.Label
end

% Private properties for data storage
properties (Access = private)
inputSignal = []
processedSignal = []
Fs = 44100
audioPlayer = []
end

% Callbacks that handle component events
methods (Access = private)

% Button pushed function: btnLoad
function loadAudioCallback(app, event)
[filename, pathname] = uigetfile({'*.mp3;*.wav;*.m4a', 'Audio Files (*.mp3, *.wav, *.m4a)'}, ...
'Select Audio File');
if filename == 0
return;
end

try
app.lblStatus.Text = 'Status: ⏳ Loading file...';
drawnow;

[app.inputSignal, app.Fs] = audioread(fullfile(pathname, filename));

% Convert stereo to mono
if size(app.inputSignal, 2) > 1
app.inputSignal = mean(app.inputSignal, 2);
end

app.btnPlayOriginal.Enable = 'on';
app.btnProcess.Enable = 'on';

duration = length(app.inputSignal) / app.Fs;
app.lblStatus.Text = sprintf('Status: ✅ Loaded "%s" (%.2f sec @ %d Hz)', filename, duration, app.Fs);
app.lblSumSampleRate.Text = sprintf('  %d Hz', app.Fs);

% Plot time domain
t = (0:length(app.inputSignal)-1)/app.Fs;
plot(app.ax1, t, app.inputSignal, 'b', 'LineWidth', 1);
title(app.ax1, 'Original - Time Domain', 'FontWeight', 'bold');

% Plot frequency spectrum
plotSpectrum(app, app.inputSignal, app.Fs, app.ax2, 'Original');

uialert(app.UIFigure, sprintf('Audio file loaded!\n\nFile: %s\nDuration: %.2f sec\nSample Rate: %d Hz', ...
filename, duration, app.Fs), 'Success', 'Icon', 'success');
catch ME
app.lblStatus.Text = 'Status: ❌ Error loading file';
uialert(app.UIFigure, ['Error: ' ME.message], 'Error', 'Icon', 'error');
end
end

% Button pushed function: btnProcess
function processAudioCallback(app, event)
if isempty(app.inputSignal)
uialert(app.UIFigure, 'Please load an audio file first!', 'Warning', 'Icon', 'warning');
return;
end

if ~app.chkDistortion.Value && ~app.chkBass.Value && ~app.chkEcho.Value
uialert(app.UIFigure, 'Please enable at least one effect!', 'Warning', 'Icon', 'warning');
return;
end

app.lblStatus.Text = 'Status: ⚙️ Processing...';
drawnow;

app.processedSignal = app.inputSignal;
distortionValue = 0;
effectsApplied = {};

% Apply distortion if enabled
if app.chkDistortion.Value
[app.processedSignal, distortionValue] = applyDistortion(app, app.processedSignal, app.Fs, app.editClipLevel.Value);
app.lblDistortion.Text = sprintf('%.2f%%', distortionValue);
effectsApplied{end+1} = sprintf('Distortion (THD=%.2f%%)', distortionValue);
else
app.lblDistortion.Text = 'N/A';
end

% Apply bass boost if enabled
if app.chkBass.Value
app.processedSignal = applyBassBoost(app, app.processedSignal, app.Fs, ...
app.editCutoff.Value, app.editOrder.Value, app.sliderGain.Value);
effectsApplied{end+1} = sprintf('Bass Boost (Gain=%.1f)', app.sliderGain.Value);
end

% Apply echo if enabled
if app.chkEcho.Value
app.processedSignal = applyEcho(app, app.processedSignal, app.Fs, ...
app.editDelay.Value/1000, app.sliderAlpha.Value);
effectsApplied{end+1} = sprintf('Echo (Delay=%dms)', round(app.editDelay.Value));
end

% Plot results
t = (0:length(app.processedSignal)-1)/app.Fs;
plot(app.ax3, t, app.processedSignal, 'r', 'LineWidth', 1);
title(app.ax3, 'Processed - Time Domain', 'FontWeight', 'bold');

plotSpectrum(app, app.processedSignal, app.Fs, app.ax4, 'Processed');

peakAmp = max(abs(app.processedSignal));

app.btnPlayResult.Enable = 'on';
app.btnSave.Enable = 'on';

app.lblStatus.Text = sprintf('Status: ✅ Done! [%s]', strjoin(effectsApplied, ' + '));

warningMsg = sprintf('Processing complete!\n\nEffects: %s\n\nPeak: ±%.4f', ...
strjoin(effectsApplied, ', '), peakAmp);

if peakAmp > 1
warningMsg = sprintf('%s\n\n⚠️ Signal exceeds ±1\nPlayback may clip.', warningMsg);
end

uialert(app.UIFigure, warningMsg, 'Success', 'Icon', 'success');
end

% Button pushed function: btnPlayOriginal
function playOriginalCallback(app, event)
if ~isempty(app.inputSignal)
app.lblStatus.Text = 'Status: ▶️ Playing original...';
drawnow;
playSignal = app.inputSignal;
if max(abs(playSignal)) > 1
playSignal = playSignal / max(abs(playSignal));
end
app.audioPlayer = audioplayer(playSignal, app.Fs);
play(app.audioPlayer);
app.btnStop.Enable = 'on';
end
end

% Button pushed function: btnPlayResult
function playProcessedCallback(app, event)
if ~isempty(app.processedSignal)
app.lblStatus.Text = 'Status: ▶️ Playing processed...';
drawnow;
playSignal = app.processedSignal;
if max(abs(playSignal)) > 1
playSignal = playSignal / max(abs(playSignal));
end
app.audioPlayer = audioplayer(playSignal, app.Fs);
play(app.audioPlayer);
app.btnStop.Enable = 'on';
end
end

% Button pushed function: btnStop
function stopPlayingCallback(app, event)
if ~isempty(app.audioPlayer)
stop(app.audioPlayer);
clear sound;
end
app.lblStatus.Text = 'Status: ⏹️ Playback stopped';
app.btnStop.Enable = 'off';
end

% Button pushed function: btnSave
function saveAudioCallback(app, event)
if isempty(app.processedSignal)
uialert(app.UIFigure, 'No processed audio to save!', 'Warning', 'Icon', 'warning');
return;
end

[filename, pathname] = uiputfile('*.wav', 'Save Processed Audio');
if filename ~= 0
try
audiowrite(fullfile(pathname, filename), app.processedSignal, app.Fs);
app.lblStatus.Text = sprintf('Status: ✅ Saved to "%s"', filename);
uialert(app.UIFigure, sprintf('Saved!\n\nFile: %s', filename), ...
'Success', 'Icon', 'success');
catch ME
app.lblStatus.Text = 'Status: ❌ Error saving';
uialert(app.UIFigure, ['Error: ' ME.message], 'Error', 'Icon', 'error');
end
end
end

% Value changed function: sliderGain
function updateGainDisplay(app, event)
app.lblGain.Text = sprintf('%.1f', app.sliderGain.Value);
updateSummary(app);
end

% Value changed function: sliderAlpha
function updateAlphaDisplay(app, event)
app.lblAlpha.Text = sprintf('%.2f', app.sliderAlpha.Value);
updateSummary(app);
end

% Value changed function: checkboxes and edit fields
function updateSummary(app, event)
if app.chkDistortion.Value
app.lblSumDist.Text = sprintf('  Clip Level=%.2f', app.editClipLevel.Value);
else
app.lblSumDist.Text = '  Disabled';
end

if app.chkBass.Value
app.lblSumBass.Text = sprintf('  Cutoff=%dHz, Order=%d, Gain=%.1f', ...
app.editCutoff.Value, app.editOrder.Value, app.sliderGain.Value);
else
app.lblSumBass.Text = '  Disabled';
end

if app.chkEcho.Value
app.lblSumEcho.Text = sprintf('  Delay=%dms, Alpha=%.2f', ...
app.editDelay.Value, app.sliderAlpha.Value);
else
app.lblSumEcho.Text = '  Disabled';
end
end

% Project 1: Distortion analysis with THD calculation
function [outputSignal, distortionPercent] = applyDistortion(app, inputSignal, Fs, clipLevel)
% Clip the signal
outputSignal = min(max(inputSignal, -clipLevel), clipLevel);

clippedSignal = outputSignal - mean(outputSignal);

% FFT analysis
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

% Auto-detect fundamental frequency
[A1, fundIdx] = max(P1(2:end));
fundIdx = fundIdx + 1;
f0 = f(fundIdx);

% Calculate harmonic power
harmonicPower = 0;
for k = 2:10
fk = k * f0;
if fk > Fs/2
break;
end
[~, idx] = min(abs(f - fk));
harmonicPower = harmonicPower + P1(idx)^2;
end

% THD calculation
if A1 > 0
distortionPercent = 100 * sqrt(harmonicPower) / A1;
else
distortionPercent = 0;
end
end

% Project 2: Bass boost using FIR filter
function outputSignal = applyBassBoost(app, inputSignal, Fs, cutoffFreq, filterOrder, gain)
% Design low-pass filter
cutoff_normalized = cutoffFreq / (Fs/2);
b = fir1(filterOrder, cutoff_normalized, 'low');

% Extract bass frequencies
bassFrequencies = filter(b, 1, inputSignal);

% Amplify and mix
amplifiedBass = bassFrequencies * gain;
outputSignal = inputSignal - bassFrequencies + amplifiedBass;
end

% Project 3: Echo effect generator
function outputSignal = applyEcho(app, inputSignal, Fs, delaySeconds, alpha)
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
function plotSpectrum(app, signal, Fs, ax, titlePrefix)
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

end

% Component initialization
methods (Access = private)

% Create UIFigure and components
function createComponents(app)

% Create UIFigure and hide until all components are created
app.UIFigure = uifigure('Visible', 'off');
app.UIFigure.Position = [50 50 1500 900];
app.UIFigure.Name = 'Integrated Audio Processing System';
app.UIFigure.Color = [0.95 0.95 0.97];

% Create mainGrid
app.mainGrid = uigridlayout(app.UIFigure);
app.mainGrid.ColumnWidth = {'1x', '1x', '1.2x'};
app.mainGrid.RowHeight = {90, 280, 280, 180};
app.mainGrid.Padding = [15 15 15 15];
app.mainGrid.RowSpacing = 12;
app.mainGrid.ColumnSpacing = 12;

% Create controlPanel
app.controlPanel = uipanel(app.mainGrid);
app.controlPanel.BorderType = 'none';
app.controlPanel.BackgroundColor = [0.88 0.92 0.96];
app.controlPanel.Layout.Row = 1;
app.controlPanel.Layout.Column = [1 3];

% Create controlGrid
app.controlGrid = uigridlayout(app.controlPanel);
app.controlGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
app.controlGrid.RowHeight = {40, 35};
app.controlGrid.RowSpacing = 8;
app.controlGrid.ColumnSpacing = 10;
app.controlGrid.Padding = [10 10 10 10];

% Create btnLoad
app.btnLoad = uibutton(app.controlGrid, 'push');
app.btnLoad.ButtonPushedFcn = createCallbackFcn(app, @loadAudioCallback, true);
app.btnLoad.BackgroundColor = [0.2 0.5 0.8];
app.btnLoad.FontSize = 15;
app.btnLoad.FontWeight = 'bold';
app.btnLoad.FontColor = [1 1 1];
app.btnLoad.Layout.Row = 1;
app.btnLoad.Layout.Column = 1;
app.btnLoad.Text = '📁 LOAD FILE';

% Create btnPlayOriginal
app.btnPlayOriginal = uibutton(app.controlGrid, 'push');
app.btnPlayOriginal.ButtonPushedFcn = createCallbackFcn(app, @playOriginalCallback, true);
app.btnPlayOriginal.BackgroundColor = [0.3 0.7 0.3];
app.btnPlayOriginal.FontSize = 15;
app.btnPlayOriginal.FontWeight = 'bold';
app.btnPlayOriginal.FontColor = [1 1 1];
app.btnPlayOriginal.Enable = 'off';
app.btnPlayOriginal.Layout.Row = 1;
app.btnPlayOriginal.Layout.Column = 2;
app.btnPlayOriginal.Text = '▶️ PLAY ORIGINAL';

% Create btnPlayResult
app.btnPlayResult = uibutton(app.controlGrid, 'push');
app.btnPlayResult.ButtonPushedFcn = createCallbackFcn(app, @playProcessedCallback, true);
app.btnPlayResult.BackgroundColor = [0.9 0.5 0.1];
app.btnPlayResult.FontSize = 15;
app.btnPlayResult.FontWeight = 'bold';
app.btnPlayResult.FontColor = [1 1 1];
app.btnPlayResult.Enable = 'off';
app.btnPlayResult.Layout.Row = 1;
app.btnPlayResult.Layout.Column = 3;
app.btnPlayResult.Text = '▶️ PLAY RESULT';

% Create btnStop
app.btnStop = uibutton(app.controlGrid, 'push');
app.btnStop.ButtonPushedFcn = createCallbackFcn(app, @stopPlayingCallback, true);
app.btnStop.BackgroundColor = [0.8 0.2 0.2];
app.btnStop.FontSize = 15;
app.btnStop.FontWeight = 'bold';
app.btnStop.FontColor = [1 1 1];
app.btnStop.Enable = 'off';
app.btnStop.Layout.Row = 1;
app.btnStop.Layout.Column = 4;
app.btnStop.Text = '⏹️ STOP';

% Create btnSave
app.btnSave = uibutton(app.controlGrid, 'push');
app.btnSave.ButtonPushedFcn = createCallbackFcn(app, @saveAudioCallback, true);
app.btnSave.BackgroundColor = [0.6 0.2 0.6];
app.btnSave.FontSize = 15;
app.btnSave.FontWeight = 'bold';
app.btnSave.FontColor = [1 1 1];
app.btnSave.Enable = 'off';
app.btnSave.Layout.Row = 1;
app.btnSave.Layout.Column = 5;
app.btnSave.Text = '💾 SAVE FILE';

% Create lblStatus
app.lblStatus = uilabel(app.controlGrid);
app.lblStatus.FontSize = 12;
app.lblStatus.FontColor = [0.3 0.3 0.3];
app.lblStatus.Layout.Row = 2;
app.lblStatus.Layout.Column = [1 3];
app.lblStatus.Text = 'Status: No file loaded';

% Create btnProcess
app.btnProcess = uibutton(app.controlGrid, 'push');
app.btnProcess.ButtonPushedFcn = createCallbackFcn(app, @processAudioCallback, true);
app.btnProcess.BackgroundColor = [0.1 0.6 0.2];
app.btnProcess.FontSize = 15;
app.btnProcess.FontWeight = 'bold';
app.btnProcess.FontColor = [1 1 1];
app.btnProcess.Enable = 'off';
app.btnProcess.Layout.Row = 2;
app.btnProcess.Layout.Column = [4 5];
app.btnProcess.Text = '⚙️ PROCESS AUDIO';

% Create panel1 (Distortion Meter)
app.panel1 = uipanel(app.mainGrid);
app.panel1.Title = 'PROJECT 1: Distortion Meter';
app.panel1.BackgroundColor = [1 0.96 0.96];
app.panel1.FontWeight = 'bold';
app.panel1.FontSize = 12;
app.panel1.Layout.Row = 2;
app.panel1.Layout.Column = 1;

% Create grid1
app.grid1 = uigridlayout(app.panel1);
app.grid1.ColumnWidth = {140, '1x'};
app.grid1.RowHeight = {35, 35, 35, 35, '1x'};
app.grid1.RowSpacing = 8;
app.grid1.Padding = [15 15 15 15];

% Create chkDistortion
app.chkDistortion = uicheckbox(app.grid1);
app.chkDistortion.ValueChangedFcn = createCallbackFcn(app, @updateSummary, true);
app.chkDistortion.Text = '✓ Enable Distortion Analysis';
app.chkDistortion.FontSize = 11;
app.chkDistortion.FontWeight = 'bold';
app.chkDistortion.Layout.Row = 1;
app.chkDistortion.Layout.Column = [1 2];

% Create label and editClipLevel
uilabel(app.grid1, 'Text', 'Clip Level:', 'FontSize', 10);
app.editClipLevel = uieditfield(app.grid1, 'numeric');
app.editClipLevel.Limits = [0 1];
app.editClipLevel.ValueChangedFcn = createCallbackFcn(app, @updateSummary, true);
app.editClipLevel.Value = 0.8;

% Spacers
uilabel(app.grid1, 'Text', ' ', 'FontSize', 1);
uilabel(app.grid1, 'Text', ' ', 'FontSize', 1);

% THD Result label
uilabel(app.grid1, 'Text', '📊 THD Result:', 'FontSize', 11, 'FontWeight', 'bold');
app.lblDistortion = uilabel(app.grid1);
app.lblDistortion.FontSize = 13;
app.lblDistortion.FontWeight = 'bold';
app.lblDistortion.FontColor = [0.8 0 0];
app.lblDistortion.Text = 'N/A';

% Create panel2 (Bass Amplifier)
app.panel2 = uipanel(app.mainGrid);
app.panel2.Title = 'PROJECT 2: Bass Amplifier';
app.panel2.BackgroundColor = [0.96 1 0.96];
app.panel2.FontWeight = 'bold';
app.panel2.FontSize = 12;
app.panel2.Layout.Row = 2;
app.panel2.Layout.Column = 2;

% Create grid2
app.grid2 = uigridlayout(app.panel2);
app.grid2.ColumnWidth = {140, '1x'};
app.grid2.RowHeight = {35, 35, 35, 35, 35, 35, '1x'};
app.grid2.RowSpacing = 8;
app.grid2.Padding = [15 15 15 15];

% Create chkBass
app.chkBass = uicheckbox(app.grid2);
app.chkBass.ValueChangedFcn = createCallbackFcn(app, @updateSummary, true);
app.chkBass.Text = '✓ Enable Bass Boost';
app.chkBass.FontSize = 11;
app.chkBass.FontWeight = 'bold';
app.chkBass.Layout.Row = 1;
app.chkBass.Layout.Column = [1 2];

% Create cutoff controls
uilabel(app.grid2, 'Text', 'LPF Cutoff (Hz):', 'FontSize', 10);
app.editCutoff = uieditfield(app.grid2, 'numeric');
app.editCutoff.Limits = [20 1000];
app.editCutoff.ValueChangedFcn = createCallbackFcn(app, @updateSummary, true);
app.editCutoff.Value = 250;

% Create filter order controls
uilabel(app.grid2, 'Text', 'Filter Order:', 'FontSize', 10);
app.editOrder = uieditfield(app.grid2, 'numeric');
app.editOrder.Limits = [10 100];
app.editOrder.ValueChangedFcn = createCallbackFcn(app, @updateSummary, true);
app.editOrder.Value = 20;

% Create gain display
uilabel(app.grid2, 'Text', 'Bass Gain:', 'FontSize', 10);
app.lblGain = uilabel(app.grid2);
app.lblGain.FontSize = 12;
app.lblGain.FontWeight = 'bold';
app.lblGain.HorizontalAlignment = 'center';
app.lblGain.Text = '30.0';

% Create gain slider
uilabel(app.grid2, 'Text', 'Gain Slider:', 'FontSize', 10);
app.sliderGain = uislider(app.grid2);
app.sliderGain.Limits = [0 40];
app.sliderGain.ValueChangedFcn = createCallbackFcn(app, @updateGainDisplay, true);
app.sliderGain.Value = 30;

% Create panel3 (Echo Generator)
app.panel3 = uipanel(app.mainGrid);
app.panel3.Title = 'PROJECT 3: Echo Generator';
app.panel3.BackgroundColor = [0.96 0.96 1];
app.panel3.FontWeight = 'bold';
app.panel3.FontSize = 12;
app.panel3.Layout.Row = 3;
app.panel3.Layout.Column = 1;

% Create grid3
app.grid3 = uigridlayout(app.panel3);
app.grid3.ColumnWidth = {140, '1x'};
app.grid3.RowHeight = {35, 35, 35, 35, 35, '1x'};
app.grid3.RowSpacing = 8;
app.grid3.Padding = [15 15 15 15];

% Create chkEcho
app.chkEcho = uicheckbox(app.grid3);
app.chkEcho.ValueChangedFcn = createCallbackFcn(app, @updateSummary, true);
app.chkEcho.Text = '✓ Enable Echo Effect';
app.chkEcho.FontSize = 11;
app.chkEcho.FontWeight = 'bold';
app.chkEcho.Layout.Row = 1;
app.chkEcho.Layout.Column = [1 2];

% Create delay controls
uilabel(app.grid3, 'Text', 'Echo Delay (ms):', 'FontSize', 10);
app.editDelay = uieditfield(app.grid3, 'numeric');
app.editDelay.Limits = [50 2000];
app.editDelay.ValueChangedFcn = createCallbackFcn(app, @updateSummary, true);
app.editDelay.Value = 500;

% Create alpha display
uilabel(app.grid3, 'Text', 'Echo Alpha:', 'FontSize', 10);
app.lblAlpha = uilabel(app.grid3);
app.lblAlpha.FontSize = 12;
app.lblAlpha.FontWeight = 'bold';
app.lblAlpha.HorizontalAlignment = 'center';
app.lblAlpha.Text = '0.60';

% Create alpha slider
uilabel(app.grid3, 'Text', 'Alpha Slider:', 'FontSize', 10);
app.sliderAlpha = uislider(app.grid3);
app.sliderAlpha.Limits = [0 1];
app.sliderAlpha.ValueChangedFcn = createCallbackFcn(app, @updateAlphaDisplay, true);
app.sliderAlpha.Value = 0.6;

% Create panelViz (Visualization)
app.panelViz = uipanel(app.mainGrid);
app.panelViz.Title = 'Signal Visualization';
app.panelViz.BackgroundColor = [1 1 0.96];
app.panelViz.FontWeight = 'bold';
app.panelViz.FontSize = 12;
app.panelViz.Layout.Row = [2 3];
app.panelViz.Layout.Column = 3;

% Create gridViz
app.gridViz = uigridlayout(app.panelViz);
app.gridViz.RowHeight = {'1x', '1x'};
app.gridViz.ColumnWidth = {'1x', '1x'};
app.gridViz.Padding = [10 10 10 10];

% Create ax1 - Original Time Domain
app.ax1 = uiaxes(app.gridViz);
app.ax1.Layout.Row = 1;
app.ax1.Layout.Column = 1;
title(app.ax1, 'Original - Time Domain');
xlabel(app.ax1, 'Time (s)');
ylabel(app.ax1, 'Amplitude');
grid(app.ax1, 'on');

% Create ax2 - Original Frequency
app.ax2 = uiaxes(app.gridViz);
app.ax2.Layout.Row = 1;
app.ax2.Layout.Column = 2;
title(app.ax2, 'Original - Frequency Spectrum');
xlabel(app.ax2, 'Frequency (Hz)');
ylabel(app.ax2, 'Magnitude (dB)');
grid(app.ax2, 'on');

% Create ax3 - Processed Time Domain
app.ax3 = uiaxes(app.gridViz);
app.ax3.Layout.Row = 2;
app.ax3.Layout.Column = 1;
title(app.ax3, 'Processed - Time Domain');
xlabel(app.ax3, 'Time (s)');
ylabel(app.ax3, 'Amplitude');
grid(app.ax3, 'on');

% Create ax4 - Processed Frequency
app.ax4 = uiaxes(app.gridViz);
app.ax4.Layout.Row = 2;
app.ax4.Layout.Column = 2;
title(app.ax4, 'Processed - Frequency Spectrum');
xlabel(app.ax4, 'Frequency (Hz)');
ylabel(app.ax4, 'Magnitude (dB)');
grid(app.ax4, 'on');

% Create summaryPanel
app.summaryPanel = uipanel(app.mainGrid);
app.summaryPanel.Title = 'Current Parameters';
app.summaryPanel.BackgroundColor = [1 0.98 0.96];
app.summaryPanel.FontWeight = 'bold';
app.summaryPanel.FontSize = 11;
app.summaryPanel.Layout.Row = 3;
app.summaryPanel.Layout.Column = 2;

% Create gridSummary
app.gridSummary = uigridlayout(app.summaryPanel);
app.gridSummary.RowHeight = repmat({25}, 1, 9);
app.gridSummary.Padding = [15 10 15 10];
app.gridSummary.RowSpacing = 5;

% Summary labels
uilabel(app.gridSummary, 'Text', '📊 SAMPLE RATE:', ...
'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0.3 0.3 0.3]);
app.lblSumSampleRate = uilabel(app.gridSummary);
app.lblSumSampleRate.Text = '  N/A';
app.lblSumSampleRate.FontSize = 9;

uilabel(app.gridSummary, 'Text', '⚙️ DISTORTION SETTINGS:', ...
'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0.6 0 0]);
app.lblSumDist = uilabel(app.gridSummary);
app.lblSumDist.Text = '  Disabled';
app.lblSumDist.FontSize = 9;

uilabel(app.gridSummary, 'Text', '⚙️ BASS BOOST SETTINGS:', ...
'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0 0.5 0]);
app.lblSumBass = uilabel(app.gridSummary);
app.lblSumBass.Text = '  Disabled';
app.lblSumBass.FontSize = 9;

uilabel(app.gridSummary, 'Text', '⚙️ ECHO SETTINGS:', ...
'FontSize', 10, 'FontWeight', 'bold', 'FontColor', [0 0 0.6]);
app.lblSumEcho = uilabel(app.gridSummary);
app.lblSumEcho.Text = '  Disabled';
app.lblSumEcho.FontSize = 9;

% Show the figure after all components are created
app.UIFigure.Visible = 'on';
end
end

% App creation and deletion
methods (Access = public)

% Construct app
function app = IntegratedAudioProcessor

% Create UIFigure and components
createComponents(app)

% Register the app with App Designer
registerApp(app, app.UIFigure)

if nargout == 0
clear app
end
end

% Code that executes before app deletion
function delete(app)

% Delete UIFigure when app is deleted
delete(app.UIFigure)
end
end
end