% CalibrationOptionsPanel Encapsulates calibration settings tool strip panel
%
%   This class represents the calibration settings/options panel used in
%   Camera Calibrator App and Stereo Camera Calibrator App.
%
%   panel = CalibrationOptionsPanel(fun) creates a tool strip panel
%   containing the calibration options controls. fun is a handle to the
%   callback function.
%
%   CalibrationOptionsPanel properties:
%
%       Panel       - Tool strip panel object
%       CameraModel - A struct containing the calibraiton options  
%
%   CalibrationOptionsPanel methods:
%
%       setAllButtonsEnabled - enable or disable the panel controls

% Copyright 2014 The MathWorks, Inc.

classdef CalibrationOptionsPanel < vision.internal.uitools.ToolStripPanel
    properties (Access=private)
        RadialCoeffsButton1
        RadialCoeffsButton2
        CheckSkewButton
        CheckTangentialButton
        
        RadialCoefficientsButtonGroup   
    end
    
    properties(Dependent)
        % CameraModel A struct containing the calibration options
        % corresponding to the current state of the panel. The struct
        % contains the following fields:
        %   NumDistortionCoefficients   - 2 or 3
        %   ComputeSkew                 - true or false
        %   ComputeTangentialDistortion - true or false
        CameraModel
    end
    
    methods
        function this = CalibrationOptionsPanel(fun)
            this.createPanel();
            this.addRadialDistortionButtons();
            this.addComputeButtons();
            this.addCallback(fun);
        end
        
        %------------------------------------------------------------------
        % Gets the camera model options
        %------------------------------------------------------------------
        function cameraModel = get.CameraModel(this)
            if this.RadialCoeffsButton1.Selected
                cameraModel.NumDistortionCoefficients = 2;
            else
                cameraModel.NumDistortionCoefficients = 3;
            end

            cameraModel.ComputeSkew = this.CheckSkewButton.Selected;
            cameraModel.ComputeTangentialDistortion = ...
                this.CheckTangentialButton.Selected;
        end
        
        %------------------------------------------------------------------
        function set.CameraModel(this, cameraModel)
            if cameraModel.NumDistortionCoefficients == 2
                this.RadialCoeffsButton1.Selected = true;
                this.RadialCoeffsButton2.Selected = false;
            else
                this.RadialCoeffsButton2.Selected = true;
                this.RadialCoeffsButton1.Selected = false;
            end

            this.CheckSkewButton.Selected = cameraModel.ComputeSkew;
            this.CheckTangentialButton.Selected = cameraModel.ComputeTangentialDist;
        end
        
        %------------------------------------------------------------------
        function setAllButtonsEnabled(this, state)
        % setAllButtonsEnabled Enable or disable all panel controls
        %   setAllButtonsEnabled(panel, state) enables or disables all
        %   controls of the panel. panel is a ToolStripPanel object. state
        %   is a logical scalar.
            this.RadialCoeffsButton1.Enabled = state;
            this.RadialCoeffsButton2.Enabled = state;
            this.CheckSkewButton.Enabled = state;
            this.CheckTangentialButton.Enabled = state;    
        end        
        
        %------------------------------------------------------------------
        function enableNumRadialCoefficients(this)
            this.RadialCoeffsButton1.Enabled = true;
            this.RadialCoeffsButton2.Enabled = true;            
            this.setToolTipText(this.RadialCoeffsButton1,...
                'vision:caltool:TwoRadialCoeffsToolTip');            
            this.setToolTipText(this.RadialCoeffsButton2,...
                'vision:caltool:ThreeRadialCoeffsToolTip');            
        end
        
        %------------------------------------------------------------------
        function disableNumRadialCoefficients(this, numCoeffs)
            this.RadialCoeffsButton1.Enabled = true;
            this.RadialCoeffsButton2.Enabled = true;
            
            if numCoeffs == 2
                this.RadialCoeffsButton1.Selected = true;
            else
                this.RadialCoeffsButton2.Selected = true;
            end
            
            this.RadialCoeffsButton1.Enabled = false;
            this.RadialCoeffsButton2.Enabled = false;
            
            this.setToolTipText(this.RadialCoeffsButton1,...
                'vision:caltool:RadialCoeffsDisabledToolTip');
            this.setToolTipText(this.RadialCoeffsButton2,...
                'vision:caltool:RadialCoeffsDisabledToolTip');            
        end
    end
    
    methods(Access = protected)
        %------------------------------------------------------------------
        function createPanel(this)
            this.Panel = toolpack.component.TSPanel('f:p, 5dlu, p:g','p:g,f:p,p:g');
        end
        
        %------------------------------------------------------------------
        function addRadialDistortionButtons(this)
            groupLabel = ...
                this.createLabel('vision:caltool:RadialButtonGroupHeading');
            
            this.create2RadialCoeffsButton();
            this.create3RadialCoeffsButton();
                        
            this.RadialCoefficientsButtonGroup = toolpack.component.ButtonGroup;
            this.RadialCoefficientsButtonGroup.add(this.RadialCoeffsButton1);
            this.RadialCoefficientsButtonGroup.add(this.RadialCoeffsButton2);
            
            add(this.Panel, groupLabel,'xy(1,1)');
            add(this.Panel, this.RadialCoeffsButton1,'xy(1,2)');
            add(this.Panel,this.RadialCoeffsButton2,'xy(1,3)');
        end
        
        %------------------------------------------------------------------
        function create2RadialCoeffsButton(this)
            titleId = 'vision:caltool:RadialCoeffsButton1';
            toolTipId = 'vision:caltool:TwoRadialCoeffsToolTip';
            this.RadialCoeffsButton1 = this.createRadioButton(titleId, ...
                'btnTwoCoeffs', toolTipId);
        end
        
        %------------------------------------------------------------------
        function create3RadialCoeffsButton(this)
            titleId = 'vision:caltool:RadialCoeffsButton2';
            toolTipId = 'vision:caltool:ThreeRadialCoeffsToolTip';
            this.RadialCoeffsButton2 = this.createRadioButton(titleId,...
                'btnThreeCoeffs', toolTipId);
        end
        
        %------------------------------------------------------------------
        function addComputeButtons(this)
            computeGroupLabel = this.createLabel(...
                'vision:caltool:ComputeButtonGroupHeading');
            
            this.createSkewButton();
            this.createTangentialButton();

            add(this.Panel,computeGroupLabel, 'xy(3,1)');
            add(this.Panel,this.CheckSkewButton,'xy(3,2)');
            add(this.Panel,this.CheckTangentialButton,'xy(3,3)');
        end
        
        %------------------------------------------------------------------
        function createSkewButton(this)
            titleId = 'vision:caltool:SkewButton';
            toolTipId = 'vision:caltool:CheckSkewToolTip';
            this.CheckSkewButton = this.createCheckBox(titleId, ...
                'btnCheckSkew', toolTipId);
        end
        
        %------------------------------------------------------------------
        function createTangentialButton(this)
            titleId = 'vision:caltool:TangentialButton';
            toolTipId = 'vision:caltool:CheckTangentialToolTip';
            this.CheckTangentialButton = this.createCheckBox(titleId, ...
                'btnCheckTangential', toolTipId);
        end
            
        %------------------------------------------------------------------
        function addCallback(this, fun)
            addButtonCallback(this.RadialCoeffsButton1, fun);
            addButtonCallback(this.RadialCoeffsButton2, fun);
            addButtonCallback(this.CheckSkewButton, fun);
            addButtonCallback(this.CheckTangentialButton, fun);
        end        
    end
end

%--------------------------------------------------------------------------
function addButtonCallback(button, fun)
    addlistener(button, 'ItemStateChanged', fun);
end