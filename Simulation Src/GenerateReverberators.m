
num_room_dims = 3;
num_absorptions = 3;
num_filter_modes = 3;
rir_dir = "Simulated Physical RIRs/";
reverberator_base_dir = "Reverberators/";
bit_depth = 32;
rt_ratios = [0, 1, 3];

% Load direct src-rec IR from each passive room, find wideband T30, and
% generate all reverberator types for this RT (all RT ratios, all filtering
% modes)

for room_dims_index = 1:num_room_dims
    for absorption_index = 1:num_absorptions
        [ir, fs] = audioread(rir_dir+"Room "+room_dims_index+" Absorption "+absorption_index+"/E_R1_S1.wav");
        passive_rt = FindT30(ir, fs);

        for filter_mode_index = 1:num_filter_modes
            for rt_ratio_index = 1:length(rt_ratios)
                folder_name = "Reverberator Room "+room_dims_index+" Absorption "+absorption_index+" RT "+rt_ratio_index+" Filter "+filter_mode_index+"/";
                mkdir(reverberator_base_dir + folder_name);
                disp("Generating Folder: " + folder_name);
                GenerateReverberator(passive_rt, ...
                    filter_mode_index, ...
                    rt_ratios(rt_ratio_index), ...
                    fs, ...
                    bit_depth, ...
                    reverberator_base_dir + folder_name);
            end
        end
    end
end

function GenerateReverberator(passive_rt, filter_mode_index, rt_ratio, fs, bit_depth, reverberator_dir)
    if rt_ratio ~= 0
        rt_dc = passive_rt * rt_ratio;

        if filter_mode_index == 2
            rt_nyquist = rt_dc / 4; % Frequency-Dependent FDN
        else
            rt_nyquist = rt_dc; % Frequency-Independent FDN (may be filtered after)
        end

        GenerateFDNIRs(rt_dc, rt_nyquist, 16, 16, fs, bit_depth, reverberator_dir);
    else
        % write all ones reverberator
        for row = 1:16
            for col = 1:16
                audiowrite(reverberator_dir + "X_R"+row+"_S"+col+".wav", 1, fs, "BitsPerSample", bit_depth);
            end
        end
    end

    % Low pass output
    if filter_mode_index == 1
        FilterReverberator(reverberator_dir, reverberator_dir, 16, 16, true);
    end
end