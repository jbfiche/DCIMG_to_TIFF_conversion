%% JB_22-03-2019
%% This new version of the im_straigther is working the same way than the previous v2
%% but is specifically designed for the Time Lapse experiments. It is called after
%% the conversion of dcimg image files in order to apply the refocus software
%% to each ROI and channel.
%% -----------------------

function im_straighter_v3(WindowSize, verbose, Folder_name)

if ~verbose
    close all
end

%% Load the baseline
%% _________________

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

%% Look for the folder where the images have been saved
%% ____________________________________________________

cd(Folder_name)
Images = dir('*.tif');

%% Define the folder where the in-focus images are going to be saved
%% _________________________________________________________________

Save_folder = strcat(Folder_name, '\In_Focus_images');
Result = isdir(Save_folder);
if ~Result
    mkdir(Save_folder)
else
    cd(Save_folder)
    delete *.tif
end

%% Read the first image in order to define the image size and the arrays
%% _____________________________________________________________________

cd(Folder_name)
imName = Images(1).name;
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
AllPlanes = zeros(size(Images,1),NROItot^2);
Nelement = (WindowSize*WindowSize)-1;

for nimage = 1 : size(Images,1)
    
    %% Select an image and retrieve information regarding its size.
    %% Calculate the median intensity as well as it standard deviation
    %% in order to normalize each image of the stack.
    %% _____________________________________________
    
    cd(Folder_name)
    im = zeros(Lx,Ly,NPlanes);
    Plane_newIm = zeros(NROItot,NROItot);
    Area = zeros(NPlanes,1);
    LSF_all = zeros(2*Nelement,1);
    
    imName = Images(nimage).name;
    
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
    %% ____________________________________
    
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
                [OTFup, OTFlow] = envelope(OTF, 5000, 'rms');
                %                 OTFup = OTFup - BaseLine*mean(OTFup(1:20))/mean(BaseLine(1:20));
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

save('All_planes.mat', 'AllPlanes');

% Plot the histogram of the planes selected for the in-focus image as well
% as the plane selected as a function of time
% --------------------------------------------

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
%% ____________________________________________________________

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
%% _____________

for nimage = 1 : size(Images,1)
       
    cd(Folder_name)
    NewIm = zeros(Lx, Ly);
    imName = Images(nimage).name;
    
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
    % ________________
    
    cd(Save_folder)
    ImName = strcat('Myxo60xBFt', num2str(nimage,'%05d'), 'xy001c1.tif');
    t = Tiff(ImName, 'w');
    
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