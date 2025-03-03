% Concert Hall
room_dim = [24 23 11];
% Studio Theatre
% room_dim = [13.2 14.5 4.75];
% Central Hall
% room_dim = [20.9 28.9 13.3];

src_positions = [room_dim(1) / 2 - 2.5, room_dim(2) / 2, 1.2];
rec_positions = [room_dim(1) / 2 + 2.5, room_dim(2) / 2, 1.2];
src_rotations = [0 0];
rec_rotations = [180 0];
src_directivities = "OMNI";
rec_directivities = "OMNI";

% front wall;
% rear wall;
% left wall;
% right wall;
% floor;
% ceiling;
alphas = [0.16064	0.13888	0.19987	0.182088	0.280875	0.36088	0.46095
						
0.03584	0.14	0.1386	0.23976	0.38	0.4498	0.675
						
0.03584	0.14	0.1386	0.23976	0.38	0.4498	0.675
						
0.03584	0.14	0.1386	0.23976	0.38	0.4498	0.675
						
0.4736	0.644	0.6006	0.65016	0.8425	0.9152	1.116
						
0.7552	1.12	0.902	0.702	0.3375	0.299	0.27
						]';

sample_rate = 48000;
group_label = "ConcertHall";
should_high_pass = true;
bit_depth = 32;

ir = GenerateSrcToRecIRs(src_positions, ...
    rec_positions, ...
    src_rotations, ...
    rec_rotations, ...
    src_directivities, ...
    rec_directivities, ...
    room_dim, ...
    alphas, ...
    sample_rate, ...
    group_label, ...
    should_high_pass);

ir = ir / max(abs(ir));

audiowrite("AbsorbCoeffsTest/" + group_label + ".wav",squeeze(ir),sample_rate, "BitsPerSample", bit_depth);