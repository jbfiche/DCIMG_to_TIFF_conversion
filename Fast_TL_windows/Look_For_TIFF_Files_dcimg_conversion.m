function [FinalFileName, FinaleDirectoryName] = Look_For_TIFF_Files_dcimg_conversion(DirectoryName)

cd(DirectoryName)
dim = 0;
AllDirectories = {};
FinalFileName = {};
FinaleDirectoryName = {};
dirinfo = dir();

% Look inside the selected folder whether there is a TIFF file
% --------------------------------------------------------------

dirinfo_TIFF = dir('*.tif');

if ~isempty(dirinfo_TIFF)
    for n = 1 : size(dirinfo_TIFF,1)
        FinaleDirectoryName{end+1,1} = dirinfo_TIFF(n).folder;
        FinalFileName{end+1,1} = dirinfo_TIFF(n).name; % Make sure the function is only returning directories and no files
    end
end

% Look at the folders inside the selected directory
% -------------------------------------------------

dirinfo(~[dirinfo.isdir]) = [];  %remove non-directories
NFolder = 0;

if length(dirinfo) > 2
    AllDirectories = cell(length(dirinfo)-2, 1);
    for k = 3 : length(dirinfo) % The two first are not directories '.' and '..'
        
        if ispc
            Path = strcat(DirectoryName, '\', dirinfo(k).name);
        elseif isunix
            Path = strcat(DirectoryName, '/', dirinfo(k).name);
        end
        if isdir(Path)
            
            if ispc
                AllDirectories{k-2} = strcat(DirectoryName, '\', dirinfo(k).name);
            elseif isunix
                AllDirectories{k-2} = strcat(DirectoryName, '/', dirinfo(k).name);
            end
            NFolder = NFolder + 1;
        end
    end
end

while NFolder > 0
    
    dim = dim + 1;
    NFolder = 0;
    
    for nFolder = 1 : size(AllDirectories,1)
        
        Path = AllDirectories{nFolder, dim};
        AllSubDirectories = {};
        
        for nSubFolder = 1 : size(Path, 1)
            if iscell(Path)
                dirinfo = dir(Path{nSubFolder});
                Path{nSubFolder};
            else
                dirinfo = dir(Path);
            end
            dirinfo(~[dirinfo.isdir]) = [];  %remove non-directories
            
            if length(dirinfo) > 2
                %                 AllSubDirectories = cell(length(dirinfo)-2, 1);
                for k = 3 : length(dirinfo) % The two first are not directories '.' and '..'
                    if iscell(Path)
                        if ispc
                            NewPath = strcat(Path{nSubFolder}, '\', dirinfo(k).name);
                        elseif isunix
                            NewPath = strcat(Path{nSubFolder}, '/', dirinfo(k).name);
                        end
                    else
                        if ispc
                            NewPath = strcat(Path, '\', dirinfo(k).name);
                        elseif isunix
                            NewPath = strcat(Path, '/', dirinfo(k).name);
                        end
                    end
                    if isdir(NewPath)
                        %                         AllSubDirectories{k-2} = strcat(NewPath);
                        AllSubDirectories{end+1,1} = strcat(NewPath);
                        NFolder = NFolder + 1;
                    end
                end
            end
        end
        
        AllDirectories{nFolder, dim+1} = AllSubDirectories;
        
    end
end

Directories = {};

for n = 1 : size(AllDirectories,1)
    for m = 1 : size(AllDirectories,2)
        
        Directories = cat(1, Directories, AllDirectories{n,m});
    end
end

for n = 1 : size(Directories,1)
    cd(Directories{n})
    
    dirinfo_TIFF = dir('*.tif');
    if ~isempty(dirinfo_TIFF)
        for nKymoFile = 1 : size(dirinfo_TIFF,1)
            if ispc
                FinalFileName{end+1,1} = dirinfo_TIFF(nKymoFile).name;
                FinaleDirectoryName{end+1,1} = dirinfo_TIFF(nKymoFile).folder;
            elseif isunix
                FinalFileName{end+1,1} = dirinfo_TIFF(nKymoFile).name;
                FinaleDirectoryName{end+1,1} = dirinfo_TIFF(nKymoFile).folder;
            end
        end
    end
end


cd(DirectoryName)