%% This soft was written for the analysis of the time lapse data. It runs
%% the conversion from dcimg to tiff files and save all the converted
%% stacks on the selected locations (ideally one of the server).
%% For the fast time laspe, all the ROIs ans channels are saved in one 
%% single file. The program is also sorting the stack according to the ROI
%% channel. The last part of the program is related to the calculation of
%% in focus images. 
%% 
%% Update 05-06-2020 : The converted images are now kept only as different
%% channels. Also, the in-focus correction is now performed only on the 
%% channel indicated by the user.

clear all
close all
clc

%% Look for all the .dcimg files in the selected folder and return the names
%% of the folders containing such data
%% -----------------------------------

[DCIMG_FinalFileName, DCIMG_FinaleDirectoryName, SearchDirectory] = Look_For_DCIMG_Files;
DCIMG_FinaleDirectoryName = unique(DCIMG_FinaleDirectoryName);
N_directory = size(DCIMG_FinaleDirectoryName,1);

%% Indicate where you want the movies to be saved 
%% ----------------------------------------------

Saving_folder = uigetdir('Y:\DATA', 'Select folder where the data should be saved:');

%% Ask the number of ROIs that were acquired during each cycle
%% -----------------------------------------------------------

prompt = {'Enter the number of ROIs:',...
    'Enter the number of channels:', ...
    'Enter the number of the channels for the in_focus calculation (coma separated):'};
title = 'Input';
dims = [1 35];
definput = {'9', '1', ''};
answer = inputdlg(prompt,title,dims,definput);

N_ROI = str2double(answer{1});
N_Channels = str2double(answer{2});
In_Focus_Channels = str2num(answer{3});

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
    
    % Define the name of the saving folder
    % ------------------------------------
    
    for n_char = length(Base_Path) : -1 : 1
        if isequal(Base_Path(n_char), '\')
            break
        end
    end
    
    Current_Saving_folder = strcat(Saving_folder,Base_Path(n_char:end));
    mkdir(Current_Saving_folder)
    
    % For each ROI a folder is created where the new movies will be saved. In
    % the same way, for each ROI, folders corresponding to each channel are
    % also created
    % ------------
    
    for n_channel = 1 : N_Channels
        Folder_name = strcat(Current_Saving_folder,'\Ch_', num2str(n_channel));
        mkdir(Folder_name)
    end
    
    % For each movie, the images are separated by ROI and channel and new
    % movies are created and saved
    % ---------------------------
    
    for n_movie = 1 : N_Movies
        
        Movie_name = strcat(Base_Path, '\', Folder_info(n_movie).name);
        hdcimg = dcimgmex('open', Movie_name);
        
        for n_roi = 1 : N_ROI
            
            n_ch = 1;
            
             for n_stack = 1 : N_Stack
                n_image = (n_roi-1)*N_Stack + n_stack;
                im = dcimgmex('readframe', hdcimg, n_image-1);
                
                Base_name = Folder_info(n_movie).name;
                Base_name = Base_name(1:end-6);
                New_movie_name = strcat(Base_name, '_Ch_', num2str(n_ch), '_ROI_', num2str(n_roi), '.tif');
                
                cd(strcat(Current_Saving_folder,'\Ch_', num2str(n_ch)))
                
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
        
        dcimgmex('close', hdcimg);
        clear('n_roi', 'n_ch', 'n_stack', 'n_image', 'im', 'hdcimg', 'Base_name', 'New_movie_name')
        disp(strcat('Conversion of DCIMG file # ', num2str(n_movie), ' / ', num2str(N_Movies), ' is done'))
    end
end

%% The last part of the analysis is to calculate from the stack the in-focus
%% image.
%% -----

if ~isempty(In_Focus_Channels)
    for n_channel = 1 : size(In_Focus_Channels,2)
        
        Current_analyzed_folder = strcat(Current_Saving_folder, '\Ch_', num2str(In_Focus_Channels(n_channel)));
        [TIFF_FileName, ~] = Look_For_TIFF_Files_dcimg_conversion(Current_analyzed_folder);
        N_tiff = size(TIFF_FileName,1);

        for n_roi = 1 : N_ROI
       
            Selected_files = zeros(N_tiff,1);
            Char = strcat('ROI_', num2str(n_roi));
            
            for n_file = 1 : N_tiff
                if ~isempty(strfind(TIFF_FileName{n_file}, Char))
                    Selected_files(n_file) = 1;
                end
            end
            
            TIFF_selected = TIFF_FileName(Selected_files==1);
            
            if ~isempty(TIFF_selected)
                In_Focus_dir = strcat(Current_analyzed_folder, '\In_Focus_images');
                mkdir(In_Focus_dir)
                In_Focus_saving_folder = strcat(In_Focus_dir, '\ROI_', num2str(n_roi));
                mkdir(In_Focus_saving_folder)
                im_straighter_FTL(512, 0, Current_analyzed_folder, TIFF_selected, In_Focus_saving_folder)
            end
        end
    end
end