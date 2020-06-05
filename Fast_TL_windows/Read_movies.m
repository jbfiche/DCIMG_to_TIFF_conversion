clear all
close all
clc

% Define the folder where the images were saved
% ---------------------------------------------

Base_Path = uigetdir('/mnt/PALM_dataserv/DATA/',...
    'Look for the folder containg the time-laspe data');
cd(Base_Path)

% Ask the number of ROIs that were acquired during each cycle
% -----------------------------------------------------------

prompt = {'Enter the number of ROIs:', 'Enter the number of channels:'};
title = 'Input';
dims = [1 35];
definput = {'9', '1'};
answer = inputdlg(prompt,title,dims,definput);

N_ROI = str2double(answer{1});
N_Channels = str2double(answer{2});

% Read in the folder the number of movies that have been recorded and
% create a folder for each ROI where all the movies are going to be saved
% -----------------------------------------------------------------------

Movies_name = dir('*.tif');
N_Movies = size(Movies_name,1);

Movies_info = imfinfo(Movies_name(1).name);
N_Frame = size(Movies_info,1);
N_Stack = N_Frame/N_ROI;

% Check the parameters are making sense with respect to the number of
% frames saved for each movie
% ----------------------------

if round(N_Stack) ~= N_Stack
    hwarn = warndlg('The number of ROIs does not match with the number of frames saved in each movie');
    uiwait(hwarn)
    delete(hwarn)
    return
end

if round(N_Stack/N_Channels) ~= N_Stack/N_Channels
    hwarn = warndlg('The number of channels does not match with the number of frames saved in each movie');
    uiwait(hwarn)
    delete(hwarn)
    return
end

% For each ROI a folder is created where the new movies will be saved
% -------------------------------------------------------------------

for n_roi = 1 : N_ROI
    Folder_name = strcat('ROI_', num2str(n_roi));
    mkdir(Folder_name)
end

% For each movie, the images are separated by ROI and channel and new
% movies are created and saved
% ---------------------------

for n_movie = 1 : N_Movies
    
    Movie_name = strcat(Base_Path, '/', Movies_name(n_movie).name);
    
    for n_roi = 1 : N_ROI
        
        Folder_name = strcat(Base_Path, '/ROI_', num2str(n_roi));
        cd(Folder_name)
        n_ch = 1;
        
        for n_stack = 1 : N_Stack
            n_image = (n_roi-1)*N_Stack + n_stack;
            im = imread(Movie_name, 'Index', n_image);
            
            Base_name = Movies_name(n_movie).name;
            Base_name = Base_name(1:end-4);
            New_movie_name = strcat(Base_name, '_Ch_', num2str(n_ch), '.tif');
            
            if n_stack<=N_Channels
                imwrite(im, New_movie_name, 'Compression', 'none', 'WriteMode', 'overwrite')
            else
                imwrite(im, New_movie_name, 'Compression', 'none', 'WriteMode', 'append')
            end
            
            if n_ch<N_Channels
                n_ch = n_ch+1;
            else
                n_ch = 1;
            end
        end
    end
    
    delete(Movie_name);
end
