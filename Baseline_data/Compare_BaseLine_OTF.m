BaseFolder = '/mnt/PALM_dataserv/DATA/JB/JB/Sara/Data/Test_FTL_8_06_2018/Raw_images';
figure(1)
cla
hold on

MeanI = zeros(6,1);
StdI = zeros(6,1);
Color = {[1 0 0], [0.5 0.5 0], [1 1 0], [0 1 0], [0 0 1], [1 0 1]};
OTF = [];

for i = 1 : 6
    
    FolderName = strcat('/Im', num2str(i));
    cd(strcat(BaseFolder, FolderName));
    
    load('BaseLine_OTF.mat')
%     plot(OTF_all/OTF_all(1), '-', 'Color', Color{i}, 'LineWidth', 2)
    plot(OTF_all, '-', 'Color', Color{i}, 'LineWidth', 2)
    axis square
    box on
    hfig2 = gca;
    hfig2.FontSize = 15;
    
    ImName = strcat('Test', num2str(i), '.tif');
    im = imread(ImName, 'Index', 1);
    MeanI(i) = mean(mean(im));
    StdI(i) = std(std(double(im)));
    
end

legend('1', '2', '3', '4', '5', '6')