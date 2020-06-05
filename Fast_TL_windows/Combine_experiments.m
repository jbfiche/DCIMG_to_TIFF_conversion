Folder_1 = 'E:\DATA\2019_03_21\005_FastTimeLapse_RAMM_Test\';
Folder_2 = 'E:\DATA\2019_03_21\006_FastTimeLapse_RAMM_Test\';

cd(Folder_1)
File_info_1 = dir('*.tif');
Nfile_1 = size(File_info_1,1);

cd(Folder_2)
File_info_2 = dir('*.tif');
Nfile_2 = size(File_info_2,1);

im_name = File_info_2(1).name;
im_info = imfinfo(im_name);
stack_size = size(im_info,1);

parfor n_movie = 1 : Nfile_2
    
    im_name = File_info_2(n_movie).name;    
    New_name = strcat(num2str(Nfile_1+n_movie-1, '%.3i'), im_name(4:end));
    
    for n_im = 1 : stack_size
        
        cd(Folder_2)
        im = imread(im_name, 'Index', n_im);
        if n_im == 1
            cd(Folder_1)
            imwrite(im, New_name, 'Compression', 'none')
        else
            cd(Folder_1)
            imwrite(im, New_name, 'Compression', 'none', 'WriteMode', 'append')
        end
    end
    disp(n_movie)
    
end
    
    
    
    
    
    