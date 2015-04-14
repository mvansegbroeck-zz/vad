% Example default usage of 'denoise.m'
% Author: Maarten Van Segbroeck

% set path
addpath mfiles/
addpath tools/

audiodir='../audio/anorexia_study/';
sildir='../sil/anorexia_study/';
wfdir='../wf/anorexia_study/';
%audiodir='../audio/OCD study/';
%outdir_txt='../pitch/OCD study/';
if ~exist(sildir), mkdir(sildir); end
if ~exist(wfdir), mkdir(wfdir); end

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
p2=20;

% ---visualize---
visualize=true;

for k = 1 : length(filenames)

 [~,filename,~]=fileparts(filenames(k).name); 

 % read in audio
 samfile=fullfile(audiodir,filenames(k).name);
 [sam,fs_orig]=wavread(samfile);
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

 % Silence labels
 sam_16k=downsample(sam(:,1),fs_orig/(2*fs));
 FrameLen=0.03*2*fs;
 FrameShift=0.01*2*fs;
 NbFr=floor((length(sam_16k)-FrameShift)/FrameShift);
 samfile_16k=fullfile(wfdir,filenames(k).name);
 wavwrite(sam_16k,fs,samfile_16k);

 silfile = fullfile(sildir,sprintf('%s.sil',filename));
 wffile = fullfile(wfdir,sprintf('%s.wav',filename));
 wffile_pcm = fullfile(wfdir,sprintf('%s.pcm',filename));
 Sillabel=ones(NbFr,1);
 Sillabel(labelsPerFrame==1)=0; 
 
 fid=fopen(silfile,'wt'); fprintf(fid,'%d',Sillabel); fclose(fid); 
 
 % wiener filtering 
 unix(sprintf('sh apply_wf.sh %s %s %s',silfile,samfile_16k,wffile_pcm));
 fid=fopen(wffile_pcm,'rb'); sam_wf=fread(fid,'short')'./2^15; fclose(fid);
 wavwrite(sam_wf,fs*2,wffile);

 if visualize
  subplot 211; spectrogram(sam_16k,16000);
  subplot 212; spectrogram(sam_wf,16000);
 end

end
