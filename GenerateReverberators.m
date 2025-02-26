sample_rate = 48000;
bit_depth = 32;
base_output_dir = "Reverberators/";

% 16x16 identity
identity = GenerateIdentity(16);

% 16x16 hadamard
hadamard = GenerateNextHadamardIteration(GenerateNextHadamardIteration(GenerateNextHadamardIteration(GenerateNextHadamardIteration(1))));

SaveReverberatorMatrix(identity, base_output_dir + "Reverberator 1/", sample_rate, bit_depth);
SaveReverberatorMatrix(hadamard, base_output_dir + "Reverberator 2/", sample_rate, bit_depth);

function identity = GenerateIdentity(num_channels)
    identity = zeros(num_channels);

    for receiver_index = 1:num_channels
        for source_index = 1:num_channels
            if source_index == receiver_index
                identity(receiver_index, source_index) = 1;
            end
        end
    end
end

function hadamard = GenerateNextHadamardIteration(input_matrix)
    num_rows = length(input_matrix);
    num_cols = num_rows;

    hadamard = zeros(num_rows * 2, num_cols * 2);

    % Fill top left
    hadamard(1:num_rows, 1:num_cols) = input_matrix;

    % Fill bottom left
    hadamard(num_rows + 1:num_rows * 2, 1:num_cols) = input_matrix;

    % Fill top right
    hadamard(1:num_cols, num_cols + 1:num_cols * 2) = input_matrix;

    % Fill bottom right
    hadamard(num_rows + 1:num_rows * 2, num_cols + 1:num_cols * 2) = -input_matrix;
end

function SaveReverberatorMatrix(matrix, output_dir, sample_rate, bit_depth)
    mkdir(output_dir);

    for receiver_index = 1:size(matrix, 1)
        for source_index = 1:size(matrix, 2)
            audiowrite(output_dir + "X_R" + receiver_index + "_S" + source_index + ".wav", matrix(receiver_index, source_index), sample_rate, BitsPerSample=bit_depth);
        end
    end
end