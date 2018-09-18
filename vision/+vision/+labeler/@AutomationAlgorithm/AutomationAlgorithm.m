%AutomationAlgorithm Interface for algorithm automation in labeling.
%   AutomationAlgorithm specifies the interface for defining custom
%   automation algorithms to run in labeling apps (Image Labeler and Ground
%   Truth Labeler app). Use of the Ground Truth Labeler requires that you
%   have the Automated Driving System Toolbox(TM).
%
%   To define a custom automation algorithm, you must construct a class
%   that inherits from the vision.labeler.AutomationAlgorithm class. The
%   AutomationAlgorithm class is an abstract class that defines the
%   signature for methods and properties that the labeling apps use for
%   loading and executing algorithms in the automation mode to generate
%   ground truth labels.
%
%   To define and use a custom automation algorithm with the Image Labeler
%   or Ground Truth Labeler App, follow these steps:
%
%   1. Create a +vision/+labeler folder within a folder that is already
%      on the MATLAB path. For example, if the folder /local/MyProject is
%      on the MATLAB path, then create a +vision/+labeler folder
%      hierarchy as follows:
%
%           projectFolder = fullfile('local','MyProject');
%           automationFolder = fullfile('+vision','+labeler');
%
%           mkdir(projectFolder, automationFolder)
%
%   2. Define a class that inherits from
%      vision.labeler.AutomationAlgorithm and implements the automation
%      algorithm. For <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'temporalAutomationAlgorithms')">temporal automation algorithms</a> (algorithms that rely
%      on the concept of linear time, like a tracking algorithm),
%      additionally inherit from vision.labeler.mixin.Temporal. Note that
%      temporal automation algorithms can only be defined for use with the
%      Ground Truth Labeler App.
%       
%      For a non-temporal automation algorithm to be used in the Image
%      Labeler or Ground Truth Labler App, <a href= "matlab:vision.labeler.AutomationAlgorithm.openTemplateInEditor">open this template class</a> and
%      follow the outlined steps.
%
%      For a temporal automation algorithm to be used in the Ground Truth
%      Labeler App, <a href="matlab:vision.labeler.AutomationAlgorithm.openTemplateInEditor('temporal')">Open this template class</a> and follow the outlined steps.
%
%   3. Save the file to the +vision/+labeler folder. Saving the file to
%      the package directory is required to use your custom algorithm from
%      within the app. You can add a folder to the path using the ADDPATH
%      function.
%
%   4. Refresh the algorithm list from within the app to start using your
%      custom algorithm.
%
%   
%   Application Programming Interface Specification
%   -----------------------------------------------
%   The AutomationAlgorithm class defines the following pre-defined 
%   properties:
%
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.SelectedLabelDefinitions')">SelectedLabelDefinitions</a>    - Selected ROI and Scene label definitions
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.ValidLabelDefinitions')">ValidLabelDefinitions</a>       - All valid label definitions
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.GroundTruth')">GroundTruth</a>                 - Ground truth labels marked before automation 
%   
%   Clients of AutomationAlgorithm are required to define the following
%   user-defined properties:
%
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.Name')">Name</a>            - Algorithm name
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.Description')">Description</a>     - Algorithm description
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.UserDirections')">UserDirections</a>  - Algorithm usage directions
%   
%   Clients of AutomationAlgorithm are required to implement the following
%   user-defined methods to define execution of the algorithm:
%
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.checkLabelDefinition')">checkLabelDefinition</a> - Check if label definition is valid
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.checkSetup')">checkSetup</a>           - Check if algorithm is ready for execution (optional)
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.initialize')">initialize</a>           - Initialize state for algorithm execution (optional)
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.run')">run</a>                  - Run algorithm on image
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.terminate')">terminate</a>            - Terminate algorithm execution and clean up state (optional)
%
%   Clients of AutomationAlgorithm can also implement the following
%   user-defined methods:
%   
%   <a href="matlab:help('vision.labeler.AutomationAlgorithm.settingsDialog')">settingsDialog</a>      - Define settings dialog
%   Constructor         - A constructor can be defined, but must take no
%                         input arguments.
%
%   
%   See also imageLabeler, groundTruthLabeler, vision.labeler.mixin.Temporal.
   

% Copyright 2017 The MathWorks, Inc.

classdef AutomationAlgorithm < handle
    
    %======================================================================
    % Application Programming Interface
    %======================================================================
    
    properties (Abstract, Constant)
        %Name Algorithm name
        %   Character vector specifying name of Automation Algorithm
        %   defined.
        Name
        
        %Description Algorithm Description
        %   Characted vector describing Automation Algorithm.
        Description
    
        %UserDirections Algorithm usage directions
        %   UserDirections is used to specify a set of directions displayed
        %   in the right panel of the App. Specify UserDirections as a cell
        %   array of character vectors.
        UserDirections
    end
    
    %----------------------------------------------------------------------
    % Use this property to query labels in the App.
    %----------------------------------------------------------------------
    properties (GetAccess = public, SetAccess = private)
        
        %GroundTruth Ground truth labels
        %   groundTruth object holding all labels marked in the labeler app
        %   prior to automation. See <a href="matlab:help('groundTruth')">groundTruth</a> for a
        %   description of the groundTruth object.
        %
        %   See also groundTruth.
        GroundTruth
        
        %SelectedLabelDefinitions Selected label definitions
        %   Struct array containing one or two elements, corresponding to
        %   selected label definitions in the labeler app. The selected
        %   label definitions are highlighted in yellow on the left panels
        %   titled 'ROI Label Definition' and 'Scene Label Definition'.
        %
        %   SelectedLabelDefinitions is a struct array with fields Type and
        %   Name. Type is a <a href="matlab:help('labelType')">labelType</a> enumeration with possible values
        %   Rectangle, Line, PixelLabel and Scene. Name is a character
        %   vector containing the name of the selected label definitions.
        %   For label definitions of type PixelLabel, an additional field
        %   PixelLabelID holds the ID for each selected pixel label.
        %
        %   Example: SelectedLabelDefinitions for Rectangle and Scene
        %   ---------------------------------------------------------
        %   selectedLabelDefs(1).Name = 'Car';
        %   selectedLabelDefs(1).Type = labelType.Rectangle;
        %   selectedLabelDefs(2).Name = 'Sunny';
        %   selectedLabelDefs(2).Type = labelType.Scene;
        %
        %   Example: SelectedLabelDefinitions for PixelLabel
        %   ------------------------------------------------
        %   selectedLabelDefs.Name         = 'Road';
        %   selectedLabelDefs.Type         = labelType.PixelLabel;
        %   selectedLabelDefs.PixelLabelID = 2;
        %
        %   See also labelType.
        SelectedLabelDefinitions
        
        %ValidLabelDefinitions Valid label definitions
        %   Struct array containing all valid label definitions in the
        %   labeler app. These are all the label definitions that satisfy
        %   the checkLabelDefinition method.
        %
        %   ValidLabelDefinitions is a struct array with fields Type and
        %   Name. Type is a <a href="matlab:help('labelType')">labelType</a> enumeration with possible values 
        %   Rectangle, Line, PixelLabel and Scene. Name is a character
        %   vector containing the name of the label. For label definitions
        %   of type PixelLabel, an additional field PixelLabelID holds the
        %   ID for each pixel label.
        %
        %   Example: ValidLabelDefinitions for Rectangle, Line and Scene
        %   ------------------------------------------------------------
        %   validLabelDefs(1).Name = 'Car';
        %   validLabelDefs(1).Type = labelType.Rectangle;
        %   validLabelDefs(2).Name = 'LaneMarker';
        %   validLabelDefs(2).Type = labelType.Line;
        %   validLabelDefs(3).Name = 'Sunny';
        %   validLabelDefs(3).Type = labelType.Scene;
        %
        %   Example: ValidLabelDefinitions for PixelLabel
        %   ---------------------------------------------
        %   validLabelDefs(1).Name          = 'Road';
        %   validLabelDefs(1).Type          = labelType.PixelLabel;
        %   validLabelDefs(1).PixelLabelID  = 1;
        %   validLabelDefs(2).Name          = 'Sky';
        %   validLabelDefs(2).Type          = labelType.PixelLabel;
        %   validLabelDefs(2).PixelLabelID  = 2;
        %
        %   See also labelType.
        ValidLabelDefinitions
    end
    
    %----------------------------------------------------------------------
    % Optionally override this method to provide Algorithm Settings for the
    % user in the labeler app.
    %----------------------------------------------------------------------
    methods
        %settingsDialog
        %   settingsDialog is invoked when the user clicks on the Settings
        %   button. Use this method to define a dialog for setting
        %   algorithm parameters.
        %
        %   settingsDialog(algObj) is used to display algorithm settings in
        %   a dialog. Use a modal dialog, created using functions such as
        %   dialog, inputdlg or listdlg.
        %
        %   See also dialog, inputdlg, listdlg.
        settingsDialog(this)
    end
    
    %----------------------------------------------------------------------
    % Override these methods to define how the automation algorithm
    % operates. checkLabelDefinition() and run() must be overriden, while
    % initialize() and terminate() are optional.
    %----------------------------------------------------------------------
    methods (Abstract)
        %checkLabelDefinition
        %   checkLabelDefinition is invoked for each ROI Label definition
        %   and Scene Label definition in the labeler app session. Use this
        %   function to restrict automation algorithms to certain label
        %   types relevant to the particular algorithm. Label definitions
        %   that return false will be disabled during automation.
        %
        %   isValid = checkLabelDefinition(algObj, labelDef) should return
        %   TRUE for valid label definitions and FALSE for invalid label
        %   definitions. labelDef is a struct containing two fields Type
        %   and Name. Type is an enumeration of class labelType with
        %   possible values Rectangle, Line, PixelLabel and Scene. Name is
        %   a character vector containing the name of the specified label.
        %
        %   Below is an example of a labelDef structure:
        %
        %           Type: Rectangle
        %           Name: 'Car'
        %
        %
        %   Example: Restrict automation to only Rectangle ROI labels 
        %   ---------------------------------------------------------
        %
        %   function checkLabelDefinition(algObj, labelDef)
        %       
        %       isValid = (labelDef.Type == labelType.Rectangle);
        %   end
        %
        %   
        %   Example: Restrict automation to only PixelLabel labels
        %   ------------------------------------------------------
        %   
        %   function checkLabelDefinition(algObj, labelDef)
        %   
        %       isValid = (labelDef.Type == labelType.PixelLabel);
        %   end
        %
        %   Notes
        %   -----
        %   In order to access the selected label definitions (highlighted
        %   in yellow on the left panels), use the <a href="matlab:help('vision.labeler.AutomationAlgorithm.SelectedLabelDefinitions')">SelectedLabelDefinitions</a>
        %   property.
        %
        %   See also labelType,
        %   vision.labeler.AutomationAlgorithm.SelectedLabelDefinitions
        isValid = checkLabelDefinition(this, labelDef)
    end
    
    methods
        function isReady = checkSetup(this, varargin) %#ok<INUSD>
        %checkSetup
        %   checkSetup is invoked when the user clicks RUN. If checkSetup
        %   returns TRUE, the app proceeds to execute initialize(), run()
        %   and terminate(). If checkSetup returns FALSE or throws an
        %   exception, a dialog is displayed. If an exception is thrown,
        %   the dialog message echoes the exception message. If the method
        %   returns false, the dialog message asks the user to set up the
        %   algorithm correctly. This method is optional.
        %
        %   isReady = checkSetup(algObj) should return TRUE if the user
        %   completed setup correctly and the automation algorithm algObj
        %   is ready to begin execution, FALSE otherwise.
        %
        %   isReady = checkSetup(algObj, labelsToAutomate) additionally
        %   provides labelsToAutomate, all labels marked before executing
        %   the algorithm. checkSetup is called with this syntax only for
        %   automation algorithms with a <a href="matlab:helpview(fullfile(docroot,'toolbox','driving','driving.map'),'temporalAutomationAlgorithms')">temporal context</a>. labelsToAutomate
        %   is a table containing all labels marked before executing the
        %   algorithm. It is a table with variables Name, Type, TimeStamp
        %   and Position as described below:
        %
        %   ---------------------------------------------------------------
        %   VARIABLE NAME | DESCRIPTION
        %   --------------|------------------------------------------------
        %   Type          | labelType enumeration with possible values
        %                 | Rectangle or Line.
        %   --------------|------------------------------------------------
        %   Name          | Character vector specifying the label name.
        %   --------------|------------------------------------------------
        %   TimeStamp     | Scalar double specifying time stamp in seconds
        %                 | at which label was marked.
        %   --------------|------------------------------------------------
        %   Position      | Position specifying location of ROI labels and 
        %                 | empty for Scene labels as described below:
        %                 |
        %                 |------------------------------------------------
        %                 | LABEL TYPE | DESCRIPTION
        %                 |------------|-----------------------------------
        %                 | Rectangle  | 1-by-4 vector specifying position
        %                 |            | of bounding box locations as 
        %                 |            | [x y w h]. Multiple Rectangle ROIs
        %                 |            | can be specified as an M-by-4
        %                 |            | matrix.
        %                 |------------|-----------------------------------
        %                 | Line       | N-by-2 vector specifying N points
        %                 |            | along a polyline as:
        %                 |            |
        %                 |            | [x1,y1; x2,y2;...xN,yN]  
        %   ---------------------------------------------------------------
        %
        %   Below is an example of a labelsToAutomate table:
        %
        %      Type           Name        TimeStamp      Position  
        %    _________    ____________    _________    ____________
        %
        %    Rectangle    'Car'           0.033333     [1x4 double]
        %    Line         'LaneMarker'    0.066667     [5x2 double] 
        %
        %   
        %   Example: Check that at least one ROI label is drawn
        %   ---------------------------------------------------
        %
        %   function isReady = checkSetup(algObj, labelsToAutomate)
        %   
        %       notEmpty = ~isempty(labelsToAutomate);
        %       
        %       hasROILabels = any(labelsToAutomate.Type == labelType.Rectangle);
        %
        %       if notEmpty && hasROILabels
        %           isReady = true;
        %       else
        %           isReady = false;
        %       end
        %       
        %   end
        %
        %   See also table, labelType.
            
            isReady = true;
        end
        
        function initialize(this, I, varargin) %#ok<INUSD>
        %initialize
        %   initialize is invoked before the automation algorithm executes.
        %   Use this method to initialize state of the automation
        %   algorithm. This method is optional.
        %
        %   initialize(algObj, I) initializes state of the automation
        %   algorithm algObj. I is a numeric matrix containing the image
        %   frame corresponding to the first image.
        %
        %   initialize(algObj, I, labelsToAutomate) additionally provides
        %   labelsToAutomate, all labels marked before executing the
        %   algorithm. initialize is called with this syntax only for
        %   automation algorithms with a <a href="matlab:helpview(fullfile(docroot,'toolbox','driving','driving.map'),'temporalAutomationAlgorithms')">temporal context</a>.
        %
        %   See also vision.labeler.AutomationAlgorithm.checkSetup.
        end
        
    end
    
    methods (Abstract)
        %run
        %   run is invoked on each image frame chosen for automation in the
        %   labeler app. Use this method to execute the algorithm to
        %   compute labels. Assign labels based on the algorithm in this
        %   method.
        %
        %   autoLabels = run(algObj, I) processes a single frame I and
        %   produces automated labels in autoLabels. The format of
        %   autoLabels depends on the type of automation algorithm being
        %   defined.
        %   
        %   Algorithms without pixel labels
        %   -------------------------------
        %   For automation algorithms without pixel labels, autoLabels can
        %   either be a struct array (or table) with fields Type, Name and
        %   Position.
        %
        %   The fields of the struct array are described below:
        %   
        %   Type        A <a href="matlab:help('labelType')">labelType</a> enumeration that defines the type of label. 
        %               Type can have values Rectangle, Line or Scene. 
        %
        %   Name        A character vector specifying a label name that
        %               returns true for checkLabelDefinition. Only
        %               existing label names previously defined in the
        %               labeler app can be used.
        %
        %   Position    A 1-by-4 or M-by-4 vector representing [x y w h] if
        %               Type is Rectangle, Nx2 matrix representing a
        %               polyline specified by N points
        %               [x1,y1;x2,y2;...xn,yn] if Type is Line and a
        %               logical if Type is Scene.
        %
        %   Algorithms with pixel labels
        %   ----------------------------
        %   For automation algorithms with pixel labels, autoLabels must be
        %   a <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'categoricalLabelMatrix')">Categorical label matrix</a>, where each category represents a
        %   pixel label.
        %
        %
        %   Below is an example of how to specify an autoLabels table for
        %   an algorithm that detects a Car, finds a lane and classifies
        %   the scene as Sunny.
        %   
        %   % Rectangle labeled 'Car' positioned with top-left at (20,20)
        %   % with width and height equal to 50.
        %   autoLabels(1).Name      = 'Car';
        %   autoLabels(1).Type      = labelType('Rectangle');
        %   autoLabels(1).Position  = [20 20 50 50];
        %
        %   % Line labeled 'LaneMarker' with 3 points.
        %   autoLabels(2).Name      = 'LaneMarker';
        %   autoLabels(2).Type      = labelType('Line');
        %   autoLabels(2).Position  = [100 100; 100 110; 110 120];
        %
        %   % Scene labeled 'Sunny'
        %   autoLabels(3).Name      = 'Sunny';
        %   autoLabels(3).Type      = labelType('Scene');
        %   autoLabels(3).Position  = true;   
        %
        %   See also categorical.
        autoLabels = run(this, I)
    end
    
    methods
        function terminate(this) %#ok<MANU>
        %terminate
        %   terminate is invoked after run() has been invoked on the last
        %   frame in the specified interval or the user stops algorithm
        %   running. Use this method to clean up state. This method is
        %   optional.
        %
        %   terminate(algObj) cleans up state of the automation algorithm
        %   algObj.    
            
        end
    end
    
    %======================================================================
    % Implementation
    %======================================================================
    
    properties (Access=private, Hidden)
        %Version Version
        %   Tag used to record versioning of object.
        Version = ver('vision');
    end
    
    methods (Hidden)
        %------------------------------------------------------------------
        % Use this method to identify if the concrete automation algorithm
        % class inherits the temporal mixin.
        %------------------------------------------------------------------
        function tf = hasTemporalContext(algObj)
            tf = isa(algObj, 'vision.labeler.mixin.Temporal');
        end
        
        %------------------------------------------------------------------
        % Use this method to identify if the concrete automation algorithm
        % class is the old driving.automation.AutomationAlgorithm instead
        % of the new vision.labeler.AutomationAlgorithm with (or
        % without) the temporal mixin.
        %------------------------------------------------------------------
        function tf = isDrivingAutomationAlgorithm(algObj)
            tf = isa(algObj, 'driving.automation.AutomationAlgorithm');
        end
    end
    
    methods (Static, Hidden)
        %------------------------------------------------------------------
        function openTemplateInEditor(varargin)
            %openTemplateInEditor opens a template AutomationAlgorithm
            %class in the MATLAB editor.
            
            if nargin==1
                templateType = varargin{1};
            else
                templateType = 'nontemporal';
            end
            
            if strcmpi(templateType,'temporal')
                fileName = 'TemporalAutomationAlgorithmExample';
            else
                fileName = 'AutomationAlgorithmExample';
            end
            
            % Read in template code. Use full path to avoid local versions
            % of the file from being read.
            example = fullfile(toolboxdir('vision'),'vision','+vision',...
                '+internal',[fileName, '.m']);
            fid = fopen(example);
            contents = fread(fid,'*char');
            fclose(fid);
            
            % Open template code in an untitled file in the editor
            editorDoc = matlab.desktop.editor.newDocument(contents);
            
            % Change the function name to the name of the untitled file
            contents = regexprep(editorDoc.Text,...
                fileName, 'MyCustomAlgorithm','once');
            
            editorDoc.Text = contents;
            editorDoc.smartIndentContents;
            editorDoc.goToLine(1);
        end
        
        %------------------------------------------------------------------
        function text = getDefaultUserDirections(name,varargin)
            switch name
                case 'selectroidef'
                    labelName = varargin{1};
                    text = [...
                        'ROI Label Definition Selection: Select one of the ',...
                        sprintf('ROI definitions to label as %s.',labelName)];
                case 'rundetector'
                    labelName = varargin{1};
                    text = sprintf('Run: Click run to detect %s in each image.',labelName);
                case 'review'
                    text = [...
                        'Review and Modify: Review automated labels manually. ',...
                        'You can modify, delete, and add new labels.'];
                case 'rerun'
                    text = [...
                        'Change Settings: If you are not satisfied with ',...
                        'the results, click Undo Run. Click Settings to ',...
                        'modify algorithm settings, and then Run again.'];
                case 'accept'
                    text = [...
                        'Accept/Cancel: When you are satisfied with ',...
                        'results, click Accept and return to manual ',...
                        'labeling. Click Cancel to return to manual ',...
                        'labeling without saving automation results.'];
            end
        end
    end
    
    methods (Access = { ?vision.internal.labeler.tool.LabelerTool,...
                        ?vision.internal.labeler.tool.AlgorithmSetupHelper})
        %------------------------------------------------------------------
        % Setup
        %------------------------------------------------------------------
        
        %------------------------------------------------------------------
        function setVideoLabels(this, labels)
            
            assert(isa(labels,'groundTruth'),'Expected a groundTruth object');
            this.GroundTruth = labels;
        end
        
        %------------------------------------------------------------------
        function setValidLabelDefinitions(this, labelDefs)
            
            this.ValidLabelDefinitions = labelDefs;
        end
        
        %------------------------------------------------------------------
        function setSelectedLabelDefinitions(this, selections)
            
            this.SelectedLabelDefinitions = selections;
        end
        
        %------------------------------------------------------------------
        function importLabels(varargin)
            % This is a stub. Automation Algorithms with no temporal
            % component cannot import labels.
        end
        
        %------------------------------------------------------------------
        function isReady = verifyAlgorithmSetup(this)

            isReady = checkSetup(this);
        end
        
        %------------------------------------------------------------------
        % Execution
        %------------------------------------------------------------------
        
        %------------------------------------------------------------------
        function doInitialize(this, I)
            
            initialize(this, I);
        end
        
        %------------------------------------------------------------------
        function [videoLabels,isValid] = doRun(this, I)
            videoLabels = run(this, I);
            
            % Check the entries in videoLabels and convert it to a struct.
            [videoLabels,isValid] = checkVideoLabelValidity(this,videoLabels);
            
        end
        
        %------------------------------------------------------------------
        function hasSettings = hasSettingsDefined(this)
            
            % Find the method associated with settingsDialog
            meta = metaclass(this);
            
            methodNames = {meta.MethodList.Name};
            settingsMethodIdx = strcmp('settingsDialog', methodNames);
            
            settingsMethod = meta.MethodList(settingsMethodIdx);
            settingsMethod = settingsMethod(1);
            
            % If the defining class for this method is abstract,
            % settingsDialog was not defined.
            hasSettings = ~settingsMethod.DefiningClass.Abstract;
        end
        
        %------------------------------------------------------------------
        function doSettings(this)
            
            settingsDialog(this);
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function [videoLabels,isValid] = checkVideoLabelValidity(algObj, videoLabels)
            
            if ~isempty(videoLabels)
                
                catValidity = iscategorical(videoLabels);
                if catValidity
                    %TODO Tim add checks here for categoricals
                    
                    % All labels must be pixel labels
                    isValid = all([algObj.ValidLabelDefinitions.Type]==labelType.PixelLabel);
                else
                    
                    % Check that struct fields match
                    structValidity = isstruct(videoLabels) ...
                        && all(isfield(videoLabels,{'Type','Name','Position'}));
                    
                    % Check that table column names match
                    tableValidity  = istable(videoLabels);
                    if tableValidity
                        variableNames = videoLabels.Properties.VariableNames;
                        
                        tableValidity = tableValidity ...
                            && any(strcmpi('Type',variableNames)) ...
                            && any(strcmpi('Name',variableNames)) ...
                            && any(strcmpi('Position',variableNames));
                    end
                    
                    isValid = structValidity || tableValidity;
                    
                    if istable(videoLabels)
                        videoLabels = table2struct(videoLabels);
                    end
                    
                    entryValidity = isValid && all(arrayfun(@validateEachEntry,videoLabels));
                    
                    isValid = isValid && entryValidity;
                end
            else
                isValid = true;
            end
            
            %--------------------------------------------------------------
            function isValidEntry = validateEachEntry(s)
                name = s.Name;
                type = s.Type;
                pos  = s.Position;
                
                 % Check that name is a char vector
                 % Check that type is a labelType enum
                 % Check that position is a float or logical
                if ~ischar(name) || ~isa(type,'labelType') || ~(isfloat(pos) || islogical(pos))
                    isValidEntry = false;
                    return;
                end
                
                switch type
                    % For a rectangular label, this must be 1-by-4
                    case labelType.Rectangle
                        isValidEntry = size(pos,2)==4;
                    % For a line label, this must be N-by-2
                    case labelType.Line
                        isValidEntry = size(pos,2)==2;
                    % For a scene label, this must be logical
                    case labelType.Scene
                        isValidEntry = islogical(pos);
                    otherwise
                        assert(false,'Invalid label Type')
                end
            end
        end
    end
end
