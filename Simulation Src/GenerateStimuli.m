% Loads the 3rd order AAES IRs, applies an equal-power fade out, convolves
% with programme items and saves the result to be used as listening test
% stimuli.

aaes_rir_dir = "Audio Data/AAES Receiver RIRs/";
programme_items_dir = "Audio Data/Programme Items/";
stimulus_output_dir = "Audio Data/Stimuli/";
fade_length_ms = 50;
bit_depth = 32;

loop_gains = readmatrix("Simulation Parameters/Loop Gains/loop_gains.dat");

num_loop_gains = length(loop_gains);
num_rooms = 1;%3;
num_absorptions = 1;%3;
num_rt_ratios = 3;
num_filters = 3;
num_routings = 4;
num_programme_items = 1;

conditions = zeros(num_loop_gains * num_rooms * num_absorptions * num_rt_ratios * num_filters * num_routings, 6);

row = 1;
for loop_gain_index = 1:num_loop_gains
    for rt_ratio_index = 1:num_rt_ratios
        for absorption_index = 1:num_absorptions
            for room_index = 1:num_rooms
                for routing_index = 1:num_routings
                    for filter_index = 1:num_filters
                        conditions(row, 1) = room_index;
                        conditions(row, 2) = absorption_index;
                        conditions(row, 3) = rt_ratio_index;
                        conditions(row, 4) = filter_index;
                        conditions(row, 5) = loop_gain_index;
                        conditions(row, 6) = routing_index;
        
                        row = row + 1;
                    end
                end
            end
        end
    end
end

for row = 1:size(conditions, 1)
    room_index = conditions(row, 1);
    absorption_index = conditions(row, 2);
    rt_ratio_index = conditions(row, 3);
    filter_index = conditions(row, 4);
    loop_gain_index = conditions(row, 5);
    routing_index = conditions(row, 6);

    [ir, fs] = audioread(aaes_rir_dir + "AAES Room "+room_index+" Absorption "+absorption_index+" RT "+rt_ratio_index+" Loop Gain "+loop_gain_index+" Filter "+filter_index+" Routing "+routing_index+"/ReceiverRIR.wav");

    % Set IR length to T30 + fade length
    t_30 = FindT30(ir(:,1), fs);
    fade_length_samples = (fade_length_ms / 1000) * fs;
    desired_ir_length = t_30 * fs + fade_length_samples;
    
    if length(ir) < desired_ir_length
        warning("It appears the IR is shorter than its T30, so the fade-out may be audible.");
    else
        ir = ir(1:desired_ir_length, :);
    end

    % Apply fade out
    increasing_samples_normalised = (1:fade_length_samples) / fade_length_samples;
    fade_samples = 0.5 * cos(increasing_samples_normalised * pi) + 0.5;
    ir((end - fade_length_samples + 1):end, :) = ir((end - fade_length_samples + 1):end, :) .* fade_samples';

    for programme_item_index = 1:num_programme_items
        disp("Generating Stimulus: Prog Item "+programme_item_index+" Room "+room_index+" Absorption "+absorption_index+" RT "+rt_ratio_index+" Loop Gain "+loop_gain_index+" Filter "+filter_index+" Routing "+routing_index);

        [programme_item, fs_programme_item] = audioread(programme_items_dir + "programme_item_" + programme_item_index + ".wav");

        assert(fs_programme_item == fs);

        if fs_programme_item ~= fs
            programme_item = resample(programme_item,fs_programme_item,fs);
        end

        % Compute convolution
        stimulus = zeros(length(programme_item) + length(ir) - 1, 16);

        for spherical_harmonic = 1:16
            stimulus(:,spherical_harmonic) = conv(programme_item, ir(:,spherical_harmonic));
        end

        output_filename = stimulus_output_dir + "Prog Item "+programme_item_index+" Room "+room_index+" Absorption "+absorption_index+" RT "+rt_ratio_index+" Loop Gain "+loop_gain_index+" Filter "+filter_index+" Routing "+routing_index+".wav";
        audiowrite(output_filename, stimulus, fs, "BitsPerSample", bit_depth);
    end
end

disp("Stimulus Generation Complete");