
% clear all

config.numMicrophones = 4;
config.numLoudspeakers = 4;

% FDN order
FDN.order = 32;

% Gains
FDN.inputGains = orth(randn(FDN.order, config.numMicrophones));
FDN.outputGains = orth(randn(config.numLoudspeakers, FDN.order)')';
FDN.directGains = zeros(config.numLoudspeakers,config.numMicrophones);

% Delay lines
FDN.delays = randi([1200,2500], [1,FDN.order]);

% Feedback matrix
FDN.feedbackMatrix = randomOrthogonal(FDN.order);

% Absoption filters
FDN.RT_DC = 2.0;                % [seconds]
FDN.RT_NY = 1.2;                % [seconds]

% FDN.RT_DC = 0.868 * rt_ratio;                % [seconds]
% FDN.RT_NY = FDN.RT_DC / 2;                % [seconds]

% Time Variation
FDN.modulationFrequency = 0.0;  % hz
FDN.modulationAmplitude = 0.0;
FDN.spread = 0.0;

FDN.blockSize = 256;
FDN.fs = 48000;

FDN = create_FDN(FDN);
irs = computeFDNirs(FDN, config);
irs = irs / max(abs(irs),[],"all");

output_dir = "Reverberators/Reverberator 1/";
mkdir(output_dir);
SaveIRs(irs, FDN.fs, 32, output_dir, "X");

% Generate FDN
function params = create_FDN(params)
    % Reverberation time
    params.RT = max(params.RT_DC, params.RT_NY);

    % Input gains
    B = convert2zFilter(params.inputGains);
    params.InputGains = dfiltMatrix(B);
    % Delay lines
    params.DelayFilters = feedbackDelay(params.blockSize, params.delays);
    % Absorption filters
    [absorption.b,absorption.a] = onePoleAbsorption(params.RT_DC, params.RT_NY, params.delays, params.fs);
    A = zTF(absorption.b, absorption.a,'isDiagonal', true);
    params.absorptionFilters = dfiltMatrix(A); 
    % Feedback matrix
    F = convert2zFilter(params.feedbackMatrix);
    params.FeedbackMatrix = dfiltMatrix(F);
    params.TVMatrix = timeVaryingMatrix(params.order, params.modulationFrequency, params.modulationAmplitude, params.fs, params.spread);
    % Output gains
    C = convert2zFilter(params.outputGains);
    params.OutputGains = dfiltMatrix(C);
    % Direct path
    D = convert2zFilter(params.directGains);
    params.DirectGains = dfiltMatrix(D);
end

% Process signal
% function output = process(obj, input)
% 
%     % Input block
%     assert(size(input,1) == obj.blockSize);
%     % Microphone input
%     source_to_mics = real(ifft( matrix_product( fft(obj.H_SM, obj.nfft, 1), fft(input, obj.nfft, 1) ), obj.nfft, 1));
%     mics_signals = source_to_mics(1:obj.blockSize,:) + obj.mics_storage(1:obj.blockSize,:);
%     % FDN
%     FDN_input = mics_signals;
%     FDN_output = obj.FDN_step(FDN_input);
%     % Loudspeaker output
%     lds_signals = obj.generalGain * FDN_output;
%     % Feedback
%     lds_to_mics = real(ifft( matrix_product( fft(obj.H_LM, obj.nfft, 1), fft(lds_signals, obj.nfft, 1) ), obj.nfft, 1));
%     % Audience signal
%     lds_to_audience = real(ifft( matrix_product( fft(obj.H_LA, obj.nfft, 1), fft(lds_signals, obj.nfft, 1) ), obj.nfft, 1));
%     source_to_audience = real(ifft( matrix_product( fft(obj.H_SA, obj.nfft, 1), fft(input, obj.nfft, 1) ), obj.nfft, 1));
%     audience_signal = lds_to_audience + source_to_audience;
%     % Output block
%     output = audience_signal(1:obj.blockSize) + obj.audience_storage(1:obj.blockSize);
%     % Store for next block iterations
%     obj.update_storage("mics_storage", source_to_mics+lds_to_mics);
%     obj.update_storage("audience_storage", audience_signal);
% 
% end
% 
% FDN iteration step
function [output, params] = FDN_step(params, input)

    % Delays 
    delayOutput = params.DelayFilters.getValues(params.blockSize);
    % Absorption
    absorptionOutput = params.absorptionFilters.filter(delayOutput); 
    % Feedback matrix
    feedback = params.FeedbackMatrix.filter(absorptionOutput);
    if ~isempty(params.TVMatrix)
        feedback = params.TVMatrix.filter(feedback);
    end
    % Output
    output = params.OutputGains.filter(absorptionOutput) + params.DirectGains.filter(input);

    % Prepare next iteration
    delayLineInput = params.InputGains.filter(input) + feedback;
    params.DelayFilters.setValues(delayLineInput);
    params.DelayFilters.next(params.blockSize);

end

function FDN_irs = computeFDNirs(params, config)

    % Define length of the FDN irs based on the FDN RT
    sigLength = params.RT * params.fs;
    
    % Allocate memory
    FDN_irs = zeros(config.numMicrophones, config.numLoudspeakers, sigLength);

    % Iterate over FDN inputs
    for i = 1:config.numMicrophones
        
        % Define input signal (Impulse at a single channel)
        inputSignal = zeros(sigLength, config.numMicrophones);
        inputSignal(1,i) = 1;

        % Block processing
        numBlocks = floor(sigLength / params.blockSize);
        for block = 1:numBlocks
            block_index = (block-1)*params.blockSize + (1:params.blockSize);
            [fdn_step_output, params] = FDN_step(params, inputSignal(block_index,:));
            FDN_irs(i,:,block_index) = fdn_step_output';
        end
    end

    params.DelayFilters.values(:) = 0;
end