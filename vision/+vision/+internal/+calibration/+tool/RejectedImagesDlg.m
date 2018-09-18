% RejectedImagesDlg Dialog for displaying rejected calibration images.

% Copyright 2014 The MathWorks, Inc.

classdef RejectedImagesDlg < vision.internal.uitools.OkDlg     
    properties(Access=private)
        RejectedFileNames = {};
    end
    
    methods
        function this = RejectedImagesDlg(groupName, fileNames)
            dlgTitle =  vision.getMessage('vision:caltool:RejectedImagesDialogTitle');
            this = this@vision.internal.uitools.OkDlg(groupName, dlgTitle);
            
            this.RejectedFileNames = fileNames;
            this.DlgSize = [800, 600];
            createDialog(this);
            addImageDisplay(this);
        end
    end
    
    methods(Access=private)
        function addImageDisplay(this)
            % turn off the warning that mentions resizing
            s = warning('query','images:initSize:adjustingMag');
            warning('off','images:initSize:adjustingMag');
            
            ax = axes('parent', this.Dlg);
            showRejectedImages(this, ax);
            
            % restore the warning state
            warning(s.state,'images:initSize:adjustingMag');
        end
        
        %------------------------------------------------------------------
        function showRejectedImages(this, ax)
            if size(this.RejectedFileNames, 1) == 1
                montage(this.RejectedFileNames, 'Parent', ax);
            else
                numPairs = size(this.RejectedFileNames, 2);
                I1 = imread(this.RejectedFileNames{1, 1});
                I2 = imread(this.RejectedFileNames{2, 1});
                
                composite = imfuse(I1, I2, 'montage');
                sizeOfImages = [size(composite, 1), size(composite, 2), ...
                    size(composite, 3), numPairs];
                images = zeros(sizeOfImages,  'like', composite);
                images(:,:,:,1) = composite;
                
                for i = 2:numPairs
                    I1 = imread(this.RejectedFileNames{1, i});
                    I2 = imread(this.RejectedFileNames{2, i});
                    composite = imfuse(I1, I2, 'montage');
                    images(:,:,:,i) = composite;
                end
                
                montage(images, 'Parent', ax);
            end
        end
    end        
end
