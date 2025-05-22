% Loads the 4th order AAES IRs, applies an equal-power fade out, convolves
% with programme items and saves the result to be used as listening test
% stimuli.

aaes_rir_dir = "Audio Data/AAES Receiver RIRs/";
programme_items_dir = "Audio Data/Programme Items/";
stimulus_output_dir = "Audio Data/Stimuli/";
fade_length_ms = 50;
output_bit_depth = 16;
num_programme_items = 2;
stimulus_duration = 12; % Pad/truncate all stimuli to this time in seconds

folders = dir(fullfile(aaes_rir_dir,"*","ReceiverRIR.wav"));

loudness_target_dB_LUFS = -34;

maxOrder = 4;
channel_weights = [];

% Calculate channel weights for loudness estimation
for n = 0:maxOrder
    wn = sqrt(1 / (2*n + 1));
    channel_weights = [channel_weights; wn * ones(2*n + 1, 1)];
end

for file_index = 1:numel(folders)
    folder_name = extractAfter(folders(file_index).folder, asManyOfPattern(wildcardPattern + "/"));
    [ir, fs] = audioread(aaes_rir_dir + folder_name + "/" + folders(file_index).name);

    % Apply fade-out to IR
    fade_length_samples = (fade_length_ms / 1000) * fs;
    increasing_samples_normalised = (1:fade_length_samples) / fade_length_samples;
    fade_samples = 0.5 * cos(increasing_samples_normalised * pi) + 0.5;
    ir((end - fade_length_samples + 1):end, :) = ir((end - fade_length_samples + 1):end, :) .* fade_samples';

    for programme_item_index = 1:num_programme_items
        disp("Generating " + folder_name + " Programme Item " + programme_item_index);

        [programme_item, fs_programme_item] = audioread(programme_items_dir + "programme_item_" + programme_item_index + ".wav");

        % assert(fs_programme_item == fs);

        if fs_programme_item ~= fs
            programme_item = resample(programme_item,fs_programme_item,fs);
        end

        % Compute convolution
        stimulus = zeros(length(programme_item) + length(ir) - 1, 25);

        for spherical_harmonic = 1:25
            stimulus(:,spherical_harmonic) = conv(programme_item, ir(:,spherical_harmonic));
        end

        desired_stimulus_length_samples = fs * stimulus_duration;

        % Pad/truncate stimulus to desired length
        if length(stimulus) < desired_stimulus_length_samples
            stimulus(end:desired_stimulus_length_samples,:) = 0.0;
        else
            stimulus = stimulus(1:desired_stimulus_length_samples, :);
        end

        % Normalise output
        loudness_dB_LUFS = integratedLoudness(stimulus, fs, channel_weights');
        gain_to_apply_dB = loudness_target_dB_LUFS - loudness_dB_LUFS;

        stimulus = stimulus * power(10.0, gain_to_apply_dB / 20.0);

        output_filename = stimulus_output_dir + " Prog Item " + programme_item_index + " " + folder_name + ".wav";
        audiowrite(output_filename, stimulus, fs, "BitsPerSample", output_bit_depth);
    end
end

disp("Stimulus Generation Complete");