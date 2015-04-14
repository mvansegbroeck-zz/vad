% ------------------------------------------------------------------------
% Copyright (C) 2015 University of Southern California, SAIL, U.S.
% Author: Maarten Van Segbroeck
% Mail: maarten@sipi.usc.edu
% Date: 2015-20-1
% ------

% set path
addpath mfiles/

audiodir='../audio/anorexia study/';
outdir_txt='../pitch/anorexia study/';
%audiodir='../audio/OCD study/';
%outdir_txt='../pitch/OCD study/';
if ~exist(outdir_txt), mkdir(outdir_txt); end

filenames=dir(sprintf('%s/*.wav',audiodir));
fs=8000;

% ---feature---
% GT
NbCh=64;
% Gabor
nb_mod_freq=2;
% LTSV
R=50; % context
M=10; % smoothing
ltsvThr=0.5;
ltsvSlope=0.2;
% vprob2 and ltsv2
K=30; order=4; 
% -------------

% ---vad model---
load('models/model.mat')

% ---vad parameters (to tune)---
p1=0.1;
p2=40;

% ---visualize---
visualize=true;

for k = 1 : length(filenames)

 % read in audio
 [sam,fs_orig]=wavread(fullfile(audiodir,filenames(k).name));
 sam_8k=downsample(sam(:,1),fs_orig/fs);
 
 % [1] extract cochleagram
 gt=FE_GT(sam_8k,fs,NbCh);

 % [2] Gabor filtering applied on mel
 gbf=FE_GBF(sam_8k,fs,nb_mod_freq,false);
 gbf= [gbf gbf(:,ones(1,10)*size(gbf,2))];
 gbf = gbf(:,1:size(gt,2));

 % [3] LTSV 
 ltsv=FE_LTSV(sam_8k,fs,R,M,gt,ltsvThr,ltsvSlope);
 ltsv2 = convert_to_context_stream(ltsv, K, order);
 ltsv2= [ltsv2 ltsv2(:,ones(1,10)*size(ltsv,2))];
 ltsv2 = ltsv2(:,1:size(gt,2));

 % [4] vprob prob
 vprob=voicingfeature(sam_8k,fs);
 vprob2 = convert_to_context_stream(vprob, K, order);
 vprob2 = [vprob2 vprob2(:,ones(1,10)*size(vprob,2))];
 vprob2 = vprob2(:,1:size(gt,2));
 
 % feature for VAD
 test_x = [gt;gbf;ltsv2;vprob2];
 test_x_norm = mvn(test_x);
 
 % VAD decoding
 [~,~,output] = nntest(dnn, test_x_norm');
  outprob=double(output(:,1));
 labelsPerFrame=medfilt1(outprob.^2,p2)>p1;
 
 if visualize
  imagesc(mvn(gt));axis xy;hold on;
  plot(10*labelsPerFrame,'m','LineWidth',3); zoom xon; hold off
  keyboard
 end
end
