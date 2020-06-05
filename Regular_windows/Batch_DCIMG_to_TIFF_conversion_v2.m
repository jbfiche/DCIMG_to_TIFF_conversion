clear all
close all
clc

%% Indicate whether the conversion is for DAPI or RT
%% -------------------------------------------------

ConversionType = questdlg('Indicate the type of conversion', 'Conversion type', 'DAPI', 'RT', 'Cancel');

%% Look for the DCIMG and TIFF files in the selected directory
%% -----------------------------------------------------------

[DCIMG_FinalFileName, DCIMG_FinaleDirectoryName, SearchDirectory] = Look_For_DCIMG_Files;
[txt_FinalFileName, txt_FinaleDirectoryName] = Look_For_txt_Files(SearchDirectory);

%% Indicate the folder where to save the converted files
%% -----------------------------------------------------

SavingPath = uigetdir('X:\');
cd(SavingPath)

%% Depending on the type of experiment, create a folder for deconvolution
%% ----------------------------------------------------------------------

switch ConversionType
    case 'DAPI'
        
        mkdir('DAPI')
        Saving_folder = strcat(SavingPath, '\DAPI');
        
    case 'RT'
        
        mkdir('RT')
        Saving_folder = strcat(SavingPath, '\RT');
end

%% Create a copy of the architecture of the folder containing only the txt
%% files
%% -----

Sep = filesep;
Idx_sep = strfind(SearchDirectory,Sep);
FileSeed = SearchDirectory(Idx_sep(end):end);

hwb = waitbar(0, 'Copying txt files ...');
Ntxt = size(txt_FinalFileName,1);

for n_txt = 1 : Ntxt
    
    hwb = waitbar(n_txt/Ntxt);
    
    cd(Saving_folder)
    Idx_seed = strfind(txt_FinaleDirectoryName{n_txt},FileSeed);
    txt_relative_path = strcat(txt_FinaleDirectoryName{n_txt}(Idx_seed:end), Sep);
    
    Source_path = strcat(txt_FinaleDirectoryName{n_txt}, Sep, txt_FinalFileName{n_txt});
    Destination_path = strcat(Saving_folder, txt_relative_path, txt_FinalFileName{n_txt});
    
    % Since the folders indicated in the destination path do not exist
    % necessarely, a quick check is run
    % ---------------------------------
    
    Idx_sep = strfind(txt_relative_path,Sep);
    for nsep = 1 : size(Idx_sep,2)-1
        
        foldername = txt_relative_path(Idx_sep(nsep)+1:Idx_sep(nsep+1));
        try cd(foldername)
        catch error
            if isequal(error.identifier,'MATLAB:cd:NonExistentFolder')
                
                mkdir(foldername)
                cd(foldername)
            else
                disp(error)
            end
        end
    end
    
    % When the path to the file has been checked, the txt is copied
    % -------------------------------------------------------------
    
    copyfile(Source_path, Destination_path)
end

delete(hwb)

%% Start the conversion of the dcimg files
%% ---------------------------------------

Ndcimg = size(DCIMG_FinalFileName,1);

parfor nFile = 1 : Ndcimg
    
    % Define the path of the folder where the converted movie is going to
    % be saved
    % --------
    
    

    Idx_seed = strfind(DCIMG_FinaleDirectoryName{nFile},FileSeed);
    DCIMG_relative_path = strcat(DCIMG_FinaleDirectoryName{nFile}(Idx_seed:end), Sep);
    Saving_folder_deconvolution = strcat(Saving_folder,DCIMG_relative_path);
    
    try cd(Saving_folder_deconvolution)
        
        % Select the directory and open the dcimg file
        % --------------------------------------------
        
        cd(DCIMG_FinaleDirectoryName{nFile})
        
        hdcimg = dcimgmex('open', DCIMG_FinalFileName{nFile});
        numFrames = dcimgmex( 'getparam', hdcimg, 'NUMBEROF_FRAME' );
        im_width = dcimgmex( 'getparam', hdcimg, 'IMAGE_WIDTH' );
        im_height = dcimgmex( 'getparam', hdcimg, 'IMAGE_HEIGHT' );
        
        % Create the tif file
        % -------------------
        
        TifName = [];
        for n = 1 : size(DCIMG_FinalFileName{nFile},2)
            if isequal(DCIMG_FinalFileName{nFile}(1,n), '.')
                TifName = cat(2, DCIMG_FinalFileName{nFile}(1:n), 'tif');
                break
            end
        end
        
        Tiff_saving_path = strcat(Saving_folder_deconvolution, Sep, TifName);
        
        for framenum = 0:numFrames-1
            
            data = dcimgmex( 'readframe', hdcimg, framenum);
%             Movie(:,:,framenum)  = data;
%             figure(1);
%             imagesc(data);
%             axis off equal;
%             colormap gray;
            if framenum == 0
                imwrite(data, Tiff_saving_path, 'Compression', 'none')
            else
                imwrite(data, Tiff_saving_path, 'WriteMode', 'append', 'Compression', 'none')
            end
        end
        
        disp(strcat('Conversion of DCIMG file # ', num2str(nFile), ' / ', num2str(Ndcimg), ' is done'))
        
    catch error
        if isequal(error.identifier,'MATLAB:cd:NonExistentFolder')
            disp(strcat('Conversion of DCIMG file # ', num2str(nFile), ' / ', num2str(Ndcimg), ' is cancelled, the file is corrupted'))
        end
    end
end

disp('DCIMG to TIFF conversion is done!')
