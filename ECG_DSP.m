% Parameters
Fs = 44100;             % Sampling frequency (samples per second)
nBits = 16;             % Bits per sample
nChannels = 1;          % Number of audio channels (1 = mono, 2 = stereo)
recordTime = 4;         % Duration to record in each loop (seconds)
cutoffFreq = 20;        % Low-pass filter cutoff frequency (Hz)
triggerThreshold = 0.02; % Trigger threshold for peak detection

% Create audiorecorder object
recObj = audiorecorder(Fs, nBits, nChannels);

% Design low-pass filter
lpFilter = designfilt('lowpassiir', 'FilterOrder', 8, ...
    'HalfPowerFrequency', cutoffFreq, 'SampleRate', Fs);


% Setup figure for live plot
fig = figure('Position', [0, 0, 900, 800]); 

ax1 = subplot(2, 1, 1); % Top plot for raw signal
xlabel(ax1, 'Time (s)');
ylabel(ax1, 'Amplitude');
title(ax1, 'Raw ECG Signal');
grid(ax1, 'on');

ax2 = subplot(2, 1, 2); % Bottom plot for filtered signal
xlabel(ax2, 'Time (s)');
ylabel(ax2, 'Amplitude');
title(ax2, 'Filtered ECG Signal');
grid(ax2, 'on');

% Initialize stop flag
global stopFlag;
stopFlag = false;

% Set up the figure CloseRequestFcn to stop the loop
set(fig, 'CloseRequestFcn', @(src, event) closeFigure(src));

% Live monitoring loop
try
    while ~stopFlag
        % Start recording
        recordblocking(recObj, recordTime);
        
        % Retrieve audio data
        audioData = getaudiodata(recObj);
        
        % Apply low-pass filter
        filteredData = filter(lpFilter, audioData);
        
        % Time axis for plot
        t = linspace(0, recordTime, length(filteredData));
        
        % Update raw signal plot
        plot(ax1, t, audioData);
        xlabel(ax1, 'Time (s)');
        ylabel(ax1, 'Amplitude');
        title(ax1, 'Raw ECG Signal');
        xlim(ax1, [0 recordTime]);
        grid(ax1, 'on');
        
        % Update filtered signal plot
        plot(ax2, t, filteredData);
        xlabel(ax2, 'Time (s)');
        ylabel(ax2, 'Amplitude');
        title(ax2, 'Filtered ECG Signal');
        xlim(ax2, [0 recordTime]);
        grid(ax2, 'on');
        
        % Add trigger line to filtered signal plot
        hold(ax2, 'on');
        yLimits = ylim(ax2);
        plot(ax2, [0 recordTime], [triggerThreshold triggerThreshold], 'r--', 'LineWidth', 1.5);
        hold(ax2, 'off');
        
        % Peak detection using trigger threshold
        peakIndices = find(filteredData > triggerThreshold);
        
        
        if length(peakIndices) > 1
            % Smooth the data for better peak detection
            smoothedData = smoothdata(filteredData, 'gaussian', 5);
            
        
            
            % Find peaks in smoothed data
            [pks, locs] = findpeaks(smoothedData, 'MinPeakHeight', triggerThreshold, 'MinPeakDistance', Fs/5);
            
            if length(locs) > 1
                
                % Peak amplitude
                peakAmplitude = max(pks);
                
                % Define the window size for noise estimation (in samples)
                noiseWindow = 0.1 * Fs; % Adjust this value as needed
                
                % Calculate SNR1 (Before Filtering)
                % Estimate noise as the standard deviation of the signal in non-peak regions
                peakIndices = locs; % Indices of detected peaks
                if ~isempty(peakIndices)
                    % Remove peak regions for noise estimation
                    noiseDataBefore = audioData;
                    noiseDataBefore(peakIndices) = NaN; % Replace peak regions with NaN
                    % Calculate standard deviation of the remaining signal (excluding NaN values)
                    noiseStdBefore = std(noiseDataBefore(~isnan(noiseDataBefore)));
                    % Calculate mean peak amplitude
                    meanPeakAmplitude = mean(pks);
                    % Calculate SNR before filtering
                    snr1 = 20 * log10(meanPeakAmplitude / noiseStdBefore);
                else
                    snr1 = NaN; % Not enough peaks for SNR calculation
                end
                
                % Calculate SNR2 (After Filtering)
                % Estimate noise as the standard deviation of the filtered signal in non-peak regions
                if ~isempty(peakIndices)
                    % Remove peak regions for noise estimation
                    noiseDataAfter = filteredData;
                    noiseDataAfter(peakIndices) = NaN; % Replace peak regions with NaN
                    % Calculate standard deviation of the remaining signal (excluding NaN values)
                    noiseStdAfter = std(noiseDataAfter(~isnan(noiseDataAfter)));
                    % Calculate mean peak amplitude (use peaks detected in filtered signal)
                    meanPeakAmplitude = mean(pks);
                    % Calculate SNR after filtering
                    snr2 = 20 * log10(meanPeakAmplitude / noiseStdAfter);
                else
                    snr2 = NaN; % Not enough peaks for SNR calculation
                end
                
                % Calculate intervals between detected peaks
                peakTimes = t(locs);
                periods = diff(peakTimes);
                
                % Calculate average period
                avgPeriod = mean(periods);
                
                % Calculate frequency from average period
                freq = 1 ./ avgPeriod; % Frequency in Hz
                
                % Calculate BPM (assuming one beat per period)
                bpm = 60 * freq; % Convert frequency to BPM
                
            else
                % If fewer than 2 peaks, set frequency, BPM, and period to NaN
                freq = NaN;
                bpm = NaN;
                avgPeriod = NaN;
                peakAmplitude = NaN;
                snr1 = NaN;
                snr2 = NaN;
            end
        else
            % If fewer than 2 detected points, set frequency, BPM, and period to NaN
            freq = NaN;
            bpm = NaN;
            avgPeriod = NaN;
        end
        
        % Display the calculated frequency, BPM, and period as text
        if isnan(freq) || isnan(bpm) || isnan(avgPeriod) || isnan(peakAmplitude) || isnan(snr2)
            freqText = 'Frequency: Not enough data';
            bpmText = 'BPM: Not enough data';
            periodText = 'Period: Not enough data';
            peakAmplitudeText = 'Peak Amplitude: Not enough data';
            snrText1 = 'SNR1: Not enough data';
            snrText2 = 'SNR2: Not enough data';
        else
            freqText = ['Frequency: ', num2str(freq, '%.2f'), ' Hz'];
            bpmText = ['BPM: ', num2str(bpm, '%.2f')];
            periodText = ['Period: ', num2str(avgPeriod, '%.2f'), ' s'];
            peakAmplitudeText = ['Peak Amplitude: ', num2str(peakAmplitude, '%.2f')];
            snrText1 = ['SNR1: ', num2str(snr1, '%.2f'), ' dB'];
            snrText2 = ['SNR2: ', num2str(snr2, '%.2f'), ' dB'];
        end
        
        % Display frequency, BPM, period, peak amplitude, and SNR text on the figure
        annotation(fig, 'textbox', [0.68, 0.25, 0.3, 0.2], 'String', {freqText, bpmText, periodText, peakAmplitudeText, snrText1, snrText2}, ...
            'FitBoxToText', 'on', 'BackgroundColor', 'white');
        
        drawnow;
        
    end
catch ME
    disp('Error occurred:');
    disp(ME.message);
end

% Cleanup
clear recObj;
disp('Monitoring stopped.');

% Function to set stop flag when figure is closed
function closeFigure(fig)
    global stopFlag
    stopFlag = true;
    delete(fig);
end