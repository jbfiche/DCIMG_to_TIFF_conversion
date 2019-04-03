clear all
close all
clc

[DCIMG_FinalFileName, DCIMG_FinaleDirectoryName, SearchDirectory] = Look_For_DCIMG_Files;
[TIFF_FinalFileName, TIFF_FinaleDirectoryName] = Look_For_TIFF_Files(SearchDirectory);

EraseTIFF = questdlg('Do you want to remove all tiff files?', 'Erase tif', 'YES', 'NO', 'NO');
switch EraseTIFF
    case 'YES'
        for nTiff = 1 : size(TIFF_FinaleDirectoryName,1)
            delete(strcat(TIFF_FinaleDirectoryName{nTiff}, '\', TIFF_FinalFileName{nTiff}))
        end
end

parfor nFile = 1 : size(DCIMG_FinalFileName,1)
    
    cd(DCIMG_FinaleDirectoryName{nFile})
    
    hdcimg = dcimgmex('open', DCIMG_FinalFileName{nFile});
    numFrames = dcimgmex( 'getparam', hdcimg, 'NUMBEROF_FRAME' );
    im_width = dcimgmex( 'getparam', hdcimg, 'IMAGE_WIDTH' );
    im_height = dcimgmex( 'getparam', hdcimg, 'IMAGE_HEIGHT' );
    
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
            imwrite(data, NewFileName)
        else
            imwrite(data, NewFileName, 'WriteMode', 'append')
        end
    end
    
    disp(strcat('Conversion of DCIMG file # ', num2str(nFile), ' / ', num2str(size(DCIMG_FinalFileName,1)), ' is done'))
end

disp('DCIMG to TIFF conversion is done!')