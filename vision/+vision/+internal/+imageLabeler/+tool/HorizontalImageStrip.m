% Class defines a horizontal thumbnail strip.

% Copyright 2017 The MathWorks, Inc.
classdef  HorizontalImageStrip < iptui.internal.imageBrowser.Thumbnails
    
    properties (SetAccess = protected)
        NumberOfThumbnails = 0;
        ImageFilename = {};
        maxTextChars   = 15;
    end
    
    events
        ImageRemovedInBrowser
        ImageRotateInBrowser
    end
    
    methods
        function this = HorizontalImageStrip(hParent)
            
            thumbNailSize = [72 72];
            this@iptui.internal.imageBrowser.Thumbnails(hParent, thumbNailSize);
            
            this.Layout = 'row';  % other valid values are 'col', 'auto'
            
            this.EnableMultiSelect = true;
                        
            this.BlockSize = [96 96];                      
            
            % Start with zero. Clients call appendImage();
            this.ImageFilename = {};
            this.NumberOfThumbnails = 0;
            
            this.refreshThumbnails();
            
            % set to match color of parent when there is nothing in
            % browser.
            this.hAxes.Color = [0.94 0.94 0.94];
            
            % Disable zoom and pan for thumbnail strip
            fig = ancestor(hParent, 'Figure');
            zoomObj = zoom(fig);
            setAllowAxesZoom(zoomObj, this.hAxes, false);
            panObj = pan(fig);
            setAllowAxesPan(panObj, this.hAxes, false);
        end
        
        %------------------------------------------------------------------
        function loadImages(this, imageFilenames)
            % load a set of images.
            
            % Color should be white when there are images in browser.
            this.hAxes.Color = [1 1 1];
            
            this.ImageFilename = imageFilenames;
            this.NumberOfThumbnails = numel(this.ImageFilename);
            this.refreshThumbnails();
        end
        
        %------------------------------------------------------------------
        function appendImage(this, imageData)
            % filename can be a char array or a cellstr. Append it to the
            % list of image file names.
            
            % Color should be white when there are images in browser.
            this.hAxes.Color = [1 1 1];
            
            this.ImageFilename = cat(1,this.ImageFilename, imageData.Filenames);
            this.NumberOfThumbnails = numel(this.ImageFilename);
            this.appendSpaceForNImages(numel(imageData.Filenames));
            
            % Update layout to account for new images
            this.updateGridLayout();
        end
        
        %------------------------------------------------------------------
        function selectImageByIndex(this, idx)
            this.setSelection(idx);
        end
        
        %------------------------------------------------------------------
        function name = imageFilenameByIndex(this, idx)
            assert(idx > 0 && idx <= numel(this.ImageFilename));
            name = this.ImageFilename{idx};
        end
        
        %------------------------------------------------------------------
        function n = numberOfVisibleImages(this)
            n = numel(this.ImageFilename);
        end
        
        %------------------------------------------------------------------
        function filterSelectedImages(this)
            
            currentSelection = this.CurrentSelection;
            
            % Sort the selection
            currentSelection = sort(currentSelection);
            filter(this, currentSelection);
        end
        
        %------------------------------------------------------------------
        function restoreAllImages(this)
            
            numImages = length(this.ImageFilename);
            filter(this, 1:numImages);
        end
    end
    
    % Implementations of required abstract methods
    methods        
        function updateBlockWithPlaceholder(this, topLeftyx, imageNum)
            % Gets called whenever imageNum is visible
            if ~(this.ImageNumToDataInd(imageNum))
                % Create placeholder image
                userdata = [];
                userdata.isPlaceholder = true;
                thumbnail = this.PlaceHolderImage;
                
                hImage = image(...
                    'Parent', this.hAxes,...
                    'Tag','Placeholder',...
                    'HitTest','off',...
                    'CDataMapping', 'scaled',...
                    'UserData', userdata,...
                    'Cdata', thumbnail);
                this.hImageData(end+1).hImage  = hImage;
                this.ImageNumToDataInd(imageNum) = numel(this.hImageData);
                
            end
            this.repositionElements(imageNum, topLeftyx);
        end
        
        function updateBlockWithActual(this, topLeftyx, imageNum)
            
            hImageInd = this.ImageNumToDataInd(imageNum);
            % Already created (could be a placeholder image)
            hImage = this.hImageData(hImageInd).hImage;
            
            if ~strcmp(hImage.Tag,'Realthumbnail')
                % Create
                [thumbnail, userdata] = this.createThumbnail(imageNum);
                % Scale display range if required
                if(~isa(thumbnail,'uint8'))
                    minPix = min(thumbnail(:));
                    thumbnail = thumbnail - minPix;
                    maxPix = max(thumbnail(:));
                    thumbnail = uint8(double(thumbnail)/double(maxPix) *255);
                end
                
                % Update existing placeholder with real image
                hImage.CData = thumbnail;
                hImage.Tag   = 'Realthumbnail';
                userdata.isPlaceholder = false;
                hImage.UserData =  userdata;
            end
            
            this.repositionElements(imageNum, topLeftyx);
        end
        
    end
    
    methods % Helpers
        
        function [thumbnail, userdata] = createThumbnail(this, imageNum)
            try
                fullImage = imread(this.ImageFilename{imageNum});
            catch ALL %#ok<NASGU>
                fullImage = this.CorruptedImagePlaceHolder;
            end
            
            % Create thumbnail
            if ndims(fullImage)>3 || ( size(fullImage,3)~=1 &&size(fullImage,3)~=3)
                % pick first plane
                fullImage = fullImage(:,:,1);
            end
            thumbnail = this.resizeToThumbnail(fullImage);
            
            % Additional meta data (will be embedded into userdata of
            % himage)
            userdata = [];
        end
        
        function repositionElements(this, imageNum, topLeftyx)
            hDataInd = this.ImageNumToDataInd(imageNum);
            hImage = this.hImageData(hDataInd).hImage;
            
            % For a single block, thumbnail is positioned inside block.
            % Text is position on the left-bottom of the thumbnail.
            %
            % topLeftxy
            %  0--------------------------------|
            %  |        BlockSize(1)            
            %  |   
            %  |      0--------------------|
            %  |      |       Thumbnail    |
            %  |      |--------------------|
            %  |       
            %  |
            %  ---------------------------------
            %
            
            % Center image within the block.  
            hImage.YData = topLeftyx(1) + (this.BlockSize(1)-size(hImage.CData,1))/2 ;
            hImage.XData = topLeftyx(2) +(this.BlockSize(2)-size(hImage.CData,2))/2;
            
            hImage.Visible = 'on';

        end
        
        function desc = getFileName(this, imageNum)
            desc = this.ImageFilename{imageNum};
        end
                
        function removeSelectedImages(this)
            displayMessage = vision.getMessage('vision:imageLabeler:RemoveImageWarning');
            dialogName = vision.getMessage('vision:imageLabeler:RemoveImage');
            
            yesOption  = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
            noOption  = vision.getMessage('MATLAB:uistring:popupdialogs:No');

            selection = questdlg(displayMessage, dialogName, yesOption, noOption, yesOption);
            
            if strcmpi(selection, yesOption)
                selectedImageIndices = this.CurrentSelection;

                % Remove from browser view and cache
                this.removeImages(selectedImageIndices);  

                this.ImageFilename(selectedImageIndices) = [];
                this.NumberOfThumbnails = numel(this.ImageFilename);            

                data = vision.internal.labeler.tool.ItemSelectedEvent(...
                    selectedImageIndices);            
                notify(this, 'ImageRemovedInBrowser', data);

                if isvalid(this) % Component is destroyed by the app if count==0                
                    newSelection = min(max(selectedImageIndices), this.NumberOfThumbnails);
                    if newSelection ~=0
                        % If any images are left
                        this.setSelection(newSelection);
                        
                        % Update layout to account for the 'holes' left by removed
                        % images.
                        this.updateGridLayout();                          
                    end
                end
            end
        end
        
        function rotateSelectedImages(this, rotationType)
            selectedImageIndices = this.CurrentSelection;
            data = vision.internal.labeler.tool.ImageRotateEvent(...
                selectedImageIndices, rotationType); 
            notify(this, 'ImageRotateInBrowser', data);
            this.recreateThumbnails(selectedImageIndices);
        end
    end
end