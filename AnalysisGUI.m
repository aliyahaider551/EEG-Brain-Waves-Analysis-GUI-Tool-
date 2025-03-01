function AnalysisGUI
    fig = uifigure('Name', 'EEG Analysis Tool', 'Position', [100 100 1000 600]);
    
  


    uibutton(fig, 'Text', 'Load EDF File', ...
        'Position', [20 550 100 30], ...
        'ButtonPushedFcn', @loadEDFFile);
    
    


    channelDropdown = uidropdown(fig, ...
        'Items', {'Select Channel'}, ...
        'Position', [140 550 150 30], ...
        'ValueChangedFcn', @changeChannel);
    
    




    statusText = uilabel(fig, 'Position', [320 550 500 30], ...
        'Text', 'Ready to load EDF file...');
    
   

    timeSlider = uislider(fig, ...
        'Position', [20 500 960 3], ...
        'Limits', [0 1], ... 
        'ValueChangedFcn', @updateTimeWindow);
    timeSlider.Visible = 'off';





    
    


    tgroup = uitabgroup(fig, 'Position', [10 50 980 440]);
    tab1 = uitab(tgroup, 'Title', 'Raw Data');
    tab2 = uitab(tgroup, 'Title', 'Filtered Data');
    tab3 = uitab(tgroup, 'Title', 'Brain Waves');
    tab4 = uitab(tgroup, 'Title', 'Power Spectral Density');

   



    rawAxes = uiaxes(tab1, 'Position', [10 10 950 400]);
    filteredAxes = uiaxes(tab2, 'Position', [10 10 950 400]);

    



    brainWavesAxes = gobjects(1, 5);
    brainWaveNames = {'Delta (0.5-4 Hz)', 'Theta (4-8 Hz)', 'Alpha (8-13 Hz)', 'Beta (13-30 Hz)', 'Gamma (30-50 Hz)'};
    for i = 1:5
        brainWavesAxes(i) = uiaxes(tab3, 'Position', [10, 400 - (i * 80), 950, 75]);
    end

    




    psdAxes = uiaxes(tab4, 'Position', [10 10 950 400]);

    


    fig.UserData = struct('EEGData', [], 'Fs', [], 'SelectedChannel', 1, ...
        'FilteredData', [], 'BrainWaves', struct(), ...
        'rawAxes', rawAxes, 'filteredAxes', filteredAxes, ...
        'brainWavesAxes', brainWavesAxes, 'psdAxes', psdAxes, ...
        'channelDropdown', channelDropdown, 'statusText', statusText, ...
        'timeSlider', timeSlider, 'timeWindow', 5); 






    function loadEDFFile(~, ~)
        try
            [filename, pathname] = uigetfile('*.edf', 'Select EDF file');
            if filename == 0, return; end
            
            statusText.Text = 'Loading EEG data...';
            drawnow;
            
            




            EEG = pop_biosig(fullfile(pathname, filename));
            
            if isempty(EEG.data)
                error('No data loaded from the EDF file.');
            end
            
            



            fig.UserData.EEGData = EEG.data;
            fig.UserData.Fs = EEG.srate;
            
            


            
            numChannels = size(EEG.data, 1);
            channelDropdown.Items = arrayfun(@(x) sprintf('Channel %d', x), 1:numChannels, 'UniformOutput', false);
            
           



            totalTime = size(EEG.data, 2) / fig.UserData.Fs;
            fig.UserData.timeSlider.Limits = [0, totalTime - fig.UserData.timeWindow];

            fig.UserData.timeSlider.Value = 0;
            fig.UserData.timeSlider.Visible = 'on';
            
            statusText.Text = 'EDF File Loaded. Select a channel.';
        catch ME
            statusText.Text = ['Error: ' ME.message];
        end
    end

    function changeChannel(~, ~)
        selectedChannelStr = channelDropdown.Value;
        if isempty(fig.UserData.EEGData)
            statusText.Text = 'Error: No EEG data loaded.';
            return;
        end
        
        




        channelNumber = sscanf(selectedChannelStr, 'Channel %d');
        if isempty(channelNumber) || channelNumber < 1 || channelNumber > size(fig.UserData.EEGData, 1)


            statusText.Text = 'Invalid channel selection.';
            return;
        end
        
        fig.UserData.SelectedChannel = channelNumber;
        updatePlots();
    end

    function updateTimeWindow(~, ~)
        if isempty(fig.UserData.EEGData)
            statusText.Text = 'Error: No EEG data loaded.';
            return;
        end
        updatePlots();
    end

    function updatePlots()
        channelNumber = fig.UserData.SelectedChannel;
        rawEEG = fig.UserData.EEGData(channelNumber, :);

        Fs = fig.UserData.Fs;
        timeWindow = fig.UserData.timeWindow;


        startTime = fig.UserData.timeSlider.Value;

        startSample = round(startTime * Fs) + 1;

        endSample = min(startSample + timeWindow * Fs - 1, length(rawEEG));
        
       





        time = (startSample:endSample) / Fs;
        rawEEGSegment = rawEEG(startSample:endSample);
        
        



        plot(rawAxes, time, rawEEGSegment);
        title(rawAxes, sprintf('Raw EEG - Channel %d', channelNumber));


        xlabel(rawAxes, 'Time (s)');
        ylabel(rawAxes, 'Amplitude (?V)');
        
        

        fig.UserData.FilteredData = preprocessEEG(rawEEGSegment, Fs);
        
        



        plot(filteredAxes, time, fig.UserData.FilteredData);

        title(filteredAxes, 'Filtered EEG');


        xlabel(filteredAxes, 'Time (s)');


        ylabel(filteredAxes, 'Amplitude (?V)');


        fig.UserData.BrainWaves = extractBrainWaves(fig.UserData.FilteredData, Fs);
        
        



        plotBrainWaves();
        
       


        calculatePSD();
        
        statusText.Text = 'Analysis complete!';
    end

    function filteredEEG = preprocessEEG(signal, Fs)
        




        lowCutoff = 0.5;

        highCutoff = 50;

        nyquist = Fs / 2;
        
       


        if lowCutoff >= nyquist
            lowCutoff = nyquist * 0.1;
            warning('Low cutoff adjusted to %.2f Hz', lowCutoff);
        end
        if highCutoff >= nyquist
            highCutoff = nyquist * 0.95;
            warning('High cutoff adjusted to %.2f Hz', highCutoff);
        end
        
        Wn = [lowCutoff highCutoff] / nyquist;
        
       


        [b, a] = butter(4, Wn, 'bandpass');

        filteredEEG = filtfilt(b, a, double(signal));
        

        


        threshold = 5 * std(filteredEEG);


        filteredEEG(abs(filteredEEG) > threshold) = median(filteredEEG);
    end

    function brainWaves = extractBrainWaves(signal, Fs)
        bands = struct('Delta', [0.5 4], 'Theta', [4 8], 'Alpha', [8 13], ...
                      'Beta', [13 30], 'Gamma', [30 50]);

        brainWaves = struct();
        nyquist = Fs / 2;
        
        for field = fieldnames(bands)'
            band = bands.(field{1});

            lowCutoff = band(1);
            highCutoff = band(2);
            
          


            if lowCutoff >= nyquist

                lowCutoff = nyquist * 0.1;
                warning('%s low cutoff adjusted to %.2f Hz', field{1}, lowCutoff);
            end
            if highCutoff >= nyquist

                highCutoff = nyquist * 0.95;
                warning('%s high cutoff adjusted to %.2f Hz', field{1}, highCutoff);
            end
            
           

            if lowCutoff >= highCutoff
                error('Invalid cutoff for %s band after adjustment', field{1});
            end
            
            Wn = [lowCutoff highCutoff] / nyquist;

            [b, a] = butter(4, Wn, 'bandpass');

            brainWaves.(field{1}) = filtfilt(b, a, double(signal));
        end
    end

    function plotBrainWaves()
        bands = fieldnames(fig.UserData.BrainWaves);

        time = (1:length(fig.UserData.FilteredData)) / fig.UserData.Fs;
        
        for i = 1:length(bands)
            plot(brainWavesAxes(i), time, fig.UserData.BrainWaves.(bands{i}));

            title(brainWavesAxes(i), brainWaveNames{i});

            xlabel(brainWavesAxes(i), 'Time (s)');


            ylabel(brainWavesAxes(i), 'Amplitude');
        end
    end

    function calculatePSD()
        cla(psdAxes);

        hold(psdAxes, 'on');
        colors = lines(5);

        Fs = fig.UserData.Fs;
        
        bands = fieldnames(fig.UserData.BrainWaves);

        for i = 1:length(bands)


            [pxx, f] = pwelch(fig.UserData.BrainWaves.(bands{i}), [], [], [], Fs);

            plot(psdAxes, f, 10*log10(pxx), 'Color', colors(i,:), 'DisplayName', bands{i});
        end
        
        legend(psdAxes, 'show');


        title(psdAxes, 'Power Spectral Density');



        xlabel(psdAxes, 'Frequency (Hz)');

        ylabel(psdAxes, 'Power/Frequency (dB/Hz)');


        hold(psdAxes, 'off');


    end


end