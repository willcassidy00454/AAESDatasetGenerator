% This script attempts to find the 1-to-1 mapping of an AAES routing matrix
% (from microphones to loudspeakers) that exhibits the maximum overall
% system delay. The aim of this is to find the AAES routing that should
% result in the least risk in terms of colouration due to strong direct
% paths. This script doesn't brute force all possible combinations, but
% rather starts from the max delays and finds a nearby 1-to-1 solution

% ============== INPUTS ==============
% loudspeaker_to_mic_matrix_irs = a square matrix of IRs characterising the
% loudspeaker-to-microphone path in some AAES

% ============== OUTPUTS ==============
% routing = a permutation matrix defining the optimal routing relative to
% loudspeaker_to_mic_matrix_irs

fs = 48000;
search_for_max_length = 10000;
H = zeros(16, 16, search_for_max_length);
H = FillIRMatrix(H, search_for_max_length, "H", "Audio Data/Physical RIRs/Room 1 Absorption 1/");

permutation_vector = FindRouting(H, fs);
permutation_matrix = zeros(16);

for i = 1:16
    permutation_matrix(permutation_vector(i), i) = 1;
end

writematrix(permutation_matrix, "Simulation Parameters/Permutations/room_1.dat");

function permutations = FindRouting(loudspeaker_to_mic_matrix_irs, fs)
    num_chans = size(loudspeaker_to_mic_matrix_irs, 1);
    delays = zeros(num_chans);
    
    % Find all zero-to-max(abs) delays in samples
    for row = 1:num_chans
        for permuted_col = 1:num_chans
            [~, delays(row, permuted_col)] = max(abs(loudspeaker_to_mic_matrix_irs(row, permuted_col, :)));
        end
    end

    % Sort rows into longest (1, :) to shortest (end, :)
    [delays_sorted_rows, sorted_row_positions] = sort(delays,"descend");

    PlotHeatmapForRouting(delays, false);
    PlotHeatmapForRouting(delays_sorted_rows, false);

    % Sort columns from highest variance to lowest variance
    column_variances = var(delays,[],2);
    [~, column_variance_permutations] = sort(column_variances, "descend");
    delays_sorted_rows_cols = delays_sorted_rows(:,column_variance_permutations);
    % sorted_row_and_col_positions = sorted_row_positions(:,column_variance_permutations);

    PlotHeatmapForRouting(delays_sorted_rows_cols, false);

    % Check indices of first row (if all are different, this is optimal)
    % Iterate through each col of the first row, checking if the index
    % matches any elements of the output routing, which is written to after
    % each col iteration. If if matches, a duplicate is found, so increment
    % the row and check again. make sure this is reset for the next column.
    permutations = zeros(num_chans, 1);

    % start = 5;
    % for col = mod(start:num_chans-1 + start, num_chans) + 1
        permuted_col = column_variance_permutations(col);
        row = 1;

        while (any(sorted_row_positions(row, permuted_col) == permutations))
            row = row + 1;
        end

        permutations(col) = sorted_row_positions(row, permuted_col);
    % end

    % Evaluate total delay of each row
    permuted_delays = zeros(num_chans, 1);
    for diagonal_index = 1:num_chans
        permuted_delays(diagonal_index) = delays(permutations(diagonal_index), column_variance_permutations(diagonal_index));
    end

    disp("Min delay in dataset: " + (min(delays,[],"all") / fs) * 1000 + " ms");
    disp("Max delay in dataset: " + (max(delays,[],"all") / fs) * 1000 + " ms");
    disp("Min selected delay: " + (min(permuted_delays) / fs) * 1000 + " ms");
    disp("Max selected delay: " + (max(permuted_delays) / fs) * 1000 + " ms");
end

function matrix_to_fill = FillIRMatrix(matrix_to_fill, desired_ir_length, filename_base_id, ir_directory)
    num_rows = size(matrix_to_fill,1);
    num_cols = size(matrix_to_fill,2);

    % Load each IR and insert into IR matrix
    for row = 1:num_rows
        for col = 1:num_cols
            padded_ir = zeros(desired_ir_length, 1);
    
            [raw_ir, ~] = audioread(ir_directory + filename_base_id + "_R" + row + "_S" + col + ".wav");
        
            nonzero_length = min(length(raw_ir), desired_ir_length); % Iterate up to the end of the audio, truncating if too long

            padded_ir(1:nonzero_length) = raw_ir(1:nonzero_length);
            matrix_to_fill(row, col, :) = padded_ir;
        end
    end
end

function PlotHeatmapForRouting(routing, convert_to_dB)
    nexttile

    if (convert_to_dB)
        if ~isempty(find(routing == 0))
            routing(find(routing == 0)) = 0.001;
        end

        routing = 20 * log10(abs(routing));
    end

    heatmap(routing, "Colormap", parula, "CellLabelColor", "none");

    if (convert_to_dB)
        title("Routing Matrix Magnitude / dB");
    else
        title("Routing Matrix Gain");
    end

    xlabel("Microphones");
    ylabel("Loudspeakers");
end