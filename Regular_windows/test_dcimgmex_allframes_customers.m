%% test mex for dcimg

%% clear all
clc;
clear all; %#ok<CLSCR>

%% open dcimg
% hdcimg        : dcimg handle
% 'FILENAME'    : dcimg file name

cd('C:\Users\sCMOS-1\Desktop\Experiment_test')
[FILENAME, PATH, ~] = uigetfile('*.dcimg');
cd(PATH)
FILENAME = cat(2, PATH, FILENAME);
hdcimg = dcimgmex( 'open', FILENAME ); %- example

%% get parameter
% param         : return parameter
% hdcimg        : dcimg handle ( returns open )
% 'PARAMNAME'   : parameter name, supported parameters below
%   'SENSOR_BINNING, 'SENSOR_HPOS', 'SENSOR_HSIZE', 'SENSOR_VPOS', 'SENSOR_VSIZE',
%   'IMAGE_WIDTH', 'IMAGE_HEIGHT', 'IMAGE_ROWBYTES', 'IMAGE_PIXELTYPE', 
%   'NUMBEROF_TOTALFRAME', 'NUMBEROF_SESSION', 'NUMBEROF_FRAME', 'NUMBEROF_VIEW', 'NUMBEROF_REGIONRECT',
%   'CURRENT_SESSION", 'CURRENT_VIEW', 'CURRENT_REGIONRECT', 'FILEFORMAT_VERSION'

numFrames = dcimgmex( 'getparam', hdcimg, 'NUMBEROF_FRAME' );
im_width = dcimgmex( 'getparam', hdcimg, 'IMAGE_WIDTH' );
im_height = dcimgmex( 'getparam', hdcimg, 'IMAGE_HEIGHT' );

%% read frame
% data          : image data
% hdcimg        : dcimg handle

% Preallocate the array
seq1 = uint16(zeros(im_width,im_height,numFrames)); 
%%seq1(:,:,:,1) = framedatatrans;

for framenum = 1:numFrames
   % Read each frame into the appropriate frame in memory.
   data = dcimgmex( 'readframe', hdcimg, framenum);
   seq1(:,:,framenum)  = data;
   figure(1);  
   imagesc(data);
   axis off equal;
   colormap gray;
   imwrite(data, 'Sara.tiff', 'WriteMode', 'append')
end

montage(seq1);
%implay(seq1,numFrames);

dcimgmex('close', hdcimg);
