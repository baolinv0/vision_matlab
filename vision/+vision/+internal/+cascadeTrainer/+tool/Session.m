% Session holds the state of the Training Data Labeler App
%
%   This class holds the entire state of the training data labeler UI.
%   It is used to save and load the labeling session. It is also
%   used to pass data amongst other classes.

% Copyright 2012-2013 The MathWorks, Inc.


classdef Session < handle
    
    properties
        CanExport;             % check whether session is ready to export
        IsChanged;             % true when session may need saving

        FileName;              % filename of the stored session
        ExportVariableName;    % default export variable name
        
        ImageSet;              % Property that will hold a class describing the entire image set        
        CategorySet;           % Property that will hold a class describing the entire category set 
    end
    
    properties(Access=private, Hidden)        
        Version = ver('vision');        
    end
        
    properties(Dependent)
        NumCategories;
    end
    
    methods
        
        %------------------------------------------------------------------
        % Constructor
        %----------------------------------------------------------------
        
        function this = Session(ROIs, filePath, fileName)
            import vision.internal.cascadeTrainer.tool.*
            if nargin == 0
                this.ImageSet = ImageSet;
                this.CategorySet = CategorySet;
                this.reset();
            else
                this.ImageSet = ImageSet(ROIs, filePath, fileName);
                if istable(ROIs)
                    % Skip the first column, it is the file names.
                    catNames = ROIs.Properties.VariableNames(2:end);
                    this.CategorySet = CategorySet(catNames);
                else
                    this.CategorySet = CategorySet;
                end
            end
        end
        
        %------------------------------------------------------------------
        function ret = getExportStatus(this)
            if ~hasAnyImages(this.ImageSet)
                ret = false;
            else
                bboxes = {this.ImageSet.ImageStruct.objectBoundingBoxes};
                if unique(cellfun(@isempty, bboxes))
                    ret = false;
                else
                    ret = true;
                end
            end
        end

        
        %------------------------------------------------------------------
        % Returns true if the session already has images else returns false
        %------------------------------------------------------------------
        
        function ret = hasAnyImages(this)
            
            ret = ~isempty(this.ImageSet.ImageStruct);
            
        end
        
        %------------------------------------------------------------------
        function resetImages(this)
            this.ImageSet.reset();
        end
        
        %------------------------------------------------------------------
        function reset(this)
            
            this.IsChanged          = false;
            this.FileName           = '';
            this.ExportVariableName = 'Unnamed';
            this.CanExport          = false;

            this.resetImages();        
            this.CategorySet.reset();
        end
        
        %------------------------------------------------------------------
        function checkImagePaths(this, pathname, filename)
            this.ImageSet.checkImagePaths(pathname, filename);
        end
        
        %------------------------------------------------------------------
        function numCategories = get.NumCategories(this)
            numCategories = this.CategorySet.numCategories;
        end
        
        %------------------------------------------------------------------
        function catName = getCategoryName(this, catID)
            idx = [this.CategorySet.CategoryStruct(:).categoryID] == catID;    
            catName = this.CategorySet.CategoryStruct(idx).categoryName;
        end
        
        %------------------------------------------------------------------
        function catColor = getCategoryColor(this, catID)
            categoryIDs = [this.CategorySet.CategoryStruct.categoryID];
            ind = (catID == categoryIDs);
            catColor = this.CategorySet.CategoryStruct(ind).categoryColor;
        end
        
        %------------------------------------------------------------------
        function labelTable = getLabelTable(this)
            [catNames, catIDs] = getCategories(this.CategorySet);
            labelTable = this.ImageSet.getLabelTable(catNames, catIDs);
        end
        
        %------------------------------------------------------------------
        function numImages = getNumImages(this)
            numImages = numel(this.ImageSet.ImageStruct);
        end
        
        %------------------------------------------------------------------
        function numLabeledImages = getNumLabeledImages(this)
            bboxes = {this.ImageSet.ImageStruct.objectBoundingBoxes};
            numLabeledImages = numel(find(~cellfun(@isempty, bboxes)));
        end
        
        %------------------------------------------------------------------
        function numROIs = getNumROIs(this)
            boundingBoxes = {this.ImageSet.ImageStruct.objectBoundingBoxes};
            [numROIsPerImage, ~] = cellfun(@size, boundingBoxes);
            numROIs = sum(numROIsPerImage);
        end
        
        %------------------------------------------------------------------
        function [imageMatrix, imageLabel] = getImages(this, idx)
            [imageMatrix, imageLabel] = this.ImageSet.getImages(idx);
        end
        
        %------------------------------------------------------------------
        function addROI(this, imageIdx, catIdx, roi)
            cid = this.CategorySet.CategoryStruct(catIdx).categoryID;
            this.ImageSet.addROI(imageIdx, cid, roi);
        end
        
        %------------------------------------------------------------------
        function tf = hasROIs(this, imageIdx)
            tf = ~isempty(this.ImageSet) && ...
                numel(this.ImageSet.ImageStruct) >= imageIdx && ...
                ~isempty(this.ImageSet.ImageStruct(imageIdx).objectBoundingBoxes);
        end
        
        %------------------------------------------------------------------
        % Used for conflict resolution while merging sessions
        function imagesCatID = replaceCategoryIndex(this, origCatID, ...
                newCatID, imagesCatID)
            
            s = this.ImageSet;
            imagesCatID = cellfun(@replaceID, {s.ImageStruct(:).catID}, ...
                imagesCatID ,'UniformOutput',false);
            
            function y = replaceID(x,y)
                y(x == origCatID) = newCatID;
            end
        end
        
        %------------------------------------------------------------------
        function renameCategory(this, newName, idx)
            this.CategorySet.renameCategory(newName,idx);
            this.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        function changeCategoryColor(this, newColor, idx)
            this.CategorySet.changeCategoryColor(newColor,idx);
            this.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        function removeCategory(this, idxMultiselect)
            categoryIDs = [this.CategorySet.CategoryStruct(idxMultiselect).categoryID];
            s = this.ImageSet;
            if ~isempty(s.ImageStruct)
                imagesCatID = {s.ImageStruct(:).catID};
                bboxes = {s.ImageStruct(:).objectBoundingBoxes};
                for i = categoryIDs
                    [imagesCatID, bboxes] = cellfun(@removeID, imagesCatID, ...
                        bboxes,'UniformOutput',false);
                end
                
                [s.ImageStruct.catID] = imagesCatID{:};
                [s.ImageStruct.objectBoundingBoxes] = bboxes{:};
                this.ImageSet = s;
            end
            
            this.CategorySet.removeCategory(idxMultiselect);
            this.IsChanged = true;
            this.ImageSet.updateAllIconDescriptions();
            
            function [x,y] = removeID(x,y)
                origCatID = i;
                y(x == origCatID,:) = [];
                x(x == origCatID) = [];
            end
        end
            
    end
    
    %----------------------------------------------------------------------
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of Session class changes
    %----------------------------------------------------------------------
    
    methods (Hidden)
       
        function that = saveobj(this)            
            that.version         = this.Version;
            that.canExport       = this.CanExport;
            that.isChanged       = this.IsChanged;
            that.filename        = this.FileName;
            that.exportVarName   = this.ExportVariableName;
            that.imageSet        = this.ImageSet;
            if(~isempty(this.CategorySet))
                that.categorySet     = this.CategorySet;
            end
        end
        
    end
    
    %----------------------------------------------------------------------
    methods (Static, Hidden)
       
        function this = loadobj(that)
            if isa(that, 'vision.internal.cascadeTrainer.tool.Session')
                this = that;
                if isempty(that.CategorySet)
                    makeCategorySet();
                end
                
            else
                this = vision.internal.cascadeTrainer.tool.Session;
                this.CanExport          = that.canExport;
                this.IsChanged          = that.isChanged;
                this.FileName           = that.filename;
                this.ExportVariableName = that.exportVarName;
                this.ImageSet           = that.imageSet;
                
                if isfield(that, 'categorySet')
                    this.CategorySet = that.categorySet;                    
                else                   
                    makeCategorySet();                   
                end
            end
            
            function makeCategorySet()
                this.CategorySet = vision.internal.cascadeTrainer.tool.CategorySet;
                anyBoundingBox = any(cellfun(@(x) ~isempty(x), ...
                    {this.ImageSet.ImageStruct.objectBoundingBoxes}));
                if(anyBoundingBox)
                    C = cellfun(@(x) repmat(this.CategorySet.numCategories,size(x,1),1), ...
                        {this.ImageSet.ImageStruct.objectBoundingBoxes},'UniformOutput',false);
                    [this.ImageSet.ImageStruct(:).catID] = deal(C{:});
                else
                    [this.ImageSet.ImageStruct(:).catID] = deal([]);
                end
                
            end
        end
    end
end


    %======================================================================
    
