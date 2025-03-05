% Applies biquad to all elements of a reverberator folder
function FilterReverberator(read_dir, write_dir, num_rows, num_cols)
    b = [0.967072031610277 -1.8417678204094883 0.8824546873377966];
    a = [1 -1.8417678204094883 0.8495267189480735];
    sos = dsp.SOSFilter(b, a);

    for row = 1:num_rows
        for col = 1:num_cols
            [ir, fs] = audioread(read_dir + "X_R"+row+"_S"+col+".wav");
            filtered_output = sos(ir);
            audiowrite(write_dir + "X_R"+row+"_S"+col+".wav", filtered_output, fs, "BitsPerSample", 32);
        end
    end
end