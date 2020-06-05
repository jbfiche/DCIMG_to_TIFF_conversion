clear all
close all
clc

%% Look for the DCIMG and TIFF files in the selected directory
%% -----------------------------------------------------------

[DCIMG_FinalFileName, DCIMG_FinaleDirectoryName, SearchDirectory] = Look_For_DCIMG_Files;
[TIFF_FinalFileName, TIFF_FinaleDirectoryName] = Look_For_TIFF_Files_dcimg_conversion(SearchDirectory);

%% In case TIFF files were already found, ask whether we should keep them or
%% delete them.
%% -----------

if ~isempty(TIFF_FinalFileName)
    EraseTIFF = questdlg('Tiff files were found. Do you want to remove all tiff files?', 'Erase tif', 'YES', 'NO', 'NO');
else
    EraseTIFF = 'NO';
end

parfor nFile = 1 : size(DCIMG_FinalFileName,1)
    
    % Select the directory and open the dcimg file
    % --------------------------------------------
    
    cd(DCIMG_FinaleDirectoryName{nFile})
    
    hdcimg = dcimgmex('open', DCIMG_FinalFileName{nFile});
    numFrames = dcimgmex( 'getparam', hdcimg, 'NUMBEROF_FRAME' );
    im_width = dcimgmex( 'getparam', hdcimg, 'IMAGE_WIDTH' );
    im_height = dcimgmex( 'getparam', hdcimg, 'IMAGE_HEIGHT' );
    
    % Check whether in the same folder you have a TIFF file with the same
    % name. Delete it if the option was selected
    % -------------------------------------------
    
    if isequal(EraseTIFF,'YES')
        Tiff_name = strcat(DCIMG_FinalFileName{nFile}(1:end-5), 'tif');
        Tiff_found = dir(Tiff_name);
        if ~isempty(Tiff_found)
            delete(Tiff_name)
        end
    end
    
    % Create the tif file
    % -------------------
    
    NewFileName = [];
    for n = 1 : size(DCIMG_FinalFileName{nFile},2)
        if isequal(DCIMG_FinalFileName{nFile}(1,n), '.')
            NewFileName = cat(2, DCIMG_FinalFileName{nFile}(1:n), 'tif');
            break
        end
    end
    
    if ~isempty(dir(NewFileName))
        delete(NewFileName)
    end
    
    for framenum = 0:numFrames-1
        
        data = dcimgmex( 'readframe', hdcimg, framenum);
        %         Movie(:,:,framenum)  = data;
        %         figure(1);
        %         imagesc(data);
        %         axis off equal;
        %         colormap gray;
        if framenum == 0
            imwrite(data, NewFileName, 'Compression', 'none')
        else
            imwrite(data, NewFileName, 'WriteMode', 'append', 'Compression', 'none')
        end
    end
    
    
    dcimgmex('close', hdcimg);
    disp(strcat('Conversion of DCIMG file # ', num2str(nFile), ' / ', num2str(size(DCIMG_FinalFileName,1)), ' is done'))
end

disp('DCIMG to TIFF conversion is done!')

%% After the conversion, the memory usage is increased by two-fold. In
%% order to avoid disk-space saturation, ask whether we want to delete the
%% dcimg file and keep only the TIFF
%% ---------------------------------

EraseDCIMG = questdlg('Do you want to remove the DCIMG files after the TIFF conversion?', 'Erase dcimg', 'YES', 'NO', 'NO');

for nFile = 1 : size(DCIMG_FinalFileName,1)
    
    cd(DCIMG_FinaleDirectoryName{nFile})
    delete(DCIMG_FinalFileName{nFile})
end