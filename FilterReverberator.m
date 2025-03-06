% Applies biquad to all elements of a reverberator folder
function FilterReverberator(read_dir, write_dir, num_rows, num_cols, should_normalise_individual)
    if ~exist("should_normalise_individual", "var")
        should_normalise_individual = false;
    end

    % f_c = 5 kHz, Q = 0.27, 2nd order
    b = [0.04856935192323814 0.09713870384647628 0.04856935192323814];
    a = [1 -0.7458655782462117 -0.059857014060835656];
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