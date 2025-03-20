% Applies biquad to all elements of a reverberator folder
function FilterReverberator(read_dir, write_dir, num_rows, num_cols, filter_type, should_normalise_individual)
    if ~exist("filter_type", "var")
        filter_type = "LPF";
    end  

    if ~exist("should_normalise_individual", "var")
        should_normalise_individual = false;
    end

    if filter_type == "LPF"
        % f_c = 5 kHz, Q = 0.27, 2nd order
        % b = [0.04856935192323814 0.09713870384647628 0.04856935192323814];
        % a = [1 -0.7458655782462117 -0.059857014060835656];
        % f_c = 800 Hz, Q = 0.27, 2nd order
        b = [0.002294837753273866 0.004589675506547732 0.002294837753273866];
        a = [1 -1.6664642575322546 0.6756436085453501];
    elseif filter_type == "High Shelf"
        % f_c = 1 kHz, Q = 0.3, +6 dB, 2nd order
        b = [1.942126127114147 -3.6298767977070048 1.7034151772350468];
        a = [1 -1.8153410827045682 0.8310055893467576];
    else
        error("Filter type not recognised. Use 'LPF' or 'High Shelf'.");
    end

    sos = dsp.SOSFilter(b, a);

    for row = 1:num_rows
        for col = 1:num_cols
            [ir, fs] = audioread(read_dir + "X_R"+row+"_S"+col+".wav");
            filtered_output = sos(ir);

            if should_normalise_individual
                filtered_output = filtered_output / max(abs(filtered_output));
            end

            audiowrite(write_dir + "X_R"+row+"_S"+col+".wav", filtered_output, fs, "BitsPerSample", 32);
        end
    end
end