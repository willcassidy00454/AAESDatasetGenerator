fs = 48000;
bit_depth = 32;
base_output_dir = "Reverberators/";

GenerateIdentity(16, base_output_dir + "Reverberator 1/", fs, bit_depth);

function GenerateIdentity(num_channels, output_dir, fs, bit_depth)
    for source_index = 1:num_channels
        for receiver_index = 1:num_channels
            if source_index ~= receiver_index
                ir = 0;
            else
                ir = 1;
            end

            audiowrite(output_dir + "X_R"+receiver_index+"_S"+source_index+".wav", ir, fs, "BitsPerSample", bit_depth);
        end
    end
end