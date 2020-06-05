clear all
close all
clc

Saving_folder = 'Y:\DATA\Sara\DATA\TimeLapseData\PredationAssays\2020_05_29';

[~, TIFF_FinaleDirectoryName] = Look_For_TIFF_Files_dcimg_conversion(Saving_folder);
TIFF_FinaleDirectoryName = unique(TIFF_FinaleDirectoryName);
N_directory = size(TIFF_FinaleDirectoryName,1);

for n_dir = 1 : N_directory
    
    folder = TIFF_FinaleDirectoryName{n_dir};
    cd(folder)
    
    for n = length(folder) : -1 : 1
       if isequal(folder(n), '\')
           break
       end
    end
    Last_path_element = folder(n+1:end);
    
    Is_in_focus = dir('In_Focus_images');
    
    if length(Is_in_focus)~=502 && ~isequal(Last_path_element, 'In_Focus_images')
        im_straighter_v3(512, 0, TIFF_FinaleDirectoryName{n_dir})
    end
end