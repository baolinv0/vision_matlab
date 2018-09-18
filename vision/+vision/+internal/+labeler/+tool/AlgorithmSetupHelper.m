classdef AlgorithmSetupHelper < handle
    
    % Copyright 2016-2017 The MathWorks, Inc.
    
    properties (Access = private)
        %Dispatcher             An instance of an AlgorithmDispatcher
        Dispatcher              
        
        %Algorithm              An instance of the dispatched AutomationAlgorithm 
        %                       (empty till Dispatcher instantiates it)
        Algorithm       
        
        %LabelChecker           An instance of an AlgorithmLabelChecker object
        LabelChecker            vision.internal.labeler.tool.AlgorithmLabelChecker
        
        %AppName                'groundTruthLabeler' or 'imageLabeler'
        AppName
        
    end
    
    events
        CaughtExceptionEvent
    end
    
    properties (Dependent, SetAccess=private)
        %ValidROILabelNames         A cell array containing names of valid
        %                           ROI label definitions (empty till
        %                           LabelChecker is created)
        ValidROILabelNames
        
        %ValidFrameLabelNames       A cell array containing names of valid
        %                           frame label definitions (empty till
        %                           LabelChecker is created)
        ValidFrameLabelNames
        
        %InvalidROILabelIndices     Logical indices to invalid ROI label
        %                           definitions
        InvalidROILabelIndices
        
        %InvalidFrameLabelIndices   Logical indices to invalid Frame label
        %                           definitions
        InvalidFrameLabelIndices
        
        %ValidLabelDefinitions      Table of valid ROI and Scene label
        %                           definitions
        ValidLabelDefinitions
        
        %AlgorithmInstance          Instance of dispatched
        %                           AutomationAglorithm object (empty till
        %                           Dispatcher instantiates it)
        AlgorithmInstance
    end
    
    methods
        %------------------------------------------------------------------
        function this = AlgorithmSetupHelper(appName)
            this.AppName = appName;
            
            if isImageLabeler(this)
                this.Dispatcher = vision.internal.imageLabeler.ImageLabelerAlgorithmDispatcher();
            else
                this.Dispatcher = vision.internal.labeler.VideoLabelerAlgorithmDispatcher();
            end
        end
        
        %------------------------------------------------------------------
        function configureDispatcher(this, algorithmClass)
            this.Dispatcher.configure(algorithmClass);
        end
        
        %------------------------------------------------------------------
        function success = isAlgorithmOnPath(this)
            
            if ~this.Dispatcher.isAlgorithmOnPath
                % Ask user if they want to add algorithm to path or CD to
                % containing folder.
                
                cancelButton    = vision.getMessage('vision:uitools:Cancel');
                addToPathButton = vision.getMessage('vision:labeler:addToPath');
                cdButton        = vision.getMessage('vision:labeler:cdFolder');
                
                % Unable to find algorithm on the path anymore. Get the
                % path cached in the repository and ask user what they want
                % to do.
                folder = this.Dispatcher.FolderFromRepository;
                alg    = sprintf('''%s''', this.Dispatcher.AlgorithmName);
                
                msg = vision.getMessage(...
                    'vision:labeler:notOnPathQuestion', alg, folder);
                
                buttonName = questdlg(msg, ...
                    getString(message('vision:labeler:notOnPathTitle')),...
                    cdButton, addToPathButton, cancelButton, cdButton);
                
                hasCanceled = true;
                switch buttonName
                    case cdButton
                        cd(folder);
                    case addToPathButton
                        addpath(folder);
                    otherwise
                        hasCanceled = true;
                end
                
                success = ~hasCanceled;
            else
                success = true;
            end
        end
        
        %------------------------------------------------------------------
        function success = isAlgorithmValid(this)
            
            [success, msg] = isAlgorithmValid(this.Dispatcher);
            
            if ~success
                dialogTitle = vision.getMessage('vision:labeler:InvalidAlgorithmTitle');
                errordlg(msg, dialogTitle, 'modal');
            end
        end
        
        %------------------------------------------------------------------
        function success = instantiateAlgorithm(this)
            
            success = false;
            try
                this.Dispatcher.instantiate();
                this.Algorithm = this.Dispatcher.Algorithm;
            catch ME
                dlgTitle = 'vision:labeler:CantInstantiateAlgorithmTitle';
                showExceptionMessage(this, ME, dlgTitle);
                return;
            end
            success = true;
        end
        
        %------------------------------------------------------------------
        function fixAlgorithmTimeInterval(this, interval, intervalIndices, isAutomationFwd)
            
            if hasTemporalContext(this.Algorithm)
                setAlgorithmTimes(this.Algorithm, interval, intervalIndices);
                setAutomationDirection(this.Algorithm, isAutomationFwd);
                if isAutomationFwd
                    updateCurrentTime(this.Algorithm, interval(1));
                else
                    updateCurrentTime(this.Algorithm, interval(2));
                end
            end
        end
        
        %------------------------------------------------------------------
        function setAlgorithmLabelData(this, labels)
            
            setVideoLabels(this.Algorithm, labels);
        end
        
        %------------------------------------------------------------------
        function success = checkValidLabels(this, roiLabelList, frameLabelList)
            
            success = false;
            try
                import vision.internal.labeler.tool.AlgorithmLabelChecker;
                this.LabelChecker = AlgorithmLabelChecker(this.Algorithm, roiLabelList, frameLabelList);
                
            catch ME
                dlgTitle = 'vision:labeler:CantValidateLabels';
                showExceptionMessage(this, ME, dlgTitle);
                return;
            end
            
            if ~isAlgorithmSelectionConsistent(this.LabelChecker)
                
                % If the label definitions contain only pixel labels, give
                % a more helpful error dialog.
                onlyPixelLabelsDefined = ~isempty([this.LabelChecker.ROILabelDefinitions.Type]) && all([this.LabelChecker.ROILabelDefinitions.Type]==labelType.PixelLabel);
                if onlyPixelLabelsDefined
                    dlgTitle = vision.getMessage('vision:labeler:UnsupportedLabelsTitle');
                    msg      = vision.getMessage('vision:labeler:PixelLabelsNotSupported');
                    errordlg(msg, dlgTitle, 'modal');
                    return;
                end
                
                dlgTitle = vision.getMessage('vision:labeler:UnsupportedLabelsTitle');
                msg      = vision.getMessage('vision:labeler:UnsupportedLabelsMessage');
                errordlg(msg, dlgTitle, 'modal');
                return;
            end
            
            % Additional checks need to be made if there are valid pixel
            % labels.
            if hasPixelLabels(this.LabelChecker)
                
                algName = this.AlgorithmInstance.Name;
                
                if ~onlyPixelLabels(this.LabelChecker)
                    allValidLabels      = [this.ValidROILabelNames, this.ValidFrameLabelNames];
                    validPixelLabels    = this.LabelChecker.ValidPixelLabelNames;
                    validNonPixelLabels = setdiff(allValidLabels, validPixelLabels);
                    
                    dlgTitle = vision.getMessage('vision:labeler:InconsistentLabelsTitle');
                    msg = vision.getMessage('vision:labeler:OnlyPixelLabelsMessage', algName, toText(validPixelLabels), toText(validNonPixelLabels));
                    
                    okBtn = vision.getMessage('vision:uitools:OK');
                    goBtn = vision.getMessage('vision:labeler:GoToCheckLabelDefinition');
                    btnName = questdlg(msg, dlgTitle, okBtn, goBtn, okBtn);
                    switch btnName
                        case okBtn
                            %do nothing
                        case goBtn
                            openCheckLabelDefinition(this.LabelChecker);
                    end
                    return;
                end
                
                if ~allPixelLabels(this.LabelChecker)
                    invalidPixelLabels = this.LabelChecker.InvalidPixelLabelNames;
                    
                    dlgTitle = vision.getMessage('vision:labeler:InconsistentLabelsTitle');
                    msg = vision.getMessage('vision:labeler:AllPixelLabelsMessage', algName, invalidPixelLabels);
                    
                    okBtn = vision.getMessage('vision:uitools:OK');
                    goBtn = vision.getMessage('vision:labeler:GoToCheckLabelDefinition');
                    btnName = questdlg(msg, dlgTitle, okBtn, goBtn, okBtn);
                    switch btnName
                        case okBtn
                            %do nothing
                        case goBtn
                            openCheckLabelDefinition(this.LabelChecker);
                    end
                    return;
                end
                
            end
            success = true;
            
            labelDefs = this.ValidLabelDefinitions;
            setValidLabelDefinitions(this.Algorithm, labelDefs);
            
            function text = toText(names)
                if isempty(names)
                    text = '';
                elseif numel(names)==1
                    text = names{1};
                else
                    % Add ', ' to all but last names
                    names(1:end-1) = strcat(names(1:end-1), {', '});
                    text = [names{:}];
                end
            end
        end
        
        %------------------------------------------------------------------
        % Given a list of rois, this method computes a list of valid ROIs
        % for and imports them into the instantiated automation algorithm
        % at the current time stamp.
        %------------------------------------------------------------------
        function validIdx = importCurrentROIs(this, rois)
            
            if hasTemporalContext(this.Algorithm)
                currentTime = this.Algorithm.CurrentTime;
                [roisToImport, validIdx] = computeValidROIs(this.LabelChecker, rois, currentTime);
            else
                [roisToImport, validIdx] = computeValidROIs(this.LabelChecker, rois);
            end
            importLabels(this.Algorithm, roisToImport);
        end
        
        %------------------------------------------------------------------
        function TF = hasSettingsDefined(this)
            TF = hasSettingsDefined(this.Algorithm);
        end
        
    end
    
    methods
        %------------------------------------------------------------------
        function names = get.ValidROILabelNames(this)
            if isempty(this.LabelChecker)
                names = {};
            else
                names = this.LabelChecker.ValidROILabelNames;
            end
        end
        
        %------------------------------------------------------------------
        function names = get.ValidFrameLabelNames(this)
            if isempty(this.LabelChecker)
                names = {};
            else
                names = this.LabelChecker.ValidFrameLabelNames;
            end
        end
        
        %------------------------------------------------------------------
        function labelDefs = get.ValidLabelDefinitions(this)
            
            roiDefs = this.LabelChecker.ROILabelDefinitions;
            roiDefs(this.LabelChecker.InvalidROILabelIndices) = [];
            
            % Remove the PixelLabelID field if none of the valid ROI
            % definitions is of PixelLabelType.
            if isfield(roiDefs, 'PixelLabelID') && isempty([roiDefs.PixelLabelID])
                roiDefs = rmfield(roiDefs, 'PixelLabelID');
            end
            
            frameDefs = this.LabelChecker.FrameLabelDefinitions;
            frameDefs(this.LabelChecker.InvalidFrameLabelIndices) = [];
            
            if isempty(roiDefs) && isempty(frameDefs)
                labelDefs = [];
            else
                % Add PixelLabelID field if required before concatenating
                if isfield(roiDefs, 'PixelLabelID')
                    if isempty(frameDefs)
                        frameDefs = repmat(struct('Name',[],'Type',[],'PixelLabelID',[]),size(frameDefs));
                    else
                        frameDefs(end).PixelLabelID = [];
                    end
                end
                labelDefs = vertcat(roiDefs,frameDefs);
            end
        end
        
        %------------------------------------------------------------------
        function idx = get.InvalidROILabelIndices(this)
            idx = this.LabelChecker.InvalidROILabelIndices;
        end
        
        %------------------------------------------------------------------
        function idx = get.InvalidFrameLabelIndices(this)
            idx = this.LabelChecker.InvalidFrameLabelIndices;
        end
        
        %------------------------------------------------------------------
        function alg = get.AlgorithmInstance(this)
            alg = this.Algorithm;
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function showExceptionMessage(this, ME, dlgTitle)
            
            dlgTitle = vision.getMessage(dlgTitle);
            evtData = vision.internal.labeler.tool.ExceptionEventData(dlgTitle, ME);
            notify(this, 'CaughtExceptionEvent', evtData);
        end
        
        %------------------------------------------------------------------
        function tf = isImageLabeler(this)
            tf = strcmpi(this.AppName, 'imageLabeler');
        end
        
    end
end