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
                im_straighter(512, 0, Current_analyzed_folder, TIFF_selected, In_Focus_saving_folder)
            end
        end
    end
end

%% Definition of the im_straighter function
%%
%% 22-03-2019 : 
%% This new version of the im_straigther is working the same way than the previous v2
%% but is specifically designed for the Time Lapse experiments. It is called after
%% the conversion of dcimg image files in order to apply the refocus software
%% to each ROI and channel.
%% 05-06-2020 : Change the way the movies are read as well as the name of the files
%% ================================================================================

function im_straighter(WindowSize, verbose, Folder_name, TIFF, Save_folder)

if ~verbose
    close all
end

%% Load the baseline
%% -----------------

cd('C:\Users\sCMOS-1\Desktop\Matlab code\Image_refocusing\Baseline_data\BaseLine_references')
if WindowSize == 512
    BaseLine = load('BaseLine_OTF_512.mat');
elseif WindowSize == 1024
    BaseLine = load('BaseLine_OTF_1024.mat');
else
    warndlg('There is no baseline available for this window size.')
    stop
end
BaseLine = BaseLine.OTF_all;

%% Read the first image in order to define the image size and the arrays
%% ---------------------------------------------------------------------

cd(Folder_name)
imName = TIFF{1};
ImInfo = imfinfo(imName);
Ly = ImInfo(1).Width;
Lx = ImInfo(1).Height;

if Lx == Ly
    NROItot = Lx/WindowSize;
else
    warndlg('The images are expected to be square. The calculation is aborted')
    uiwait(warndlg)
    delete(warndlg)
    return
end

NPlanes = uint8(size(ImInfo,1));
AllPlanes = zeros(size(TIFF,1),NROItot^2);
Nelement = (WindowSize*WindowSize)-1;

parfor nimage = 1 : size(TIFF,1)
    
    %% Select an image and retrieve information regarding its size.
    %% Calculate the median intensity as well as it standard deviation
    %% in order to normalize each image of the stack.
    %% ----------------------------------------------
    
    cd(Folder_name)
    im = zeros(Lx,Ly,NPlanes);
    Plane_newIm = zeros(NROItot,NROItot);
    Area = zeros(NPlanes,1);
    LSF_all = zeros(2*Nelement,1);
    
    imName = TIFF{nimage};
    
    for plane = 1 : NPlanes
        im(:,:,plane) = imread(imName,plane);
    end
    
    ImSingleRow = reshape(im,[numel(im),1,1]);
    Mean = median(ImSingleRow);
    Std = std(ImSingleRow);
    
    %%  The image is splitted into "NROItot*NROItot", each with a size of
    %%  "WindowSize". For each ROI, the edge spread function (equivalent
    %% of the OTF but for one single direction) is calculated. The idea is
    %% to compare the ESF for each plane and pick only the plane with the
    %% sharpest details.
    %% The calculatation is done as follows :
    %%  1- for each plane, the image is cropped in order to select only one
    %%     portion defined by "Rect"
    %%  2- For each row and column, the ESF is calculated by renormalizing
    %%     the intensity and then the first order derivative is calculated.
    %%  3- The results is called the LSD = Line spread function.
    %%  4- The calculation is done sequentially on every rows and columns
    %%     and the result is stored in "LSF_all".
    %%  5- The OTF is then calculated using the Fourier transform of the LSF
    %%  6- Since the OTF is really noisy, the envelope of the curve is
    %%     calculated.
    %%
    %% In order to compare the results for each plane, the area of each
    %% curve is calculated. The plane displaying the largest area will also
    %% be the one with the sharpest details.
    %% -------------------------------------
    
    for ROI_x = 1:NROItot
        for ROI_y = 1:NROItot
            
            if verbose
                figure(1)
                hold off
                cla
            else
                figure(1)
                close
            end
            
            % Define the ROI used to crop the main image
            % ------------------------------------------
            
            Rect = [(ROI_x-1)*WindowSize+1,(ROI_y-1)*WindowSize+1,WindowSize-1,WindowSize-1];
            
            % For each plane, calculate the information and selecte the
            % plane with the largest amount of information as the in-focus
            % plane
            % ------
            
            for nplane = 1 : NPlanes
                
                ImCrop = imcrop(im(:,:,nplane), Rect);
                
                Line = reshape(ImCrop, [numel(ImCrop),1]);
                ESF = (Line - Mean)/Std;
                LSF = diff(ESF);
                LSF_all(1:Nelement) = LSF;
                
                Line = reshape(transpose(ImCrop), [numel(ImCrop),1]);
                ESF = (Line - Mean)/Std;
                LSF = diff(ESF);
                LSF_all(Nelement+1:end) = LSF;
                
                OTF = fft(LSF_all);
                OTF = abs(OTF);
                N = round(length(OTF)/2);
                OTF = (OTF(1:N) + flipud(OTF(end-N+1:end)))/2;
                %     OTF = OTF(OTF(:)>50);
                %     OTF = smooth(OTF,50,'lowess');
                [OTFup, ~] = envelope(OTF, 5000, 'rms');
                %     OTFup = OTFup - BaseLine*mean(OTFup(1:20))/mean(BaseLine(1:20));
                OTFup = OTFup - BaseLine*median(OTFup(end-50000:end))/median(BaseLine(end-50000:end));
                Area(nplane) = sum(OTFup);
                
                if verbose
                    figure(1);
                    hold on
                    plot(OTFup, '-', 'Color', [1 (nplane-1)/NPlanes 0], 'LineWidth', 2)
                    axis square
                    box on
                    hfig2 = gca;
                    hfig2.FontSize = 15;
                end
            end
            
            [~,plane] = max(Area);
            Plane_newIm(ROI_x,ROI_y) = plane;
            
            if verbose
                figure(2)
                hold off
                cla
                imagesc(imcrop(im(:,:,plane), Rect))
                axis image
                box on
                colormap('Gray')
                title(num2str(plane))
            end
        end
    end
    
    % Plot in a new figure how the planes have been selected to reconstruct
    % the in-focus image
    % ------------------
    
    if verbose
        figure(3)
        imagesc(Plane_newIm)
        axis image
        colorbar
        title('Disposition of the planes for the in-focus image')
    end
    
    AllPlanes(nimage,:) = reshape(Plane_newIm, [1 numel(Plane_newIm)]);
    disp(strcat('Image #', num2str(nimage,'%03d'), ' is analyzed'))
end

% Plot the histogram of the planes selected for the in-focus image as well
% as the plane selected as a function of time
% --------------------------------------------

cd(Save_folder)
save('All_planes.mat', 'AllPlanes');

for n_roi = 1 : NROItot*NROItot
    
    figure(5)
    subplot(NROItot,NROItot,n_roi)
    
    histogram(AllPlanes(:,n_roi))
    E = median(AllPlanes(:,n_roi));
    E = round(E);
    Std = std(AllPlanes(:,n_roi));
    title(strcat(num2str(E), '+/-', num2str(Std)))
    axis square
end

saveas(gcf,'Plane_distribution_histogram.png')

for n_roi = 1 : NROItot*NROItot
    
    figure(6)
    subplot(NROItot,NROItot,n_roi)
    
    plot(AllPlanes(:,n_roi), '-b')
    axis square
end

saveas(gcf,'Plane_distribution_time.png')

%% For each ROI, calculate the plane that was selected the most
%% ------------------------------------------------------------

MaxLikelihood_Planes = zeros(1, NROItot*NROItot);

for n_roi = 1 : NROItot*NROItot
    MaxLikelihood_Planes(:,n_roi) = round(median(AllPlanes(:,n_roi)));
end

%% Reconstruct the in-focus images according to the previous results. For
%% each ROI, if the selected plane is close to the MaxLikelihood planes,
%% then the selected plane is kept. If however, the selected planes is
%% separated by more than 2 planes from the MaxLikelihood, then the analysis
%% is performed again using only the planes that are the closest to the
%% MaxLikelihood.
%% -------------

for nimage = 1 : size(TIFF,1)
       
    cd(Folder_name)
    NewIm = zeros(Lx, Ly);
    imName = TIFF{nimage};
    
    Plane_newIm = AllPlanes(nimage,:);
    Plane_dist = abs(Plane_newIm - MaxLikelihood_Planes);
    
    Plane = Plane_newIm;
    Idx = Plane_dist(:)>2;
    Plane(Idx) = MaxLikelihood_Planes(Idx);
    
    Plane = reshape(Plane, [NROItot,NROItot]);
    Plane_unique = unique(Plane);
    
    for n_plane = 1 : length(Plane_unique)
        
        Selected_plane = Plane_unique(n_plane);
        im = imread(imName,Selected_plane);
        
        for row = 1 : NROItot
            for col = 1 : NROItot
                if Plane(row, col) == Selected_plane
                    Rect = [(row-1)*WindowSize+1,(col-1)*WindowSize+1,WindowSize-1,WindowSize-1];
                    ImCrop = imcrop(im, Rect);
                    NewIm((col-1)*WindowSize+1:(col-1)*WindowSize+WindowSize , (row-1)*WindowSize+1:(row-1)*WindowSize+WindowSize) = ImCrop;
                end
            end
        end
    end
    
    % The new "in-focus" image is then saved in a folder with a name fit
    % for super-segger.
    % -----------------
    
    cd(Save_folder)
    t = Tiff(imName, 'w');
    
    tagstruct = struct('ImageLength', size(NewIm,1), ...
        'ImageWidth', size(NewIm,2), ...
        'BitsPerSample', 16, ...
        'Photometric', Tiff.Photometric.MinIsBlack, ...
        'PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
    
    t.setTag(tagstruct);
    t.write(uint16(NewIm));
    t.close();
    
    disp(strcat('Image #', num2str(nimage,'%03d'), ' is saved'))
    
    if verbose
        figure(4)
        imagesc(NewIm)
        axis image
        colormap('Gray')
    end
end

disp('Calculation is done')
end