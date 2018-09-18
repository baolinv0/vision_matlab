%RangeSlider Interface to create a range slider.
%   RangeSlider creates a range slider with the following components:
%   1. Slider with timeline, scrubber and left-right flags to specify
%      interval
%
%   2. Text box to specify Start time, Current time and End time for input
%      video/image sequence
%
%   3. Hardcoded Max time for input video/image sequence
%
%   4. Playback controls
%
%   5. Button to zoom in/out the interval specified by left-right flags
%
%   How to use
%   ----------
%   Follow these steps to use the RangeSlider class:
%
%   1. Create a container figure
%
%   2. Create a panel (slider panel) to hold just the slider components
%
%   3. Create another panel (time panel) below the slider panel. This panel
%      holds the text boxes for time, zoom button, playback controls
%
%   4. Create a structure with figure handle, panel handles, and relative
%      position of the slider panel w.r.t. the parent and call the
%      constructor RangeSlider to create RangeSlider (see example below)
%
%   5. Associate listener to the events of RangeSlider based on your
%      application.
%
%   Example
%   -------
%   hFig = figure('position',[100     100   744   496]);
%   TimePanel = uipanel('parent', hFig,...
%         'Units','pixels',...
%         'backgroundColor', [0.9412 0.9412 0.9412],...
%         'borderWidth', 0,...
%         'Position', [1 2 744 50],...
%         'BorderType', 'Line',...
%         'HighlightColor', [0.9412 0.9412 0.9412],...
%         'Visible', 'on');
% 
%   SliderPanel = uipanel('parent', hFig,...
%         'Units','pixels',...
%         'backgroundColor',  [0.9412 0.9412 0.9412],...
%         'borderWidth', 0,...
%         'Position', [1 54 744 40],...
%         'BorderType', 'Line',...
%         'HighlightColor', [0.9412 0.9412 0.9412],...
%         'Visible', 'on');
% 
%   containerObj.FigHandle =  hFig;
%   ocontainerObj.FigHandle.KeyPressFcn = '';
%   containerObj.Xoffset = 5;
%   containerObj.XposImagePanel = 5;
%   containerObj.TimePanel = TimePanel;
%   containerObj.SliderPanel = SliderPanel;
% 
%   obj = vision.internal.labeler.tool.RangeSlider(containerObj, 0, 100, 100, 1:100)

classdef RangeSlider  < handle
    properties (Access = private)
        FigHandle;
        SliderPanel;
        TimePanel;
        Xoffset;
        XposImagePanel;
        ScrubberPanel;
        ScrubberPos;
        
        BtnRelListner4Scrubber = [];
        BtnRelListner4LeftRightFlag = [];
        BtnDwnlListner4Scrubber = [];
        BtnDwnlListner4LeftFlag = [];
        BtnDwnlListner4RightFlag = [];
        
        % left flag and pole
        LeftFlagPanel;
        LeftPolePanel;
        
        % right flag and pole
        RightFlagPanel;
        RightPolePanel;
        
        % horizontal lines
        FullHLinePanel;
        LeftHLinePanel;
        MiddleHLinePanel;
        RightHLinePanel;
        
        % time
        HasHour;
        HasMin;
        StartEBHandle;
        EndEBHandle;
        CurrentEBHandle;
        %
        StartEBPanelHandle;
        EndEBPanelHandle;
        CurrentEBPanelHandle;
        
        %
        DurationPanel;
        
        OrigPointerForBtn;
        OrigPointerForFig;
        
        % Figure Keypress callback
        KeyPressCallback
        
        % Snap button
        SnapUnsnapBtnHandle;
        PlayBackSection = struct('FirstFrameBtnHandle',[], ...
            'PreviousFrameBtnHandle',[], ...
            'PlayPauseBtnHandle',[], ...
            'NextFrameBtnHandle',[], ...
            'LastFrameBtnHandle',[]);
        
        FullHLineLength;
        CharWidthInPixels;
        CharHeightInPixels;
        
        OrigFigUnits;
        IsSnapMode = false;
        
        IsScrubberBtnUpCalled = false;
        IsScrubberBtnDown = false;
        IsLeftOrRightFlagBtnDown = false;
                
        IsSnapModeBeforeFreeze; % no need to have play and other mode flags
                                % always switches to snap mode in freeze
        IsFlagEnabledB4FreezePlayMode = true;
        IsFlagEnabledB4FreezeOtherMode = true;
        IsStEnEBEnabledB4FreezePlayMode = true;% Start-End Edit Box
        IsStEnEBEnabledB4FreezeOtherMode = true;
        IsSUBtnEnabledB4FreezePlayMode = false;% Snap-Unsnap button
        IsSUBtnEnabledB4FreezeOtherMode = false;
        
        minStartXforPlaybackPanel;
        PlaybackPanelWidth;
        SnapUnsnapBtnWidth;
        PlaybackPanelHandle;
        
        IsPauseHit = false;
        IsInPlayModeFreeze = false;
        
        % Constants - color
        FLAG_BGCOLOR_ENABLE  = [0.7020 0 0];
        FLAG_BGCOLOR_DRAGGED = [1 0.61 0];%[0.9 0.1 0.1];
        FLAG_BGCOLOR_DISBALE = [0.65 0.65 0.65];
        
        SCRUBBER_BGCOLOR_ENABLE  = [0.9608 0.9608 0.9608];%[0.7529 0.8902 0.4353];
        SCRUBBER_BGCOLOR_DRAGGED = [1 0.61 0];%[0.99 0.99 0.99];%[0.85 0.99 0.54];
        SCRUBBER_BGCOLOR_DISABLE = [0.65 0.65 0.65];
        
        DEFAULT_BGCOLOR = [0.9412 0.9412 0.9412];
        
        TIME_EB_BGCOLOR_ENABLE = [1 1 1];
        TIME_EB_BGCOLOR_DISABLE = [0.9216 0.9216 0.9216];% win (240/255), glnx (235/255)
        
        % Constants - IDs
        START_EB_ID   = 1;
        CURRENT_EB_ID = 2;
        END_EB_ID     = 3;
        
        HOUR_EB_ID = 1;
        MIN_EB_ID  = 2;
        SEC_EB_ID  = 3;
        
        %
        LEFT_FLAG_REGULAR_POS = 0;
        LEFT_FLAG_EXTEREME_LEFT = 1;
        LEFT_FLAG_AT_SCRUBBER_MIDX = 2;
        %
        RIGHT_FLAG_REGULAR_POS = 0;
        RIGHT_FLAG_EXTEREME_RIGHT = 1;
        RIGHT_FLAG_AT_SCRUBBER_MIDX = 2;
        %
        SCRUBBER_REGULAR_POS = 0;
        SCRUBBER_EXTEREME_LEFT = 1;
        SCRUBBER_EXTEREME_RIGHT = 2;
        %
        ICON_PATH = fullfile(matlabroot,'toolbox','driving','driving','+driving','+internal','+videoLabeler','+tool');
        %
        TEST_MODE = false;
    end
    properties 
        %VideoStartTime Video Start Time
        %   Video start time, specified in seconds. The video start time
        %   relates to the source video file.        
        VideoStartTime;
        
        %VideoEndTime Video End Time
        %   Video end time, specified in seconds. The video end time
        %   relates to the source video file.        
        VideoEndTime;
        
        %NumberOfFrames Number of frames
        %   Number of video frames or number of images in image sequence       
        NumberOfFrames;
        
        %TimeVector Time stamps for the loaded video
        %   Time stamps for the loaded video, specified in an array. It
        %   must be a column vector with data type double.
        TimeVector;
        
        %ScrubberCurrentTime Scrubber current Time
        %   Scrubber current Time, specified in seconds. The scrubber
        %   position denotes the scrubber current Time.        
        ScrubberCurrentTime;
        
        %IntervalStartTime Interval start time
        %   Interval start time, specified in seconds. The left flag
        %   position denotes the interval start time.
        IntervalStartTime;
        
        %IntervalEndTime Interval end time
        %   Interval end time, specified in seconds. The right flag
        %   position denotes the interval end time.        
        IntervalEndTime;
        
        %CurrentTimeUpdateDone Boolean flag
        %   Flag to check if current time is updated completely
        CurrentTimeUpdateDone =false;
        
        %IsSelectiveFreeze Boolean flag
        %   Flag to specify if some widgets should be frozen/unfrozen.
        %   For groundTruthLabeler, IsSelectiveFreeze means if it is in
        %   Algorithm mode
        IsSelectiveFreeze = false;
        
        %StartReachedByReader Boolean flag
        %   Flag to specify if video start frame is reached by reader
        StartReachedByReader = false;
        
        %EndReachedByReader Boolean flag
        %   Flag to specify if video end frame is reached by reader        
        EndReachedByReader = false;
        
        %TimeNow Time value
        %   Current time value specified by the client          
        TimeNow;
        
        %DrawInteractive Boolean flag
        %   Flag to specify if client should draw in interactive mode          
        DrawInteractive;
        
        %IsDoingSnap Boolean flag
        %   Flag to check if the app is currently going into snap mode         
        IsDoingSnap
       
        %IsVideoPaused Boolean flag
        %   Flag to check if the video is paused           
        IsVideoPaused        
    end
    
    properties  (GetAccess = public, SetAccess = private)
         CaughtExceptionDuringPlay = false;
    end
    
    events
        % Mouse button is down on scr8ubber
        ScrubberPressed
        
        % Mouse button is down on and dragged on scr8ubber
        ScrubberMoved
        
        % Mouse button is up on scr8ubber
        ScrubberReleased
        
        % Current time edit box value changed
        CurrentTimeChanged
        
        % Client requests a value update for current time
        UpdateValue
        
        % Playback control - first frame button is pressed
        FirstFrameRequested
        
        % Playback control - last frame button is pressed
        LastFrameRequested
        
        % Playback control - previous frame button is pressed
        PrevFrameRequested
        
        % Playback control - next frame button is pressed
        NextFrameRequested
       
        % Playback control - play button is pressed. Initialization stage.
        PlayInit
        
        % Playback control - play button is pressed. looping stage.
        PlayLoop
        
        % Playback control - play button is pressed. Play end stage.
        PlayEnd
        %
        %CloseAppInstanceEvent        

        % Current time changed; so scrubber moved. So frame time changed
        FrameChangeEvent
        
        % Start time or End time edit box value changed
        StartOrEndTimeUpdated
    end
    methods
        %==================================================================
        function obj = RangeSlider(containerObj, videoStartTime, videoEndTime, numberOfFrames, timeVector)
            
            %% Retrieve parameters
            retrieveParamsFromObject(obj, containerObj);
            obj.VideoStartTime = videoStartTime;
            obj.VideoEndTime   = ceilTo5Decimal(videoEndTime);
            obj.NumberOfFrames = numberOfFrames;
            obj.TimeVector = timeVector;
            
            %% Call utility functions to set properties
            hasHourMin(obj);
            charToPixel(obj);
            getFigUnits(obj);
            
            %% Call layout generator functions to create UI
            createSliderLayout(obj);
            createTimeLayout(obj);
            setStartTime(obj);
            setCurrentTime(obj);
            setEndTime(obj);
            setDuration(obj);
            
            %% Set callback functions
            addBtnDwnlListner4Scrubber(obj);
            addBtnDwnlListner4LeftRightFlags(obj);
            setSnapUnsnapBtnCallback(obj);
        end
        
        %==================================================================        
        function val = get.ScrubberCurrentTime (this)
            
            val = getSliderCurrentTime(this);
        end
        %==================================================================        
        function val = get.IntervalStartTime(this)
            
            val = getSliderStartTime(this);
        end
        %==================================================================        
        function val = get.IntervalEndTime(this)
            
            val = getSliderEndTime(this);
        end  
        
        %==================================================================
        function exceptionDuringPlayListener(this, varargin)
            this.CaughtExceptionDuringPlay = true;
        end
        
        %==================================================================
        function resetExceptionDuringPlay(this)
            this.CaughtExceptionDuringPlay = false;
        end
        
        %==================================================================
        function notifyFrameChangeEvent(this)
            notify(this,'FrameChangeEvent');
            % notification does not care if there is listener or not;
            % that means FrameChangeListener can be empty too
        end
        
        %==================================================================
        function resizeSliderPanelForFig(obj, newContainerW)
            wFull = newContainerW;
            fullHLine_w = wFull-2*obj.Xoffset;
            
            obj.FullHLineLength = max(fullHLine_w,1);
            
            resizeFullHLine(obj);
            if obj.IsSnapMode
                moveBackFlagsScrubberHLinesInSnapMode(obj);
            else
                moveBackFlagsScrubberHLinesInUnsnapMode(obj);
            end
            movePlaybackButtons(obj);
            moveSnapUnsnapButton(obj);
        end   
   
        %==================================================================
        function freezeInterval(obj)
            saveSnapUnsnapBtnStateBeforeFreeze(obj);
            if canChangeStateOfSnapUnsnapBtn(obj)
                if mustSwitchToSnapMode(obj)
                    % go into snap modeo
                    obj.SnapUnsnapBtnHandle.Value = 1;
                    snapUnsnapCallback(obj, [], []);
                end
                disableSnapUnsnapBtn(obj);
            end
            saveStateAndDisableLeftRightFlags(obj);
            saveStateAndDisable2TimeEditBoxes(obj);            
        end
        %==================================================================
        function freezeInteraction(obj, playbackControlState)
            
            if nargin>1 && ~playbackControlState
                disableAllPBButtons(obj);
            end
            
            disableScrubber(obj);
            disableCurrentEditBox(obj);
        end
        %==================================================================
        function unfreezeInterval(obj)
            if canChangeStateOfSnapUnsnapBtn(obj)
                if mustSwitchToSnapMode(obj)
                    % go into unsnap modeo
                    obj.SnapUnsnapBtnHandle.Value = 0;
                    snapUnsnapCallback(obj, [], []);
                end
                enableSnapUnsnapBtn(obj);
            end
            restoreLeftRightFlagsAtUnfreeze(obj);
            restore2TimeEditBoxesAtUnfreeze(obj);               
            
        end
        %==================================================================
        function unfreezeInteraction(obj, playbackControlState)
            
            if nargin>1 && playbackControlState
                %enableAllPBButtons(obj);
                updatePlayBackControlState(obj);
            end
            
            enableScrubber(obj);
            enableCurrentEditBox(obj);
            
            %restoreSnapUnsnapBtnAtUnfreeze(obj);
        end  
        %==================================================================
        function updateLeftIntervalToTime(obj, startTime)
            % Change the start of the interval
            setEBsTimeAt(obj, obj.StartEBHandle, startTime);
            
            % If the range slider is in snap mode (i.e. time interval is
            % zoomed in), we don't need to move the flag. Only update edit
            % boxes.
            if ~obj.IsSnapMode
                moveLeftFlagFamilyForEditBoxTimes(obj);
            end
        end
        %==================================================================
        function updateRightIntervalToTime(obj, endTime)
            % Change the start of the interval
            setEBsTimeAt(obj, obj.EndEBHandle, endTime);
            
            % If the range slider is in snap mode (i.e. time interval is
            % zoomed in), we don't need to move the flag. Only update edit
            % boxes.
            if ~obj.IsSnapMode
                moveRightFlagFamilyForEditBoxTimes(obj);
            end
        end
        %==================================================================
        % This method is called by client on RangeSlider
        function updateLabelerCurrentTime(obj, t, drawInteractive)
            % update image
            t = clipCurrentTime(obj, t);
            obj.CurrentTimeUpdateDone = false;
            
            % (moved to client; see what impact it has) 
            updateRangeSliderAtCurrentTime(obj, t);
            obj.DrawInteractive = drawInteractive;
                        
            % check if UpdateValueListener really uses CurrentTimeUpdateDone
            % if NO, CurrentTimeUpdateDone false,true set up could
            % potentially be optimized
            notify(obj,'UpdateValue'); % listener uses drawInteractive
            obj.CurrentTimeUpdateDone = true;
            
            % This is a call from Custom Viewer; so we need to notify frame
            % change event
            notifyFrameChangeEvent(obj);
        end
      
        %==================================================================
        function moveScrubberFamilyAtTime(obj, t)
            
            setCurrentTimeAt(obj, t);
            if obj.IsSnapMode
                moveScrubberForEditBoxTimesInSnapMode(obj);
            else
                moveScrubberForEditBoxTimesInUnSnapMode(obj);
            end
        end   
        %==================================================================
        function updateRangeSliderForNewVideo(obj, ...
                videoStartT, videoEndT, numberOfFrames, timeVector)
            % Some uicontrol in time edit boxes may be removed or created
            % For example, if new vide has hour, hour edit box needs to be
            % created. Similarly min edit box may need to be removed
            
            %% Update
            obj.VideoStartTime = videoStartT;
            obj.VideoEndTime   = ceilTo5Decimal(videoEndT);
            obj.NumberOfFrames = numberOfFrames;
            obj.TimeVector = timeVector;
            hasHourMin(obj);
            
            %% Reset
            restoreBtnEBoxFlagStateInUnsnapMode(obj)
            deleteUIControlsInTextLayout(obj);
            
            %% Time
            createTimeLayout(obj);
            setStartTime(obj);
            setCurrentTime(obj);
            setEndTime(obj);
            setDuration(obj);
            
            %% Set callback functions
            addBtnDwnlListner4Scrubber(obj);
            addBtnDwnlListner4LeftRightFlags(obj);
            setSnapUnsnapBtnCallback(obj);
            %%
            moveScrubberForEditBoxTimesInUnSnapMode(obj);
            %%
            moveLeftFlagFamilyToExtremeLeft(obj);
            moveRightFlagFamilyToExtremeRight(obj);           
        end
        
        %==================================================================
        function updateRangeSliderAtCurrentTime(this, t)
            % This does not check if input time t is within interval.
            % Callers responsibility is to check that t is within the
            % interval specified by the left and right flags
      
            moveScrubberFamilyAtTime(this, t);
            updatePlayBackControlState(this);
        end
        
        %==================================================================
        function updateRangeSlider(obj, startT, endT)

            setEBsTimeAt(obj, obj.StartEBHandle, startT);
            setEBsTimeAt(obj, obj.EndEBHandle, endT);
                        
            moveLeftFlagFamilyForEditBoxTimes(obj);
            moveRightFlagFamilyForEditBoxTimes(obj);
        end        
        
        %==================================================================
        function updateSnapButtonStatus(obj, snapButtonStatus)
            setEnableStateOfSnapButton(obj);     
            if snapButtonStatus
                obj.SnapUnsnapBtnHandle.Value = 1;
                snapUnsnapCallback(obj);
            end
        end         
        
        %==================================================================
        function flag = get.IsVideoPaused(this)             
            flag = this.IsPauseHit;
        end 
        
        %==================================================================
        function firstFrameCallback(this, ~, ~)
            % The scrubber moves RangeSlider status to first frame
            % Reader:  if the reader is unsuccessful to read the first frame,
            %          it shows an error message in FIRST FRAME
            % Custom Display: does not impact range slider

            if ~isFirstFrPBButtonEnabled(this)
                return;
            end
            
            notify(this, 'FirstFrameRequested');
            if this.CaughtExceptionDuringPlay
                % Handle exception
                resetExceptionDuringPlay(this);                
            end

            moveScrubberFamilyToStart(this);
            % Range slider should throw frame change event, as it changes
            % the scrubber for successful frame change
            notifyFrameChangeEvent(this); 
        end
        
        %==================================================================
        function previousFrameCallback(this, ~, ~)            
            
            if ~isPrevFrPBButtonEnabled(this)
                return;
            end
                        
            enablePlayPausePBButton(this);
            changePauseToPlay(this);
            enableRightPBButtons(this);
            
            notify(this, 'PrevFrameRequested');
            if this.CaughtExceptionDuringPlay
                % Handle exception
                resetExceptionDuringPlay(this);                
            end
            if (~this.StartReachedByReader)
                moveScrubberFamilyAtTime(this, this.TimeNow);
            else
                moveScrubberFamilyAtTime(this, this.IntervalStartTime);
                disableLeftPBButtons(this);
            end
            notifyFrameChangeEvent(this);
        end        
        %==================================================================
        function nextFrameCallback(this, ~, ~)
            
            if ~isNextFrPBButtonEnabled(this)
                return;
            end
                        
            enablePlayPausePBButton(this);
            changePauseToPlay(this);
            enableLeftPBButtons(this);
            
            notify(this, 'NextFrameRequested');            
            
            if this.CaughtExceptionDuringPlay
                % Handle exception
                resetExceptionDuringPlay(this);                
            end
            
            if (~this.EndReachedByReader)
                moveScrubberFamilyAtTime(this, this.TimeNow);
            else
                moveScrubberFamilyToEnd(this);
            end
            notifyFrameChangeEvent(this);
        end
        
        %==================================================================
        function moveScrubberFamilyToEnd(this)
            
            disablePlayPausePBButton(this);
            changePlayToPause(this);
            
            enableLeftPBButtons(this);
            disableRightPBButtons(this);
            
            tEnd = this.IntervalEndTime; % recomputed
            moveScrubberFamilyAtTime(this, tEnd);            
        end
        
        %==================================================================
        function moveScrubberFamilyToStart(this)
            
            enablePlayPausePBButton(this);
            changePauseToPlay(this);
            
            disableLeftPBButtons(this);
            enableRightPBButtons(this);
            
            tStart = getSliderStartTime(this);
            moveScrubberFamilyAtTime(this, tStart);
            
        end
        
        %==================================================================
        function lastFrameCallback(this, ~, ~)            
            
            if ~isLastFrPBButtonEnabled(this)
                return;
            end     
            
            notify(this, 'LastFrameRequested');            
            if this.CaughtExceptionDuringPlay
                % Handle exception
                resetExceptionDuringPlay(this);                
            end

            moveScrubberFamilyToEnd(this);
            % Range slider should throw frame change event, as it changes
            % the scrubber for successful frame change            
            notifyFrameChangeEvent(this);
        end  
        %==================================================================
        function playPauseCallback(obj, arg2, ~)
            % toggle value
            if isempty(arg2) % explicit call (not from button mouse click)
                flag = obj.PlayBackSection.PlayPauseBtnHandle.Value;
                obj.PlayBackSection.PlayPauseBtnHandle.Value = ~flag;
            end
            
            % toggle icon image
            changeIconTooltip(obj);
            
            if needToChangeToPauseMode(obj)
                obj.IsPauseHit = false;
                obj.playVideo();
            else
                obj.IsPauseHit = true;
                obj.pauseVideo();
            end
        end        
        %==================================================================
        function flag = get.IsDoingSnap(obj)
            flag = obj.SnapUnsnapBtnHandle.Value;
        end     

        %==================================================================
        function moveLeftIntervalToCurrentTime(this)
            
            setStartTimeAsCurrentTime(this);            
            moveLeftFlagFamilyForEditBoxTimes(this);
            enableSUBtnForLeftFlagMove(this);
        end   
        
        %==================================================================
        function moveRightIntervalToCurrentTime(this)
            
            setEndTimeAsCurrentTime(this);            
            moveRightFlagFamilyForEditBoxTimes(this);
            enableSUBtnForRightFlagMove(this);
        end        
    end
    methods (Access = private)
               
        %==================================================================
        function enableSUBtnForLeftFlagMove(obj)
            if ~isLeftPoleAtExtremeLeft(obj)
                enableSnapUnsnapBtn(obj);
            end                
        end
        
        %==================================================================
        function enableSUBtnForRightFlagMove(obj)
            if ~isRightPoleAtExtremeRight(obj)
                enableSnapUnsnapBtn(obj);
            end                
        end
        
        %==================================================================
        function moveLeftFlagFamilyForEditBoxTimes(obj)
            oldUnits = getOldUnitsAndSetToPixels(obj, obj.FigHandle);
            
            startT = obj.VideoStartTime;
            ebStartTime = getTimeFromEB(obj,obj.StartEBHandle);
            endT = obj.VideoEndTime;
            
            leftFlag_rightVBorder = getPositionForTime(obj, ebStartTime, startT, endT);
            
            %% left flag
            leftFlagPos_tmp = get(obj.LeftFlagPanel, 'position');
            flagW = leftFlagPos_tmp(3);
            leftFlagPos_tmp(1) = leftFlag_rightVBorder - flagW+1;
            set(obj.LeftFlagPanel, 'position', leftFlagPos_tmp);
            
            %% left flag pole
            setLeftPolePos(obj, leftFlag_rightVBorder);
            
            %% left horizontal line
            setLeftHLinePos(obj, leftFlag_rightVBorder);
            
            %% restore unit for figure
            restoreUnits(obj, obj.FigHandle, oldUnits);
            
            notify(obj,'StartOrEndTimeUpdated');              

        end   
        
        %==================================================================
        function setStartTimeAsCurrentTime(obj)
            if obj.HasHour
                copyEBStringAndUserData(obj, obj.CurrentEBHandle.hHourEB, obj.StartEBHandle.hHourEB);
            end
            
            if obj.HasMin
                copyEBStringAndUserData(obj, obj.CurrentEBHandle.hMinEB, obj.StartEBHandle.hMinEB);
            end
            
            % sec edit box is always present
            copyEBStringAndUserData(obj, obj.CurrentEBHandle.hSecEB, obj.StartEBHandle.hSecEB);
        end         
        %==================================================================
        function t = getSliderStartTime(obj)            
            t = getTimeFromEB(obj, obj.StartEBHandle);
        end
        
        %==================================================================
        function t = getSliderCurrentTime(obj)            
            t = getTimeFromEB(obj, obj.CurrentEBHandle);
        end
        
        %==================================================================
        function t = getSliderEndTime(obj)            
            t = getTimeFromEB(obj, obj.EndEBHandle);
        end  
        
        %==================================================================
        function flag = isFirstFrPBButtonEnabled(this)
            flag = strcmp(this.PlayBackSection.FirstFrameBtnHandle.Enable, ...
                'on');
        end
        %==================================================================
        function flag = isPrevFrPBButtonEnabled(this)
            flag = strcmp(this.PlayBackSection.PreviousFrameBtnHandle.Enable, ...
                'on');
        end
        %==================================================================
        function flag = isNextFrPBButtonEnabled(this)
            flag = strcmp(this.PlayBackSection.NextFrameBtnHandle.Enable, ...
                'on');
        end
        %==================================================================
        function flag = isLastFrPBButtonEnabled(this)
            flag = strcmp(this.PlayBackSection.LastFrameBtnHandle.Enable, ...
                'on');
        end  
        %==================================================================
        function flag = isPlayPausePBButtonEnabled(this)
            flag = strcmp(this.PlayBackSection.PlayPauseBtnHandle.Enable, ...
                'on');
        end         
        
        %==================================================================
        function t = clipCurrentTime(obj, t)
            tS = getSliderStartTime(obj);
            tE = getSliderEndTime(obj);
            if t < tS
                t = tS;
            elseif t > tE
                t = tE;
            end
        end        
        %==================================================================
        function retrieveParamsFromObject(obj, containerObj)
            obj.FigHandle      = containerObj.FigHandle;
            obj.KeyPressCallback = containerObj.FigHandle.KeyPressFcn;
            obj.Xoffset        = containerObj.Xoffset;
            obj.XposImagePanel = containerObj.XposImagePanel;
            obj.TimePanel   = containerObj.TimePanel;
            obj.SliderPanel = containerObj.SliderPanel;
        end
        %==================================================================
        function hasHourMin(obj)
            if (obj.VideoEndTime >= 3600)
                obj.HasHour = true;
                obj.HasMin = true;
            elseif (obj.VideoEndTime >= 60)
                obj.HasHour = false;
                obj.HasMin = true;
            else
                obj.HasHour = false;
                obj.HasMin = false;
            end
        end
        %==================================================================
        function charToPixel(obj)
            figUnit = 'pixels';
            tmpPos = [0 0 1 1];% position of 1 pixel width, 1 pixel height container at (0,0)
            charInPixels=hgconvertunits(obj.FigHandle, tmpPos, 'char', figUnit, obj.FigHandle);
            obj.CharWidthInPixels = charInPixels(3);
            obj.CharHeightInPixels = charInPixels(4);
        end
        %==================================================================
        function getFigUnits(obj)
            obj.OrigFigUnits = get(obj.FigHandle, 'units');
        end
        %==================================================================
        function oldUnits = getOldUnitsAndSetToPixels(~, h)
            oldUnits = get(h, 'units');
            set(h,'units','pixels');
        end
        %==================================================================
        function restoreUnits(~, h, oldUnits)
            set(h,'units', oldUnits);
        end        

        %==================================================================
        function createSliderLayout(obj)
            %% Constants for this method
            FULL_HLINE_HEIGHT = 5; % in pixel
            SCRUBBER_WIDTH    = 15;% in pixel
            SCRUBBER_HEIGHT   = 11;% in pixel
            FLAG_WIDTH        = 8; % in pixel
            FLAG_HEIGHT       = 7; % in pixel
            POLE_WIDTH        = 2; % in pixel
            CLEARANCE_VERT    = 10; % in pixel
            
            %% Slider container width and height
            oldUnits = getOldUnitsAndSetToPixels(obj, obj.SliderPanel);
            pos = get(obj.SliderPanel,'position');
            wFull = pos(3);
            hFull = pos(4);
            
            %% First line: full horizontal line ===========================
            %  it is resized only in resize event
            
            % Compute parameters
            params.parent = obj.SliderPanel;
            fullHLine_w = wFull-2*obj.Xoffset;
            MM=6;
            fullHLine_y = floor(hFull/2)-floor(FULL_HLINE_HEIGHT/2)-MM;
            params.position = [obj.Xoffset fullHLine_y fullHLine_w FULL_HLINE_HEIGHT];
            params.backgroundColor = obj.DEFAULT_BGCOLOR;
            params.borderWidth = 1;
            params.highlightColor = [0.8 0.8 0.8];% border color
            params.tag = 'FullHLinePanel';
            
            % Create full horizontal line
            obj.FullHLinePanel = createPanel(params);
            addAssert(obj, obj.FullHLinePanel,'createSliderLayout');
            
            % compute additional parameters for later use
            fullHLine_endX = wFull-obj.Xoffset;
            posH = get(obj.FullHLinePanel,'position');
            obj.FullHLineLength = posH(3);
            
            leftPoleEndX = obj.Xoffset;
            scrubberMidX = obj.Xoffset;
            rightPoleStartX = fullHLine_endX-1;
            
            %% Second line: left horizontal line ==========================
            %  it spans from right most pixel of left flag pole up to the
            %  end of full horizontal line
            %  it is controlled by (1) left flag drag (2) figure resize event
            
            % Compute parameters
            startX = leftPoleEndX;
            params.position = [startX fullHLine_y fullHLine_endX-startX FULL_HLINE_HEIGHT];
            params.backgroundColor = [0.1686    0.5686    0.9686];
            %params.borderWidth = 0;
            params.tag = 'LeftHLinePanel';
            
            % Create left horizontal line
            obj.LeftHLinePanel = createPanel(params);
            addAssert(obj, obj.LeftHLinePanel,'createSliderLayout');
            
            %% Third line: middle horizontal line =========================
            % it spans from center pixel of scrubber up to the end of
            % full horizontal line
            
            % Compute parameters
            startX = scrubberMidX;
            params.position = [startX fullHLine_y fullHLine_endX-startX FULL_HLINE_HEIGHT];
            params.backgroundColor = [0.6353    0.8431    1.0000];
            %params.borderWidth = 0;
            params.tag = 'MiddleHLinePanel';
            
            % Create middle horizontal line
            obj.MiddleHLinePanel = createPanel(params);
            addAssert(obj, obj.MiddleHLinePanel,'createSliderLayout');
            
            %% Fourth line: right horizontal line =========================
            % it spans from rightmost pixel of right flag pole up to the
            % end of full horizontal line
            
            % Compute parameters
            startX = rightPoleStartX;
            params.position = [startX fullHLine_y fullHLine_endX-startX FULL_HLINE_HEIGHT];
            params.backgroundColor = obj.DEFAULT_BGCOLOR;
            params.borderWidth = 1;
            params.tag = 'RightHLinePanel';
            
            % Create right horizontal line
            obj.RightHLinePanel = createPanel(params);
            addAssert(obj, obj.RightHLinePanel,'createSliderLayout');
            
            %% left flag pole panel =======================================
            pole_y = 5;%CLEARANCE_VERT;
            startX = leftPoleEndX-POLE_WIDTH+1;
            pole_h = hFull - pole_y - CLEARANCE_VERT -FLAG_HEIGHT;
            params.position = [startX pole_y  POLE_WIDTH pole_h];
            params.backgroundColor = obj.FLAG_BGCOLOR_ENABLE;
            params.borderWidth = 0;
            params.tag = 'LeftPolePanel';
            obj.LeftPolePanel = createPanel(params);
            
            %% left flag panel ============================================
            flagY = pole_y+pole_h-1;
            startX = leftPoleEndX-FLAG_WIDTH+1;
            params.position = [startX flagY FLAG_WIDTH FLAG_HEIGHT];
            params.backgroundColor = obj.FLAG_BGCOLOR_ENABLE;
            params.borderWidth = 0;
            params.tag = 'LeftFlagPanel';
            obj.LeftFlagPanel = createPanel(params);
            
            % NOTE: render scrubber after the right flag, so that
            %       scrubber is over left and right flag poles
            
            %% right flag pole panel ======================================
            startX = rightPoleStartX;
            params.position = [startX pole_y  POLE_WIDTH pole_h];
            params.backgroundColor = obj.FLAG_BGCOLOR_ENABLE;
            params.borderWidth = 0;
            params.tag = 'RightPolePanel';
            obj.RightPolePanel = createPanel(params);
            
            %% right flag panel ===========================================
            params.position = [startX flagY FLAG_WIDTH FLAG_HEIGHT];
            params.backgroundColor = obj.FLAG_BGCOLOR_ENABLE;
            params.borderWidth = 0;
            params.tag = 'RightFlagPanel';
            obj.RightFlagPanel = createPanel(params);
            
            %% scrubber ===================================================
            startX = scrubberMidX-floor(SCRUBBER_WIDTH/2);
            startY = (hFull/2)-(SCRUBBER_HEIGHT/2)-MM;
            params.position = [startX startY SCRUBBER_WIDTH SCRUBBER_HEIGHT];
            params.backgroundColor = obj.SCRUBBER_BGCOLOR_ENABLE;%[0.7 0.7 0.7];
            params.borderWidth = 1;
            params.highlightColor = [0.5 0.5 0.5];
            params.tag = 'ScrubberPanel';
            obj.ScrubberPanel = createPanel(params);
            
            set(obj.FigHandle,'Interruptible','off')
            set(obj.FigHandle,'BusyAction','cancel')
            %
            restoreUnits(obj, obj.SliderPanel, oldUnits);
        end
        %==================================================================
        function resizeFullHLine(obj)
            pos = get(obj.FullHLinePanel,'position');
            pos(3) = obj.FullHLineLength;
            set(obj.FullHLinePanel,'position', pos);
        end

        %==================================================================
        function addBtnDwnlListner4Scrubber(obj)
            if isempty(obj.BtnDwnlListner4Scrubber)
               obj.BtnDwnlListner4Scrubber = ...
                addlistener(obj.ScrubberPanel,'ButtonDown', @obj.scrubberBtnDownCallback);  
            end
        end
        %==================================================================
        function removeBtnDwnlListner4Scrubber(obj)
            
            delete(obj.BtnDwnlListner4Scrubber);            
            obj.BtnDwnlListner4Scrubber = [];
        end        
        %==================================================================
        function addBtnDwnlListner4LeftRightFlags(obj)
            if isempty(obj.BtnDwnlListner4LeftFlag)
              obj.BtnDwnlListner4LeftFlag = ...
                addlistener(obj.LeftFlagPanel,'ButtonDown', @obj.leftFlagBtnDownCallback);
            end
            if isempty(obj.BtnDwnlListner4RightFlag)
              obj.BtnDwnlListner4RightFlag = ...
                addlistener(obj.RightFlagPanel,'ButtonDown', @obj.rightFlagBtnDownCallback);   
            end
        end
        %==================================================================
        function deleteBtnDwnlListner4LeftRightFlags(obj)
            
            delete(obj.BtnDwnlListner4LeftFlag);
            obj.BtnDwnlListner4LeftFlag = [];
            
            delete(obj.BtnDwnlListner4RightFlag);            
            obj.BtnDwnlListner4RightFlag = [];
        end
        
        %==================================================================
        function isValid = isNumericValue(~, val) 
            % hmsEBoxID represents the ID of edit box for hour or min or sec
            
            isValid = ~isnan(val);
        end
        
        %==================================================================
        function val = saturateMinOrSecValue(obj, val, hmsEBoxID)
           
            if (hmsEBoxID==obj.MIN_EB_ID) || (hmsEBoxID==obj.SEC_EB_ID) % min, sec edit boxes
                if (val < 0)
                    val = 0;
                elseif (val > 59)
                    val = 59;
                end
            end                
        end
       
        %==================================================================
        function [valNew, valStrNew] = getFormattedValue(obj, val, hmsEBoxID)
            % hmsEBoxID represents the ID of edit box for hour or min or sec
            
            if (hmsEBoxID==obj.HOUR_EB_ID) || (hmsEBoxID==obj.MIN_EB_ID) % hour, min edit boxes
                valNew = floor(val); % no decimal point
                valStrNew = sprintf('%02d', valNew); % num2str(valNew);
            else % sec edit box
                valStrNew = formatSec(val);
                valNew = str2double(valStrNew);
            end
        end
        
        %==================================================================
        function [tOut, isSaturated] = saturateTimeValue(~, tIn, tMin, tMax)
            tOut = tIn;
            isSaturated = false;
            if (tIn < tMin)
                tOut = tMin;
                isSaturated = true;
            elseif (tIn > tMax)
                tOut = tMax;
                isSaturated = true;
            end            
        end
        
        %==================================================================
        function saturateSetAndSaveEBvalues(obj, hObject, valNew, valStrNew, sceEBoxID, hmsEBoxID)
            % sceEBoxID represents the ID of edit box for start or current
            % or end time
            
            %% find time values
            if (sceEBoxID == obj.START_EB_ID) % valNew is startTime
                startTs   = getTimeFromEBwithVal(obj, obj.StartEBHandle, valNew, hmsEBoxID);
                currentTs = getTimeFromEB(obj, obj.CurrentEBHandle);
                %endTs     = getTimeFromEB(obj, obj.EndEBHandle);
                [startTs, isSaturated] = saturateTimeValue(obj, startTs, obj.VideoStartTime, currentTs);
                setAndSaveValuesInEBs(obj, hObject, obj.StartEBHandle, valStrNew, startTs, isSaturated);
            elseif (sceEBoxID == obj.CURRENT_EB_ID) % valNew is currentTime
                startTs   = getTimeFromEB(obj, obj.StartEBHandle);
                currentTs = getTimeFromEBwithVal(obj, obj.CurrentEBHandle, valNew, hmsEBoxID);
                endTs     = getTimeFromEB(obj, obj.EndEBHandle);
                [currentTs, isSaturated] = saturateTimeValue(obj, currentTs, startTs, endTs);   
                setAndSaveValuesInEBs(obj, hObject, obj.CurrentEBHandle, valStrNew, currentTs, isSaturated);
            else% valNew is endTime
                %startTs   = getTimeFromEB(obj, obj.StartEBHandle);
                currentTs = getTimeFromEB(obj, obj.CurrentEBHandle);
                endTs     = getTimeFromEBwithVal(obj, obj.EndEBHandle, valNew, hmsEBoxID);
                [endTs, isSaturated] = saturateTimeValue(obj, endTs, currentTs, obj.VideoEndTime);
                setAndSaveValuesInEBs(obj, hObject, obj.EndEBHandle, valStrNew, endTs, isSaturated);
            end
        end
        
        %==================================================================
        function restorePrevValidValue(~, hObject)
            %% find handle of the edit box
            lastValStr = get(hObject,'UserData');
            set(hObject,'string', lastValStr);
        end
        
        %==================================================================
        function setAndSaveValuesInEBs(obj, hObject, hEBs, valStrNew, ts, isSaturated)
            if isSaturated
                setEBsTimeAt(obj, hEBs, ts);                
            else
                setAndSaveValueInEB(obj, hObject, valStrNew);
            end
        end   
        
        %==================================================================
        function setAndSaveValueInEB(~, hObject, valStrNew)
            set(hObject,'string', valStrNew);
            set(hObject,'UserData', valStrNew);
        end
        
        %==================================================================
        function moveRightFlagFamilyForEditBoxTimes(obj)
            oldUnits = getOldUnitsAndSetToPixels(obj, obj.FigHandle);
            
            startT = obj.VideoStartTime;
            ebEndTime = getTimeFromEB(obj,obj.EndEBHandle);
            endT = obj.VideoEndTime;
            
            rightFlag_leftVBorder = getPositionForTime(obj, ebEndTime, startT, endT);
            
            %% right flag
            rightFlagPos_tmp = get(obj.RightFlagPanel, 'position');
            rightFlagPos_tmp(1) = rightFlag_leftVBorder;
            set(obj.RightFlagPanel, 'position', rightFlagPos_tmp);
            
            %% right flag pole
            setRightPolePos(obj, rightFlag_leftVBorder);
            
            %% right horizontal line
            setRightHLinePos(obj, rightFlag_leftVBorder);
            
            %% restore unit for figure
            restoreUnits(obj, obj.FigHandle, oldUnits);
            
            notify(obj,'StartOrEndTimeUpdated');   
        end
        
        %==================================================================
        function xPos = getPositionForTime(obj, thisTime, startT, endT)
            
            %      (endT-startT)      represents fullHLen_inRange
            % so,  (thisTime-startT)  represents (fullHLen_inRange/(endT-startT))*(thisTime-startT)
            
            % (endT-startT) is 0 based (startT is 0)
            % so we need to convert FullHLineLength to 0 based start
            
            fullHLen_inRange = obj.FullHLineLength -1;
            xPos = floor(((fullHLen_inRange/(endT-startT))*(thisTime-startT)) + 0.5);
            
            % Set boundary explicitly
            if xPos < 0
                xPos = 0;
            elseif xPos > fullHLen_inRange
                xPos = fullHLen_inRange;
            end
            xPos = xPos + obj.Xoffset;
            
            % it must meet these conditions
            % if (thisTime==startT),
            %    xPos = obj.Xoffset [already met in above equation]
            % end
            % if (thisTime==endT),
            %    xPos = fullHLen_inRange + obj.Xoffset [already met in above equation, as floor(x+0.5)=x]
            % end
        end
        
        %==================================================================
        function saveFlagStateBeforeFreeze(obj)
            hasBtnDwnlListner = ~isempty(obj.BtnDwnlListner4LeftFlag);
            if obj.IsInPlayModeFreeze
                obj.IsFlagEnabledB4FreezePlayMode = hasBtnDwnlListner;
            else
                obj.IsFlagEnabledB4FreezeOtherMode = hasBtnDwnlListner;
            end
        end
        
        %==================================================================
        function saveStartEndEBStateBeforeFreeze(obj)
            enState = get(obj.StartEBHandle.hSecEB,'enable');
            if obj.IsInPlayModeFreeze
               obj.IsStEnEBEnabledB4FreezePlayMode = strcmpi(enState, 'on');
            else
               obj.IsStEnEBEnabledB4FreezeOtherMode = strcmpi(enState, 'on');
            end            
        end
        
        %==================================================================
        function saveStateAndDisableLeftRightFlags(obj)
            saveFlagStateBeforeFreeze(obj); 
            if canChangeStateOfFlags(obj)
                disableLeftRightFlags(obj);
            end
        end
        
        %==================================================================
        function restoreLeftRightFlagsAtUnfreeze(obj)
            if canChangeStateOfFlags(obj)
                enableLeftRightFlags(obj);
            end
        end
        
        %==================================================================
        function saveSnapUnsnapBtnStateBeforeFreeze(obj)
            enState = get(obj.SnapUnsnapBtnHandle,'enable');
            if obj.IsInPlayModeFreeze
               obj.IsSUBtnEnabledB4FreezePlayMode = strcmpi(enState, 'on');
            else
               obj.IsSUBtnEnabledB4FreezeOtherMode = strcmpi(enState, 'on');
            end
            obj.IsSnapModeBeforeFreeze = obj.IsSnapMode;
        end

        %==================================================================
        function freezeInPlay(obj)
            if ~obj.IsSelectiveFreeze
                freezeInterval(obj);
            end
            freezeInteraction(obj);
        end
        
        %==================================================================
        function unfreezeInPlayEndOrPause(obj)
            unfreezeInteraction(obj);
            if ~obj.IsSelectiveFreeze
                unfreezeInterval(obj);
            end
        end
        
        %==================================================================
        function setEnableStateOfSnapButton(obj)
            startT = getTimeFromEB(obj, obj.StartEBHandle);
            endT  = getTimeFromEB(obj, obj.EndEBHandle);
            if (startT == obj.VideoStartTime) && (endT == obj.VideoEndTime)
                set(obj.SnapUnsnapBtnHandle, 'enable', 'off');
            else
                set(obj.SnapUnsnapBtnHandle, 'enable', 'on');
            end
        end

        %==================================================================
        function repositionUIwidgets(obj, sceEBoxID)
            % sceEBoxID represents the ID of edit box for start or current
            % or end time
            if obj.IsSnapMode
                assert(sceEBoxID == obj.CURRENT_EB_ID)% in snap mode, only current time can be changed
                moveScrubberForEditBoxTimesInSnapMode(obj);
            else
                if (sceEBoxID == obj.START_EB_ID) % start time edit box
                    % move left flag, left pole, left horizontal line
                    moveLeftFlagFamilyForEditBoxTimes(obj);
                elseif (sceEBoxID == obj.CURRENT_EB_ID) % current time edit box
                    % move scrubber, middle horizontal line
                    moveScrubberForEditBoxTimesInUnSnapMode(obj);
                else % end time edit box
                    % move right flag, right pole, right horizontal line
                    moveRightFlagFamilyForEditBoxTimes(obj);
                end
                setEnableStateOfSnapButton(obj);
            end
        end
        
        %==================================================================
        function timeEditBoxCallback(obj, hObject, ~, sceEBoxID, hmsEBoxID)
            % sceEBoxID represents the ID of edit box for start or current
            % or end time
            % hmsEBoxID represents the ID of edit box for hour or min or sec
            
            val = str2double(hObject.String);
            if isNumericValue(obj, val)
                val = saturateMinOrSecValue(obj, val, hmsEBoxID);
                [valNew, valStrNew] = getFormattedValue(obj, val, hmsEBoxID);
                saturateSetAndSaveEBvalues(obj, hObject, valNew, valStrNew, sceEBoxID, hmsEBoxID);

                repositionUIwidgets(obj, sceEBoxID);
                if (sceEBoxID == obj.CURRENT_EB_ID) % current value changed
                    notify(obj,'CurrentTimeChanged');
                    notifyFrameChangeEvent(obj);
                end
                updatePlayBackControlState(obj);
            else
                restorePrevValidValue(obj, hObject);
            end
            
        end
        %==================================================================
        function attachEBCallbacks(obj)
            if obj.HasHour
                set(obj.StartEBHandle.hHourEB, 'callback', {@obj.timeEditBoxCallback, obj.START_EB_ID, obj.HOUR_EB_ID});
            end
            if obj.HasMin
                set(obj.StartEBHandle.hMinEB, 'callback',  {@obj.timeEditBoxCallback, obj.START_EB_ID, obj.MIN_EB_ID});
            end
            set(obj.StartEBHandle.hSecEB, 'callback',  {@obj.timeEditBoxCallback, obj.START_EB_ID, obj.SEC_EB_ID});
            %%
            if obj.HasHour
                set(obj.CurrentEBHandle.hHourEB, 'callback', {@obj.timeEditBoxCallback, obj.CURRENT_EB_ID, obj.HOUR_EB_ID});
            end
            if obj.HasMin
                set(obj.CurrentEBHandle.hMinEB, 'callback',  {@obj.timeEditBoxCallback, obj.CURRENT_EB_ID, obj.MIN_EB_ID});
            end
            set(obj.CurrentEBHandle.hSecEB, 'callback',  {@obj.timeEditBoxCallback, obj.CURRENT_EB_ID, obj.SEC_EB_ID});
            %%
            if obj.HasHour
                set(obj.EndEBHandle.hHourEB, 'callback', {@obj.timeEditBoxCallback, obj.END_EB_ID, obj.HOUR_EB_ID});
            end
            if obj.HasMin
                set(obj.EndEBHandle.hMinEB, 'callback',  {@obj.timeEditBoxCallback, obj.END_EB_ID, obj.MIN_EB_ID});
            end
            set(obj.EndEBHandle.hSecEB, 'callback',  {@obj.timeEditBoxCallback, obj.END_EB_ID, obj.SEC_EB_ID});
        end
        %==================================================================
        function createTimeLayout(obj)
            
            %% Start time
            info.labelText = 'Start Time';
            info.startX = 3; % in pixels
            info.hourTag = 'Start Hour';
            info.minTag  = 'Start min';
            info.secTag  = 'Start sec';
            [obj.StartEBHandle, obj.StartEBPanelHandle, endX, ~] = createTimeLabelAndEditBoxes(obj,info);
            
            
            %% Current time
            clearanceX = 5*(obj.CharWidthInPixels);
            info.labelText =  'Current';
            info.startX = endX + clearanceX; % in pixels
            info.hourTag = 'Current Hour';
            info.minTag  = 'Current min';
            info.secTag  = 'Current sec';
            [obj.CurrentEBHandle, obj.CurrentEBPanelHandle, endX, ~] = createTimeLabelAndEditBoxes(obj,info);
            
            %% End time
            
            info.labelText = 'End Time';
            info.startX = endX + clearanceX; % in pixels
            info.hourTag = 'End Hour';
            info.minTag  = 'End min';
            info.secTag  = 'End sec';
            [obj.EndEBHandle, obj.EndEBPanelHandle, endX, ~] = createTimeLabelAndEditBoxes(obj,info);
            
            %% Duration
            
            info.labelText = 'Max Time';
            info.startX = endX + clearanceX; % in pixels
            info.hourTag = 'End Hour';
            info.minTag  = 'End min';
            info.secTag  = 'End sec';
            [endX, endY] = createDurationLabel(obj,info);
            
            %% Attach callbacks
            attachEBCallbacks(obj);
            
            %% Playback controls
            info.startX = endX + clearanceX;
            info.endY = endY;
            info.prevControlEndX = endX;
            endX = createPlaybackControlsLayout(obj,info);
            
            %% Snap
            info.startX = endX + clearanceX;
            info.prevControlEndX = endX;
            createSnapLayout(obj,info);
        end
        %==================================================================
        function bgColor = getBGColorForPlaybackBtn(obj)
            bgColor = get(obj.TimePanel,'BackgroundColor');
        end
        function createPlayPauseBtn(obj, params)
            
            obj.PlayBackSection.PlayPauseBtnHandle = uicontrol('parent', params.parent, ...
                'Units','pixels',...
                'position', params.position, ...
                'HorizontalAlignment','right', ... % text alignment
                'backgroundColor', params.backgroundColor,  ...
                'Style','togglebutton', ...
                'Max',1, 'Min',0, ...
                'Tag', params.tag, ...
                'String', '', ...
                'TooltipString', params.tooltipString,...
                'KeyPressFcn', obj.KeyPressCallback);
            setPlayPauseButtonImageTTString(obj, params.image, params.tooltipString);
        end
        
        function h=createPlaybackButton(obj, params)
            h = uicontrol('parent', params.parent, ...
                'Units','pixels',...
                'Tag', params.tag, ...
                'position', params.position, ...
                'HorizontalAlignment','right', ... % text alignment
                'backgroundColor', params.backgroundColor,  ...
                'Style','pushbutton', ...
                'Enable', params.enable, ...
                'String', '', ...
                'TooltipString', params.tooltipString,...
                'KeyPressFcn', obj.KeyPressCallback);
            im = imread(params.image);
            
            set(h,'cdata', im);
        end
        function deleteUIControlsInTextLayout(obj)
            controlsOnTimePanel = findall(obj.TimePanel, '-property', 'Visible');
            pause(1);
            delete(controlsOnTimePanel(2:end)); % exlude obj.TimePanel
        end
        
        function addBeginningButton(this, params)
            
            params.image  = fullfile(this.ICON_PATH, 'tobeginning.png');
            params.tag  = 'btnBeginning';
            params.tooltipString = getString( message('vision:labeler:BeginningButtonTooltip') );
            params.enable = 'off';
            h=createPlaybackButton(this, params);
            set(h,'callback', @this.firstFrameCallback);
            this.PlayBackSection.FirstFrameBtnHandle = h;
        end
        
        function addPreviousFrameButton(this, params)
            
            params.image  = fullfile(this.ICON_PATH, 'topreviousframe.png');
            params.tag  = 'btnPreviousFrame';
            params.tooltipString = getString( message('vision:labeler:PreviousFrameButtonTooltip') );
            params.enable = 'off';
            h=createPlaybackButton(this, params);
            set(h,'callback', @this.previousFrameCallback);
            this.PlayBackSection.PreviousFrameBtnHandle = h;
        end
        
        function addPlayPauseButton(this, params)
            
            params.image  = fullfile(this.ICON_PATH, 'play.png');
            params.tag  = 'btnPlay';
            params.tooltipString = getString( message('vision:labeler:PlayButtonTooltip') );
            createPlayPauseBtn(this, params);
            setPlayPauseBtnCallback(this);
        end
        
        function addNextFrameButton(this, params)
            
            params.image  = fullfile(this.ICON_PATH, 'tonextframe.png');
            params.tag  = 'btnNextFrame';
            params.tooltipString = getString( message('vision:labeler:NextFrameButtonTooltip') );
            params.enable = 'on';
            h=createPlaybackButton(this, params);
            set(h,'callback', @this.nextFrameCallback);
            this.PlayBackSection.NextFrameBtnHandle = h;
        end
        
        function addEndingButton(this, params)
            
            params.image  = fullfile(this.ICON_PATH, 'toend.png');
            params.tag  = 'btnEnding';
            params.tooltipString = getString( message('vision:labeler:EndingButtonTooltip') );
            params.enable = 'on';
            h=createPlaybackButton(this, params);
            set(h,'callback', @this.lastFrameCallback);
            this.PlayBackSection.LastFrameBtnHandle = h;
        end
        
        function startX = getStartXforPlaybackPanel(obj)
            
            pos = get(obj.TimePanel, 'position');
            fullW = pos(3);
            startX = floor(fullW/2)- floor(obj.PlaybackPanelWidth/2);
            if startX < obj.minStartXforPlaybackPanel
                startX = obj.minStartXforPlaybackPanel;
            end
        end
        
        function startX = getStartXforSnapUnsnapButton(obj)
            
            pos = get(obj.PlaybackPanelHandle, 'position');
            minStartX = pos(1) + pos(3) + 20;
            
            pos = get(obj.TimePanel, 'position');
            fullW = pos(3);
            startX = fullW- obj.SnapUnsnapBtnWidth - 3;
            if startX < minStartX
                startX = minStartX;
            end
        end
        
        function endX = createPlaybackControlsLayout(obj, info)
            clearanceX = 5;
            obj.minStartXforPlaybackPanel = info.startX + clearanceX;
            w = 16+10;
            h = w;
            offsetX = 2;
            obj.PlaybackPanelWidth = (w+offsetX)*5+offsetX; % 5 buttons
            params.parent = obj.TimePanel;
            pos_y = info.endY - h;
            startX = getStartXforPlaybackPanel(obj);
            params.position = [startX pos_y 142 h];
            params.backgroundColor = get(params.parent ,'backgroundColor');%obj.DEFAULT_BGCOLOR;
            params.borderWidth = 0;
            params.highlightColor = [0.8 0.8 0.8];% border color
            params.tag = 'playback control panel';
            obj.PlaybackPanelHandle = createPanel(params);
            %
            %endX = params.position(1) + params.position(3);
            params.parent = obj.PlaybackPanelHandle;
            
            startX = offsetX;
            %w = 16+10;
            
            endX = startX + w;
            params.position = [startX 1 w h];
            addBeginningButton(obj, params);
            %
            startX = endX + offsetX;
            endX = startX + w;
            params.position = [startX 1 w h];
            addPreviousFrameButton(obj, params);
            %
            startX = endX + offsetX;
            endX = startX + w;
            params.position = [startX 1 w h];
            addPlayPauseButton(obj, params);
            %
            startX = endX + offsetX;
            endX = startX + w;
            params.position = [startX 1 w h];
            addNextFrameButton(obj, params);
            %
            startX = endX + offsetX;
            endX = startX + w;
            params.position = [startX 1 w h];
            addEndingButton(obj, params);
            
        end
        
        %==================================================================
        function createSnapLayout(obj, info)
            
            %% Button
            
            params.parent = obj.TimePanel;
            obj.SnapUnsnapBtnWidth = 180;
            w = obj.SnapUnsnapBtnWidth;
            stX = getStartXforSnapUnsnapButton(obj);
            h = 16+10;
            pos_y = info.endY - h;
            params.position = [stX pos_y w h];
            
            %params.position = [stX 1 w 28];
            params.backgroundColor = get(params.parent ,'backgroundColor');
            
            createSnapUnsnapBtn(obj, params);
            
        end
        
        %==================================================================
        function setString(obj, str)
            set(obj.SnapUnsnapBtnHandle, 'String', str);
        end
        
        %==================================================================
        function setBGcolorOfLeftRightFlags(obj, bgColor)
            % left flag
            set(obj.LeftFlagPanel,'backgroundcolor', bgColor);
            % left flag pole
            set(obj.LeftPolePanel,'backgroundcolor', bgColor);
            % right flag
            set(obj.RightFlagPanel,'backgroundcolor', bgColor);
            % right flag pole
            set(obj.RightPolePanel,'backgroundcolor', bgColor);
        end
        
        %==================================================================
        function setBGcolorOfScrubber(obj, bgColor)
            set(obj.ScrubberPanel,'backgroundcolor', bgColor);
        end
        
        %==================================================================
        function disableLeftRightFlags(obj)
            % no enable property of uipanel; so change color; disable
            % callback
            setBGcolorOfLeftRightFlags(obj, obj.FLAG_BGCOLOR_DISBALE);
            deleteBtnDwnlListner4LeftRightFlags(obj);
        end
        
        %==================================================================
        function enableLeftRightFlags(obj)
            % no enable property of uipanel; so change color; disable
            % callback
            setBGcolorOfLeftRightFlags(obj, obj.FLAG_BGCOLOR_ENABLE);
            addBtnDwnlListner4LeftRightFlags(obj);
        end
        
        %==================================================================
        function disableScrubber(obj)
            % no enable property of uipanel; so change color; disable
            % callback
            setBGcolorOfScrubber(obj, obj.SCRUBBER_BGCOLOR_DISABLE);
            removeBtnDwnlListner4Scrubber(obj);
        end
        
        %==================================================================
        function enableScrubber(obj)
            % no enable property of uipanel; so change color; disable
            % callback
            setBGcolorOfScrubber(obj, obj.SCRUBBER_BGCOLOR_ENABLE);
            addBtnDwnlListner4Scrubber(obj);
        end
        
        %==================================================================
        function disableSnapUnsnapBtn(obj)
            set(obj.SnapUnsnapBtnHandle,'enable', 'off');
        end
        
        %==================================================================
        function enableSnapUnsnapBtn(obj)
            set(obj.SnapUnsnapBtnHandle,'enable', 'on');
        end 
        
        %==================================================================
        function restoreSnapUnsnapBtnAtUnfreeze(obj)
            if obj.IsSUBtnEnabledB4FreezePlayMode
                set(obj.SnapUnsnapBtnHandle,'enable', 'on');
            end
        end
        
        %==================================================================
        function saveStateAndDisable2TimeEditBoxes(obj)
            saveStartEndEBStateBeforeFreeze(obj); 
            if canChangeStateOfStEnEB(obj)    
                disableStartEndEditBoxes(obj);
            end
        end
        
        %==================================================================
        function saveStateAndDisable3TimeEditBoxes(obj)
            saveStateAndDisable2TimeEditBoxes(obj);
            % nobody else controls current edit box state
            disableCurrentEditBox(obj);
        end  
        
        %==================================================================
        function flag = canChangeStateOfStEnEB(obj) % Start-End Edit Box
            if obj.IsInPlayModeFreeze
                flag = obj.IsStEnEBEnabledB4FreezePlayMode;
            else
                flag = obj.IsStEnEBEnabledB4FreezeOtherMode;
            end
        end
        
        %==================================================================
        function flag = canChangeStateOfFlags(obj) % Left-Right flags
            if obj.IsInPlayModeFreeze
                flag = obj.IsFlagEnabledB4FreezePlayMode;
            else
                flag = obj.IsFlagEnabledB4FreezeOtherMode;
            end  
        end   
        
        %==================================================================
        function flag = mustSwitchToSnapMode(obj) 
            if obj.IsInPlayModeFreeze
                flag = false;
            else % algo mode freezeInPlay call
                if obj.IsSnapModeBeforeFreeze
                    % already in snap mode; no need to switch
                    flag = false;
                else
                    flag = true;
                end
            end
        end       
        
        %==================================================================
        function flag = canChangeStateOfSnapUnsnapBtn(obj) % Snap-Unsnap button
            if obj.IsInPlayModeFreeze
                flag = obj.IsSUBtnEnabledB4FreezePlayMode;
            else
                flag = obj.IsSUBtnEnabledB4FreezeOtherMode;
            end
        end        
        %==================================================================
        function restore2TimeEditBoxesAtUnfreeze(obj)
            if canChangeStateOfStEnEB(obj)
                enableStartEndEditBoxes(obj);
            end
        end
        %==================================================================
        function disableStartEndEditBoxes(obj)
            setStatesOfStartEndEditBoxes(obj, 'off', obj.TIME_EB_BGCOLOR_DISABLE)
        end
        %==================================================================
        function enableStartEndEditBoxes(obj)
            setStatesOfStartEndEditBoxes(obj, 'on', obj.TIME_EB_BGCOLOR_ENABLE)
        end
        %==================================================================
        function disableCurrentEditBox(obj)
            setStatesOfCurrentEditBoxes(obj, 'off', obj.TIME_EB_BGCOLOR_DISABLE)
        end
        %==================================================================
        function enableCurrentEditBox(obj)
            setStatesOfCurrentEditBoxes(obj, 'on', obj.TIME_EB_BGCOLOR_ENABLE)
        end
        %==================================================================
        function setStatesOfCurrentEditBoxes(obj, state, panelBGcolor)
            % no enable property of uipanel; so change each edit box
            % start time
            if obj.HasHour
                set(obj.CurrentEBHandle.hHourEB,'enable', state);
                set(obj.CurrentEBHandle.hHourColon,'backgroundcolor', panelBGcolor);
            end
            if obj.HasMin
                set(obj.CurrentEBHandle.hMinEB,'enable', state);
                set(obj.CurrentEBHandle.hMinColon,'backgroundcolor', panelBGcolor);
            end
            set(obj.CurrentEBHandle.hSecEB,'enable', state);
            set(obj.CurrentEBPanelHandle,'backgroundcolor', panelBGcolor);
        end
        %==================================================================
        function setStatesOfStartEndEditBoxes(obj, state, panelBGcolor)
            % no enable property of uipanel; so change each edit box
            % start time
            if obj.HasHour
                set(obj.StartEBHandle.hHourEB,'enable', state);
                set(obj.StartEBHandle.hHourColon,'backgroundcolor', panelBGcolor);
            end
            if obj.HasMin
                set(obj.StartEBHandle.hMinEB,'enable', state);
                set(obj.StartEBHandle.hMinColon,'backgroundcolor', panelBGcolor);
            end
            set(obj.StartEBHandle.hSecEB,'enable', state);
            set(obj.StartEBPanelHandle,'backgroundcolor', panelBGcolor);
            
            % end time
            if obj.HasHour
                set(obj.EndEBHandle.hHourEB,'enable', state);
                set(obj.EndEBHandle.hHourColon,'backgroundcolor', panelBGcolor);
            end
            if obj.HasMin
                set(obj.EndEBHandle.hMinEB,'enable', state);
                set(obj.EndEBHandle.hMinColon,'backgroundcolor', panelBGcolor);
            end
            set(obj.EndEBHandle.hSecEB,'enable', state);
            set(obj.EndEBPanelHandle,'backgroundcolor', panelBGcolor);
        end
        %==================================================================
        function saveStateAndDisableSnapUnsnapBtn(obj)
            saveSnapUnsnapBtnStateBeforeFreeze(obj); % saves IsSUBtnEnabledB4FreezePlayMode
            if obj.IsSUBtnEnabledB4FreezePlayMode
                disableSnapUnsnapBtn(obj);
            end
        end
        %==================================================================
        function movePlaybackButtons(obj)
            pos = get(obj.PlaybackPanelHandle,'position');
            pos(1) = getStartXforPlaybackPanel(obj);
            set(obj.PlaybackPanelHandle,'position', pos);
        end
        %==================================================================
        function moveSnapUnsnapButton(obj)
            pos = get(obj.SnapUnsnapBtnHandle,'position');
            pos(1) = getStartXforSnapUnsnapButton(obj);
            set(obj.SnapUnsnapBtnHandle,'position', pos);
        end
        %==================================================================
        function moveScrubberForEditBoxTimesInSnapMode(obj)
            startT = getTimeFromEB(obj,obj.StartEBHandle);
            currentT = getTimeFromEB(obj,obj.CurrentEBHandle);
            endT = getTimeFromEB(obj,obj.EndEBHandle);
            
            scrubberMidX = getScrubberMidXFromTime(obj,startT, currentT, endT);
            moveScrubberFamily(obj, scrubberMidX);
        end
        %==================================================================
        function moveScrubberForEditBoxTimesInUnSnapMode(obj)
            startT = obj.VideoStartTime;
            currentT = getTimeFromEB(obj,obj.CurrentEBHandle);
            endT = obj.VideoEndTime;
            
            scrubberMidX = getScrubberMidXFromTime(obj,startT, currentT, endT);
            moveScrubberFamily(obj, scrubberMidX);
        end
        
        %==================================================================
        function moveBackFlagsScrubberHLinesInSnapMode(obj)
            moveLeftFlagFamilyToExtremeLeft(obj);
            moveRightFlagFamilyToExtremeRight(obj);
            moveScrubberForEditBoxTimesInSnapMode(obj);
        end
        
        %==================================================================
        function moveBackFlagsScrubberHLinesInUnsnapMode(obj)
            moveLeftFlagFamilyForEditBoxTimes(obj);
            moveRightFlagFamilyForEditBoxTimes(obj);
            moveScrubberForEditBoxTimesInUnSnapMode(obj);
        end        

        %==================================================================
        function enableSnapUnsnapButton(obj)
            set(obj.SnapUnsnapBtnHandle,'enable', 'on');
        end
        %==================================================================
        function restoreBtnEBoxFlagStateInUnsnapMode(obj)
            if obj.IsSnapMode
                setString(obj, vision.getMessage('vision:labeler:ZoomInTimeInterval'));
                enableLeftRightFlags(obj);
                setStatesOfStartEndEditBoxes(obj, 'on', obj.TIME_EB_BGCOLOR_ENABLE);
                obj.IsSnapMode = false;
            end
        end
        
        %==================================================================
        function flag = needToChangeToPauseMode(obj)
            % at construction time, icon=play, value = 0
            % at every click value toggles between 0 (play)/1(pause). Value
            % change happens before button callback is invoked
            flag = obj.PlayBackSection.PlayPauseBtnHandle.Value;
        end
        %==================================================================
        function setPlayPauseButtonImageTTString(obj, imFile, tooltipString)
            im =imread(imFile);
            
            set(obj.PlayBackSection.PlayPauseBtnHandle,'cdata', im, ...
                'tooltipString', tooltipString);
        end
        
        
        %==================================================================
        function  changePauseToPlay(obj)
            imFile  = fullfile(obj.ICON_PATH, 'play.png');
            tooltipString = getString( message('vision:labeler:PlayButtonTooltip') );
            setPlayPauseButtonImageTTString(obj, imFile, tooltipString);
            obj.PlayBackSection.PlayPauseBtnHandle.Value   = false;
        end
        
        %==================================================================
        function  changePlayToPause(obj)
            imFile  = fullfile(obj.ICON_PATH, 'pause.png');
            tooltipString = getString( message('vision:labeler:PauseButtonTooltip') );
            setPlayPauseButtonImageTTString(obj, imFile, tooltipString);
            obj.PlayBackSection.PlayPauseBtnHandle.Value   = true;
        end
        
        %==================================================================
        function  changeIconTooltip(obj)
            
            if needToChangeToPauseMode(obj)
                imFile  = fullfile(obj.ICON_PATH, 'pause.png');
                tooltipString = getString( message('vision:labeler:PauseButtonTooltip') );
                
            else
                imFile  = fullfile(obj.ICON_PATH, 'play.png');
                tooltipString = getString( message('vision:labeler:PlayButtonTooltip') );
            end
            setPlayPauseButtonImageTTString(obj, imFile, tooltipString);
        end
        
        %==================================================================
        function playVideo(this)
            % play/pause button must be enabled before coming here
            % Play button must be switched to Pause mode before coming here
            this.disableLeftRightPBButtons();
            this.IsInPlayModeFreeze = true;
            notify(this, 'PlayInit');
            this.freezeInPlay();
            
            notify(this, 'PlayLoop');
            
            if ishandle(this.FigHandle) && this.CaughtExceptionDuringPlay % client must set this 
                pauseVideo(this);
                changePauseToPlay(this);
                this.CaughtExceptionDuringPlay = false;
                return;
            end
              
           
            % The following exception handles both reader and connector
            % exceptions
            if this.CaughtExceptionDuringPlay 
                % Handle exception and return to caller
                pauseVideo(this);
                changePauseToPlay(this);
                % Reset exception
                resetExceptionDuringPlay(this);   
                return;
            end
            
            if ishandle(this.FigHandle) && (~this.IsPauseHit)
                % if App is attempted to close using "x" button during
                % play, figure might be deleted before coming here
                
                % slider might not be a leftmost point; move it at leftmost
                this.moveScrubberFamilyAtTime(this.IntervalEndTime);
                notify(this, 'PlayEnd');
                
                this.unfreezeInPlayEndOrPause();
                this.IsInPlayModeFreeze = false;
                this.disablePlayPausePBButton();
                %this.changePauseToPlay();
                this.enableLeftPBButtons();
                notifyFrameChangeEvent(this);
           %else
                % handled by pauseVideo()
            end
        end        
        %==================================================================
        function pauseVideo(this)
            % play/pause button must be enabled before coming here
            % Play button must be switched to Pause mode before coming here
            %this.enablePlayPausePBButton();
            this.enableLeftRightPBButtons();
            notify(this, 'PlayEnd');
            this.unfreezeInPlayEndOrPause();
            this.IsInPlayModeFreeze = false;
        end
        %==================================================================
        function setStateOfLeftPBButtons(this, state)
            
            this.PlayBackSection.FirstFrameBtnHandle.Enable    = state;
            this.PlayBackSection.PreviousFrameBtnHandle.Enable = state;
        end
        %==================================================================
        function setStateOfRightPBButtons(this, state)
            
            this.PlayBackSection.NextFrameBtnHandle.Enable = state;
            this.PlayBackSection.LastFrameBtnHandle.Enable = state;
        end
        %==================================================================
        function setStateOfPlayPausePBButton(this, state)
            
            this.PlayBackSection.PlayPauseBtnHandle.Enable = state;
        end
        %==================================================================
        function disableLeftPBButtons(this)
            
            setStateOfLeftPBButtons(this, 'off');
        end
        %==================================================================
        function enableLeftPBButtons(this)
            
            setStateOfLeftPBButtons(this, 'on');
        end
        %==================================================================
        function disableLeftRightPBButtons(this)
            
            setStateOfLeftPBButtons(this, 'off');
            setStateOfRightPBButtons(this, 'off');
        end
        
        %==================================================================
        function enableLeftRightPBButtons(this)
            
            setStateOfLeftPBButtons(this, 'on');
            setStateOfRightPBButtons(this, 'on');
        end
        %==================================================================
        function disableRightPBButtons(this)
            
            setStateOfRightPBButtons(this, 'off');
        end
        %==================================================================
        function enableRightPBButtons(this)
            
            setStateOfRightPBButtons(this, 'on');
        end
        
        %==================================================================
        function enablePlayPausePBButton(this)
            setStateOfPlayPausePBButton(this, 'on');
        end
        %==================================================================
        function disablePlayPausePBButton(this)
            setStateOfPlayPausePBButton(this, 'off');
        end
        
        %==================================================================
        function disableAllPBButtons(this)
            disableLeftPBButtons(this);
            disablePlayPausePBButton(this);
            disableRightPBButtons(this);
        end
        
        %==================================================================
        function enableAllPBButtons(this)
            enableLeftPBButtons(this);
            enablePlayPausePBButton(this);
            enableRightPBButtons(this);
        end
        
        %==================================================================
        function disableForwardPBButtons(this)
            disablePlayPausePBButton(this);
            disableRightPBButtons(this);
        end
        
        %==================================================================
        function snapUnsnapCallback(obj, ~, ~)
            
            if obj.IsDoingSnap
                setString(obj, 'Zoom Out Time Interval');
                moveLeftFlagFamilyToExtremeLeft(obj);
                moveRightFlagFamilyToExtremeRight(obj);
                moveScrubberForEditBoxTimesInSnapMode(obj);
                % when moving flags to extreme corners, it disables the
                % snpUnsnap button; enable it now
                enableSnapUnsnapButton(obj);
                
                disableLeftRightFlags(obj);
                setStatesOfStartEndEditBoxes(obj, 'off', obj.TIME_EB_BGCOLOR_DISABLE);
                obj.IsSnapMode = true;
            else
                restoreBtnEBoxFlagStateInUnsnapMode(obj);
                moveBackFlagsScrubberHLinesInUnsnapMode(obj);
            end
        end
        %==================================================================
        function setSnapUnsnapBtnCallback(obj)
            set(obj.SnapUnsnapBtnHandle,'callback', @obj.snapUnsnapCallback)
        end
        
        %==================================================================
        function setPlayPauseBtnCallback(obj)
            set(obj.PlayBackSection.PlayPauseBtnHandle,'callback', @obj.playPauseCallback)
        end
        %==================================================================
        function setEBStringAndUserData(~, handle, valStr)
            set(handle, 'String', valStr);
            set(handle, 'UserData', valStr);
        end
        
        %==================================================================
        function copyEBStringAndUserData(~, handleFrom, handleTo)
            valStr = get(handleFrom, 'String');
            set(handleTo, 'String', valStr);
            set(handleTo, 'UserData', valStr);
        end
        
        %==================================================================
        function setEBsTimeAt(obj, hEBs, t)
            [hStr, mStr, sStr] = splitAndFormatTime(obj, t);
            if obj.HasHour
                setEBStringAndUserData(obj, hEBs.hHourEB, hStr);
            end
            
            if obj.HasMin
                setEBStringAndUserData(obj, hEBs.hMinEB, mStr);
            end
            
            % sec edit box is always present
            setEBStringAndUserData(obj, hEBs.hSecEB, sStr);            
        end
        
        %==================================================================
        function setCurrentTimeAt(obj, t)
            setEBsTimeAt(obj, obj.CurrentEBHandle, t);
        end
        
        %==================================================================
        function setCurrentTime(obj)
            setEBsTimeAt(obj, obj.CurrentEBHandle, obj.VideoStartTime);
        end
        
        %==================================================================
        function setStartTime(obj)
            setEBsTimeAt(obj, obj.StartEBHandle, obj.VideoStartTime);
        end
        
        %==================================================================
        function setEndTime(obj)
            setEBsTimeAt(obj, obj.EndEBHandle, obj.VideoEndTime);
        end
        
        %==================================================================
        function setDuration(obj)
            [hStr, mStr, sStr] = splitAndFormatTime(obj, obj.VideoEndTime);
            
            str = '';
            if obj.HasHour
                str = [hStr ':'];
            end
            if obj.HasMin
                str = [str mStr ':'];
            end  
            
            str = [str sStr];     
            set(obj.DurationPanel, 'String', str);
        end
        
        %==================================================================
        function setEndTimeAsCurrentTime(obj)
            if obj.HasHour
                copyEBStringAndUserData(obj, obj.CurrentEBHandle.hHourEB, obj.EndEBHandle.hHourEB);
            end
            
            if obj.HasMin
                copyEBStringAndUserData(obj, obj.CurrentEBHandle.hMinEB, obj.EndEBHandle.hMinEB);
            end
            
            % sec edit box is always present
            copyEBStringAndUserData(obj, obj.CurrentEBHandle.hSecEB, obj.EndEBHandle.hSecEB);
        end
        
        %==================================================================
        function newCurrTimeInSec = setCurrentTimeAsStartTime(obj)
            if obj.HasHour
                copyEBStringAndUserData(obj, obj.StartEBHandle.hHourEB, obj.CurrentEBHandle.hHourEB);
            end
            
            if obj.HasMin
                copyEBStringAndUserData(obj, obj.StartEBHandle.hMinEB, obj.CurrentEBHandle.hMinEB);
            end
            
            % sec edit box is always present
            copyEBStringAndUserData(obj, obj.StartEBHandle.hSecEB, obj.CurrentEBHandle.hSecEB);
            newCurrTimeInSec = getTimeFromEB(obj, obj.StartEBHandle);
        end
        
        %==================================================================
        function newCurrTimeInSec = setCurrentTimeAsEndTime(obj)
            if obj.HasHour
                copyEBStringAndUserData(obj, obj.EndEBHandle.hHourEB, obj.CurrentEBHandle.hHourEB);
            end
            
            if obj.HasMin
                copyEBStringAndUserData(obj, obj.EndEBHandle.hMinEB, obj.CurrentEBHandle.hMinEB);
            end
            
            % sec edit box is always present
            copyEBStringAndUserData(obj, obj.EndEBHandle.hSecEB, obj.CurrentEBHandle.hSecEB);
            newCurrTimeInSec = getTimeFromEB(obj, obj.EndEBHandle);
        end
        
        %==================================================================
        function [hEB, hTimeValuePanel, endX, endY] = createTimeLabelAndEditBoxes(obj,info)
            
            % 'StartEnd/Current time' label
            timeLabelX = info.startX; % in pixels
            timeLabelY = 5; % in pixels
            
            timeLabel = info.labelText;
            
            clearanceW = obj.CharWidthInPixels;% in pixels
            clearanceH = floor(obj.CharHeightInPixels/2);% in pixels
            timeLabelW = length(timeLabel)*obj.CharWidthInPixels*2; % in char length('Start time:')=11
            timeLabelH = obj.CharHeightInPixels + 5; % in pixels
            
            params.parent = obj.TimePanel;
            params.position = [timeLabelX timeLabelY timeLabelW timeLabelH];
            params.backgroundColor = get(params.parent,'backgroundColor');%[0.5 0.5 0.5];%
            params.string = timeLabel;
            createLabel(params);
            
            %% StartEnd/Current time values
            if obj.HasHour
                timeFormatStr = 'hh:mm:ss.sssss';
            elseif obj.HasMin
                timeFormatStr = 'mm:ss.sssss';
            else
                timeFormatStr = 'ss.sssss';
            end

            magicNumberFullW = getAdjValueForFullEditBox(obj);
            timeValueW = length(timeFormatStr)*obj.CharWidthInPixels+clearanceW*4 + magicNumberFullW; % in pixels
            timeValueH = 22;%obj.CharHeightInPixels+clearanceH; % in char
            timeValueX = timeLabelX;
            timeValueY = timeLabelY + timeLabelH + 5;
            params.position = [timeValueX timeValueY timeValueW timeValueH];
            endY = timeValueY+timeValueH;
            params.backgroundColor = [1 1 1];
            params.borderWidth = 1;
            params.highlightColor = [0.8 0.8 0.8];
            
            params.tag = '';
            hTimeValuePanel = createPanel(params);
            params.parent = hTimeValuePanel;
            
            timeValueEndX = timeValueX + timeValueW;
            endX = timeValueEndX;
            %% hh
            hourX = 1; % in pixels
            hourY = floor(clearanceH/2); % in pixels
            maxNumHourChars = 2; %length('hh');
            hourH = obj.CharHeightInPixels;
            
            [magicNumberHr, magicNumberMin, magicNumberSec] = getAdjValueForThisEditBox(obj);
            
            if obj.HasHour
                
                hourW = maxNumHourChars*obj.CharWidthInPixels+clearanceW + magicNumberHr;
                
                params.position = [hourX hourY hourW hourH];
                params.ebString = '00'; % '0'
                hEB.hHourEB = createBorderlessEditBox(obj, params, info.hourTag);
                
                %% Colon(:) after hh
                hColonX = hourX+hourW; % in pixels
                hColonY = hourY;%obj.CharHeightInPixels/2;% magic number (not using hourY)
                hColonW = obj.CharWidthInPixels;%floor(obj.CharWidthInPixels/2);
                hColonH = hourH; % in pixels
                
                params.position = [hColonX hColonY hColonW hColonH];
                hEB.hHourColon = createColonLabel(params);
            else
                assert(~obj.HasHour);
                hEB.hHourEB = [];
                hColonX = hourX;
                hColonW = 0;
            end
            
            %% mm
            if obj.HasMin
                minX = hColonX+hColonW; % in pixels
                minY = hourY; % in pixels
                maxNumMinChars = 2; %length('mm');
                minW = maxNumMinChars*obj.CharWidthInPixels+clearanceW + magicNumberMin;
                minH = hourH;
                
                params.position = [minX minY minW minH];
                params.ebString = '00'; % '0'
                hEB.hMinEB = createBorderlessEditBox(obj, params, info.minTag);
                
                %% Colon(:) after mm
                mColonX = minX+minW; % in pixels
                mColonY = hourY;%obj.CharHeightInPixels/2;% magic number (not using hourY)
                mColonW = obj.CharWidthInPixels;
                mColonH = hourH; % in pixels
                
                params.position = [mColonX mColonY mColonW mColonH];
                hEB.hMinColon = createColonLabel(params);
            else
                % info.HasHour must be false here
                hEB.hMinEB = [];
                mColonX = hourX;
                mColonW = 0;
            end
            %% ss.sssss
            minX = mColonX+mColonW; % in pixels
            minY = hourY; % in pixels
            maxNumSecChars = 8; % length('ss.sssss');
            minW = maxNumSecChars*obj.CharWidthInPixels+clearanceW + magicNumberSec;
            minH = hourH;
            
            params.position = [minX minY minW minH];
            params.ebString = '00.00000'; % '0.00000'
            hEB.hSecEB = createBorderlessEditBox(obj, params, info.secTag);
        end
        
        %==================================================================
        function [endX, endY] = createDurationLabel(obj,info)
            
            % 'StartEnd/Current time' label
            timeLabelX = info.startX; % in pixels
            timeLabelY = 5; % in pixels
            
            timeLabel = info.labelText;
            
            clearanceW = obj.CharWidthInPixels;% in pixels
            timeLabelW = length(timeLabel)*obj.CharWidthInPixels*2; % in char length('Start time:')=11
            timeLabelH = obj.CharHeightInPixels + 5; % in pixel
            
            params.parent = obj.TimePanel;
            params.position = [timeLabelX timeLabelY timeLabelW timeLabelH];
            params.backgroundColor = get(params.parent,'backgroundColor');%[0.5 0.5 0.5];%
            params.string = timeLabel;
            createLabel(params);
            
            %% StartEnd/Current time values
            if obj.HasHour
                timeFormatStr = 'hh:mm:ss.sssss';
            elseif obj.HasMin
                timeFormatStr = 'mm:ss.sssss';
            else
                timeFormatStr = 'ss.sssss';
            end
            magicNumberDur = 10;
            timeValueW = length(timeFormatStr)*obj.CharWidthInPixels+clearanceW*4 + magicNumberDur; % in pixels
            timeValueH = 22;%obj.CharHeightInPixels+clearanceH; % in char
            timeValueX = timeLabelX;
            timeValueY = timeLabelY + timeLabelH + 1;
            params.position = [timeValueX timeValueY timeValueW timeValueH];
            params.string = timeLabel;
            endY = timeValueY+timeValueH;
            
            obj.DurationPanel = createLabel(params);
            
            timeValueEndX = timeValueX + timeValueW;
            endX = timeValueEndX;

        end
        
        %==========================================================================
        function  hEB = createBorderlessEditBox(obj, params, ebTag)
            
            params.backgroundColor = get(params.parent,'backgroundColor');
            params.borderWidth = 0;
            params.tag = '';
            hPanel = createPanel(params);
            if ispc
                params.position = [0 0 params.position(3)+2 params.position(4)+2]; % params.position is in pixels
            else
                params.position = [-1 -1 params.position(3)+4 params.position(4)+4]; % params.position is in pixels
            end
            
            if obj.HasHour
                params.TooltipString = 'Time (h:m:s)';
            elseif obj.HasMin
                params.TooltipString = 'Time (m:s)';
            else
                params.TooltipString = 'Time (s)';
            end
            
            hEB = uicontrol('parent', hPanel, ...
                'Tag', ebTag, ...
                'position', params.position, ...
                'HorizontalAlignment','right', ... % text alignment
                'backgroundColor', [1 1 1],  ...
                'Style','edit', ...
                'String', params.ebString, ...
                'TooltipString', params.TooltipString);
            set(hEB,'UserData',params.ebString);
        end
        
        %==================================================================
        function changeScrubberColorOnMouseButtonDown(obj, hObject)
            
            set(hObject, 'backgroundcolor', obj.SCRUBBER_BGCOLOR_DRAGGED);
        end
        
        %==================================================================
        function changeLeftFlagColorOnMouseButtonDown(obj, hObject)
            
            set(hObject, 'backgroundcolor', obj.FLAG_BGCOLOR_DRAGGED);
            set(obj.LeftPolePanel, 'backgroundcolor', obj.FLAG_BGCOLOR_DRAGGED);
        end
        
        %==================================================================
        function changeRightFlagColorOnMouseButtonDown(obj, hObject)
            
            set(hObject, 'backgroundcolor', obj.FLAG_BGCOLOR_DRAGGED);
            set(obj.RightPolePanel, 'backgroundcolor', obj.FLAG_BGCOLOR_DRAGGED);
        end
        
        %==================================================================
        function scrubberBtnDownCallback(obj, hObject, ~)
            
            if ~obj.IsScrubberBtnDown
                obj.IsScrubberBtnDown = true;
            else
                % both left and right mouse buttons are down
                return;
            end
            % scrubberBtnDownCallback function first sets
            % figScrubberMotionCallback; then sets
            % figScrubberButtonUpCallback; so here IsScrubberBtnUpCalled
            % can safely be set to false
            obj.IsScrubberBtnUpCalled = false;
            
            % Handles the slide highlighting/selection update
            changeScrubberColorOnMouseButtonDown(obj, hObject);
            notify(obj, 'ScrubberPressed');
            
            % Uses the figure callback mechanisms to control the interactive scrubber placement
            origWindowButtonMotionFcn = get(obj.FigHandle, 'WindowButtonMotionFcn');
            setappdata(obj.FigHandle, 'origWinBtnMotFcn_FromScrubber', origWindowButtonMotionFcn);
            
            % Use WindowButtonMotionFcn for mouse drag. Even if some mouse
            % motion event is dropped, it doesn not cause any issue
            set(obj.FigHandle, 'WindowButtonMotionFcn', @obj.figScrubberMotionCallback);
            saveOldSetNewMPointerForBtn(obj);
            
            % NOTE_EVENT: Instead of using WindowButtonUpFcn, use WindowMouseRelease.
            % Reason:
            % In figure, set 'Interruptible =  off' and 'BusyAction = cancel'
            % to avoid sluggish behavior of scrubber ('BusyAction = queue'
            % makes things slower). For this setting, in WindowButtonMotionFcn,
            % when video reader is reading image using DLL, mouse up event might
            % be missed and as events are not queued, we totally miss
            % WindowButtonMotionFcn and the scrubber becomes a free running
            % scrubber
            % listener does not depend on figure's 'BusyAction' property
            if isempty(obj.BtnRelListner4Scrubber)
               obj.BtnRelListner4Scrubber = addlistener(obj.FigHandle, ...
                'WindowMouseRelease', @obj.figScrubberButtonUpCallback);
            end
        end
        
        %==================================================================
        function saveOldSetNewMPointerForBtn(obj)
            obj.OrigPointerForBtn = get(obj.FigHandle,'pointer');
            if ispc
                set(obj.FigHandle,'pointer','right');% both left-right sided arrow
            else
                set(obj.FigHandle,'pointer','hand');
            end
        end
        
        %==================================================================
        function restoreMPointerForBtn(obj)
            if ~isempty(obj.OrigPointerForBtn)
                set(obj.FigHandle,'pointer', obj.OrigPointerForBtn);
            end
        end
        
        %==================================================================
        function saveOldSetNewMPointerForFig(obj)
            obj.OrigPointerForFig = get(obj.FigHandle,'pointer');
            if ispc
                set(obj.FigHandle,'pointer','right');% both left-right sided arrow
            else
                set(obj.FigHandle,'pointer','hand');
            end
        end
        
        %==================================================================
        function restoreMPointerForFig(obj) % mouse pointer
            if ~isempty(obj.OrigPointerForFig)
                set(obj.FigHandle,'pointer', obj.OrigPointerForFig);
            end
        end
        %==================================================================
        function leftFlagBtnDownCallback(obj, hObject, ~)
            
            if ~obj.IsLeftOrRightFlagBtnDown
                obj.IsLeftOrRightFlagBtnDown = true;
            else
                % both left and right mouse buttons are down
                return;
            end
            
            % Handles the slide highlighting/selection update
            changeLeftFlagColorOnMouseButtonDown(obj,hObject);
            
            % Uses the figure callback mechanisms to control the interactive left flag placement
            origWindowButtonMotionFcn = get(obj.FigHandle, 'WindowButtonMotionFcn');
            setappdata(obj.FigHandle, 'origWinBtnMotFcn_FromLeftRightFlag', origWindowButtonMotionFcn);
            
            % Use WindowButtonMotionFcn for mouse drag. Even if some mouse
            % motion event is dropped, it doesn not cause any issue
            set(obj.FigHandle, 'WindowButtonMotionFcn', @obj.figLeftFlagMotionCallback);
            saveOldSetNewMPointerForBtn(obj);
            
            % see 'NOTE_EVENT'
            if isempty(obj.BtnRelListner4LeftRightFlag)
              obj.BtnRelListner4LeftRightFlag = addlistener(obj.FigHandle, ...
                'WindowMouseRelease', @obj.figLeftOrRightFlagButtonUpCallback);
            end
            
        end
        
        %==================================================================
        function rightFlagBtnDownCallback(obj, hObject, ~)
            
            if ~obj.IsLeftOrRightFlagBtnDown
                obj.IsLeftOrRightFlagBtnDown = true;
            else
                % both left and right mouse buttons are down
                return;
            end
            
            % Handles the slide highlighting/selection update
            changeRightFlagColorOnMouseButtonDown(obj,hObject);
            
            % Uses the figure callback mechanisms to control the interactive slide placement
            origWindowButtonMotionFcn = get(obj.FigHandle, 'WindowButtonMotionFcn');
            setappdata(obj.FigHandle, 'origWinBtnMotFcn_FromLeftRightFlag', origWindowButtonMotionFcn);
            
            % Use WindowButtonMotionFcn for mouse drag. Even if some mouse
            % motion event is dropped, it doesn not cause any issue
            set(obj.FigHandle, 'WindowButtonMotionFcn', @obj.figRightFlagMotionCallback);
            saveOldSetNewMPointerForBtn(obj);
            
            % see 'NOTE_EVENT'
            if isempty(obj.BtnRelListner4LeftRightFlag)
              obj.BtnRelListner4LeftRightFlag = addlistener(obj.FigHandle, ...
                'WindowMouseRelease', @obj.figLeftOrRightFlagButtonUpCallback);
            end
            
        end
        
        %==================================================================
        function [oldUnits, newPointXwrtSliderPanel]= setFigInPixelGetGrabPt(obj)
            
            oldUnits = getOldUnitsAndSetToPixels(obj, obj.FigHandle);
            newPoint = get(obj.FigHandle, 'currentPoint');
            % newPoint's x starts from leftmost border of app window
            % scrubber's x starts with left border of bounding box that contains fig
            % and SliderPanel
            newPointXwrtSliderPanel = newPoint(1)-obj.XposImagePanel;
        end
        %==================================================================
        function currentT = getTimeForPosition(obj,scrubberMidX, startT, endT)
            
            %      fullHLen_inRange      represents (endT-startT)
            % so,  scrubberMidX  represents ((endT-startT)/fullHLen_inRange)*scrubberMidX
            
            % (endT-startT) is 0 based (startT is 0)
            % so we need to convert FullHLineLength to 0 based start
            
            fullHLen_inRange = obj.FullHLineLength -1;
            currentT = ((endT-startT)/fullHLen_inRange)*scrubberMidX + startT;
        end
        %==================================================================
        function scrubberMidX = getScrubberMidXFromTime(obj, startT, currentT, endT)
            
            %      (endT-startT)      is represented by fullHLen_inRange
            % so,  (currentT-startT)  is represented by (fullHLen_inRange/(endT-startT))*(currentT-startT)
            
            % (endT-startT) is 0 based (startT is 0)
            % so we need to convert FullHLineLength to 0 based start
            
            %pos = get(FullHLinePanel,'position');
            fullHLen_inRange = obj.FullHLineLength -1;
            if (endT ~= startT)
                scrubberMidXwrtStartTpos = floor((fullHLen_inRange/(endT-startT))*(currentT-startT));
                scrubberMidX = scrubberMidXwrtStartTpos+obj.Xoffset;
            else
                scrubberMidX = obj.Xoffset;
            end
        end
        %==================================================================
        function newEndT = updateTimeValue(obj, hThisEB, posXwrtPanel, startT, endT)
            
            pos = get(obj.FullHLinePanel, 'position');
            posXwrtFullHLine = posXwrtPanel - pos(1);
            newEndT = getTimeForPosition(obj, posXwrtFullHLine, startT, endT);

            [hStr, mStr, sStr] = splitAndFormatTime(obj, newEndT);

            if obj.HasHour
                set(hThisEB.hHourEB, 'String',   hStr);
                set(hThisEB.hHourEB, 'UserData', hStr);
            end
            
            if obj.HasMin
                set(hThisEB.hMinEB, 'String',   mStr);
                set(hThisEB.hMinEB, 'UserData', mStr);
            end
            
            set(hThisEB.hSecEB, 'String',   sStr);
            set(hThisEB.hSecEB, 'UserData', sStr);
        end
        %==================================================================
        function updateEndTime(obj, rightFlag_leftVBorder, cond)
            % Left/Right flag can be moved only when -
            % leftmost point of fullHLine represents video start time, and
            % rightmost point of fullHLine represents video end times
            % Note, in snap mode (when fullHLine represents shorter time
            % span) the left/right flag cannot be moved
            startT = obj.VideoStartTime;
            endT = obj.VideoEndTime;
            
            if (cond == obj.RIGHT_FLAG_REGULAR_POS)
                updateTimeValue(obj, obj.EndEBHandle, rightFlag_leftVBorder, startT, endT);
            elseif (cond == obj.RIGHT_FLAG_EXTEREME_RIGHT)
                setEndTime(obj); % no need to compuet the time
            else % if (cond == obj.RIGHT_FLAG_AT_SCRUBBER_MIDX)
                setEndTimeAsCurrentTime(obj);
            end
        end
        %==================================================================
        function updateStartTime(obj, leftFlag_rightVBorder, cond)
            % Left/Right flag can be moved only when -
            % leftmost point of fullHLine represents video start time, and
            % rightmost point of fullHLine represents video end times
            % Note, in snap mode (when fullHLine represents shorter time
            % span) the left/right flag cannot be moved
            startT = obj.VideoStartTime;
            endT = obj.VideoEndTime;
            
            if (cond == obj.LEFT_FLAG_REGULAR_POS)
                updateTimeValue(obj, obj.StartEBHandle, leftFlag_rightVBorder, startT, endT);
            elseif (cond == obj.LEFT_FLAG_EXTEREME_LEFT)
                setStartTime(obj); % no need to compuet the time
            else % if (cond == obj.LEFT_FLAG_AT_SCRUBBER_MIDX)
                setStartTimeAsCurrentTime(obj);
            end
        end
        %==================================================================
        function updateCurrentTime(obj, scrubberMidX, cond)
            % Scrubber can be moved both in snap mode and unsnap mode
            % in snap mode, fullHLine represents full video length, but
            % in unsnap mode, fullHLine represents shorter time span.
            % so need to recompute start and end time from edit box
            if obj.IsSnapMode
                startT = getTimeFromEB(obj,obj.StartEBHandle);
                endT = getTimeFromEB(obj,obj.EndEBHandle);
            else
                startT = obj.VideoStartTime;
                endT = obj.VideoEndTime;
            end
            if (cond == obj.SCRUBBER_REGULAR_POS)
                updateTimeValue(obj, obj.CurrentEBHandle, scrubberMidX, startT, endT);
            elseif (cond == obj.SCRUBBER_EXTEREME_LEFT)
                setCurrentTimeAsStartTime(obj);
            else % if (cond == obj.SCRUBBER_EXTEREME_RIGHT)
                setCurrentTimeAsEndTime(obj);
            end
        end
        %==================================================================
        function addAssert(obj,HLinePanel, id)
            if obj.TEST_MODE
                HLinePos = get(HLinePanel,'position');
                pos = get(obj.FullHLinePanel,'position');
                endX = pos(1)+pos(3)-1;
                
                if (HLinePos(1)+HLinePos(3)-1) ~= endX
                    error(['WRONG:' id ': HLinePos(1)+HLinePos(3)-1) ~= endX']);
                end
            end
        end
        
        %==================================================================
        function figScrubberMotionCallback(obj, ~, ~)
            
            [oldUnits, newPointXwrtSliderPanel] = setFigInPixelGetGrabPt(obj);
            scrubberPos_tmp = get(obj.ScrubberPanel, 'position');
            scrubberPos_tmp(1) = newPointXwrtSliderPanel;
            
            %
            leftPolePos_tmp = get(obj.LeftPolePanel,'position');
            rightPolePos_tmp = get(obj.RightPolePanel,'position');
            
            %% Scrubber
            scrubberHalfW = floor(scrubberPos_tmp(3)/2);
            % scrubber's  left vertical border must be >= xL
            xL = (leftPolePos_tmp(1)+leftPolePos_tmp(3)-1)-scrubberHalfW;
            % scrubber's  left vertical border must be <= xR
            xR = rightPolePos_tmp(1)-scrubberHalfW;
            
            newScrubberPos = scrubberPos_tmp;
            cond = obj.SCRUBBER_REGULAR_POS;
            if (scrubberPos_tmp(1) <= xL)
                newScrubberPos(1) = xL;
                cond = obj.SCRUBBER_EXTEREME_LEFT;
            end
            if (scrubberPos_tmp(1) >= xR)
                newScrubberPos(1) = xR;
                cond = obj.SCRUBBER_EXTEREME_RIGHT;
            end
            set(obj.ScrubberPanel, 'position', newScrubberPos);
            
            %% middle horizontal line
            scrubberMidX = newScrubberPos(1) + scrubberHalfW;
            setMiddleHLinePos(obj, scrubberMidX);
            addAssert(obj, obj.MiddleHLinePanel, 'figScrubberMotionCallback');
            
            %% update current time
            updateCurrentTime(obj, scrubberMidX, cond);
            %% update video frame
            % Note: why we need IsScrubberBtnUpCalled? 
            %      -----------------------------------
            % Ans: When we are in 'figScrubberMotionCallback',
            % 'drawVideoFrameAtTime' function takes a long time to execute.
            % At the beginning or during 'drawVideoFrameAtTime' call,
            % button up event may occur and this calls
            % 'fighScrubberButtonUpCallback' -which calls
            % 'redrawInteractiveROIs' and draws interactive ROIS. But after
            % 'figScrubberButtonUpCallback' is executed, it comes at the
            % beginning or in the middle of call 'drawVideoFrameAtTime' and
            % this overwrites interactive ROIs (created in button up
            % callback) with static ROis created here in button motion
            % callback. To restore interactive ROIs after button up
            % callback we need the following checks.            
            % 'before' check is a must; 'after' check is done to prevent
            % mix of interactive and static ROIs.
            if ~obj.IsScrubberBtnUpCalled % 'before' check
               
               notify(obj, 'ScrubberMoved');
                
               % The following exception handles both reader and connector
               % exceptions
               if obj.CaughtExceptionDuringPlay 
                   % If a reader exception is caught during scrubber motion
                   % make sure figScrubberButtonUpCallback executes without
                   % redrawing interactive ROIs
                   obj.figScrubberButtonUpCallback();
                   resetExceptionDuringPlay(obj);
                   %% restore unit for figure
                   restoreUnits(obj, obj.FigHandle, oldUnits);
                   return;
               end

               notifyFrameChangeEvent(obj);
                
            end
            % obj.IsScrubberBtnUpCalled value might change after the above
            % call
            
            % NOTE: don't use else (instead of 'if
            % obj.IsScrubberBtnUpCalled'). New if condition ensuures that 
            % obj.IsScrubberBtnUpCalled is recomputed here
            if obj.IsScrubberBtnUpCalled % 'after' check
                notify(obj, 'ScrubberReleased');
            end
            %% restore unit for figure
            restoreUnits(obj, obj.FigHandle, oldUnits);
        end
        %==================================================================
        function figLeftFlagMotionCallback(obj, ~, ~)
            
            %FigHandle = props.FigHandle;
            [oldUnits, newPointXwrtSliderPanel] = setFigInPixelGetGrabPt(obj);
            
            scrubberPos_tmp = get(obj.ScrubberPanel, 'position');
            scrubberMidX = scrubberPos_tmp(1) + floor(scrubberPos_tmp(3)/2);
            
            %% left flag
            leftFlagPos_tmp = get(obj.LeftFlagPanel, 'position');
            flagW = leftFlagPos_tmp(3);
            flagStartX = newPointXwrtSliderPanel;
            leftFlag_rightVBorder = flagStartX + flagW-1;
            % when dragging left flag to left
            min_leftFlag_rightVBorder = obj.Xoffset;
            cond = obj.LEFT_FLAG_REGULAR_POS;
            if (leftFlag_rightVBorder <= min_leftFlag_rightVBorder)
                leftFlag_rightVBorder = min_leftFlag_rightVBorder;
                cond = obj.LEFT_FLAG_EXTEREME_LEFT;
            end
            % when dragging left flag to right
            if (leftFlag_rightVBorder >= scrubberMidX)
                leftFlag_rightVBorder = scrubberMidX;
                cond = obj.LEFT_FLAG_AT_SCRUBBER_MIDX;
            end
            leftFlagPos_tmp(1) = leftFlag_rightVBorder - flagW+1;
            set(obj.LeftFlagPanel, 'position', leftFlagPos_tmp);
            
            %% left flag pole
            setLeftPolePos(obj, leftFlag_rightVBorder);
            
            %% left horizontal line
            setLeftHLinePos(obj, leftFlag_rightVBorder);
            
            %% update start time
            updateStartTime(obj, leftFlag_rightVBorder, cond);
            
            %% restore unit for figure
            restoreUnits(obj, obj.FigHandle, oldUnits);
        end
        %==================================================================
        function figRightFlagMotionCallback(obj,~, ~)
            
            %FigHandle = props.FigHandle;
            [oldUnits, newPointXwrtSliderPanel] = setFigInPixelGetGrabPt(obj);
            
            scrubberPos_tmp = get(obj.ScrubberPanel, 'position');
            scrubberMidX = scrubberPos_tmp(1) + floor(scrubberPos_tmp(3)/2);
            
            %% right flag
            rightFlagPos_tmp = get(obj.RightFlagPanel, 'position');
            flagStartX = newPointXwrtSliderPanel;
            rightFlag_leftVBorder = flagStartX;
            % when dragging right flag to left
            cond = obj.RIGHT_FLAG_REGULAR_POS;
            if (rightFlag_leftVBorder <= (scrubberMidX))
                rightFlag_leftVBorder = scrubberMidX;
                cond = obj.RIGHT_FLAG_AT_SCRUBBER_MIDX;
            end
            % when dragging right flag to right
            max_rightFlag_leftVBorder = obj.FullHLineLength  + obj.Xoffset -1;
            if (rightFlag_leftVBorder >= max_rightFlag_leftVBorder)
                rightFlag_leftVBorder = max_rightFlag_leftVBorder;
                cond = obj.RIGHT_FLAG_EXTEREME_RIGHT;
            end
            rightFlagPos_tmp(1) = rightFlag_leftVBorder;
            set(obj.RightFlagPanel, 'position', rightFlagPos_tmp);
            
            %% right flag pole
            setRightPolePos(obj, rightFlag_leftVBorder);
            
            %% right horizontal line
            setRightHLinePos(obj, rightFlag_leftVBorder);
            
            %% update start time
            updateEndTime(obj, rightFlag_leftVBorder, cond);
            
            %% restore unit for figure
            restoreUnits(obj, obj.FigHandle, oldUnits);
        end

        %==================================================================
        function flag = isLeftPoleAtExtremeLeft(obj)
            
            posV = get(obj.LeftPolePanel, 'position');
            leftPoleEndX = posV(1)+posV(3)-1;
            posF = get(obj.FullHLinePanel, 'position');
            fullHLineStartX = posF(1);
            flag = (leftPoleEndX==fullHLineStartX);
        end
        %==================================================================
        function flag = isRightPoleAtExtremeRight(obj)
            
            posV = get(obj.RightPolePanel, 'position');
            leftPoleStartX = posV(1);
            posF = get(obj.FullHLinePanel, 'position');
            fullHLineEndX = posF(1)+posF(3)-1;
            flag = (leftPoleStartX==fullHLineEndX);
        end
        
        %==================================================================
        function flag = areCurrentAndEndTimeSame(this)
            flag = (getSliderCurrentTime(this) == getSliderEndTime(this));
        end
        
        %==================================================================
        function flag = areCurrentAndStartTimeSame(this)
            flag = (getSliderCurrentTime(this) == getSliderStartTime(this));
        end
        
        %==================================================================
        function updatePlayBackControlState(this)
            currentETend = areCurrentAndEndTimeSame(this);
            currentETstart = areCurrentAndStartTimeSame(this);
            if (currentETend && currentETstart)
                disableAllPBButtons(this);
            else
                enableAllPBButtons(this);
                
                if currentETend
                    disableForwardPBButtons(this);
                    this.changePlayToPause();
                else
                    if currentETstart
                        disableLeftPBButtons(this);
                    end
                    this.changePauseToPlay();
                end
            end
        end
        
        %==================================================================
        function figScrubberButtonUpCallback(obj, ~, ~)
            % Button up callback invoked, so downed mouse button must be up
            % now
            obj.IsScrubberBtnDown = false;
            
            obj.IsScrubberBtnUpCalled = true;
            
            % restore original BG color (for left flag, right flag, scrubber move)
            set(obj.ScrubberPanel, 'backgroundcolor', obj.SCRUBBER_BGCOLOR_ENABLE)
            
            % restore original WindowButtonMotionFcn
            origWindowButtonMotionFcn = getappdata(obj.FigHandle,'origWinBtnMotFcn_FromScrubber');
            set(obj.FigHandle, 'WindowButtonMotionFcn', origWindowButtonMotionFcn);
            
            % restore figure units
            set(obj.FigHandle, 'units', obj.OrigFigUnits);
            
            restoreMPointerForBtn(obj);
            
            % Redraw Interactive ROIs only when there are no reader exceptions
            if ~(obj.CaughtExceptionDuringPlay)
                % redrawInteractiveROIs must be called after restoring app data
                % otherwise figScrubberButton motion function may be called
                notify(obj, 'ScrubberReleased');
            end            
            
            updatePlayBackControlState(obj);
            
            % reset appdata
            setappdata(obj.FigHandle,'origWinBtnMotFcn_FromScrubber',[]);
            
            % remove listener for better performance
            delete(obj.BtnRelListner4Scrubber);
            obj.BtnRelListner4Scrubber = [];
        end
        
        %==================================================================
        function figLeftOrRightFlagButtonUpCallback(obj, ~, ~)
            
            % Button up callback invoked, so downed mouse button must be up
            % now
            obj.IsLeftOrRightFlagBtnDown = false;
            
            restoreMPointerForBtn(obj);
            if obj.IsSnapMode
                return;
            end
            % restore original BG color (for left flag, right flag, scrubber move)
            set(obj.LeftFlagPanel, 'backgroundcolor', obj.FLAG_BGCOLOR_ENABLE)
            set(obj.RightFlagPanel, 'backgroundcolor', obj.FLAG_BGCOLOR_ENABLE)
            
            % for left flag or right flag move,
            %   (1) change flag pole color
            %   (2) enable/disable StretchToFit button
            % set both of them; one might be redundant, but it let's you
            % create only one callback for both left and right flags
            set(obj.LeftPolePanel, 'backgroundcolor', obj.FLAG_BGCOLOR_ENABLE);
            set(obj.RightPolePanel, 'backgroundcolor', obj.FLAG_BGCOLOR_ENABLE);
            
            if (isLeftPoleAtExtremeLeft(obj) && ...
                    isRightPoleAtExtremeRight(obj))
                set(obj.SnapUnsnapBtnHandle, 'enable', 'off');
            else
                set(obj.SnapUnsnapBtnHandle, 'enable', 'on');
            end
            
            set(obj.FigHandle, 'WindowButtonMotionFcn', '', 'units', obj.OrigFigUnits);
            
            updatePlayBackControlState(obj);
            
            % restore original WindowButtonMotionFcn
            origWindowButtonMotionFcn = getappdata(obj.FigHandle,'origWinBtnMotFcn_FromLeftRightFlag');
            set(obj.FigHandle, 'WindowButtonMotionFcn', origWindowButtonMotionFcn);
            
            % reset appdata
            setappdata(obj.FigHandle,'origWinBtnMotFcn_FromLeftRightFlag',[]);
            
            % remove listener for better performance
            delete(obj.BtnRelListner4LeftRightFlag);
            obj.BtnRelListner4LeftRightFlag = [];
            
            notify(obj,'StartOrEndTimeUpdated');              
        end
        
        %==================================================================
        function t = getTimeFromEBwithVal(obj, hEB, val, hmsEBoxID)
            
            t=0;
            if obj.HasHour
                if (hmsEBoxID==obj.HOUR_EB_ID)
                    t = t + val*3600;
                else
                    t = t + str2double(get(hEB.hHourEB,'string'))*3600;
                end
            end
            if obj.HasMin
                if (hmsEBoxID==obj.MIN_EB_ID)
                    t = t + val*60;
                else
                    t = t + str2double(get(hEB.hMinEB,'string'))*60;
                end
            end
            if (hmsEBoxID==obj.SEC_EB_ID)
                t = t + val;
            else
                t = t + str2double(get(hEB.hSecEB,'string'));
            end
        end
        %==================================================================
        function t = getTimeFromEB(obj, hEB)
            
            t=0;
            if obj.HasHour
                t = t + str2double(get(hEB.hHourEB,'string'))*3600;
            end
            if obj.HasMin
                t = t + str2double(get(hEB.hMinEB,'string'))*60;
            end
            
            t = t + str2double(get(hEB.hSecEB,'string'));
        end

        %==================================================================
        function setMiddleHLinePos(obj, scrubberMidX)
            
            middleHLinePos_tmp = get(obj.MiddleHLinePanel,'position');
            if obj.TEST_MODE
                HLine_endX = middleHLinePos_tmp(1)+middleHLinePos_tmp(3)-1;
                assert(HLine_endX == (obj.FullHLineLength+obj.Xoffset-1));
            end
            
            HLine_endX = obj.FullHLineLength+obj.Xoffset-1;
            
            middleHLinePos_tmp(1) = scrubberMidX;%?? -1,+1?? April-6
            middleHLinePos_tmp(3) = max(HLine_endX-middleHLinePos_tmp(1)+1,1);
            set(obj.MiddleHLinePanel, 'position', middleHLinePos_tmp);
        end
        %==================================================================
        function setLeftHLinePos(obj, leftFlag_rightVBorder)
            leftHLinePos_tmp = get(obj.LeftHLinePanel,'position');
            if obj.TEST_MODE
                HLine_endX = leftHLinePos_tmp(1)+leftHLinePos_tmp(3)-1;
                assert(HLine_endX == (obj.FullHLineLength+obj.Xoffset-1));
            end
            
            HLine_endX = obj.FullHLineLength+obj.Xoffset-1;
            
            leftHLinePos_tmp(1) = leftFlag_rightVBorder;
            leftHLinePos_tmp(3) = max(HLine_endX-leftHLinePos_tmp(1)+1,1);
            set(obj.LeftHLinePanel, 'position', leftHLinePos_tmp);
            addAssert(obj, obj.LeftHLinePanel, 'setLeftHLinePos');
        end
        %==================================================================
        function setRightPolePos(obj, rightFlag_leftVBorder)
            rightPolePos_tmp = get(obj.RightPolePanel,'position');
            rightPolePos_tmp(1) = rightFlag_leftVBorder;
            set(obj.RightPolePanel, 'position', rightPolePos_tmp);
        end
        %==================================================================
        function setLeftPolePos(obj, leftFlag_rightVBorder)
            
            leftPolePos_tmp = get(obj.LeftPolePanel,'position');
            w = leftPolePos_tmp(3);
            leftPolePos_tmp(1) = leftFlag_rightVBorder-w+1;
            set(obj.LeftPolePanel, 'position', leftPolePos_tmp);
        end
        %==================================================================
        function setRightHLinePos(obj, rightFlag_leftVBorder)
            
            rightHLinePos_tmp = get(obj.RightHLinePanel,'position');
            
            if obj.TEST_MODE
                HLine_endX = rightHLinePos_tmp(1)+rightHLinePos_tmp(3)-1;
                assert(HLine_endX == (obj.FullHLineLength+obj.Xoffset-1));
            end
            
            HLine_endX = obj.FullHLineLength+obj.Xoffset-1;
            rightHLinePos_tmp(1) = rightFlag_leftVBorder;
            rightHLinePos_tmp(3) = max(HLine_endX-rightHLinePos_tmp(1)+1, 1);
            set(obj.RightHLinePanel, 'position', rightHLinePos_tmp);
            addAssert(obj, obj.RightHLinePanel, 'setRightHLinePos');
        end
        %==================================================================
        function moveScrubberFamily(obj,scrubberMidX)
            
            %% scrubber
            scrubberPos_tmp = get(obj.ScrubberPanel, 'position');
            scrubberW = scrubberPos_tmp(3);
            startX = scrubberMidX-floor(scrubberW/2);
            scrubberPos_tmp(1) = startX;
            set(obj.ScrubberPanel, 'position', scrubberPos_tmp);
            
            %% middle horizontal line
            setMiddleHLinePos(obj, scrubberMidX);
            addAssert(obj, obj.MiddleHLinePanel, 'moveScrubberFamily');
        end
        %==================================================================
        function moveLeftFlagFamilyToEndX(obj,leftFlag_rightVBorder)
            
            %% left flag
            leftFlagPos_tmp = get(obj.LeftFlagPanel, 'position');
            flagW = leftFlagPos_tmp(3);
            leftFlagPos_tmp(1) = leftFlag_rightVBorder - flagW+1;
            set(obj.LeftFlagPanel, 'position', leftFlagPos_tmp);
            
            %% left flag pole
            setLeftPolePos(obj, leftFlag_rightVBorder)
            
            %% left horizontal line
            setLeftHLinePos(obj, leftFlag_rightVBorder);
        end
        %==================================================================
        function moveLeftFlagFamilyToExtremeLeft(obj)
            
            pos = get(obj.FullHLinePanel,'position');
            leftFlag_rightVBorder = pos(1);
            moveLeftFlagFamilyToEndX(obj,leftFlag_rightVBorder);
            notify(obj,'StartOrEndTimeUpdated');              
        end
        %==================================================================
        function moveRightFlagFamilyToEndX(obj,rightFlag_leftVBorder)
            
            %% right flag
            rightFlagPos_tmp = get(obj.RightFlagPanel, 'position');
            rightFlagPos_tmp(1) = rightFlag_leftVBorder;
            set(obj.RightFlagPanel, 'position', rightFlagPos_tmp);
            
            %% right flag pole
            setRightPolePos(obj, rightFlag_leftVBorder)
            
            %% right horizontal line
            setRightHLinePos(obj, rightFlag_leftVBorder);
        end
        %==================================================================
        function moveRightFlagFamilyToExtremeRight(obj)
            
            %pos = get(obj.RightHLinePanel,'position');
            %rightFlag_leftVBorder2 = pos(1)+pos(3)-1;
            rightFlag_leftVBorder = obj.FullHLineLength + obj.Xoffset-1;
            %assert(rightFlag_leftVBorder2==rightFlag_leftVBorder);
            
            moveRightFlagFamilyToEndX(obj,rightFlag_leftVBorder);
            notify(obj,'StartOrEndTimeUpdated');              
        end
        
        %==================================================================
        function createSnapUnsnapBtn(obj, params)
            
            obj.SnapUnsnapBtnHandle = uicontrol('parent', params.parent, ...
                'Units','pixels',...
                'position', params.position, ...
                'HorizontalAlignment','right', ... % text alignment
                'backgroundColor', params.backgroundColor,  ...
                'Style','togglebutton', ...
                'Max',1, 'Min',0, ...
                'Tag', 'Snap Unsnap', ...
                'String', vision.getMessage('vision:labeler:ZoomInTimeInterval'), ...
                'Enable','off',...
                'KeyPressFcn', obj.KeyPressCallback, ...
                'TooltipString', vision.getMessage('vision:labeler:ZoomInTimeIntervalToolTip'));
        end
        
        %==================================================================
        function [hStr, mStr, sStr] = splitAndFormatTime(obj, ts)
            [h, m, s] = splitTime(ts);
            if obj.HasHour
                hStr = sprintf('%02d', h); % num2str(h);
            else
                hStr = '';
            end
            if obj.HasMin
                mStr = sprintf('%02d', m); % num2str(m);
            else
                mStr = '';
            end
            sStr = formatSec(s);
        end  
        
        %==================================================================
        function magicNumber = getAdjValueForFullEditBox(obj)
            
            if obj.HasHour
                if ispc
                   magicNumber = 10;
                else
                   magicNumber = 0;
                end                
            elseif obj.HasMin
                if ispc
                   magicNumber = 0;
                else
                   magicNumber = -5;
                end
            else
                magicNumber = -7;
            end         
        end  
        %==================================================================
        function [magicNumberHr, magicNumberMin, magicNumberSec] = getAdjValueForThisEditBox(obj)
            
            if obj.HasMin
                if ispc
                   magicNumberSec = 5;
                else
                   magicNumberSec = 0;
                end
            else
                if ispc
                   magicNumberSec = 5;
                else
                   magicNumberSec = 5;
                end
            end
            
            if obj.HasHour
                if ispc
                   magicNumberMin = 3;
                else
                   magicNumberMin = -2;
                end
            else
                if ispc
                   magicNumberMin = 3;
                else
                   magicNumberMin = 3;
                end
            end 
            
            magicNumberHr = 3;            
        end
        
    end
end

%==================================================================
function outVal = ceilTo5Decimal(inVal)
    strVal = sprintf('%0.5f', double(inVal));
    outVal = str2double(strVal);
    if (outVal < inVal)
        outVal = outVal + 0.00001;
    end
end
   
%==================================================================
function [h, m, s] = splitTime(ts)

h = fix(ts / 3600);
s = ts - 3600*h;
m = fix(s / 60);
s = s - 60*m;
%s = sprintf('%0.5f',s); % get only five decimal points
s = ceilTo5Decimal(s);
end

%==================================================================
function s = formatSec(s)
    
    % alternatively use: sStr = sprintf('%0.5f', s);
    intPart = floor(s);
    fractPart = s-intPart;

    intPartStr = sprintf('%02d', intPart);
    fractPart = sprintf('%0.5f', fractPart);

    s = [intPartStr fractPart(2:end)];
end 
        
%==========================================================================
function stLabelControl = createColonLabel(params)
stLabelControl = uicontrol('parent', params.parent, ...
    'position', params.position, ...
    'backgroundColor', [1 1 1], ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment','left', ...
    'Style','text', ...
    'String', ':');

end
%==========================================================================
function stLabelControl = createLabel(params)
stLabelControl = uicontrol('parent', params.parent, ...
    'position', params.position, ...
    'backgroundColor', params.backgroundColor, ...
    'Style','text', ...
    'HorizontalAlignment', 'left', ...
    'String', params.string);
end

%==========================================================================
function hPanel = createPanel(params)
hPanel = uipanel('parent', params.parent,...
    'Units','pixels',...
    'Tag', params.tag, ...
    'backgroundColor', params.backgroundColor,...
    'borderWidth', params.borderWidth,...
    'Position', params.position,...
    'BorderType', 'Line',...
    'HighlightColor', params.highlightColor,...
    'Visible', 'on');
end

