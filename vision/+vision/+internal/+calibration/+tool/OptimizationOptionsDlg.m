% Copyright 2014 The MathWorks, Inc.

classdef OptimizationOptionsDlg < vision.internal.uitools.OkCancelDlg
        
    properties
        OptimizationOptions;
    end
    
    properties(Access=private)
        IntrinsicsCheckBox;
        IntrinsicsTextField;
        DistortionCheckBox;
        DistortionTextField;
    end
    
    
    methods        
        %------------------------------------------------------------------
        function this = OptimizationOptionsDlg(groupName, optimizationOptions)
            dlgTitle = getString(message('vision:caltool:OptimOptionsDlgTitle'));            
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);
            
            if nargin < 2
                optimizationOptions = [];
            end
            
            this.OptimizationOptions = optimizationOptions;
            
            if isempty(this.OptimizationOptions)
                this.OptimizationOptions.InitialIntrinsics = [];
                this.OptimizationOptions.InitialDistortion = [];
            end
            
            this.DlgSize = [400, 240];
            createDialog(this);
            addIntrinsicsWidgets(this);
            addDistortionWidgets(this);
        end              
    end    
    
    methods(Access=private)
        %------------------------------------------------------------------
        function addIntrinsicsWidgets(this)
            usingInitialIntrinsics = ...
                ~isempty(this.OptimizationOptions) && ...
                ~isempty(this.OptimizationOptions.InitialIntrinsics);
            
            % Add the checkbox
            xLoc = 10;
            yLoc = 205;
            width = 375;
            location = [xLoc, yLoc, 20, 20];
            this.IntrinsicsCheckBox = this.addCheckBox(location, usingInitialIntrinsics);
            this.IntrinsicsCheckBox.Callback = @intrinsicsCheckboxCallback;
            this.IntrinsicsCheckBox.TooltipString = getString(message(...
                'vision:caltool:InitialIntrinsicsToolTip'));
            
            % Add the checkbox label
            location = [xLoc + 20, yLoc - 12, width, 32];
            prompt = this.addTextLabel(location, ...
                getString(message('vision:caltool:InitialIntrinsicsPrompt')));
            prompt.FontUnits = 'normalized';
            prompt.FontSize = 0.4;
            
            % Add the text field
            height = 60;
            location = [xLoc, yLoc - 22 - height, width,  height];
            this.IntrinsicsTextField = this.addTextField(location);
            this.IntrinsicsTextField.Min = 1;
            this.IntrinsicsTextField.Max = 3;
            this.IntrinsicsTextField.FontUnits = 'normalized';
            this.IntrinsicsTextField.FontSize = 0.2;
            if usingInitialIntrinsics
                this.IntrinsicsTextField.Enable = 'on';
                this.IntrinsicsTextField.String = ...
                    mat2str(this.OptimizationOptions.InitialIntrinsics);                
            else
                this.IntrinsicsTextField.Enable = 'off';
                this.IntrinsicsTextField.String = [];
            end

            
            %--------------------------------------------------------------
            function intrinsicsCheckboxCallback(h, ~)
                if get(h, 'Value')
                    this.IntrinsicsTextField.Enable = 'on';
                else
                    this.IntrinsicsTextField.Enable = 'off';
                end
            end
        end
        
        %------------------------------------------------------------------
        function addDistortionWidgets(this)
            usingInitialDistortion = ...
                ~isempty(this.OptimizationOptions) && ...
                ~isempty(this.OptimizationOptions.InitialDistortion);
            
            xLoc = 10;
            yLoc = 94;
            width = 375;
            location = [xLoc, yLoc, 20, 20];
            this.DistortionCheckBox = this.addCheckBox(location, usingInitialDistortion);
            this.DistortionCheckBox.Callback = @distortionCheckboxCallback;
            this.DistortionCheckBox.TooltipString = getString(message(...
                'vision:caltool:InitialDistortionToolTip'));
            
            % Add the checkbox label
            location = [xLoc + 20, yLoc - 12, width, 32];
            prompt = this.addTextLabel(location, ...
                getString(message('vision:caltool:InitialDistortionPrompt')));
            prompt.FontUnits = 'normalized';
            prompt.FontSize = 0.4;
            
            % Add the text field
            height = 20;
            location = [xLoc, yLoc - 20 - height, width, height];
            this.DistortionTextField = this.addTextField(location);
            this.DistortionTextField.FontUnits = 'normalized';
            this.DistortionTextField.FontSize = 0.6;
            if usingInitialDistortion
                this.DistortionTextField.Enable = 'on';
                this.DistortionTextField.String = ...
                    mat2str(this.OptimizationOptions.InitialDistortion);                
            else
                this.DistortionTextField.Enable = 'off';
                this.DistortionTextField.String = [];
            end
                        
            %---------------------------------------------------------------
            function distortionCheckboxCallback(h, ~)
                if get(h, 'Value')
                    this.DistortionTextField.Enable = 'on';
                else
                    this.DistortionTextField.Enable = 'off';
                end
            end            
        end   
        
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            K = str2num(get(this.IntrinsicsTextField, 'String')); %#ok<ST2NM>
            isBadIntrinsics = this.IntrinsicsCheckBox.Value && ...
                ~(ismatrix(K) && isequal(size(K), [3 3]));
            
            distCoeffs = str2num(this.DistortionTextField.String); %#ok<ST2NM>
            numCoeffs = numel(distCoeffs);
            isBadDistCoeffs = this.DistortionCheckBox.Value && ...
                ~(isvector(distCoeffs) && isnumeric(distCoeffs) && ...
                (numCoeffs == 2 || numCoeffs == 3));
            
            if isBadIntrinsics
                errordlg(getString(message('vision:caltool:InvalidInitialIntrinsics')));
                return;
            elseif isBadDistCoeffs
                errordlg(getString(message('vision:caltool:InvalidInitialDistortion')));
                return
            else
                this.IsCanceled = false;
                if this.IntrinsicsCheckBox.Value
                    this.OptimizationOptions.InitialIntrinsics = K;
                else
                    this.OptimizationOptions.InitialIntrinsics = [];
                end
                
                if this.DistortionCheckBox.Value                    
                    this.OptimizationOptions.InitialDistortion = distCoeffs;
                else
                    this.OptimizationOptions.InitialDistortion = [];
                end
                close(this);
            end
        end
    end
end