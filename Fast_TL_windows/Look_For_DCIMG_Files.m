function [FinalFileName, FinaleDirectoryName, DirectoryName] = Look_For_DCIMG_Files

DirectoryName = uigetdir('E:\');
cd(DirectoryName)
dim = 0;
AllDirectories = {};
FinalFileName = {};
FinaleDirectoryName = {};
dirinfo = dir();

% Look inside the selected folder whether there is a DCIMG file
% --------------------------------------------------------------

dirinfo_DCIMG = dir('*.dcimg');

if ~isempty(dirinfo_DCIMG)
    for n = 1 : size(dirinfo_DCIMG,1)
            FinalFileName{end+1,1} = dirinfo_DCIMG(n).name; % Make sure the function is only returning directories and no files
            FinaleDirectoryName{end+1,1} = dirinfo_DCIMG(n).folder;
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
    
    dirinfo_DCIMG = dir('*.dcimg');
    if ~isempty(dirinfo_DCIMG)
        for nKymoFile = 1 : size(dirinfo_DCIMG,1)
            if ispc
                FinalFileName{end+1,1} = dirinfo_DCIMG(nKymoFile).name;
                FinaleDirectoryName{end+1,1} = dirinfo_DCIMG(nKymoFile).folder;
            elseif isunix
                FinalFileName{end+1,1} = dirinfo_DCIMG(nKymoFile).name;
                FinaleDirectoryName{end+1,1} = dirinfo_DCIMG(nKymoFile).folder;
            end
        end
    end
end


cd(DirectoryName)