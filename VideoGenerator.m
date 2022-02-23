% This Skript generates a Video File from the selected ZugVersuch Project
% Author      --- Ishwor Koirala
% Email       --- i@koirala.de (ishwor.koirala@htwg-konstanz.de) 
% Last edited --- 14.12.2021

% Selecting the Project 
ProjectPath = uigetdir('Bitte Ordner auswählen.');
[~, ProjectName] = fileparts(ProjectPath);

% Checking whether a project is valid or not
try
    load([ProjectName,'/',ProjectName,'.mat']);
catch
    error('Projekt nicht gültig!');                
end

% Starting a Video File
Video_file = VideoWriter([ProjectName,'_Video.avi']);
Video_file.FrameRate = 20;
open(Video_file);

% Starting a Figure to plot everything
Window = figure(1);
Window.OuterPosition = [0,0,1920,1080];

% Ploting the steps in For loop
for Frame = 1:length(FrameInfo)
    % Preparing for x-axis
    TimeVec = ref.TimeVec(1:Frame);
    DisVec = ref.DisVec(1:Frame);
    [minT, maxT] = bounds(TimeVec);
    minTD = datetime(minT, 'ConvertFrom','datenum');
    maxTD = datetime(maxT, 'ConvertFrom', 'datenum');
    duration = maxTD - minTD;
    durationVec = datetime(TimeVec,'ConvertFrom','datenum')-...
        minTD;
                        
    % Preparing for y-axis
    expansion = (DisVec - DisVec(1))./DisVec(1)*100;
    
    %Plotting the Data
    subplot(1,2,1);
    plot(durationVec,expansion);
    xlim('auto')
    ylim('auto')
    xtickangle(45);
    
    % Setting x and ylabel
    ylabel('Ausdehnung in [%]');
    if duration > hours(72)
        % Show ylabel in Days
        xtickformat('d');
        xlabel('Zeit in Tagen');
    elseif duration > minutes(180)
        % Show ylabel in Hours
        xtickformat('h');
        xlabel('Zeit in Stunden');
    else 
        % Show ylabel in mm:ss
        xtickformat('mm:ss');
        xlabel('Zeit in mm:ss');
    end

    % Ploting Current Frame with Overlay
    subplot(1,2,2)
    % Loading Current Frame to matlab
    Img = imread([ProjectName,'/',FrameInfo{Frame}.FrameName]);
    % Geting the location of Points
    rel_location = [FrameInfo{Frame}.XabsUp,...
        FrameInfo{Frame}.YabsUp,40;...
        FrameInfo{Frame}.XabsDown,...
        FrameInfo{Frame}.YabsDown,40];

    % Calculating the middle point of the points
    x_middle = (FrameInfo{Frame}.XabsUp + FrameInfo{Frame}.XabsDown)/2;
    y_middle = (FrameInfo{Frame}.YabsUp + FrameInfo{Frame}.YabsDown)/2;

    % Calculating the Position of Message
    x_message = x_middle -240;
    y_message = y_middle + 50;
    offset_arrow = DisVec(Frame)/2 - 60;

    % Circle Overlay 
    label = {'',''};
    img_with_circle = insertObjectAnnotation(Img,'circle',rel_location,label,'LineWidth',...
        6,'Color',{'magenta','magenta'},'TextColor','black','FontSize',40);
    % Message Overlay
    Message = ['Distance: ',num2str(DisVec(Frame),'%.2f'),'px'];
    img_with_annotation = insertObjectAnnotation(img_with_circle,'circle',[x_message,y_message,0],Message,'LineWidth',...
        1,'Color','cyan','TextColor','black','FontSize',50);
    
    % Showing image
    imshow(img_with_annotation); hold on; 
    quiver(x_middle,y_middle+50,0,offset_arrow,'LineWidth',2,'Color','cyan')
    quiver(x_middle,y_middle-50,0,-offset_arrow,'LineWidth',2,'Color','cyan')
    hold off
    drawnow;
    
    % Saving the Frame to Video
    writeVideo(Video_file,getframe(gcf));
end
% Closing and saving the Video
close(Video_file)
close all;
