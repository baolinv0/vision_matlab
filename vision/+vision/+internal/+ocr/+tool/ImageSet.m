% This class is for internal use only and may change in the future.

% ImageSet Stores images and associated label data for ocr training
% session.

% Copyright 2015 The MathWorks, Inc.

classdef ImageSet < handle
    
    properties
        % ImageStruct 
        %   Contains following fields:
        %     1. imageFilename
        %     2. objectBoundingBoxes
        %     3. text
        %     4. ImageIcon
        %     5. ImageLabel        
        ImageStruct                       
        
        % AreThumbnailsGenerated 
        %   Logical array that stores whether or not an icon has been
        %   generated for each image in the ImageStruct.        
        AreThumbnailsGenerated         
        AreCharThumbnailsGenerated
        
        % SelectedBoxes 
        %   List of selected boxes per character montage.
        SelectedBoxes
        
        % Selection Map - maps selection to image index and box index. This
        % in only updated when new char montage is drawn so we can remember
        % what's going in current setting.
        SelectionMap
        
        % CharMap
        %   Map relating character label to images and boxes where found.
        CharMap
        CharView = true;
        CharIcons;
        DelayRemoval = {};
        DelayRemovalSelectedBoxes = [];
        
        % RemoveMode Determines whether or not remove callback should move
        % to unknown or delete. First version of app supports move. This is
        % left here to easily add remove later.
        RemoveMode = 'move';
        
        %Font - Choose a font that supports unicode across multiple
        %       platforms. Used for char browser display.
        Font
         
        % TextDetectionParams - Text detetion parameter struct array.
        % Contains ROI, min/max aspect ratio, and area threshold
        % parameters.
        TextDetectionParams
    end
    
    %----------------------------------------------------------------------
    properties(Dependent)
        % Count - Number of images loaded in training session.
        Count
    end
    
    %----------------------------------------------------------------------
    properties(Access=private, Hidden)        
        Version = ver('vision');        
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor
        %----------------------------------------------------------------        
        function this = ImageSet()            
            this.ImageStruct = [];           
            this.AreThumbnailsGenerated = [];            
            this.AreCharThumbnailsGenerated = []; 
            this.SelectedBoxes = [];
            this.CharMap = containers.Map;
            this.TextDetectionParams = [];
        end
                
        %------------------------------------------------------------------
        % Returns true if the session already has images else returns false
        %------------------------------------------------------------------        
        function ret = hasAnyImages(this)                        
            ret = ~isempty(this.ImageStruct);                        
        end
        
        %------------------------------------------------------------------
        % Returns true if the session characters
        %------------------------------------------------------------------        
        function ret = hasAnyCharacters(this)                       
             ret = ~isempty(this.CharMap);                               
        end
        
        %------------------------------------------------------------------
        function val = get.Count(this)
            val = numel(this.ImageStruct);
        end
        
        %------------------------------------------------------------------
        function imagesWithoutText = boxAndLabelImages(this, start, ocrOptions, autoLabel)
            if this.hasAnyImages                                
                
                progressBar = vision.internal.uitools.ImageSetProgressBar(...
                    this.Count-start+1, ...
                    'vision:ocrTrainer:ExtractSamplesTitle',...
                    'vision:ocrTrainer:ExtractSamplesMsg');
                
                k = 1;
                for i = start:this.Count      
                    update(progressBar);
                    
                    % image may disappear off disk. treat this as a
                    % non-text detection event. an error dialog is issued
                    % earlier.
                    try
                    this.ImageStruct(i).objectBoundingBoxes = detectTextInImage(this, i);                    
                    catch
                        imageHasText(k) = false;
                        k = k + 1;
                        continue
                    end
                    
                    if autoLabel % manual vs. auto label
                        imageHasText(k) = this.autoLabelImage(i, ocrOptions);
                    else
                        nboxes = size(this.getBoxes(i),1);
                        if nboxes > 1
                            imageHasText(k) = true;         
                    else
                            imageHasText(k) = false;
                        end
                        this.ImageStruct(i).text = repmat({char(0)},nboxes,1);                                                                                                               
                    end
                    
                    k = k + 1;
                end   
                
                % remove images without text                
                noText = false(1,this.Count);
                noText(start:end) = ~imageHasText;
                
                % return images that were removed
                imagesWithoutText = {this.ImageStruct(noText).imageFilename};
                
                this.removeImage(noText);                               
                
                % add image text data to char map
                for i = start:this.Count
                    addToCharMap(this, i);                                        
                end                
                               
                this.initialize();
                
                delete(progressBar);
            end
        end
        
        %------------------------------------------------------------------
        % Initialize SelectedBoxes, char icons, and AreCharThumbnailsGenerated
        %------------------------------------------------------------------
        function initialize(this)
            % initialize selected boxes
            this.SelectedBoxes = cell(1, length(this.CharMap));
            k = this.CharMap.keys;
            for i = 1:length(k)
                n = this.getNumCharSamples(k{i});
                d = sparse(false(1,n));
                d(1) = true; % first box selected
                this.SelectedBoxes{i} = d;
            end
            
            % initialize char icons to placeholders
            this.CharIcons = this.generateCharPlaceHolders(length(this.CharMap));
            
            this.AreCharThumbnailsGenerated = false(1,length(this.CharMap));
        end
        
        %------------------------------------------------------------------
        function addToCharMap(this, whichImage)  
            
            % get indices of the non-deleted text (marked as -1);
            idx = getValidIndices(this, whichImage);
            
            % get indices to actual position in the bbox array.
            values = find(idx); 
            
            labels = this.ImageStruct(whichImage).text(idx);
            
            map = containers.Map;
            
            for idx = 1:numel(labels)
                
                key = labels{idx};                                                                    
                if isKey(map, key)   
                    map(key) = [map(key) values(idx)];                    
                else
                    map(key) = values(idx);
                end
                
            end
          
            keys = map.keys;
            for i = 1:numel(keys) 
                key = keys{i};                                                             
                              
                s.imageIndex = whichImage;
                s.bboxIndex  = map(key);
                            
                if isKey(this.CharMap, key)                    
                    this.CharMap(key) = [this.CharMap(key) s];
                else                    
                    this.CharMap(key) = s;
                end
            end               
            
        end
        
        
        %------------------------------------------------------------------
        function resetSelectionMap(this, label)
            % This is reset everytime a new character montage is drawn. It
            % maps the selected boxes back to the image
            value = this.CharMap(label);
            
            this.SelectionMap = {};
            for i = 1:numel(value);
                b = value(i).bboxIndex(:);
                a = repelem(value(i).imageIndex, numel(b), 1);
                oldLabel = repmat({label}, numel(b), 1);
                newLabel = cell(numel(b), 1); 
                data = [num2cell([a b]) oldLabel newLabel];
                this.SelectionMap = [this.SelectionMap; data];
            end  
                        
        end
       
        %------------------------------------------------------------------
        function imageHasText = autoLabel(this, start, ocrOptions)
        
            if this.hasAnyImages                                
                imageHasText = false(1,this.Count-start+1);
                
                progressBar = vision.internal.uitools.ImageSetProgressBar(...
                    this.Count, ...
                    'vision:ocrTrainer:ExtractSamplesTitle',...
                    'vision:ocrTrainer:ExtractSamplesMsg');
                
                for i = start:this.Count
                    update(progressBar);
                    imageHasText(i) = this.autoLabelImage(i, ocrOptions);
                end                                               
                
            end                        
        end
        
        %------------------------------------------------------------------       
        function detectText(this, start)
            
            if this.hasAnyImages                                
                
                for i = start:this.Count                    
                    this.ImageStruct(i).objectBoundingBoxes = detectTextInImage(this, i);                    
                end
                
            end
        end
        
        %------------------------------------------------------------------       
        % Initialize selected boxes to be the first one. 
        %------------------------------------------------------------------
        function initializeSelectedBoxes(this, start)
            if this.hasAnyImages                                
                
                for i = start:this.Count    
                    hasBoxes = ~isempty(this.ImageStruct(i).objectBoundingBoxes);
                    if hasBoxes                         
                        this.SelectedBoxes{i} = 1;
                    else
                        this.SelectedBoxes{i} = [];
                    end
                end
                
            end
        end
        
        %------------------------------------------------------------------
        function [bboxes, out] = findText(this, I, params)
            
            roi = params.ROI;
            
            doCrop = ~isempty(roi);
            
            [m, n, ~] = size(I);
            
            if doCrop % convert to pixel coords
                roi(:, 1:2) = roi(:,1:2) + 0.5;
                
                % clip to within image in case 
                roi(:, 1:2) = max(roi(:,1:2),1);                
                roi(:, 3)   = min(roi(:,3), n);
                roi(:, 4)   = min(roi(:,4), m);
            end
            
            I = vision.internal.detector.cropImageIfRequested(I, roi, doCrop);
            
            bw = binarizeImage(this, I);                     

            if nargout == 2
                returnMask = true;
                stats = {'BoundingBox', 'PixelIdxList'};
            else
                returnMask = false;
                stats = {'BoundingBox'};
            end
            
            cc = bwconncomp(bw);
            stats = regionprops(cc, stats{:});
            bboxes = vertcat(stats(:).BoundingBox);
            
            if isempty(bboxes)
                bboxes = zeros(0,4);
                out = false(m,n);                
                return
            end
                       
            bboxes(:,1:2) = bboxes(:,1:2) + 0.5; % to pixel coords
           
            [M, N] = size(bw);
            
            % Remove bounding boxes that contain the entire image as these don't make sense.                  
            toRemove = all(bsxfun(@eq, round(bboxes(:,[4 3])), [M N]),2);            
            
            % Remove extremely small boxes            
            area = prod(bboxes(:,[3 4]), 2);
            toRemove = toRemove | area < params.MinArea;                       
            
            % Remove boxes with extreme aspect ratios
            aspectRatio = bboxes(:,3)./bboxes(:,4);
            toRemove = toRemove | ...
                aspectRatio > params.MaxAspectRatio | ...
                aspectRatio < params.MinAspectRatio;                       
            
            % merge overlapping bounding boxes            
            overlap = bboxOverlapRatio(bboxes,bboxes, 'min');
            
            % remove boxes that overlap more than 5 other boxes
            overlap(toRemove,:) = 0; % do not count those boxes that are to be removed.
            numChildren = sum(overlap > 0) - 1; % -1 for self
            
            toRemove = toRemove | numChildren' > 5;
           
            bboxes(toRemove, :) = [];
            
            overlap = bboxOverlapRatio(bboxes,bboxes, 'min');
                        
            g = graph(overlap > 0.5,'OmitSelfLoops');
            
            componentIndices = conncomp(g);
            
            xmin = bboxes(:,1);
            ymin = bboxes(:,2);
            xmax = xmin + bboxes(:,3) - 1;
            ymax = ymin + bboxes(:,4) - 1;
            
            % Merge the boxes based on the minimum and maximum dimensions.
            xmin = accumarray(componentIndices', xmin, [], @min);
            ymin = accumarray(componentIndices', ymin, [], @min);
            xmax = accumarray(componentIndices', xmax, [], @max);
            ymax = accumarray(componentIndices', ymax, [], @max);
            
            bboxes = [xmin ymin xmax-xmin+1 ymax-ymin+1];
            
            bboxes = vision.internal.detector.addOffsetForROI(bboxes, roi, doCrop);
            
            bboxes(:,1:2) = bboxes(:,1:2) - 0.5; % back to spatial coords
            
            if returnMask
                allpx = vertcat(stats(~toRemove).PixelIdxList);
                out = false(size(bw));
                out(allpx) = bw(allpx);
                
                if doCrop
                    r = roi(2):(roi(2) + roi(4) - 1);
                    c = roi(1):(roi(1) + roi(3) - 1);
                    
                    bw = false(m,n);
                    bw(r,c) = out;
                    out = bw;
                end
            end
        end
        
        %------------------------------------------------------------------
        % Return bounding boxes around potential text blobs in the image.
        %------------------------------------------------------------------
        function [bboxes, varargout] = detectTextInImage(this, idx)
       
            I = getImages(this, idx);
                  
            params = this.TextDetectionParams(idx);
            
            [bboxes, varargout{1:nargout-1}] = this.findText(I, params);
                                      
                end
        
        %------------------------------------------------------------------
        function I = binarizeImage(~, I)           
            
            if ~ismatrix(I) 
                I = rgb2gray(I);
            end

            if ~islogical(I)
                I = imbinarize(I);
            end
            
            % determine text polarity; dark on light vs. light on dark. For
            % text blob detection we want light on dark.
            c = imhist(I);
            [~,bin] = max(c);
            
            if bin == 2 % light background
                % complement image to switch polarity 
                I = imcomplement(I);
            end
        end
        
        %------------------------------------------------------------------
        function foundText = autoLabelImage(this, idx, ocrOptions)
            
            try
            I = getImages(this, idx);
            catch                
                foundText = false;
                return;
            end
            
            hasBoxes = ~isempty(this.ImageStruct(idx).objectBoundingBoxes);
            
            if hasBoxes
                foundText = true;
                
                % run ocr on boxes
                bboxes = this.getBoxes(idx);
                try
                    
                    results = ocr(I, bboxes, ...
                        'TextLayout', 'Character', ...
                        'Language', ocrOptions.Language, ...
                        'CharacterSet', ocrOptions.CharacterSet);
                catch
                    % OCR issued an error for unknown reasons. Return that
                    % no text was found so that the image is not included
                    % in the session.
                    foundText = false;
                    return
                end
                
                text = {results(:).Text};
                
            else
                foundText = false;
            end
                
            if foundText
            % remove training whitespace and newlines
            text = deblank(text);
            
                % change unlabeled boxes to unknown
            unlabeled = cellfun(@(x)isempty(x),text);
            text(unlabeled) = {char(0)};
            
            this.setText(idx, text);
            end
        end
        
        %------------------------------------------------------------------
        function setText(this, whichImage, text)
            this.ImageStruct(whichImage).text = text;            
        end
        
        %------------------------------------------------------------------
        function addTextROI(this, params, startingIndex)        
            % params has ROI, MinArea, MinAspectRatio, and MaxAspectRatio
            this.TextDetectionParams(startingIndex:this.Count) = params;            
        end        
        
        %------------------------------------------------------------------
        function setBoxes(this, whichImage, boxes)
            this.ImageStruct(whichImage).objectBoundingBoxes = boxes;            
        end
                
        %------------------------------------------------------------------
        % Creates and populates a struct file ImageStruct
        %------------------------------------------------------------------
        % edit: create new struct and then append        
        function [startingIndex, imageFileNames] = addImagesToSession(this, imageFileNames)

            imageFileNames = reshape(imageFileNames,1,[]); % row vector
            
            startingIndex = []; % initialize the index
            
            % Function that eliminates files that are not images
            imageFileNames = this.eliminateNonImages(imageFileNames);
            
            % If there are no images
            if isempty(imageFileNames)
                return;
            end
            
            % look for duplicates and if found, silently remove them
            if this.hasAnyImages() 
                imageFileNames = this.getUniqueFiles(imageFileNames);
                if isempty(imageFileNames)
                    return; % nothing to add
                end                
            end            
            
            labels = generateImageLabels(imageFileNames);
            placeholders = this.generatePlaceHolders(imageFileNames);
            icons = placeholders;
            areThumbnailsGenerated = zeros(1, numel(imageFileNames));
                   
            n = numel(imageFileNames);
            newImageStruct = struct('imageFilename', imageFileNames, ...
                'objectBoundingBoxes', cell(1, n), ...
                'text',                cell(1, n), ...
                'ImageIcon', icons, 'ImageLabel', labels, ...
                'ImagePlaceHolder', placeholders);
            
            % setup default text detection parameters                       
            txtParams = repelem(getDefaultTextDetectionParams(this),1,n);
            
            % by default the first box is selected. 
            selectedBoxesToAdd = num2cell(ones(1,numel(imageFileNames)));                        
            
            if this.hasAnyImages()                
                this.AreThumbnailsGenerated = [this.AreThumbnailsGenerated, ...
                    areThumbnailsGenerated];
                startingIndex = numel(this.ImageStruct)+1;
                this.ImageStruct = [this.ImageStruct newImageStruct];
                this.SelectedBoxes = [this.SelectedBoxes selectedBoxesToAdd];
                this.TextDetectionParams = [this.TextDetectionParams txtParams];
            else
                this.ImageStruct = newImageStruct;
                this.AreThumbnailsGenerated = areThumbnailsGenerated;
                this.SelectedBoxes = selectedBoxesToAdd;
                this.TextDetectionParams = txtParams;
                startingIndex = 1;
            end 
   
        end
        
        %------------------------------------------------------------------
        function defaults = getDefaultTextDetectionParams(~)
            defaults.ROI = [];
            defaults.MinArea = 50;
            defaults.MinAspectRatio = 1/16;
            defaults.MaxAspectRatio = 4;
        end
        
        %------------------------------------------------------------------
        function setTextDetectionParams(this, params, idx)
            % ROI is not updated here. 
            if nargin == 2
                % set all
                for idx = 1:numel(this.TextDetectionParams)
                    this.TextDetectionParams(idx).MinArea = params.MinArea;
                    this.TextDetectionParams(idx).MinAspectRatio = params.MinAspectRatio;
                    this.TextDetectionParams(idx).MaxAspectRatio = params.MaxAspectRatio;
                end
            else
                this.TextDetectionParams(idx).MinArea = params.MinArea;
                this.TextDetectionParams(idx).MinAspectRatio = params.MinAspectRatio;
                this.TextDetectionParams(idx).MaxAspectRatio = params.MaxAspectRatio;
            end
        end
        
        %------------------------------------------------------------------
        % inputs:
        % newImageStruct            - ImageStruct from the newly opened session;
        % newAreThumbnailsGenerated - Logical array to indicate if thumbnails
        %                             are generated;
        %------------------------------------------------------------------        
        function addedImages = addImageStructToCurrentSession(this,newImageSet)
             
            newImageStruct = newImageSet.ImageStruct;
            newAreThumbnailsGenerated = newImageSet.AreThumbnailsGenerated;          
            
            if isempty(newImageStruct)
                addedImages = false;
                return;
            end
            
            % Look for duplicate images in the added session
            imageFilenames = this.getUniqueFiles({newImageStruct.imageFilename});
            if isempty(imageFilenames)
                addedImages = false;
                return;
            end
            addedImages = true;
            [~, indices] = intersect({newImageStruct.imageFilename}, imageFilenames);
            
            start = numel(this.ImageStruct) + 1;            
            
            this.ImageStruct = [this.ImageStruct newImageStruct(indices)];
                        
            this.TextDetectionParams = [this.TextDetectionParams ...
                newImageSet.TextDetectionParams(indices)];
            
            stop = numel(this.ImageStruct);                     
            
            this.AreThumbnailsGenerated = [this.AreThumbnailsGenerated,...
                newAreThumbnailsGenerated(indices)];
            
            % merge char maps. Cannot use vertcat between the current and
            % new session because some images might be duplicates.
            for whichImage = start:stop                
                this.addToCharMap(whichImage);                
            
            end 

            % Initialize everything. Ensures internal states are setup.
            this.initialize(); 
                 
        end
        
        %-----------------------------------------------------------------
        function [imageMatrix, imageLabel] = getImages(this, selectedIndex)
                        
            % If multiple files are selected grab just the first one
            selectedIndex = selectedIndex(1);
            imageMatrix = imread(this.ImageStruct(selectedIndex).imageFilename);
            imageLabel = this.ImageStruct(selectedIndex).imageFilename;
            
        end
        
        %------------------------------------------------------------------
        function name = getImageFilename(this, selectedIndex)
                                   
            name = this.ImageStruct(selectedIndex).imageFilename;
        
        end
        %--------------------------------------------------------------
        function imageIndices = getImagesContainingCharacter(this, character)
            s = this.CharMap(character);
            imageIndices = [s(:).imageIndex];            
        end
        
        %--------------------------------------------------------------
        function [imageIndex, charIndex] = getImageIndex(this, whichBox)           
            imageIndex = this.SelectionMap{whichBox, 1};                        
            charIndex  = this.SelectionMap{whichBox, 2};
        end
        
        %------------------------------------------------------------------
        % Crop out patches that correspond to the input label.
        %------------------------------------------------------------------
        function [patches] = getPatches(this, label)
            
            v = this.CharMap(label);                                    
            
            numImages = numel(v);
            
            patches = {};
            for i = 1:numImages
                
                idx     = v(i).imageIndex;               
                bboxIdx = v(i).bboxIndex;
                
                bboxes = getBoxes(this, idx);
                
                 % convert boxes to pixel coordinates for patch extraction.
                bboxes(:, 1:2) = bboxes(:,1:2) + 0.5;
                    
                    
                % image reading can fail if images no longer exist.
                try
                [~, I] = this.detectTextInImage(idx);
                catch                    
                    % failed to read image. issue error dialog and do not
                    % process this image.                                       
                    errordlg(...
                        vision.getMessage('vision:ocrTrainer:ImageReadError', ...
                        this.ImageStruct(idx).imageFilename),...
                        vision.getMessage('vision:ocrTrainer:ImageReadErrorTitle'), ...
                        'modal');
                    continue
                end
                
                [nrows,ncols] = size(I);
                
                for j = 1:numel(bboxIdx)
                    roi = bboxes(bboxIdx(j),:);
                                        
                    overlap = bboxOverlapRatio(roi, bboxes, 'min');
                    
                    % expanded box overlaps everything. Highly likely
                    % that this bbox spans entire image. Don't merge.
                    if all(overlap)
                        idx    = false(size(overlap));
                        idx(j) = true; 
                    else
                        idx = overlap > 0;
                    end
                    
                    xmin = bboxes(idx,1);
                    ymin = bboxes(idx,2);
                    xmax = xmin + bboxes(idx,3) - 1;
                    ymax = ymin + bboxes(idx,4) - 1;
                    
                    % Get box spanning all nearby chars
                    xmin = min(xmin);
                    ymin = min(ymin);
                    xmax = max(xmax);
                    ymax = max(ymax);
                    
                    box = [xmin ymin xmax-xmin+1 ymax-ymin+1];
                    
                    % make the current character centered box
                    cx = floor(xmin + (xmax - xmin + 1)/2);
                    cy = floor(ymin + (ymax - ymin + 1)/2);
                    
                    cxroi = roi(1) + floor(roi(3)/2);
                    cyroi = roi(2) + floor(roi(4)/2);
                    
                    offsetx = cxroi - cx;
                    offsety = cyroi - cy;
                    
                    box(1) = box(1) + offsetx;
                    box(2) = box(2) + offsety;
                    
                    % expand box around patch a bit to make it look nicer,
                    % then crop out patch.
                    box = vision.internal.detector.expandROI(size(I), box, 1);
                    
                    xmin = max(box(:,1), 1);
                    ymin = max(box(:,2), 1);
                    xmax = min(box(:,1) + box(:,3) - 1, size(I,2));
                    ymax = min(box(:,2) + box(:,4) - 1, size(I,1));
                    
                    box = [xmin ymin xmax-xmin+1 ymax-ymin+1];
                    
                    p = vision.internal.detector.cropImage(I, box);
                    
                    p = im2uint8(p);
                    
                    % Get the box in the cropped image coordinates
                    roi = vision.internal.detector.expandROI(size(I), roi, 1);
                    xx = roi(1) - box(1) + 1;
                    yy = roi(2) - box(2) + 1;
                    
                    c1 = max(xx,1);
                    c2 = min(xx + roi(3) - 1, ncols);
                    
                    r1 = max(yy,1);
                    r2 = min(yy + roi(4) - 1, nrows);
                    
                    % Apply blending to deemphasize surrounding chars
                    [mm,nn] = size(p);
                    
                    mask = true(size(p));
                                        
                    r1 = max(round(r1), 1);
                    r2 = min(round(r2), mm);
                    c1 = max(round(c1), 1);
                    c2 = min(round(c2), nn);
                    mask(r1:r2,c1:c2) = false;
                    
                    p = roifilt2(p,mask,@blend);
                    
                    % colorize background
                    p = repmat(p,1,1,3);
                    
                    patches = [patches p];
                end
            end
            
            %--------------------------------------------------------------
            % Blend function used with roifilt2
            %--------------------------------------------------------------
            function J = blend(I)
                opacity = 0.85;  % is a pleasing opacity value.
                J = 128 * ones(size(I),'like',I);
                J = (1-opacity)*I + opacity*J;
            end
        end
        
        %------------------------------------------------------------------
        function bboxes = getBoxes(this, selectedImageIndex)
            bboxes = this.ImageStruct(selectedImageIndex).objectBoundingBoxes;
        end
        
        %------------------------------------------------------------------
        function idx = getValidIndices(this, selectedImageIndex)
            idx = cellfun(@(x)ischar(x),this.ImageStruct(selectedImageIndex).text);
        end
        
        %------------------------------------------------------------------
        function idx = getUnknownIndices(this, selectedImageIndex)
            idx = cellfun(@(x)ischar(x) && strcmp(x,char(0)), ...
                this.ImageStruct(selectedImageIndex).text);
        end
        
        %------------------------------------------------------------------
        function bboxes = getValidBoxes(this, selectedImageIndex)
            bboxes = this.getBoxes(selectedImageIndex);
            
            isValid = this.getValidIndices(selectedImageIndex);
            
            isValid = isValid & ~this.getUnknownIndices(selectedImageIndex);
            
            bboxes = bboxes(isValid,:);
        end
        
        %------------------------------------------------------------------
        function text = getValidText(this, selectedImageIndex)
            text = this.getText(selectedImageIndex);  
            
            isValid = this.getValidIndices(selectedImageIndex);  
            
            isValid = isValid & ~this.getUnknownIndices(selectedImageIndex);
            
            text = text(isValid);
        end
        
        %------------------------------------------------------------------
        function numSelected = getNumSelectedBoxes(this, selectedImageIndex)
            
            selected = this.SelectedBoxes{selectedImageIndex};
                       
            numSelected = nnz(selected);
        end
        
        %--------------------------------------------------------------
        function selected = getSelectedBoxes(this, selectedImageIndex, ~)
            
            selected = this.SelectedBoxes{selectedImageIndex};
                       
            selected = find(selected);
                       
            selected = min(selected, this.getNumBoxes()); % can't select more than available
        end
        
        %------------------------------------------------------------------
        % Selects one box. Clears existing selection first. 
        %------------------------------------------------------------------
        function setSelectedBoxes(this, selectedChar, selectedBox)
            d = this.SelectedBoxes{selectedChar};           
            d(d) = false; % clear existing selection
            selectedBox = min(selectedBox, max(1,numel(d))); % can't select more than available
            d(selectedBox) = true;
            this.SelectedBoxes{selectedChar} = d;           
        end
        
        %------------------------------------------------------------------
        % Marks selectedBox as selected. Changes nothing else
        %------------------------------------------------------------------
        function selectBox(this, selectedChar, selectedBox)
            d = this.SelectedBoxes{selectedChar};
            selectedBox = min(selectedBox, numel(d));
            d(selectedBox) = true;
            this.SelectedBoxes{selectedChar} = d;
        end
        
        %------------------------------------------------------------------
        % Marks selectedBox as selected. Changes nothing else
        %------------------------------------------------------------------
        function unselectBox(this, selectedChar, selectedBox)
            d = this.SelectedBoxes{selectedChar};
            selectedBox = min(selectedBox, numel(d));
            d(selectedBox) = false;
            this.SelectedBoxes{selectedChar} = d;
        end
        
        %--------------------------------------------------------------
        function charLabel = getCharLabel(this, selectedImageIndex, selectedCharacterIdx)
            if isvector(selectedCharacterIdx)
                selectedCharacterIdx = selectedCharacterIdx(1); % just return first one in case of multiselect
            end
            
            charLabel = this.ImageStruct(selectedImageIndex).text{selectedCharacterIdx};                                                  
        end
        
        %------------------------------------------------------------------
        function txt = getText(this, whichImage)
            txt = this.ImageStruct(whichImage).text;
        end
        
        %------------------------------------------------------------------
        function c = getCharacterByIndex(this, idx)                      
            
            k = this.CharMap.keys();
            
            if isscalar(idx)
                c = k{idx};
            else
                c = k(idx);
            end
        end
        
        %------------------------------------------------------------------
        function charRemoved = removeDeffered(this, idx)
                
            charRemoved = false;
            
            if ~isempty(this.DelayRemovalSelectedBoxes)
                
                charRemoved = true;
                
                if idx >= 1
                    % check idx >= 1. makes sure char is still in browser.
                    % A right-click remove can remove the char from the
                    % list. If that happened, no need to do any deferred
                    % work.
                    
                    % do deferred update for SelectedBox
                    d = this.SelectedBoxes{idx};
                    rmidx = this.DelayRemovalSelectedBoxes;
                    
                    % find what's selected
                    selected = this.getSelectedBoxes(idx);
                    
                    % remove and update SelectedBoxes
                    d(rmidx) = [];
                    this.SelectedBoxes{idx} = d;
                    
                    % check if previously selected were removed. if so we need
                    % to mark something selected. Use original selected.
                    if numel(d) > 0 && any(ismember(selected,rmidx))
                        this.setSelectedBoxes(idx, selected(1));
                    end
                    
                end
                % reset deferred work
                this.DelayRemovalSelectedBoxes = [];
            end
            
            list = this.DelayRemoval;
            charRemoved = charRemoved || numel(list) > 0;
            for i = 1:numel(list)
                removeChar(this, list{i});
            end
            this.DelayRemoval = {};
            
        end
        
        %------------------------------------------------------------------
        % Remove single character from char map. The image and bbox of this
        % character are given by imageIndex and bboxIndex.
        %------------------------------------------------------------------
        function removeFromCharMap(this, old, imageIndex, bboxIndex, shouldDeferRemoval)                       
            
            if nargin == 4
                shouldDeferRemoval = false;
            end
            
            v = this.CharMap(old);
            
            % remove the bbox associated with modified char
            j = [v(:).imageIndex] == imageIndex;
            v(j).bboxIndex(v(j).bboxIndex == bboxIndex) = [];
            
            % If no more bboxes remain, then there are no more
            % samples of this char the image. Remove the image
            % from the char map.
            if isempty(v(j).bboxIndex)
                v(j) = [];
            end
            
            if numel(v) == 0
                if shouldDeferRemoval
                    this.deferRemoval(old, v);
                else
                % No samples left of old char in any of the images,
                % it can be removed completely.                             
                this.removeChar(old);                  
                end
            else
                % update char map with new info.
                this.CharMap(old) = v;
                this.updateIconDescription(old);
            end
            
        end
        
        %------------------------------------------------------------------
        function deferRemoval(this, old, v)
            % Defer removal of char in cases when the
            % current selected character losses all
            % samples. In this case we do not want the char
            % montage to be destroyed until the user has
            % switched to another one. Keep track of which
            % one should be removed and defer removal until
            % the char view is changed.
            if ~ismember(old, this.DelayRemoval)
                this.DelayRemoval{end+1} = old;
                
                % force icon description to 0 so char list
                % display is correct.
                this.updateIconDescription(old, 0);
                this.CharMap(old) = v;
            end
        end
        
        %------------------------------------------------------------------
        % Update char map when changing to new char view. This saves all
        % changes while labeling in the char view. SelectionMap and
        % SelectedBoxes are updated here.
        %------------------------------------------------------------------
        function updated = updateCharMap(this, whichBox, selectedChar)
            
            updated = false;
            
            if isempty(this.SelectionMap)
                % first time                
            else                                
                
                if nargin == 2
                    % update specific box - dynamic update while labeling.
                    modified = whichBox;
                    updated = true;
                else
                    % update on char list selection change
                    
                    % get modified labels. only pick up undeleted chars.
                    modified = cellfun(@(x)~isempty(x) && ischar(x),this.SelectionMap(:,4));
                    
                    modified = find(modified);
                    
                    if any(modified)
                        updated = true;
                    end
                end
                
                % Only update the modified chars
                for i = 1:numel(modified)
                    
                    idx = modified(i);
                                                            
                    % remove old character from char map. then insert new
                    % one.
                    old = this.SelectionMap{idx, 3};
                    new = this.SelectionMap{idx, 4};
                    
                    imageIndex = this.SelectionMap{idx,1};
                    bboxIndex  = this.SelectionMap{idx,2};
                    
                   
                    if strcmp(new, selectedChar)
                        % Remove new char from deferred removal list. This
                        % is required when a box label is change back and
                        % forth between the selected char in the browser and a
                        % different label.
                        this.DelayRemovalSelectedBoxes(...
                            this.DelayRemovalSelectedBoxes == idx) = [];
                        
                    elseif ~ismember(idx, this.DelayRemovalSelectedBoxes)
                        % Mark box for deferred removal from SelectedBoxes
                        % only if it is not already part of the list.
                        this.DelayRemovalSelectedBoxes(end+1) = idx;
                    
                    end
                    
                    v = this.CharMap(old);
                                        
                    % remove the bbox associated with modified char
                    j = [v(:).imageIndex] == imageIndex;
                    v(j).bboxIndex(v(j).bboxIndex == bboxIndex) = [];
                    
                    % If no more bboxes remain, then there are no more
                    % samples of this char the image. Remove the image
                    % from the char map.
                    if isempty(v(j).bboxIndex)
                        v(j) = [];
                    end
                    
                    if numel(v) == 0         
                        % No samples left of old char in any of the images,
                        % it can be removed completely.
                        
                        if nargin == 3 && strcmp(selectedChar,old) 
                            this.deferRemoval(old, v);
                        else
                            this.removeChar(old, false);                                                         
                        end
                    else
                        % update char map with new info.
                        this.CharMap(old) = v;
                        this.updateIconDescription(old);
                    end                                        
                    
                    % Insert new char
                    if isKey(this.CharMap, new)
                        
                        % check if char was marked for deferred removal. If
                        % so, remove it from the deferred removal list.
                        if ismember(new, this.DelayRemoval)
                            this.DelayRemoval(...
                                strcmp(new, this.DelayRemoval)) = [];
                        end
                    
                        % Entry exists for char, append into the existing
                        % entry.
                        v = this.CharMap(new);
                        
                        % Find where we should append. Find location based
                        % on which image the new char is found in.
                        j = find([v(:).imageIndex] == imageIndex,1);
                        if isempty(j)                           
                            % Image isn't part of data entry yet. Add it.
                            s = struct('imageIndex', imageIndex,...
                                       'bboxIndex', bboxIndex); 
                                                                                             
                            this.CharMap(new) = [v s];
                            
                            % Update SelectedBoxes for the newly appended
                            % entry.
                            position = numel([v(:).bboxIndex]);
                            
                        else
                            % Image is already part of the entry. Append
                            % bbox location of new char.
                            position = numel([v(1:j).bboxIndex]);
                            v(j).bboxIndex(end+1) = bboxIndex;
                            this.CharMap(new) = v;
                        end
                            
                        if ~strcmp(new, selectedChar)
                            % place new entries in SelectedBoxes only when
                            % the new char isn't the current selectedChar.
                            % This can happen if box label is change from
                            % curent char to something else and then back
                            % to the current char.
                            this.insertIntoSelectedBoxes(new, position);                            
                        end
                        
                        this.updateIconDescription(new);                                       
                                                
                    else
                        % Brand new char, not in char map yet. Create an
                        % entry for it and populate it's data.
                        
                        s = struct('imageIndex', imageIndex,...
                                   'bboxIndex', bboxIndex);                        
                        this.CharMap(new) = s;  
                        
                        idx = this.getCharacterIndex(new);
                        
                        % insert new character into its place and update
                        % all the state information.
                        
                        v = this.AreCharThumbnailsGenerated;
                        this.AreCharThumbnailsGenerated = [v(1:idx-1) false v(idx:end)];
                        
                        v = this.SelectedBoxes;                      
                        this.SelectedBoxes = [v(1:idx-1) {sparse(true)} v(idx:end)];
                        
                        v = this.CharIcons;
                        this.CharIcons =  [v(1:idx-1) {[]} v(idx:end)];
                        
                        this.updateImageListEntry(idx-1); % minus 1 for java idx                        
                        
                    end
                    
                    % Mark selection map as unmodified to prevent double
                    % updates when switching to a new char montage.
                    this.SelectionMap{modified(i),3} = this.SelectionMap{modified(i),4};
                    this.SelectionMap{modified(i),4} = [];
                end               
            end
                         
        end
        
        %------------------------------------------------------------------
        % Inserts false entry into SelectedBoxes for the new character at
        % the specified position. This required when adding/modifying
        % character labels for keeping track of which boxes are selected
        % across char montage views.
        %------------------------------------------------------------------
        function insertIntoSelectedBoxes(this, new, position)
            cidx = this.getCharacterIndex(new);
            d = this.SelectedBoxes{cidx};
                        
            if position+1 <= numel(d)
                % do insert
                d = [d(1:position) false d(position+1:end)];
            else
                % do append
                d = [d(1:position) false];
                
            end
            
            this.SelectedBoxes{cidx} = d;
        end
        
        %------------------------------------------------------------------
        % Set character label for a box. ImageStruct and SelectionMap are
        % updated.
        %------------------------------------------------------------------
        function setCharLabel(this, whichBox, label)
            
            % update text label in image struct
            for i = 1:numel(whichBox)
                
                bidx = whichBox(i);
                
                [whichImage, whichChar] = this.getImageIndex(bidx);                         
                
                this.ImageStruct(whichImage).text{whichChar} = label;
                
                % also update current selection map
                this.SelectionMap{bidx,4} = label;
            end           
                        
        end
        
        %------------------------------------------------------------------
        % Return the label assigned to a box. This information updated live
        % in the SelectionMap.
        function label = getBoxLabel(this, whichBox)              
            
            label = this.SelectionMap(whichBox,3);
            
            if numel(label) == 2
                label = label{1};
            end
            
        end
        
        
        %------------------------------------------------------------------
        function needsUpdate = updateBoundingBoxes(this, selectedIndex, boundingBoxes, roiselected)
            
            % If multiple files are selected grab just the first one
            selectedIndex = selectedIndex(1);
            needsUpdate = false;
            if ~isequal(this.ImageStruct(selectedIndex).objectBoundingBoxes, ...
                    boundingBoxes)
                this.ImageStruct(selectedIndex).objectBoundingBoxes = boundingBoxes;
                if ~isequal(this.SelectedBoxes{selectedIndex}, roiselected)
                    this.SelectedBoxes{selectedIndex} = roiselected;
                end
                needsUpdate = true;
            else
                if ~isequal(this.SelectedBoxes{selectedIndex}, roiselected)
                    this.SelectedBoxes{selectedIndex} = roiselected;
                    needsUpdate = true;
                end
            end
            
        end
        
        %------------------------------------------------------------------
        function removeImage(this, selectedIndex)            
            this.ImageStruct(selectedIndex)            = [];
            this.AreThumbnailsGenerated(selectedIndex) = [];                        
            this.TextDetectionParams(selectedIndex) = [];
        end
        
        %------------------------------------------------------------------
        function moveCharToUnknown(this, whichOne)

            if ischar(whichOne)
                % remove by char
                character = whichOne;
                idx = this.getCharacterIndex(character);
            else
                % remove by index
                idx = whichOne;
                character = this.getCharacterByIndex(idx);
            end
           
            character = cellstr(character);
            
            % cellstr marks char(0) as '' instead of ' '. correct this.
            character(strcmp('',character)) = {char(0)};
            
            for i = 1:numel(idx)
                c = character{i};
                
                if strcmp(c,char(0))
                    continue
                end
                
                this.resetSelectionMap(c);
                
                whichBox = 1:this.getNumCharSamples(c);                                                
                
                this.setCharLabel(whichBox,char(0));                               
                
                % update the char map
                this.updateCharMap(whichBox, c);
            end
            
        end
        
        %------------------------------------------------------------------
        function removeChar(this, whichOne, invalidateBox)      
            
            if nargin == 2
                invalidateBox = true;
            end
            
            if ischar(whichOne)
                % remove by char
                character = whichOne;
                idx = this.getCharacterIndex(character);
            else
                % remove by index
                idx = whichOne;
                character = this.getCharacterByIndex(idx);
            end
                        
            this.AreCharThumbnailsGenerated(idx) = [];
            this.SelectedBoxes(idx) = [];
            this.CharIcons(idx) = [];

            % remove boxes from image struct
            character = cellstr(character);
            
            % cellstr marks char(0) as '' instead of ' '. correct this.
            character(strcmp('',character)) = {char(0)};
            
            % invalidate a box by marking the text with -1. this is done
            % when removing a character. Otherwise it's not done
            if invalidateBox
                for i = 1:numel(character)
                    key = character{i};
                    if isKey(this.CharMap, key)
                        val = this.CharMap(key);
                        invalidateBoxes(this, val);
                    end
                end                         
            end
                      
            
            % remove from char map
            keysToRemove = isKey(this.CharMap, character);
            remove(this.CharMap, character(keysToRemove));  
            
        end                  
        
        %------------------------------------------------------------------
        function removeCharSample(this, whichBox, shouldDeferRemoval)
          
            [v.imageIndex, v.bboxIndex] = this.getImageIndex(whichBox);
            
            selectedChar = this.getBoxLabel(whichBox);
            
            this.removeFromCharMap(...
                selectedChar{1}, v.imageIndex, v.bboxIndex, ...
                shouldDeferRemoval);
            
            % mark as invalid
            this.invalidateBoxes(v);                      
            
        end
        
        
        %------------------------------------------------------------------
        function invalidateBoxes(this, value)
            
            % mark boxes associated with a character as invalid. invalid
            % boxes are not used for training.
            for i = 1:numel(value)
                imgIdx = value(i).imageIndex;
                boxIdx = value(i).bboxIndex;
                
                % invalid box is marked with -1 text value
                this.ImageStruct(imgIdx).text(boxIdx) = {-1};
            end
        end
                        
        %------------------------------------------------------------------
        function removeItem(this, idx)
            if strcmp(this.RemoveMode, 'move')
                this.moveCharToUnknown(idx);
            else
                if this.CharView
                    this.removeChar(idx);
                else
                    this.removeImage(idx);
                end
            end
        end
        
        %------------------------------------------------------------------
        function reset(this)                
            this.ImageStruct = [];                
            this.SelectedBoxes = {};
            this.AreThumbnailsGenerated = [];
            this.AreCharThumbnailsGenerated = [];
            this.CharMap = containers.Map;
            this.CharIcons = {};
            this.SelectionMap = {};
            this.TextDetectionParams = [];
        end               
        
        
        %------------------------------------------------------------------
        function n = getNumBoxes(this)
            
            n = size(this.SelectionMap,1);            
            
        end
        
        %------------------------------------------------------------------
        function idx = getCharacterIndex(this, whichOne)
            idx = find(strcmp(whichOne, keys(this.CharMap)),1);
        end
        
        %------------------------------------------------------------------
        function updateIconDescription(this, whichOne, numSamples)
            if this.CharView                
                idx = this.getCharacterIndex(whichOne);
                if nargin == 2                                    
                    numSamples = this.getNumCharSamples(whichOne);
                end
                label = vision.internal.ocr.tool.ImageSet.generateCharacterIconDescription(numSamples);
                this.CharIcons{idx}.setDescription(label);
            else
                label = this.ImageStruct(whichOne).ImageLabel;          
                this.ImageStruct(whichOne).ImageIcon.setDescription(label);
            end
            
        end
        
        %------------------------------------------------------------------
        % This method should be called after the Image Session is loaded
        % from a MAT file to check that all the images can be found at
        % their specified locations
        %------------------------------------------------------------------
        function checkImagePaths(this, currentSessionFilePath,...
                origFullSessionFileName)
            
            % verify that all the images are present; adjust path if
            % necessary
            for i=1:numel(this.ImageStruct)
                if ~exist(this.ImageStruct(i).imageFilename,'file')
                    
                    this.ImageStruct(i).imageFilename = ...
                        vision.internal.uitools.tryToAdjustPath(...
                        this.ImageStruct(i).imageFilename, ...
                        currentSessionFilePath, origFullSessionFileName);
                    
                end
            end            
        end 
        
        %------------------------------------------------------------------        
        function ret = areAllImagesLabeled(this)
            
            ret = ~any(cellfun(@isempty, {this.ImageStruct.objectBoundingBoxes}));
            
        end
        
        %------------------------------------------------------------------
        function cellArrayOfIcons = getIcons(this)
            if this.CharView
                cellArrayOfIcons = this.CharIcons;
            else
                cellArrayOfIcons = {this.ImageStruct.ImageIcon};
            end
        end
                
        %------------------------------------------------------------------
        % Return number of elements in the the set. For purposes of
        % rendering image strip list. 
        %------------------------------------------------------------------
        function n = getNumel(this)
            if this.CharView                
                n = length(this.CharMap);
            else
                n = numel(this.ImageStruct);
            end
        end
        
        %------------------------------------------------------------------
        function n = getNumCharSamples(this, c)
            s = this.CharMap(c);
            n = numel([s(:).bboxIndex]);
        end
        
        %------------------------------------------------------------------
        function icon = generateIcon(this, selectedIndex)
            if this.CharView
                k = keys(this.CharMap);
                character = k{selectedIndex};
                n = this.getNumCharSamples(character);
                
                icon = vision.internal.ocr.tool.generateCharacterIcon(...
                    this.Font, character, n);
                
                this.CharIcons{selectedIndex} = icon{1};
            else
                filename = this.ImageStruct(selectedIndex).imageFilename;  
                icon = vision.internal.ocr.tool.ImageSet.generateImageIcon(filename);
                this.ImageStruct(selectedIndex).ImageIcon = icon{1};
            end
        end
        
        %------------------------------------------------------------------
        % edit: change the name to updateImageListEntry(this, selectedIndex)
        function updateMade = updateImageListEntry(this, selectedIndex)
            
            updateMade = true;            
            
            if selectedIndex == -1 % when JList is loading for the first time
                selectedIndex = 1;
            else
                selectedIndex = selectedIndex+1; % making it MATLAB based
            end
                       
            
            if this.getIsThumbnailGenerated(selectedIndex)
                updateMade = false;
                return;
            end
                                           
            this.generateIcon(selectedIndex);            
            this.setIsThumbnailGenerated(selectedIndex,1);
            
        end
                
        %------------------------------------------------------------------
        function tf = getIsThumbnailGenerated(this, idx)
            if this.CharView
                tf = this.AreCharThumbnailsGenerated(idx);
            else
                tf = this.AreThumbnailsGenerated(idx);
            end
        end
        
        %------------------------------------------------------------------
        function setIsThumbnailGenerated(this, idx, value)
            if this.CharView
                this.AreCharThumbnailsGenerated(idx) = value;
            else
                this.AreThumbnailsGenerated(idx) = value;
            end
        end
        
        %------------------------------------------------------------------
        function ret = areAllIconsGenerated(this)
            if this.CharView
                ret = all(this.AreCharThumbnailsGenerated);
            else
                ret = all(this.AreThumbnailsGenerated);
            end
        end
        
        %------------------------------------------------------------------
        function resetIcons(this)
            if this.CharView                
                this.AreCharThumbnailsGenerated = false(1,length(this.CharMap));
            else
                this.AreThumbnailsGenerated = false(1,this.Count);
            end
        end
        
        end
                
    %----------------------------------------------------------------------
    methods (Access=private)      
        function uniqueImageFileNames = getUniqueFiles(this, imageFileNames)
            uniqueImageFileNames = setdiff(unique(...
                [{this.ImageStruct.imageFilename} imageFileNames]),...
                {this.ImageStruct.imageFilename});
        end                
    end

    %----------------------------------------------------------------------
    methods(Hidden, Static)
                
        %------------------------------------------------------------------
        % This function generates place holder icons for N characters
        %------------------------------------------------------------------
        function icons = generatePlaceHolders(imageFileNames)
            icons = cell(1, numel(imageFileNames));
            
            % grab a place holder image from the disk
            placeHolderImage = fullfile(matlabroot,'toolbox','vision',...
                'vision','+vision','+internal','+cascadeTrainer','+tool',...
                'PlaceHolderImage_72.png');
            im = imread(placeHolderImage);
            
            % prapare list data
            javaImage = im2java2d(im);           
            labels = generateImageLabels(imageFileNames);
            
            % populate the icons
            for i = 1:numel(imageFileNames)
                icons{i} = javax.swing.ImageIcon(javaImage);
                icons{i}.setDescription(labels{i});
            end
        end
        
        %------------------------------------------------------------------
        % This function generates place holder icons for N characters
        %------------------------------------------------------------------
        function icons = generateCharPlaceHolders(N)
            
            % grab a place holder image from the disk
            placeHolderImage = fullfile(matlabroot,'toolbox','vision',...
                'vision','+vision','+internal','+ocr','+tool',...
                'iconbg.png');            
            im = imread(placeHolderImage);
            
            % prapare list data
            javaImage = im2java2d(im);       
                        
            icons = repmat({javax.swing.ImageIcon(javaImage)}, 1, N);
            for i = 1:N
                icons{i}.setDescription('');
            end
        end
        
        %------------------------------------------------------------------
        % edit code to return icon as a java icon object and not a cell array
        %------------------------------------------------------------------        
        function icon = generateImageIcon(imageFileName)
            if ~iscell(imageFileName)
                imageFileName = cellstr(imageFileName);
            end
            label = generateImageLabels(imageFileName);
            try
                im = imread(imageFileName{1});
                javaImage = im2java2d(imresize(im, [72 72],'nearest'));
                icon{1} = javax.swing.ImageIcon(javaImage);
                icon{1}.setDescription(label{1});
            catch loadingEx
                errordlg(loadingEx.message,...
                    vision.getMessage('vision:uitools:LoadingImageFailedTitle'),...
                    'modal');
            end
        end
        
        %------------------------------------------------------------------
        function label = generateCharacterIconDescription(numSamples)           
             if numSamples == 1            
                 msg = ['%d ' vision.getMessage('vision:ocrTrainer:SampleString')];
             else
                 msg = ['%d ' vision.getMessage('vision:ocrTrainer:SamplesString')];
             end
             label = sprintf(msg,numSamples);
        end
              
        %------------------------------------------------------------------
        function files = eliminateNonImages(imageFileNames)
            isImage = true(1, numel(imageFileNames));
            disableImfinfoWarnings();
            for i = 1:numel(imageFileNames)
                
                try
                    imfinfo(imageFileNames{i});
                catch
                    isImage(i) = false;
                end
            end
            enableImfInfoWarnings();
            files = imageFileNames(isImage);
            
            % Nested functions
            %--------------------------------------------------------------
            function disableImfinfoWarnings()
                imfinfoWarnings('off');
            end
            %--------------------------------------------------------------
            function enableImfInfoWarnings()
                imfinfoWarnings('on');
            end
            %--------------------------------------------------------------
            function imfinfoWarnings(onOff)
                warnings = {'MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero',...
                    'MATLAB:imagesci:tifftagsread:numDirectoryEntriesIsZero',...
                    'MATLAB:imagesci:tifftagsread:tagDataPastEOF'};
                for j = 1:length(warnings)
                    warning(onOff, warnings{j});
                end
            end
            %--------------------------------------------------------------
        end
    end
  
    %----------------------------------------------------------------------
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of Session class changes
    %----------------------------------------------------------------------
    methods (Hidden)
        
        function thisOut = saveobj(this)
            thisOut = this;
        end
        
    end
    %======================================================================
    
    methods (Static, Hidden)
        
        function thisOut = loadobj(this)
            thisOut = this;
        end
        
    end
    %======================================================================
    
end

%------------------------------------------------------------------
% edit: trace where the imageFileNames first come into play and protect it over there.
function labels = generateImageLabels(imageFileNames)

if ~iscell(imageFileNames)
    imageFileNames = cellstr(imageFileNames);
end
[~, labels, ~] = cellfun(@fileparts, imageFileNames, 'UniformOutput', 0);

end
