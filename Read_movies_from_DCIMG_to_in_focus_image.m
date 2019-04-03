clear all
close all
clc

%% Look for all the .dcimg files in the selected folder and return the names
%% of the folders containing such data
%% -----------------------------------

[DCIMG_FinalFileName, DCIMG_FinaleDirectoryName, SearchDirectory] = Look_For_DCIMG_Files;
DCIMG_FinaleDirectoryName = unique(DCIMG_FinaleDirectoryName);
N_directory = size(DCIMG_FinaleDirectoryName,1);

%% Ask the number of ROIs that were acquired during each cycle
%% -----------------------------------------------------------

prompt = {'Enter the number of ROIs:', 'Enter the number of channels:'};
title = 'Input';
dims = [1 35];
definput = {'9', '1'};
answer = inputdlg(prompt,title,dims,definput);

N_ROI = str2double(answer{1});
N_Channels = str2double(answer{2});

%% Read the first movie found in order to define the number of frames
%% composing each movie.
%% ---------------------

cd(DCIMG_FinaleDirectoryName{1})
Movie_name = DCIMG_FinalFileName{1};
hdcimg = dcimgmex('open', Movie_name);
N_Frame = dcimgmex( 'getparam', hdcimg, 'NUMBEROF_FRAME' );
N_Stack = N_Frame/N_ROI;

%% Check the parameters are making sense with respect to the number of
%% frames saved for each movie
%% ----------------------------

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

%% For each folder, all the images saved in the folder are converted together
%% and separated according to the number of ROIs and channels.
%% ----------------------------------------------------------

for n_dir = 1 : N_directory
    
    % Define the folder where the images were saved and the number of
    % movies inside the folder
    % ------------------------
    
    Base_Path = DCIMG_FinaleDirectoryName{n_dir};
    cd(Base_Path)
    
    Folder_info = dir('*.dcimg');
    N_Movies = size(Folder_info,1);
    
    % For each ROI a folder is created where the new movies will be saved. In
    % the same way, for each ROI, folders corresponding to each channel are
    % also created
    % ------------
    
    for n_roi = 1 : N_ROI
        
        cd(Base_Path)
        Folder_name = strcat('ROI_', num2str(n_roi));
        mkdir(Folder_name)
        cd(Folder_name)
        for n_channel = 1 : N_Channels
            Folder_name = strcat('Ch_', num2str(n_channel));
            mkdir(Folder_name)
        end
    end
    
    % For each movie, the images are separated by ROI and channel and new
    % movies are created and saved
    % ---------------------------
    
    for n_movie = 1 : N_Movies
        
        Movie_name = strcat(Base_Path, '\', Folder_info(n_movie).name);
        
        for n_roi = 1 : N_ROI
            
            Folder_name = strcat(Base_Path, '\ROI_', num2str(n_roi));
            n_ch = 1;
            
            for n_stack = 1 : N_Stack
                n_image = (n_roi-1)*N_Stack + n_stack;
                hdcimg = dcimgmex('open', Movie_name);
                im = dcimgmex('readframe', hdcimg, n_image);
                
                Base_name = Folder_info(n_movie).name;
                Base_name = Base_name(1:end-6);
                New_movie_name = strcat(Base_name, '_Ch_', num2str(n_ch), '.tif');
                
                cd(Folder_name)
                cd(strcat('Ch_', num2str(n_ch)))
                
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
    end
end

%% The last part of the analysis is to calculate from the stack the in-focus 
%% image.
%% -----

[~, TIFF_FinaleDirectoryName] = Look_For_TIFF_Files_dcimg_conversion(SearchDirectory);
TIFF_FinaleDirectoryName = unique(TIFF_FinaleDirectoryName);
N_directory = size(TIFF_FinaleDirectoryName,1);

for n_dir = 1 : N_directory
    im_straighter_v3(512, 0, TIFF_FinaleDirectoryName{n_dir})
end
