classdef ZugVersuch < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ZeitstandzugversuchUIFigure  matlab.ui.Figure
        TabGroup                     matlab.ui.container.TabGroup
        NeuerVersuchTab              matlab.ui.container.Tab
        KeinProjektLabel             matlab.ui.control.Label
        ResetButton                  matlab.ui.control.Button
        VersuchBeendenButton         matlab.ui.control.Button
        Lamp_4                       matlab.ui.control.Lamp
        Lamp_3                       matlab.ui.control.Lamp
        Lamp_2                       matlab.ui.control.Lamp
        Lamp                         matlab.ui.control.Lamp
        Lamp_5                       matlab.ui.control.Lamp
        VersuchStartenButton         matlab.ui.control.Button
        CameraKalibrationButton      matlab.ui.control.Button
        KameraCheckButton            matlab.ui.control.Button
        ArduinoCheckButton           matlab.ui.control.Button
        ProjektStartenButton         matlab.ui.control.Button
        UIAxes                       matlab.ui.control.UIAxes
        VersuchFortsetzenTab         matlab.ui.container.Tab
        KeinProjektLabel_2           matlab.ui.control.Label
        ResetButton_2                matlab.ui.control.Button
        VersuchBeendenButton_2       matlab.ui.control.Button
        Lamp_10                      matlab.ui.control.Lamp
        Lamp_9                       matlab.ui.control.Lamp
        Lamp_8                       matlab.ui.control.Lamp
        Lamp_7                       matlab.ui.control.Lamp
        Lamp_6                       matlab.ui.control.Lamp
        ProjektFortsetzenButton      matlab.ui.control.Button
        CameraKalibrationButton_2    matlab.ui.control.Button
        KameraCheckButton_2          matlab.ui.control.Button
        ArduinoCheckButton_2         matlab.ui.control.Button
        ProjektAuswhlenButton        matlab.ui.control.Button
        UIAxes_2                     matlab.ui.control.UIAxes
        ExtrasTab                    matlab.ui.container.Tab
        Label_5                      matlab.ui.control.Label
        Label_4                      matlab.ui.control.Label
        Label_3                      matlab.ui.control.Label
        Label_2                      matlab.ui.control.Label
        Label                        matlab.ui.control.Label
        aktuelleAusdehnungLabel      matlab.ui.control.Label
        vergangeneZeitLabel          matlab.ui.control.Label
        aktuellerFrameLabel          matlab.ui.control.Label
        GesamtdauerLabel             matlab.ui.control.Label
        echteWartezeitLabel          matlab.ui.control.Label
        InformationenLabel           matlab.ui.control.Label
        SpeichernButton              matlab.ui.control.Button
        GesamtFramesEditField        matlab.ui.control.NumericEditField
        GesamtFramesEditFieldLabel   matlab.ui.control.Label
        CropYEditField               matlab.ui.control.NumericEditField
        CropYEditFieldLabel          matlab.ui.control.Label
        WartezeitsEditField          matlab.ui.control.NumericEditField
        ZeitzwischendenBildernLabel  matlab.ui.control.Label
        CropXEditField               matlab.ui.control.NumericEditField
        CropXEditFieldLabel          matlab.ui.control.Label
        EinstellungenLabel           matlab.ui.control.Label
        UIAxes2                      matlab.ui.control.UIAxes
    end

    
    properties (Access = private)

    end
        
    properties (Access = public)
        % Location of API for uEye (IDS) cameras
        ueyeApiLoc = ['C:\Program Files\IDS\uEye\Develop\'...
           'DotNet\signed\uEyeDotNet.dll'];
        % Location of Camera Manager Application
        idsCamLoc = ['C:\ProgramData\Microsoft\Windows\Start Menu\',...
            'Programs\IDS\IDS Kameramanager.lnk'];
        appFolder; % Location of this application for other references
        ScreenSize; % Size of the Monitor
        guiSize; % Size of GUI
        calWinSize; % Size of Calibration & AOI Window
        ProjectName; % Name of current Project
        ProjectPath; % Path to the current Project
        Flash; % Arduino Object
        CamSuccess; % Success Message for uEye Camera Object
        CamPar; % Camera Parametere like Exposure
        Camera; % Camera Object for current Camera
        Image; % Image Object for the Image taken from Camera
        AOISelectButton; % Okay Button to start AOI selection
        AOIConfirmButton; % Okay Button to confirm AOI selection
        LoadedFrameInfo; % Frame Infos of the loaded Project
        loadedRef; % Reference of loaded Project
        newProject; % Variable to decide if a Project is new or old
        Experiment = 1; % Variable to break the Project
        
        Delay = 15; % Time Interval to take next Frame [in Seconds] 
        % Setting for the AOI (area of interest) of next Frame. The AOI 
        % will be 2*CropY in Y direction and 2*CropX in X direction
        CropY = 150; % 150px up and 150px down from last Point
        CropX = 75; % 75px left and 75px right from last Point
        FrameLimit = 10000; % It is the maximum Frames taken by the System

        % Variables for the Information window of Extras Tab
        TotalTime; % Total Time needed for the Experiment
        realDelay; % Real Time interval between two frames
        cFrame = 0; % Current Frame number
        cExpansion = 0; % Current expansion in %
        TimePassed = '0 Second'; % Time Passed since the start of experiment

    end
    
    methods (Access = private)
       
        function setGUISize(app)
            % -- This function sets the size and position of GUI ---
            % Setting Position for GUI Window 
                app.ZeitstandzugversuchUIFigure.Position = round([app.guiSize.x,...
                    app.guiSize.y, app.guiSize.w, app.guiSize.h]);

            % Setting Position for TabGroups
            % Start from Bottom left of Window and equal to the GUI Window
            % size
            app.TabGroup.Position = [0,0,app.guiSize.w,app.guiSize.h];
        end
                
        function ScreenResolution(app)
            % -- This function gets the real Resolution of Monitor, scaled
            % resolution as well as size of Taskbar and Title Bar. This is
            % used to position the GUI in the middle of Screen. ---

            % Get Real Screen Resolution
            toolkit = java.awt.Toolkit.getDefaultToolkit();
            scr_size = toolkit.getScreenSize();
            RealWidth = scr_size.width;            

            % Get Scaled Screen Resolution 
            MatWinSize = get(0, 'ScreenSize');
            ScaledWidth = MatWinSize(3); ScaledHeight = MatWinSize(4);
            
            % Get Real Taskbar Height
            jframe = javax.swing.JFrame;
            insets = toolkit.getScreenInsets...
                (jframe.getGraphicsConfiguration());
            TaskBarHeight = insets.bottom;
            
            % Calculate Scaled Taskbar Height
            ScreenMagnification = RealWidth / ScaledWidth;
            ScaledTaskBarHeight = TaskBarHeight/ScreenMagnification;
            
            % Get Scaled Titlebar Height
            fh = figure('Menu','none','ToolBar','none','Visible','off');
            titleBarHeight = fh.OuterPosition(4) - fh.InnerPosition(4)...
                + fh.OuterPosition(2) - fh.InnerPosition(2); delete(fh)

            % Saving all the Properties in a Variable
            app.ScreenSize.Width = ScaledWidth;
            app.ScreenSize.Height = ScaledHeight;
            app.ScreenSize.TaskBar = ScaledTaskBarHeight;
            app.ScreenSize.TitleBar = titleBarHeight;
        end

        function guiWinSize(app)
            % --- This function calculates the size of the GUI window
            % according to screen resolution and Padding defined by the
            % user ---

            % Position of UIFigure
            if app.ScreenSize.Height > 720
                % If the screen height is greater than this value the
                % windows size of the GUI remains constant as defined below
                app.guiSize.h = 640; % Height of GUI
                % y position of the GUI
                app.guiSize.y = (app.ScreenSize.Height ...
                    - app.guiSize.h - app.ScreenSize.TaskBar)/2 ...
                    + round(app.ScreenSize.TitleBar) ...
                    + app.ScreenSize.TaskBar;
            else
                % This is for the smaller screen
                Padding = 5; % 5px Padding for smaller Screen
                app.guiSize.y = app.ScreenSize.TaskBar + Padding;
                app.guiSize.h = app.ScreenSize.Height - app.guiSize.y - ...
                    round(app.ScreenSize.TitleBar) - Padding; 
            end
            % Width of the GUI is defined as 4/3 of the screen height
            app.guiSize.w = app.guiSize.h * 4/3;
            % X Position of the GUI is defined so that the GUI remains in
            % the middle of the screen
            app.guiSize.x = (app.ScreenSize.Width - app.guiSize.w)/2; 
        end

        function calibrationWinSize(app)
            % Position of Calibration Screen
            calPadding = 0.05; % Padding in % of Windows Size
            x = calPadding * app.ScreenSize.Width;
            y = calPadding * app.ScreenSize.Height + (1 - calPadding) * ...
                app.ScreenSize.TaskBar;
            h = (1 - 2 * calPadding) * app.ScreenSize.Height ...
                - app.ScreenSize.TaskBar;
            w = 2 * round((1920/2560 - 0.01) * h);
            app.calWinSize = [x, y, w, h];
        end
        
        function app = createProjectFolder(app)
            % --- This function asks the user to enter the project name and
            % checks for the wildcards. If there is no wildcards in the
            % input, it creates a folder. It also checks if the folder
            % already exists and warns the user. ---

            % 1. Asking for Project Name / Folder Name
            newProjectName = inputdlg('Wie soll das Projekt heißen?',...
                'Projektname Eingeben',[1 60]);
            % Adding 'proj_' prefix so that it can be identified as a
            % project folder in explorer
            app.ProjectName = ['proj_',newProjectName{1}];

            % 2. Check for Wildcards in Folder Name
            % 'fullfile' gives the name of Project accepted by OS
            validName = fullfile(app.ProjectName);
            % If the name entered by user and the name unterstood by OS is
            % not the same, there should be wildcards in project name.
            if ~strcmp(validName,app.ProjectName) || ~isempty(regexp(...
                    app.ProjectName,'/', 'once'))
                Message = ['Die von eingegebene Projektname enthält ' ...
                    'unzulässige Buchstaben. Bitte geben Sie ein neue' ...
                    'Projektname ein.'];
                Topic = 'Unzulässige Buchstaben!';
                uialert(app.ZeitstandzugversuchUIFigure,Message,Topic,...
                    'Icon','warning','CloseFcn', @AlertCallback);
                % Waits untill Okay button is clicked
                uiwait(app.ZeitstandzugversuchUIFigure);
                app = createProjectFolder(app); % Rekursive function
            end
            
            % 3. Checking if the Folder/Project already exists
            if isfolder(fullfile(app.ProjectPath,app.ProjectName))
                Message = ['Ein Ordner mit Name .. ',app.ProjectName,...
                    ' .. existiert bereit! Möchten Sie diesen Ordner ' ...
                    'überschreiben oder ein neues Ordner benutzen?'];
                Topic = 'Ordner Existiert Bereit!';
                answer = questdlg(Message, Topic,'Überschreiben',...
                    'Neues Ordner Auswählen','Überschreiben');
                if strcmp(answer, 'Neues Ordner Auswählen')
                    app = createProjectFolder(app); % Rekursive function
                end
            end

            % 4. Creating Folder
            [status, ~, ~] = mkdir(app.ProjectPath,app.ProjectName);   

            % 5. Checking if the folder is successfully created
            if ~status
                Message = ['Matlab kann kein neue Ordner erstellen. ' ...
                    'Überprüfen Sie ob MatLab genug rechte hat und ' ...
                    'versuchen Sie es erneut mit Projekt Starten'];
                Topic = 'Erzeugen eines neuen Ordners nicht möglich!';
                uialert(app.ZeitstandzugversuchUIFigure,Message,Topic,...
                    'Icon','error','CloseFcn', @AlertCallback);
                % Waits untill Okay button is clicked
                uiwait(app.createProjectFolder);
                startupFcn(app); % Restart GUI
            end
            
            % 6. Saves the project path as a variable
            app.ProjectPath = fullfile(app.ProjectPath,app.ProjectName);
            
            function AlertCallback(~,~)
                % --- Function to pause matlab execution untill the user
                % confirms the warning message ---
                uiresume(app.ZeitstandzugversuchUIFigure);
            end     
        end
                
        function ArduinoNotConnected(app)
            % --- This function will be executed, if no Arduino is detected
            % by the system. It will give a warning to the user and stops
            % the project. ---
            Message = ['Kein Arduino Uno erkannt. Bitte stellen' ...
                ' Sie sicher, dass Arduino Uno für die' ...
                ' Beleuchtung angeschlossen ist.'];
            Topic = 'Arduino Anschließen';
            % Alerting user
            uialert(app.ZeitstandzugversuchUIFigure,Message,Topic,...
                'Icon','warning','CloseFcn',@AlertCallback);
            % Waits untill Okay button is clicked
            uiwait(app.ZeitstandzugversuchUIFigure);
            % Show Button to try again
            if app.newProject
                app.ArduinoCheckButton.Enable = 'on';
            else
                app.ArduinoCheckButton_2.Enable = 'on';
            end

            function AlertCallback(~,~)
                % --- Function to pause matlab execution untill the user
                % confirms the warning message ---
                uiresume(app.ZeitstandzugversuchUIFigure);
            end                
        end

        function app = ExposureCallback(app,newExposure)
            % --- This function is executed if the exposure of camera is
            % changed in the exposure slider of calibration window. It
            % changes the changed parameter to true and sets the new
            % exposure. ---
            app.CamPar.Changed = 1;
            app.CamPar.Exposure = newExposure;   
        end        
        
        function ErrorValue = chkErr(app, err, Name)
            % --- This function checks if there was any error during
            % performing tasks using camera. If there was any error, it
            % would give error message as output and changes ErrorValue to
            % true ---
            if err ~= app.CamSuccess
                Message = ['Fehler beim Abrufen von: ',Name];
                uialert(app.ZeitstandzugversuchUIFigure,Message,'Error',...
                    'Icon','error');
                ErrorValue = 1;
            else
                ErrorValue = 0;
            end
        end
        
        function app = StartCamera(app)
            % --- This function starts the camera and sets all the camera
            % parameters that is relevant for this project. ---

            % 1. Creating camera object handle if it is not already 
            % created
            if isempty(app.Camera)
                app.Camera = uEye.Camera;
            end

            % 2. Starting first camera if it is not already opened
            if ~app.Camera.Device.IsOpened
                status = app.Camera.Init;
                % Checking error during execution
                if chkErr(app, status, 'Camera Init'), return; end               
            end

            % 3. Setting Colormode to 8-bit RAW
            status = app.Camera.PixelFormat.Set...
                (uEye.Defines.ColorMode.SensorRaw8);
            if chkErr(app, status, 'Pixel Format'), return; end

            % 4. Setting trigger mode to software
            status = app.Camera.Trigger.Set...
                (uEye.Defines.TriggerMode.Software);
            if chkErr(app, status, 'Trigger Mode'), return; end

            % 5. Changing Exposure Time
            status = app.Camera.Timing.Exposure.Set(app.CamPar.Exposure);
            if chkErr(app, status, 'Exposure Time'), return; end

            % 6. Setting Shutter Mode to Rolling Shutter
            status = app.Camera.Device.Feature.ShutterMode.Set...
                (uEye.Defines.Shuttermode.Rolling);
            if chkErr(app, status, 'Shutter Mode'), return; end

            % 7. Allocating image memory
            [status, app.Image.ID] = app.Camera.Memory.Allocate(true);
            if chkErr(app, status, 'Memory Allocation'), return; end

            % 8. Obtaining image information
            [status, app.Image.Width, app.Image.Height, app.Image.Bits,...
                app.Image.Pitch] = app.Camera.Memory.Inquire(app.Image.ID);
            if chkErr(app, status, 'Image Information'), return; end      
        end
        
        function app = triggerImage(app)
            % --- When this function is executed, it will turn flash on,
            % takes an Image from camera, turns the flash off, reshapes the
            % Image and saves the data in a Variable ---

            % 1. Turning on the Flash
            writePWMVoltage(app.Flash, 'D11', 5);

            % 2. Capturing Image and saving into Camera Memory
            status = app.Camera.Acquisition.Freeze(true);
            if chkErr(app, status, 'Image Acquistion'), return; end

            % 3. Turning off the Flash
            writePWMVoltage(app.Flash, 'D11', 0);        

            % 4. Copying Image to Matlab Memory
            [status, tmpImg] = app.Camera.Memory.CopyToArray(app.Image.ID); 
            if chkErr(app, status, 'Copy to Array'), return; end

            % 5. Reshaping image according to the image size
            app.Image.Data = reshape(uint8(tmpImg), ...
                [app.Image.Width, app.Image.Height, app.Image.Bits/8])';
        end
        
        function startExperiment(app,AOIFigure)
            % --- This function is the core of this Programm. After
            % choosing AOI (area of interest) of upper and lower point,
            % this function is executed. Everything from triggering Image
            % to Distance Calculation and saving happens within this
            % function. ---

            % 1. Closing the AOIFigure
            app.AOIConfirmButton.Visible = 'off';
            AOIFigure.Visible = 'off';
            clear AOIFigure;

            % 2. Setting button Visibility    
            if app.newProject
                app.VersuchStartenButton.Enable = 'off';
                app.Lamp_5.Color = 'g';   
            else
                app.ProjektFortsetzenButton.Enable = 'off';
                app.Lamp_6.Color = 'g';
            end

            % 3. Getting the area where the points are located
            upFrame = imcrop(app.Image.Data, app.Image.upRect);
            downFrame = imcrop(app.Image.Data, app.Image.downRect);

            % 4. Getting the relative location of points
            [XrelUp, YrelUp] = getRelLoc(upFrame);
            [XrelDown, YrelDown] = getRelLoc(downFrame);

            % 5. Absolute location of points
            XabsUp = round(XrelUp + app.Image.upRect(1));
            YabsUp = round(YrelUp + app.Image.upRect(2));
            XabsDown = round(XrelDown + app.Image.downRect(1));
            YabsDown = round(YrelDown + app.Image.downRect(2)); 

            % 6. Initializing the Parameters for Loop
            ref.Exposure = app.CamPar.Exposure;
            app.UIAxes2.XLim = [0 width(app.Image.Data)];
            app.UIAxes2.YLim = [0 height(app.Image.Data)]; 
            if app.newProject
                % New Project starts from Frame 1 and the plot should be in
                % new project Axis
                currentFrame = 1;
                Fig_Axis = app.UIAxes;
            else
                currentFrame = length(app.LoadedFrameInfo) + 1;
                DisVec = app.loadedRef.DisVec;
                TimeVec = app.loadedRef.TimeVec;
                FrameInfo = app.LoadedFrameInfo;
                Fig_Axis = app.UIAxes_2;
            end
            

            % 7. Enabling 'Versuch Beenden' Button
            if app.newProject
                app.VersuchBeendenButton.Enable = 'on';
                app.Lamp_5.Enable = 'on';
            else
                app.VersuchBeendenButton_2.Enable = 'on';
                app.Lamp_6.Enable = 'on';
            end
            
            % 8. Starting Loop
            StartTime = tic;
            FirstLoop = 1; % Variable to detect the start of loop

            while true
                % 8.01 Breaks loop if app.Experiment is false
                if ~app.Experiment
                    break;
                end

                % 8.02 Trigger a new Image
                app = triggerImage(app);      
                TimeTaken = now;

                % 8.03 Correcting the distortion
                temp_undistort = undistortImage(app.Image.Data,...
                    app.CamPar.disCorr);
                app.Image.Data = rot90(temp_undistort);

                % 8.04 Preparing the info of last point
                if ~FirstLoop
                    XabsUp = round(FrameInfo{currentFrame-1}.XabsUp);
                    YabsUp = round(FrameInfo{currentFrame-1}.YabsUp);
                    XabsDown = round(FrameInfo{currentFrame-1}.XabsDown);
                    YabsDown = round(FrameInfo{currentFrame-1}.YabsDown);
                else
                    % takes the location of points from the user selected
                    % AOI and sets the FirstLoop to false for next Loop
                    FirstLoop = 0;
                end

                % 8.05 Cropping the relevant region for Point detection
                upRect = [XabsUp - app.CropX, YabsUp - app.CropY,...
                    2 * app.CropX, 2 * app.CropY];
                upFrame = imcrop(app.Image.Data, upRect);
                downRect = [XabsDown - app.CropX, YabsDown - app.CropY, ...
                    2 * app.CropX, 2 * app.CropY];
                downFrame = imcrop(app.Image.Data,downRect);

                % 8.06 Get relative Location of Point
                [XrelUp, YrelUp] = getRelLoc(upFrame);
                [XrelDown, YrelDown] = getRelLoc(downFrame);   

                % 8.07 Absolute Location of Points
                XabsUp = XrelUp + upRect(1);
                YabsUp = YrelUp + upRect(2);
                XabsDown = XrelDown + downRect(1);
                YabsDown = YrelDown + downRect(2);    
                
                % 8.08 Calculating Distance
                Distance = sqrt((YabsDown-YabsUp)^2+(XabsDown-XabsUp)^2);

                % 8.09 Saving Time and Distance in an array
                DisVec(currentFrame) = Distance;
                TimeVec(currentFrame) = TimeTaken;

                % 8.10 Plotting current progress

                % 8.10.1 Preparing for x-axis
                [minT, maxT] = bounds(TimeVec);
                minTD = datetime(minT, 'ConvertFrom','datenum');
                maxTD = datetime(maxT, 'ConvertFrom', 'datenum');
                duration = maxTD - minTD;
                durationVec = datetime(TimeVec,'ConvertFrom','datenum')-...
                    minTD;
                % 8.10.2 Preparing for y-axis
                expansion = (DisVec - DisVec(1))./DisVec(1)*100;

                % 8.10.3 Plotting the Data
                plot(Fig_Axis,durationVec,expansion);
                Fig_Axis.Visible = 'on';
                xlim(Fig_Axis,'auto')
                ylim(Fig_Axis,'auto')
                daspect(Fig_Axis,'auto');
                Fig_Axis.YDir = 'normal';
                Fig_Axis.XTickLabelRotation = 45;

                % 8.10.4 Setting x and ylabel
                ylabel(Fig_Axis,'Ausdehnung in [%]');
                if duration > hours(72)
                    % Show ylabel in Days
                    xtickformat(Fig_Axis,'d');
                    xlabel(Fig_Axis,'Zeit in Tagen');
                    app.TimePassed = string(duration,'d');
                elseif duration > minutes(180)
                    % Show ylabel in Hours
                    xtickformat(Fig_Axis,'h');
                    xlabel(Fig_Axis,'Zeit in Stunden');
                    app.TimePassed = string(duration,'h');
                else 
                    % Show ylabel in mm:ss
                    xtickformat(Fig_Axis,'mm:ss');
                    xlabel(Fig_Axis,'Zeit in mm:ss');
                    app.TimePassed = string(duration,'mm:ss');
                end
                drawnow;

                % 8.11 Saving Mechanism for Project
                % 8.11.1 Saving Image
                % Generating name of file based on frame no., project name
                % and time taken
                FrameNum = num2str(currentFrame, '%05d');
                TimeStr = datestr(TimeTaken,'yymmdd_HHMMSS');
                FrameName = [FrameNum,'-',app.ProjectName,'-',TimeStr,...
                    '.png'];
                % Saving the current frame in project folder
                imwrite(app.Image.Data,[app.ProjectPath,'/',FrameName]...
                    ,'png');

                % 8.11.2 Saving Mat File
                % Information of current Frame
                FrameData.Distance = Distance;
                FrameData.Time = TimeTaken;
                FrameData.XabsUp = XabsUp;
                FrameData.YabsUp = YabsUp;
                FrameData.XabsDown = XabsDown;
                FrameData.YabsDown = YabsDown;
                FrameData.FrameName = FrameName;
                FrameInfo{currentFrame} = FrameData;
                % General information about this Project
                ref.OriginalLength = DisVec(1);
                ref.OriginalTime = TimeVec(1);                
                ref.LastTime = TimeTaken;
                ref.DisVec = DisVec;
                ref.TimeVec = TimeVec;
                % Saving all the information in a mat File
                save([app.ProjectPath,'/',app.ProjectName,'.mat'],...
                    'FrameInfo','ref');

                % Showing Label in Current Frame (Extras)
                LocationCir = [XabsUp, YabsUp, 40; XabsDown, YabsDown, 40];
                x = (XabsUp + XabsDown)/2;
                y = (YabsUp + YabsDown)/2;
                a = x -240;
                b = y + 50;
                arrowLength = Distance/2 - 60;
                FCircle = insertObjectAnnotation(app.Image.Data,...
                    'circle',LocationCir,{'',''},'LineWidth',6,'Color',...
                    {'magenta','magenta'},'TextColor','black',...
                    'FontSize',40);
                
                Message = ['Distance: ',num2str(DisVec(currentFrame),...
                    '%.2f'),'px'];
                FLabel = insertObjectAnnotation(FCircle,'circle',[a,b,0]...
                    ,Message,'LineWidth',1,'Color','cyan','TextColor',...
                    'black','FontSize',50);
                
                imshow(FLabel,'Parent',app.UIAxes2)
                hold(app.UIAxes2,'on') 
                quiver(x,y+50,0,arrowLength,'LineWidth',2,'Color',...
                    'cyan','Parent',app.UIAxes2);
                quiver(x,y-50,0,-arrowLength,'LineWidth',2,'Color',...
                    'cyan','Parent',app.UIAxes2);
                hold(app.UIAxes2,'off') 
                drawnow;

                % 8.12 Informations on Extra Tab
                app.cFrame = currentFrame;
                app.cExpansion = expansion(currentFrame);
                showInformation(app);

                % 8.13 Loop Management
                currentFrame = currentFrame + 1;
                % Breaking loop on Break detection
                if currentFrame ~= 1
                    DiffDistance = Distance - FrameInfo{currentFrame -...
                        1}.Distance;
                    if DiffDistance > 70 % Breaks loop if dist > 70
                        uialert(app.ZeitstandzugversuchUIFigure,...
                            'Bruch Erkannt !','Versuch Beendet','Icon',...
                            'info');
                        break;
                    end
                end
                % Breaking loop on excessive frame count (due to Storage
                % limitation)
                if currentFrame > app.FrameLimit
                    break;
                end

                % 8.13 
                
                % 8.13 Delay untill next Frame
                % Waits untill Time is greater than Delay
                while toc(StartTime) < app.Delay
                    if ~app.Experiment
                        break;
                    end                    
                    pause(0.1);
                end 

                % 8.14 
                app.realDelay = toc(StartTime);
                app.TotalTime = duration + seconds(app.realDelay * ...
                    (app.FrameLimit - currentFrame));
                StartTime = tic;
            end
            
            % 9. Disabling 'Versuch Beenden' Buttons and notifying user
            app.VersuchBeendenButton.Enable = 'off';
            app.VersuchBeendenButton_2.Enable = 'off';
            uialert(app.ZeitstandzugversuchUIFigure,...
                'Versuch Beendet !','Versuch Beendet','Icon','info');  

            % 10. Closing Camera
            if ~isempty(app.Camera)
                app.Camera.Exit;
                app.Camera = [];  
            end

        function [x,y] = getRelLoc(Frame)
            % --- This function detects point in the supplied 'Frame',
            % binarises the Frame based on automatic threshold, filters the
            % frame and calculates the center of gravity (location of the
            % point). ---

            % 1. Calculating automatic threshold
            threshold = graythresh(Frame);

            % 2. Binarizing and reversing the Frame
            binaryFrame = ~(imbinarize(Frame,threshold));

            % 3. Reversing the grayscale Frame
            clean_Frame = imcomplement(Frame);

            % 4. Filtering the grayscale Frame, based on the binarised
            % frame
            clean_Frame(~binaryFrame) = 0;       

            % 5. Center of Gravity
            SizeOfFrame = size(clean_Frame);

            % 5.1 Center of Gravity for X
            locations_x = 1:SizeOfFrame(2);
            values_x = sum(clean_Frame,1)';
            x = (locations_x * values_x) / sum(values_x);

            % 5.2 Center of Gravity for y
            locations_y = 1:SizeOfFrame(1);
            values_y = sum(clean_Frame,2);
            y = (locations_y * values_y) / sum(values_y);            
        end                
        end

        function showInformation(app)
            % --- This function updates the Information shown in the Extras
            % Windows ---
            % Updating Total Time needed for the Experiment based on the
            % remaining Frames to be taken and the delay between Frames
            if app.TotalTime > days(3)
                % if totalTime is more than 3 Days the time Axis would be
                % shown in Days
                app.Label.Text = string(app.TotalTime,'d');
            elseif app.TotalTime > minutes(180)
                app.Label.Text = string(app.TotalTime,'h');
            else 
                app.Label.Text = string(app.TotalTime,'mm:ss');
            end
            % Updating real Delay
            app.Label_2.Text = [num2str(app.realDelay,'%.1f'),...
                ' Seconds'];
            % Updating current Frame
            app.Label_3.Text = num2str(app.cFrame);
            % Updating current expansion in %
            app.Label_4.Text = [num2str(app.cExpansion,'%.3f'),' %'];
            app.Label_5.Text = app.TimePassed;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % 01.Getting App Location
            [app.appFolder,~,~] = fileparts(mfilename('fullpath'));
            
            % 02. Getting Screen Resolution and Calculating GUI Windows
            % Size and Calibration Windows Size
            ScreenResolution(app);
            guiWinSize(app);
            calibrationWinSize(app);

            % 03. Setting the GUI Windows size according to Screen
            % Resolution
            setGUISize(app);  

            % 04. Showing Welcome Photo in GUI Homescreen
            WelcomePhoto = imread([app.appFolder,'\resources\index.png']);
            imshow(WelcomePhoto,'Parent',app.UIAxes);
            app.UIAxes.XLim = [0 width(WelcomePhoto)];
            app.UIAxes.YLim = [0 height(WelcomePhoto)];
            % Welcome Photo for second tab
            WelcomePhoto2 = imread([app.appFolder,'\resources\index2.jpg']);
            imshow(WelcomePhoto2,'Parent',app.UIAxes_2);
            app.UIAxes_2.XLim = [0 width(WelcomePhoto2)];
            app.UIAxes_2.YLim = [0 height(WelcomePhoto2)];            

            % 05. Addding .NET Assembly in order to communicate with Camera
            asm = System.AppDomain.CurrentDomain.GetAssemblies;
            % Add only if it doesn't already Exists
            if ~any(arrayfun(@(n) strncmpi(char(asm.Get(n-1).FullName), ...
                    'uEyeDotNet', length('uEyeDotNet')), 1:asm.Length))
                % Specifying the Folder of .dll file from IDS Camera
                NET.addAssembly(app.ueyeApiLoc);
            end

            % 06. Showing the first Option to start the project
            app.ProjektStartenButton.Enable = 'on';
            app.Lamp.Enable = 'on';
            app.ProjektAuswhlenButton.Enable = 'on';
            app.Lamp_7.Enable = 'on';            

            % 07. Load CameraParmaeter for Distortion Correction
            app.CamPar = load([app.appFolder,'\resources\CamPar.mat']);

            % 08. Calculate Total Time for Information (Extras Windows)
            app.realDelay = app.Delay;
            app.TotalTime = seconds(app.FrameLimit * app.realDelay);
            showInformation(app);
        end

        % Button pushed function: ProjektStartenButton
        function ProjektStartenButtonPushed(app, event)
            % 01. Hiding the Project Start Button to avoid double Click
            app.SpeichernButton.Enable = 'off'; %
            app.ProjektStartenButton.Enable = 'off';
            app.ResetButton.Enable = 'on';
            app.ProjektAuswhlenButton.Enable = 'off';

            % 02. Showing a PopUp Message to notify user
            Message = ['Jetzt wird ein neues Projekt gestartet. Bitte ' ...
                'in nächsten Schritt ein Ordner Auswählen, wo das ' ...
                'Projekt gespeichert werden soll.'];
            Topic = 'Neues Projekt';
            % Alerts user that a new project is being created
            uialert(app.ZeitstandzugversuchUIFigure,Message,Topic,'Icon','info',...
                'CloseFcn',@AlertCallback);
            % Wait untill Okay in PopUp window is clicked
            uiwait(app.ZeitstandzugversuchUIFigure); 

            % 03. Asking User to select a folder to save the Project
            app.ProjectPath = uigetdir(app.appFolder,...
                'Bitte Ordner auswählen.');
            figure(app.ZeitstandzugversuchUIFigure); % Bringing GUI to top

            % 04. Asking for Project Name & creating new Project folder
            app = createProjectFolder(app);

            % 05. Lamp & Button Visibility
            app.ProjektStartenButton.Enable = 'off';
            app.ArduinoCheckButton.Enable = 'on';
            app.Lamp.Color = 'g';
            app.Lamp_2.Enable = 'on';
            
            % Show Project Name in Label
            app.KeinProjektLabel.Text = app.ProjectName(6:end);
            app.KeinProjektLabel.Visible = 'on';
            % Automatically push Arduino Check Button and setting new
            % Project to true
            app.newProject = 1;
            app.ArduinoCheckButtonPushed(app);

            function AlertCallback(~,~)
                % --- Function to pause matlab execution untill the user
                % confirms the warning message ---                
                uiresume(app.ZeitstandzugversuchUIFigure);
            end 
        end

        % Button pushed function: ArduinoCheckButton
        function ArduinoCheckButtonPushed(app, event)
            % 01. Disable Arduino Check Button
            app.ArduinoCheckButton.Enable = 'off';
            app.ArduinoCheckButton_2.Enable = 'off';
            ArduinoConnected = 0;

            % 02. Trying to establish a connection to Arduino
            try
                FlashTemp = arduino;
                if strcmp(FlashTemp.Board,'Uno')
                    Message = ['Arduino Uno ist im Port: ',FlashTemp.Port,...
                        ' erkannt und wird für dieses Projekt benutzt.'];
                    Topic = 'Arduino Erkannt';
                    % Alerting user
                    uialert(app.ZeitstandzugversuchUIFigure,Message,...
                        Topic,'Icon','info','CloseFcn',@AlertCallback);
                    % Wait untill Okay window is clicked
                    uiwait(app.ZeitstandzugversuchUIFigure);

                    % Turn the Flash 'on' for testing
                    writePWMVoltage(FlashTemp, 'D11', 5); % Flash on

                    % Ask User to confirm the Flash
                    Message = ['Das Licht (Blitz) sollte es an sein.',...
                        'Ist es der Fall?'];
                    Topic = 'Blitzer Test';
                    answer = questdlg(Message, Topic,'Ja',...
                        'Nein','Ja');
                    writePWMVoltage(FlashTemp, 'D11', 0); % Flash off

                    if strcmp(answer, 'Nein')
                        clear FlashTemp;
                        ArduinoNotConnected(app);
                    else 
                        app.Flash = FlashTemp;
                        ArduinoConnected = 1;
                        if app.newProject
                            % Lamp & Button Visibility
                            app.ArduinoCheckButton.Enable = 'off';
                            app.KameraCheckButton.Enable = 'on';
                            app.Lamp_2.Color = 'g';
                            app.Lamp_3.Enable = 'on';   
                        else
                            app.ArduinoCheckButton_2.Enable = 'off';
                            app.KameraCheckButton_2.Enable = 'on';
                            app.Lamp_8.Color = 'g';
                            app.Lamp_9.Enable = 'on';
                        end                         
                    end
                else
                    ArduinoNotConnected(app);
                end
            catch
                ArduinoNotConnected(app);
            end

            % Automatically push Camera Check Button
            if ArduinoConnected
                app.KameraCheckButtonPushed(app);    
            end

            function AlertCallback(~,~)
                % --- Function to pause matlab execution untill the user
                % confirms the warning message ---                 
                uiresume(app.ZeitstandzugversuchUIFigure);
            end            
        end

        % Button pushed function: KameraCheckButton
        function KameraCheckButtonPushed(app, event)
            % 01. Define CameraParameters Value
            % Success string for reference
            app.CamSuccess = uEye.Defines.Status.Success; 
            app.CamPar.Changed = 0; % Leave this value to zero
            app.CamPar.Aperture = 4; % Should be manually adjusted on Lens 
            if app.newProject
                app.CamPar.Exposure = 25; % Exposure Time in Miliseconds
            else
                % load Exposure time from the project data
                app.CamPar.Exposure = app.loadedRef.Exposure;
            end
            % 02. Getting the List of connected Cameras
            [status,CameraList] = uEye.Info.Camera.GetCameraList;
            if chkErr(app, status, 'CameraList'), return; end

            % 03. Extract the no. of Cameras from CameraList
            NumberOfCamera = CameraList.Length;

            % 04. Checking connected Cameras
            if NumberOfCamera == 0
                Message = ['Es werden keine Kameras gefunden. Prüfen ' ...
                    'Sie ob die Kamera richtig angeschlossen ist. Sie ' ...
                    'können dafür IDS Kameramanager benutzen. Schließen' ...
                    ' Sie die IDS Kameramanger sobald dort ein Kamera ' ...
                    'erkannt wird.'];
                Topic = 'Kamera nicht erkannt';
                % Alerts user that there is no camera connected
                uialert(app.ZeitstandzugversuchUIFigure,Message,Topic,...
                    'Icon','warning','CloseFcn',@AlertCallback);
                % Wait untill Okay in PopUp window is clicked
                uiwait(app.ZeitstandzugversuchUIFigure);  
                system(app.idsCamLoc);
                return;
            else
                Message = ['Die Kamera: ',CameraList(1).Model.char,...
                    ' ist an den Rechner angeschlossen und wird für ' ...
                    'die Messung verwendet.'];
                Topic = 'Kamera erkannt';

                % Alerts user that camera is detected.
                uialert(app.ZeitstandzugversuchUIFigure,Message,Topic,...
                    'Icon','info','CloseFcn',@AlertCallback);
                % Wait untill Okay in PopUp window is clicked
                uiwait(app.ZeitstandzugversuchUIFigure)
            end

            % 05. Checking if the Camera is Busy
            if CameraList(1).InUse
                Message = ['Die Kamera wird gerade von einem anderen ' ...
                    'Prozess verwendet. Bitte beenden Sie diesen Prozess' ...
                    ' und machen Sie weiter'];
                Topic = 'Kamera ist beschäftigt';
                % Alerts user that the Camera is busy
                uialert(app.ZeitstandzugversuchUIFigure,Message,Topic,...
                    'Icon','warning','CloseFcn',@AlertCallback);
                % Wait untill Okay in PopUp window is clicked
                uiwait(app.ZeitstandzugversuchUIFigure);
                return;
            end

            % 06. Starting Camera and setting the Parameters
            app = StartCamera(app);

            % 07. Trigger an Image
            app = triggerImage(app);  
            % Compensate for Camera Rotation 
            app.Image.Data = rot90(app.Image.Data); 

            % 10. Lamp & Button Visibility
            if app.newProject
                app.KameraCheckButton.Enable = 'off';
                app.CameraKalibrationButton.Enable = 'on';
                app.Lamp_3.Color = 'g';
                app.Lamp_4.Enable = 'on';
            else
                app.KameraCheckButton_2.Enable = 'off';
                app.CameraKalibrationButton_2.Enable = 'on';
                app.Lamp_9.Color = 'g';
                app.Lamp_10.Enable = 'on';
            end

            % 11. Click Camera Kalibration Button Automatically
            app.CameraKalibrationButtonPushed(app);

            function AlertCallback(~,~)
                % --- Function to pause matlab execution untill the user
                % confirms the warning message ---                 
                uiresume(app.ZeitstandzugversuchUIFigure);
            end
        end

        % Button pushed function: CameraKalibrationButton
        function CameraKalibrationButtonPushed(app, event)
            % 01. Load previous Image as an example
            ImgPair = [app.Image.Data,rangefilt(app.Image.Data)];
            CalImg = cat(3, ImgPair, ImgPair, ImgPair);

            % 02. Prepare a Calibration Window to show live feed
            CalFigure = figure(1);
            CalFigure.MenuBar = 'none';
            CalFigure.OuterPosition = app.calWinSize;
            CalFigure.Name = 'Kalibrierungsfenster';
            set(gca, 'Position', [0,0,1,1]);
            figure(CalFigure);

            % 03. Plot previous Image to the Calibration Window
            CalImage = imagesc(CalImg);
            axis(CalImage.Parent, 'image');
            axis(CalImage.Parent, 'off'); 

            % 04. Configure Done Button
            CalUI = uicontrol('Style', 'ToggleButton', 'String', 'Done', ...
             'ForegroundColor', 'r', 'FontWeight', 'Bold', 'FontSize', 15);
            CalUI.Position = [app.calWinSize(3)-85,0,60,30];
            CalUI.Visible = 'on';
            
            % 05. Configure Exposure Slider
            ExpSlider = uicontrol(CalFigure);
            ExpSlider.Style = 'slider';
            ExpSlider.Position = [0, 0, app.calWinSize(3)-90, 30];
            ExpSlider.Value = app.CamPar.Exposure;
            ExpSlider.Min = 10;
            ExpSlider.Max = 100;
            % Listner for Slider
            CallBack = @(~,b)ExposureCallback(app,b.AffectedObject.Value);
            addlistener(ExpSlider, 'Value', 'PostSet',CallBack);

            % 06. Flash on
            writePWMVoltage(app.Flash, 'D11', 5);

            % 07. Calibration Start 
            while ~CalUI.Value                
                % 7.1 Checking if Slider is changed
                if app.CamPar.Changed 
                    % Change Exposure Setting
                    status = app.Camera.Timing.Exposure.Set...
                        (app.CamPar.Exposure);
                    if chkErr(app, status, 'Exposure Time'), return; end
                    app.CamPar.Changed = 0;
                end                

                % 7.2 Capturing Image and saving into Camera Memory
                status = app.Camera.Acquisition.Freeze(true);
                if chkErr(app, status, 'Image Acquistion'), return; end        
    
                % 7.3 Extract Image to Matlab Memory
                [status, tmpImg] = app.Camera.Memory.CopyToArray...
                    (app.Image.ID); 
                if chkErr(app, status, 'Copy to Array'), return; end
    
                % 7.4 Reshape image
                tmpImg = reshape(uint8(tmpImg), ...
                    [app.Image.Width, app.Image.Height, app.Image.Bits/8])';
    
                % 7.5 Rotate Image (Compensate for Camera Rotation)
                app.Image.Data = rot90(tmpImg);
                    
                % 7.6 prepare to show
                ImgPair = [app.Image.Data,rangefilt(app.Image.Data)];
                CalImg = cat(3, ImgPair, ImgPair, ImgPair);
                
                % 7.7 Show Image in CalWindow
                CalImage.CData = CalImg;
                drawnow;
            end

            % 08. Flash off
            writePWMVoltage(app.Flash, 'D11', 0);

            % 09. Trigger an Image
            app = triggerImage(app);
            app.Image.Data = rot90(app.Image.Data);

            % 10. Show Image in UIAxes
            if app.newProject
                imshow(app.Image.Data,'Parent',app.UIAxes);
                app.UIAxes.XLim = [0 width(app.Image.Data)];
                app.UIAxes.YLim = [0 height(app.Image.Data)];  
            else
                imshow(app.Image.Data,'Parent',app.UIAxes_2);
                app.UIAxes_2.XLim = [0 width(app.Image.Data)];
                app.UIAxes_2.YLim = [0 height(app.Image.Data)]; 
            end

            % 11. closing Calibration Window
            CalFigure.Visible = 'off';
            CalUI.Visible = 'off';
            ExpSlider.Visible = 'off';
            clear CalFigure;

            % 12. Lamp & Button Visibility
            if app.newProject
                app.CameraKalibrationButton.Enable = 'off';
                app.VersuchStartenButton.Enable = 'on';
                app.Lamp_4.Color = 'g';
                app.Lamp_5.Enable = 'on';
            else
                app.CameraKalibrationButton_2.Enable = 'off';
                app.ProjektFortsetzenButton.Enable = 'on';
                app.Lamp_10.Color = 'g';
                app.Lamp_6.Enable = 'on';   
            end
        end

        % Button pushed function: VersuchStartenButton
        function VersuchStartenButtonPushed(app, event)

            % 1. Create camera object handle if not already exists
            if isempty(app.Camera)
                app.KameraCheckButtonPushed(app);
                app.VersuchStartenButton(app);
            end
            % 2. Trigger a new Image
            app = triggerImage(app);
            % Rotate to compensate Camera Rotation
            app.Image.Data = rot90(app.Image.Data);

            % 3. Prepare a Window to select AOI (area of interest)
            AOIFigure = figure(2);
            AOIFigure.MenuBar = 'None';
            AOIFigure.Position = app.calWinSize;
            AOIFigure.Position(3)  = AOIFigure.Position(3) * (942/1858);
            AOIFigure.Visible = 'on';            
            set(gca, 'Position', [0,0,1,1]);

            % 4. AOI Select Button
            app.AOISelectButton = uicontrol('Style', 'ToggleButton',...
                'String', 'Okay','ForegroundColor', 'r', 'FontWeight',...
                'Bold', 'FontSize', 18);
            app.AOISelectButton.Position = [AOIFigure.Position(3)/1.4,...
                AOIFigure.Position(4)/5,80,40];
            app.AOISelectButton.Visible = 'on';
            imshow(imread([app.appFolder,'/resources/AOIinfo.png']));

            % 5. Listener for Okay Button
            CallBack = @(~,~)startAOI;
            addlistener(app.AOISelectButton, 'Value', 'PostSet',CallBack);

            function startAOI(~,~)
                app.AOISelectButton.Visible = 'off';
    
                % 5.1 AOI of upper Point
                AOIFigure.Name = 'Obere Punkt im Bild markieren';
                [~,app.Image.upRect] = imcrop(app.Image.Data);
                imshow(imcrop(app.Image.Data,app.Image.upRect));pause(1);
                
                % 5.2 AOI of lower Point
                AOIFigure.Name = 'Untere Punkt im Bild markieren';
                [~,app.Image.downRect] = imcrop(app.Image.Data); 
                imshow(imcrop(app.Image.Data,app.Image.downRect));pause(1);
    
                % 5.3 Check AOI
                imshow(app.Image.Data); hold on;
                rectangle('Position',app.Image.upRect,'EdgeColor','r',...
                    'LineWidth',1);
                rectangle('Position',app.Image.downRect,'EdgeColor','r',...
                    'LineWidth',1);
                hold off;

                % 5.4 AOI Confirm Button
                app.AOIConfirmButton = uicontrol('Style', 'ToggleButton',...
                    'String','Okay','ForegroundColor', 'r', 'FontWeight',...
                    'Bold','FontSize', 18);
                app.AOIConfirmButton.Position = app.AOISelectButton.Position;
                app.AOIConfirmButton.Visible = 'on';

                CallBack2 = @(~,~)startExperiment(app,AOIFigure);
                addlistener(app.AOIConfirmButton, 'Value', 'PostSet',...
                    CallBack2);
                
                % 5.5 Retry Message
                text(100,300,{'Zum erneuten Auswählen',...
                    'schließen Sie bitte dieses Fenster'...
                    'und starten Sie den Versuch neu !'},...
                    "FontSize",18,'Color','b');           
            end
        end

        % Button pushed function: VersuchBeendenButton
        function VersuchBeendenButtonPushed(app, event)
            Message = ['Möchten Sie den Versuch wirklich beenden?'];
            Topic = 'Versuch Beenden';
            % Asking user to confirm the input
            answer = questdlg(Message, Topic,'Beenden',...
                'Nicht Beenden','Nicht Beenden');
            % Closing the experiment
            if strcmp(answer, 'Beenden')
                app.Experiment = 0;
                if app.newProject
                    app.VersuchBeendenButton.Enable = 'off';
                else
                    app.VersuchBeendenButton_2.Enable = 'off';
                end
                app.Camera.Exit;
                app.Camera = [];  
            end
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            Message = ['Möchten Sie den wirklich resetten?'];
            Topic = 'Reset';
            % Asking user to confirm the input
            answer = questdlg(Message, Topic,'Ja',...
                'Nein','Nein');
            % Closing the current session and starting a new session
            if strcmp(answer, 'Ja')
                if ~isempty(app.Camera)
                    app.Camera.Exit;
                end
                delete(app);
                clear;
                close all;
                app = ZugVersuch; 
            end
        end

        % Button pushed function: ProjektAuswhlenButton
        function ProjektAuswhlenButtonPushed(app, event)
            % 01. Disabling Buttons to avoid doubleclicks
            app.SpeichernButton.Enable = 'off';
            app.ProjektAuswhlenButton.Enable = 'off';
            app.ProjektStartenButton.Enable = 'off';

            % 02. Enabling the Reset Button
            app.ResetButton_2.Enable = 'on';

            % 03. Asking User to select folder of the project
            app.ProjectPath = uigetdir(app.appFolder,...
                'Bitte Ordner auswählen.');
            figure(app.ZeitstandzugversuchUIFigure); % Bringing GUI to top
            [~, app.ProjectName] = fileparts(app.ProjectPath);

            % 04. Checking whether a project is valid or not
            try
                vari = load([app.ProjectName,'/',app.ProjectName,'.mat']);
                app.LoadedFrameInfo = vari.FrameInfo;
                app.loadedRef = vari.ref;
            catch
                uialert(app.ZeitstandzugversuchUIFigure,...
                    'Projekt nicht gültig!','Nicht Gültig!','Icon',...
                    'error');                
                app.ProjektAuswhlenButton.Enable = 'on';
                return; % stops the execution of this function
            end

            % 05. Show Project Name in Label
            app.KeinProjektLabel_2.Text = app.ProjectName(6:end);
            app.KeinProjektLabel_2.Visible = 'on';

            % 06. Lamp and Buttons
            app.ProjektAuswhlenButton.Enable = 'off';
            app.Lamp_7.Color = 'g';
            app.ArduinoCheckButton_2.Enable = 'on';
            app.Lamp_8.Enable = 'on';
            app.newProject = 0;
            app.ArduinoCheckButton_2Pushed(app);
        end

        % Button pushed function: ArduinoCheckButton_2
        function ArduinoCheckButton_2Pushed(app, event)
            ArduinoCheckButtonPushed(app);
        end

        % Button pushed function: KameraCheckButton_2
        function KameraCheckButton_2Pushed(app, event)
            KameraCheckButtonPushed(app);
        end

        % Button pushed function: CameraKalibrationButton_2
        function CameraKalibrationButton_2Pushed(app, event)
            CameraKalibrationButtonPushed(app);
        end

        % Button pushed function: ProjektFortsetzenButton
        function ProjektFortsetzenButtonPushed(app, event)
            VersuchStartenButtonPushed(app);
        end

        % Button pushed function: ResetButton_2
        function ResetButton_2Pushed(app, event)
            app.ResetButtonPushed(app);
        end

        % Button pushed function: VersuchBeendenButton_2
        function VersuchBeendenButton_2Pushed(app, event)
            VersuchBeendenButtonPushed(app);
        end

        % Button pushed function: SpeichernButton
        function SpeichernButtonPushed(app, event)
            % --- This callback function saves the user defined settings
            % for this experiment ---
            app.Delay = app.WartezeitsEditField.Value;
            app.FrameLimit = app.GesamtFramesEditField.Value;
            app.CropX = app.CropXEditField.Value;
            app.CropY = app.CropYEditField.Value;
            uialert(app.ZeitstandzugversuchUIFigure,...
                    'Einstellungen werden erfolgreich gespeichert','Done',...
                    'Icon','success');
            % If the Dealy is set less than 1 Second, it will show 1
            % Seconds because of the system Delay
            if app.Delay < 1
                app.realDelay = 1;
            else
                app.realDelay = app.Delay;
            end
            app.TotalTime = seconds(app.FrameLimit * app.realDelay);
            showInformation(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ZeitstandzugversuchUIFigure and hide until all components are created
            app.ZeitstandzugversuchUIFigure = uifigure('Visible', 'off');
            app.ZeitstandzugversuchUIFigure.Position = [100 100 647 467];
            app.ZeitstandzugversuchUIFigure.Name = 'Zeitstandzugversuch';
            app.ZeitstandzugversuchUIFigure.Resize = 'off';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.ZeitstandzugversuchUIFigure);
            app.TabGroup.Position = [0 0 853 640];

            % Create NeuerVersuchTab
            app.NeuerVersuchTab = uitab(app.TabGroup);
            app.NeuerVersuchTab.Title = 'Neuer Versuch';

            % Create UIAxes
            app.UIAxes = uiaxes(app.NeuerVersuchTab);
            app.UIAxes.Position = [209 40 621 549];

            % Create ProjektStartenButton
            app.ProjektStartenButton = uibutton(app.NeuerVersuchTab, 'push');
            app.ProjektStartenButton.ButtonPushedFcn = createCallbackFcn(app, @ProjektStartenButtonPushed, true);
            app.ProjektStartenButton.HorizontalAlignment = 'left';
            app.ProjektStartenButton.FontName = 'Britannic Bold';
            app.ProjektStartenButton.FontWeight = 'bold';
            app.ProjektStartenButton.Enable = 'off';
            app.ProjektStartenButton.Position = [15 525 151 36];
            app.ProjektStartenButton.Text = 'Projekt Starten';

            % Create ArduinoCheckButton
            app.ArduinoCheckButton = uibutton(app.NeuerVersuchTab, 'push');
            app.ArduinoCheckButton.ButtonPushedFcn = createCallbackFcn(app, @ArduinoCheckButtonPushed, true);
            app.ArduinoCheckButton.HorizontalAlignment = 'left';
            app.ArduinoCheckButton.FontName = 'Britannic Bold';
            app.ArduinoCheckButton.FontWeight = 'bold';
            app.ArduinoCheckButton.Enable = 'off';
            app.ArduinoCheckButton.Position = [15 426 151 36];
            app.ArduinoCheckButton.Text = 'Arduino Check';

            % Create KameraCheckButton
            app.KameraCheckButton = uibutton(app.NeuerVersuchTab, 'push');
            app.KameraCheckButton.ButtonPushedFcn = createCallbackFcn(app, @KameraCheckButtonPushed, true);
            app.KameraCheckButton.HorizontalAlignment = 'left';
            app.KameraCheckButton.FontName = 'Britannic Bold';
            app.KameraCheckButton.FontWeight = 'bold';
            app.KameraCheckButton.Enable = 'off';
            app.KameraCheckButton.Position = [15 327 151 36];
            app.KameraCheckButton.Text = 'Kamera Check';

            % Create CameraKalibrationButton
            app.CameraKalibrationButton = uibutton(app.NeuerVersuchTab, 'push');
            app.CameraKalibrationButton.ButtonPushedFcn = createCallbackFcn(app, @CameraKalibrationButtonPushed, true);
            app.CameraKalibrationButton.HorizontalAlignment = 'left';
            app.CameraKalibrationButton.FontName = 'Britannic Bold';
            app.CameraKalibrationButton.FontWeight = 'bold';
            app.CameraKalibrationButton.Enable = 'off';
            app.CameraKalibrationButton.Position = [15 228 151 36];
            app.CameraKalibrationButton.Text = 'Camera Kalibration';

            % Create VersuchStartenButton
            app.VersuchStartenButton = uibutton(app.NeuerVersuchTab, 'push');
            app.VersuchStartenButton.ButtonPushedFcn = createCallbackFcn(app, @VersuchStartenButtonPushed, true);
            app.VersuchStartenButton.HorizontalAlignment = 'left';
            app.VersuchStartenButton.FontName = 'Britannic Bold';
            app.VersuchStartenButton.FontWeight = 'bold';
            app.VersuchStartenButton.Enable = 'off';
            app.VersuchStartenButton.Position = [15 129 151 36];
            app.VersuchStartenButton.Text = 'Versuch Starten';

            % Create Lamp_5
            app.Lamp_5 = uilamp(app.NeuerVersuchTab);
            app.Lamp_5.Enable = 'off';
            app.Lamp_5.Position = [137 137 21 21];
            app.Lamp_5.Color = [1 0 0];

            % Create Lamp
            app.Lamp = uilamp(app.NeuerVersuchTab);
            app.Lamp.Enable = 'off';
            app.Lamp.Position = [137 533 21 21];
            app.Lamp.Color = [1 0 0];

            % Create Lamp_2
            app.Lamp_2 = uilamp(app.NeuerVersuchTab);
            app.Lamp_2.Enable = 'off';
            app.Lamp_2.Position = [137 434 21 21];
            app.Lamp_2.Color = [1 0 0];

            % Create Lamp_3
            app.Lamp_3 = uilamp(app.NeuerVersuchTab);
            app.Lamp_3.Enable = 'off';
            app.Lamp_3.Position = [137 335 21 21];
            app.Lamp_3.Color = [1 0 0];

            % Create Lamp_4
            app.Lamp_4 = uilamp(app.NeuerVersuchTab);
            app.Lamp_4.Enable = 'off';
            app.Lamp_4.Position = [137 236 21 21];
            app.Lamp_4.Color = [1 0 0];

            % Create VersuchBeendenButton
            app.VersuchBeendenButton = uibutton(app.NeuerVersuchTab, 'push');
            app.VersuchBeendenButton.ButtonPushedFcn = createCallbackFcn(app, @VersuchBeendenButtonPushed, true);
            app.VersuchBeendenButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.VersuchBeendenButton.FontName = 'Britannic Bold';
            app.VersuchBeendenButton.FontSize = 13;
            app.VersuchBeendenButton.FontWeight = 'bold';
            app.VersuchBeendenButton.Enable = 'off';
            app.VersuchBeendenButton.Position = [15 48 151 36];
            app.VersuchBeendenButton.Text = 'Versuch Beenden';

            % Create ResetButton
            app.ResetButton = uibutton(app.NeuerVersuchTab, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Enable = 'off';
            app.ResetButton.Position = [57 19 52 22];
            app.ResetButton.Text = {'Reset'; ''};

            % Create KeinProjektLabel
            app.KeinProjektLabel = uilabel(app.NeuerVersuchTab);
            app.KeinProjektLabel.BackgroundColor = [0.651 0.651 0.651];
            app.KeinProjektLabel.HorizontalAlignment = 'center';
            app.KeinProjektLabel.FontSize = 13;
            app.KeinProjektLabel.FontWeight = 'bold';
            app.KeinProjektLabel.FontColor = [0 0 1];
            app.KeinProjektLabel.Visible = 'off';
            app.KeinProjektLabel.Position = [15 580 174 27];
            app.KeinProjektLabel.Text = 'Kein Projekt';

            % Create VersuchFortsetzenTab
            app.VersuchFortsetzenTab = uitab(app.TabGroup);
            app.VersuchFortsetzenTab.Title = 'Versuch Fortsetzen';

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.VersuchFortsetzenTab);
            app.UIAxes_2.Position = [209 40 621 549];

            % Create ProjektAuswhlenButton
            app.ProjektAuswhlenButton = uibutton(app.VersuchFortsetzenTab, 'push');
            app.ProjektAuswhlenButton.ButtonPushedFcn = createCallbackFcn(app, @ProjektAuswhlenButtonPushed, true);
            app.ProjektAuswhlenButton.HorizontalAlignment = 'left';
            app.ProjektAuswhlenButton.FontName = 'Britannic Bold';
            app.ProjektAuswhlenButton.FontWeight = 'bold';
            app.ProjektAuswhlenButton.Enable = 'off';
            app.ProjektAuswhlenButton.Position = [15 525 151 36];
            app.ProjektAuswhlenButton.Text = 'Projekt Auswählen';

            % Create ArduinoCheckButton_2
            app.ArduinoCheckButton_2 = uibutton(app.VersuchFortsetzenTab, 'push');
            app.ArduinoCheckButton_2.ButtonPushedFcn = createCallbackFcn(app, @ArduinoCheckButton_2Pushed, true);
            app.ArduinoCheckButton_2.HorizontalAlignment = 'left';
            app.ArduinoCheckButton_2.FontName = 'Britannic Bold';
            app.ArduinoCheckButton_2.FontWeight = 'bold';
            app.ArduinoCheckButton_2.Enable = 'off';
            app.ArduinoCheckButton_2.Position = [15 426 151 36];
            app.ArduinoCheckButton_2.Text = 'Arduino Check';

            % Create KameraCheckButton_2
            app.KameraCheckButton_2 = uibutton(app.VersuchFortsetzenTab, 'push');
            app.KameraCheckButton_2.ButtonPushedFcn = createCallbackFcn(app, @KameraCheckButton_2Pushed, true);
            app.KameraCheckButton_2.HorizontalAlignment = 'left';
            app.KameraCheckButton_2.FontName = 'Britannic Bold';
            app.KameraCheckButton_2.FontWeight = 'bold';
            app.KameraCheckButton_2.Enable = 'off';
            app.KameraCheckButton_2.Position = [15 327 151 36];
            app.KameraCheckButton_2.Text = 'Kamera Check';

            % Create CameraKalibrationButton_2
            app.CameraKalibrationButton_2 = uibutton(app.VersuchFortsetzenTab, 'push');
            app.CameraKalibrationButton_2.ButtonPushedFcn = createCallbackFcn(app, @CameraKalibrationButton_2Pushed, true);
            app.CameraKalibrationButton_2.HorizontalAlignment = 'left';
            app.CameraKalibrationButton_2.FontName = 'Britannic Bold';
            app.CameraKalibrationButton_2.FontWeight = 'bold';
            app.CameraKalibrationButton_2.Enable = 'off';
            app.CameraKalibrationButton_2.Position = [15 228 151 36];
            app.CameraKalibrationButton_2.Text = 'Camera Kalibration';

            % Create ProjektFortsetzenButton
            app.ProjektFortsetzenButton = uibutton(app.VersuchFortsetzenTab, 'push');
            app.ProjektFortsetzenButton.ButtonPushedFcn = createCallbackFcn(app, @ProjektFortsetzenButtonPushed, true);
            app.ProjektFortsetzenButton.HorizontalAlignment = 'left';
            app.ProjektFortsetzenButton.FontName = 'Britannic Bold';
            app.ProjektFortsetzenButton.FontWeight = 'bold';
            app.ProjektFortsetzenButton.Enable = 'off';
            app.ProjektFortsetzenButton.Position = [15 129 151 36];
            app.ProjektFortsetzenButton.Text = 'Projekt Fortsetzen';

            % Create Lamp_6
            app.Lamp_6 = uilamp(app.VersuchFortsetzenTab);
            app.Lamp_6.Enable = 'off';
            app.Lamp_6.Position = [137 137 21 21];
            app.Lamp_6.Color = [1 0 0];

            % Create Lamp_7
            app.Lamp_7 = uilamp(app.VersuchFortsetzenTab);
            app.Lamp_7.Enable = 'off';
            app.Lamp_7.Position = [137 533 21 21];
            app.Lamp_7.Color = [1 0 0];

            % Create Lamp_8
            app.Lamp_8 = uilamp(app.VersuchFortsetzenTab);
            app.Lamp_8.Enable = 'off';
            app.Lamp_8.Position = [137 434 21 21];
            app.Lamp_8.Color = [1 0 0];

            % Create Lamp_9
            app.Lamp_9 = uilamp(app.VersuchFortsetzenTab);
            app.Lamp_9.Enable = 'off';
            app.Lamp_9.Position = [137 335 21 21];
            app.Lamp_9.Color = [1 0 0];

            % Create Lamp_10
            app.Lamp_10 = uilamp(app.VersuchFortsetzenTab);
            app.Lamp_10.Enable = 'off';
            app.Lamp_10.Position = [137 236 21 21];
            app.Lamp_10.Color = [1 0 0];

            % Create VersuchBeendenButton_2
            app.VersuchBeendenButton_2 = uibutton(app.VersuchFortsetzenTab, 'push');
            app.VersuchBeendenButton_2.ButtonPushedFcn = createCallbackFcn(app, @VersuchBeendenButton_2Pushed, true);
            app.VersuchBeendenButton_2.BackgroundColor = [0.9412 0.9412 0.9412];
            app.VersuchBeendenButton_2.FontName = 'Britannic Bold';
            app.VersuchBeendenButton_2.FontSize = 13;
            app.VersuchBeendenButton_2.FontWeight = 'bold';
            app.VersuchBeendenButton_2.Enable = 'off';
            app.VersuchBeendenButton_2.Position = [15 48 151 36];
            app.VersuchBeendenButton_2.Text = 'Versuch Beenden';

            % Create ResetButton_2
            app.ResetButton_2 = uibutton(app.VersuchFortsetzenTab, 'push');
            app.ResetButton_2.ButtonPushedFcn = createCallbackFcn(app, @ResetButton_2Pushed, true);
            app.ResetButton_2.Enable = 'off';
            app.ResetButton_2.Position = [57 19 52 22];
            app.ResetButton_2.Text = {'Reset'; ''};

            % Create KeinProjektLabel_2
            app.KeinProjektLabel_2 = uilabel(app.VersuchFortsetzenTab);
            app.KeinProjektLabel_2.BackgroundColor = [0.651 0.651 0.651];
            app.KeinProjektLabel_2.HorizontalAlignment = 'center';
            app.KeinProjektLabel_2.FontSize = 13;
            app.KeinProjektLabel_2.FontWeight = 'bold';
            app.KeinProjektLabel_2.FontColor = [0 0 1];
            app.KeinProjektLabel_2.Visible = 'off';
            app.KeinProjektLabel_2.Position = [15 580 174 27];
            app.KeinProjektLabel_2.Text = 'Kein Projekt';

            % Create ExtrasTab
            app.ExtrasTab = uitab(app.TabGroup);
            app.ExtrasTab.Tooltip = {''};
            app.ExtrasTab.Title = 'Extras';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.ExtrasTab);
            app.UIAxes2.Position = [309 19 529 588];

            % Create EinstellungenLabel
            app.EinstellungenLabel = uilabel(app.ExtrasTab);
            app.EinstellungenLabel.BackgroundColor = [0.7294 0.8314 0.851];
            app.EinstellungenLabel.HorizontalAlignment = 'center';
            app.EinstellungenLabel.VerticalAlignment = 'top';
            app.EinstellungenLabel.FontSize = 16;
            app.EinstellungenLabel.FontWeight = 'bold';
            app.EinstellungenLabel.Position = [11 281 274 326];
            app.EinstellungenLabel.Text = {''; 'Einstellungen'; ''};

            % Create CropXEditFieldLabel
            app.CropXEditFieldLabel = uilabel(app.ExtrasTab);
            app.CropXEditFieldLabel.BackgroundColor = [0.7294 0.8314 0.851];
            app.CropXEditFieldLabel.HorizontalAlignment = 'right';
            app.CropXEditFieldLabel.FontColor = [1 0 0];
            app.CropXEditFieldLabel.Position = [72 416 39 22];
            app.CropXEditFieldLabel.Text = 'CropX';

            % Create CropXEditField
            app.CropXEditField = uieditfield(app.ExtrasTab, 'numeric');
            app.CropXEditField.Limits = [50 100];
            app.CropXEditField.RoundFractionalValues = 'on';
            app.CropXEditField.FontColor = [1 0 0];
            app.CropXEditField.BackgroundColor = [0.7294 0.8314 0.851];
            app.CropXEditField.Tooltip = {'Dies ist die halbe Größe des rechteckigen Bereichs in x-Richtung um den Punkt, der für die Punkterkennung verwendet werden soll. Ändern Sie nichts, außer Sie wissen, was Sie tun.'};
            app.CropXEditField.Position = [118 416 98 22];
            app.CropXEditField.Value = 75;

            % Create ZeitzwischendenBildernLabel
            app.ZeitzwischendenBildernLabel = uilabel(app.ExtrasTab);
            app.ZeitzwischendenBildernLabel.HorizontalAlignment = 'right';
            app.ZeitzwischendenBildernLabel.Position = [21 514 88 35];
            app.ZeitzwischendenBildernLabel.Text = 'Wartezeit [s]';

            % Create WartezeitsEditField
            app.WartezeitsEditField = uieditfield(app.ExtrasTab, 'numeric');
            app.WartezeitsEditField.Limits = [0.1 3600];
            app.WartezeitsEditField.Tooltip = {'Wartezeit vor der Aufnahme des nächsten Bildes. [in Sekunden].'};
            app.WartezeitsEditField.Position = [115 520 100 22];
            app.WartezeitsEditField.Value = 15;

            % Create CropYEditFieldLabel
            app.CropYEditFieldLabel = uilabel(app.ExtrasTab);
            app.CropYEditFieldLabel.BackgroundColor = [0.7294 0.8314 0.851];
            app.CropYEditFieldLabel.HorizontalAlignment = 'right';
            app.CropYEditFieldLabel.FontColor = [1 0 0];
            app.CropYEditFieldLabel.Position = [70 364 39 22];
            app.CropYEditFieldLabel.Text = 'CropY';

            % Create CropYEditField
            app.CropYEditField = uieditfield(app.ExtrasTab, 'numeric');
            app.CropYEditField.Limits = [75 200];
            app.CropYEditField.RoundFractionalValues = 'on';
            app.CropYEditField.FontColor = [1 0 0];
            app.CropYEditField.BackgroundColor = [0.7294 0.8314 0.851];
            app.CropYEditField.Tooltip = {'Dies ist die halbe Größe des rechteckigen Bereichs in y-Richtung um den Punkt, der für die Punkterkennung verwendet werden soll. Ändern Sie nichts, außer Sie wissen, was Sie tun.'};
            app.CropYEditField.Position = [116 364 100 22];
            app.CropYEditField.Value = 150;

            % Create GesamtFramesEditFieldLabel
            app.GesamtFramesEditFieldLabel = uilabel(app.ExtrasTab);
            app.GesamtFramesEditFieldLabel.HorizontalAlignment = 'right';
            app.GesamtFramesEditFieldLabel.Position = [17 468 91 22];
            app.GesamtFramesEditFieldLabel.Text = 'Gesamt Frames';

            % Create GesamtFramesEditField
            app.GesamtFramesEditField = uieditfield(app.ExtrasTab, 'numeric');
            app.GesamtFramesEditField.Limits = [1 99999];
            app.GesamtFramesEditField.RoundFractionalValues = 'on';
            app.GesamtFramesEditField.ValueDisplayFormat = '%11.5g';
            app.GesamtFramesEditField.Tooltip = {'Maximale Anzahl der aufzunehmenden Bilder. '; 'Das Experiment endet, nachdem diese Anzahl von Bildern aufgenommen wurde.'};
            app.GesamtFramesEditField.Position = [115 468 100 22];
            app.GesamtFramesEditField.Value = 10000;

            % Create SpeichernButton
            app.SpeichernButton = uibutton(app.ExtrasTab, 'push');
            app.SpeichernButton.ButtonPushedFcn = createCallbackFcn(app, @SpeichernButtonPushed, true);
            app.SpeichernButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.SpeichernButton.Position = [161 307 73 24];
            app.SpeichernButton.Text = 'Speichern';

            % Create InformationenLabel
            app.InformationenLabel = uilabel(app.ExtrasTab);
            app.InformationenLabel.BackgroundColor = [0.7294 0.8314 0.851];
            app.InformationenLabel.HorizontalAlignment = 'center';
            app.InformationenLabel.VerticalAlignment = 'top';
            app.InformationenLabel.FontSize = 16;
            app.InformationenLabel.FontWeight = 'bold';
            app.InformationenLabel.Position = [11 19 274 245];
            app.InformationenLabel.Text = {''; 'Informationen'};

            % Create echteWartezeitLabel
            app.echteWartezeitLabel = uilabel(app.ExtrasTab);
            app.echteWartezeitLabel.HorizontalAlignment = 'right';
            app.echteWartezeitLabel.Position = [43 155 95 22];
            app.echteWartezeitLabel.Text = 'echte Wartezeit :';

            % Create GesamtdauerLabel
            app.GesamtdauerLabel = uilabel(app.ExtrasTab);
            app.GesamtdauerLabel.HorizontalAlignment = 'right';
            app.GesamtdauerLabel.Position = [50 190 88 28];
            app.GesamtdauerLabel.Text = 'Gesamtdauer :';

            % Create aktuellerFrameLabel
            app.aktuellerFrameLabel = uilabel(app.ExtrasTab);
            app.aktuellerFrameLabel.HorizontalAlignment = 'right';
            app.aktuellerFrameLabel.Position = [43 114 95 28];
            app.aktuellerFrameLabel.Text = 'aktueller Frame :';

            % Create vergangeneZeitLabel
            app.vergangeneZeitLabel = uilabel(app.ExtrasTab);
            app.vergangeneZeitLabel.HorizontalAlignment = 'right';
            app.vergangeneZeitLabel.Position = [36 32 102 28];
            app.vergangeneZeitLabel.Text = 'vergangene Zeit  :';

            % Create aktuelleAusdehnungLabel
            app.aktuelleAusdehnungLabel = uilabel(app.ExtrasTab);
            app.aktuelleAusdehnungLabel.HorizontalAlignment = 'right';
            app.aktuelleAusdehnungLabel.Position = [15 73 123 28];
            app.aktuelleAusdehnungLabel.Text = 'aktuelle Ausdehnung :';

            % Create Label
            app.Label = uilabel(app.ExtrasTab);
            app.Label.Position = [144 193 107 22];

            % Create Label_2
            app.Label_2 = uilabel(app.ExtrasTab);
            app.Label_2.Position = [144 155 107 22];

            % Create Label_3
            app.Label_3 = uilabel(app.ExtrasTab);
            app.Label_3.Position = [144 117 107 22];

            % Create Label_4
            app.Label_4 = uilabel(app.ExtrasTab);
            app.Label_4.Position = [144 76 107 22];

            % Create Label_5
            app.Label_5 = uilabel(app.ExtrasTab);
            app.Label_5.Position = [144 35 107 22];

            % Show the figure after all components are created
            app.ZeitstandzugversuchUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ZugVersuch

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.ZeitstandzugversuchUIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.ZeitstandzugversuchUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ZeitstandzugversuchUIFigure)
        end
    end
end