output_dir = "Simulation Parameters/Routings/";
mkdir(output_dir);

% % 16x16 identity
% identity = GenerateIdentity(16);
% 
% % 16x16 hadamard
% hadamard = GenerateNextHadamardIteration(GenerateNextHadamardIteration(GenerateNextHadamardIteration(GenerateNextHadamardIteration(1))));
% 
% % 16x16 frontal focus matrix
% frontal_focus = GenerateFrontalFocusFromIdentity(identity);
% 
% % 16x16 lateral focus matrix
% lateral_focus = GenerateLateralFocusMatrix();



% writematrix(identity, output_dir + "routing_1.dat");
writematrix(ones(16), output_dir + "routing_2.dat");
% writematrix(frontal_focus, output_dir + "routing_3.dat");
% writematrix(lateral_focus, output_dir + "routing_4.dat");

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

function matrix = GenerateFrontalFocusFromIdentity(identity)
    num_channels = length(identity);
    matrix = identity;

    gain_dB = -12;

    % Attenuate the coeffs past element 4
    for diag_index = 5:num_channels
        matrix(diag_index, diag_index) = db2mag(gain_dB);

        if mod(diag_index, 4) == 0
            gain_dB = gain_dB - 12;
        end
    end
end

function matrix = GenerateLateralFocusMatrix()
    matrix = zeros(16);

    % Add diagonal elements
    for diag_index = [5 8:16]
        matrix(diag_index, diag_index) = 1;
    end

    % Attenuate overhead channels
    gain_dB = -12;

    matrix(10,10) = db2mag(gain_dB);
    matrix(11,11) = db2mag(gain_dB);

    % Add frontal microphone re-routing
    matrix(5,1) = 1;
    matrix(9,2) = 1;
    matrix(12,3) = 1;
    matrix(8,4) = 1;
    matrix(13,6) = 1;
    matrix(16,7) = 1;
end