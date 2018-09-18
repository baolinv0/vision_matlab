% CategorySet Stores all information about categories that are labeled
%
%    This class stores all the information about the labeled categories

% Copyright 2015 The MathWorks, Inc.

classdef CategorySet < handle

    properties
       % Array of Categories containing
       %    1. categoryID
       %    2. categoryName
       %    3. categoryColor
       %    4. A look up table for the colors of categories
       
       CategoryStruct;
       colorLookup; 
       numCategories = 0;
    end
    
    % Adding property 'IsCategorySelected' to store selection status of categories
    % It is 'Transient' since we do not want to save it in the MAT file
    
    properties(Transient = true)
        categorySelected;
    end
    
    methods
        
        %------------------------------------------------------------------
        % Constructor
        %----------------------------------------------------------------
        
        function this = CategorySet(catNames)
            startingIndex = 1;
            this.colorLookup = im2double(label2rgb(1:10, 'lines','c','shuffle'));
            
            if nargin == 0
                this.numCategories = startingIndex;
                this.CategoryStruct = struct('categoryID', startingIndex,...
                    'categoryName', {'Unnamed'}, ...
                    'categoryColor', reshape(this.colorLookup(:,this.numCategories,:),1,3),...
                    'categoryIcon', this.generateCategoryIcon(this.numCategories,'Unnamed'));
            else
                for i = 1:numel(catNames)
                    this.addCategoryToSession(catNames{i});
                end
            end
            this.categorySelected = 1;
            
        end
        
        %------------------------------------------------------------------
        % Returns true if the session already has categories else returns false
        %------------------------------------------------------------------        
        function ret = hasAnyCategories(this)            
            ret = ~isempty(this.CategoryStruct);            
        end   
        
        %------------------------------------------------------------------
        function [catNames, catIDs] = getCategories(this)
            catNames = {this.CategoryStruct(:).categoryName};
            catIDs = [this.CategoryStruct(:).categoryID];
        end
        
        %------------------------------------------------------------------
        function reset(this)                
            startingIndex = 1;
            this.numCategories = startingIndex;
            this.colorLookup = im2double(label2rgb(1:10, 'lines','c','shuffle'));    
            
            this.CategoryStruct = struct('categoryID', startingIndex,...
                'categoryName', {'Unnamed'}, ...
                'categoryColor', reshape(this.colorLookup(:,this.numCategories,:),1,3),...
                'categoryIcon', this.generateCategoryIcon(this.numCategories,'Unnamed'));        
            
            this.categorySelected = 1;
        end
                
        %------------------------------------------------------------------
        function [numCat, startingIndex] = addCategoryToSession(this, categoryName, varargin)                                   
            startingIndex = 1;
            numCat = this.numCategories;
                        
            if this.hasAnyCategories()                 
                startingIndex = max([this.CategoryStruct(:).categoryID]) + 1;
                
                % look for duplicates and if found, fail the operation
                catName = this.isUniqueCategoryName(categoryName);
                if ~catName                    
                    errordlg(vision.getMessage('vision:uitools:InvalidCategoryMessage'));
                    return; % nothing to add
                end
            end
            
            this.numCategories = this.numCategories + 1;
            
            if nargin > 2 % color is specified
                color = varargin{:};
                this.colorLookup(:,this.numCategories,:) = color;
            elseif this.numCategories > size(this.colorLookup, 2)
                color = rand(1, 3);
                this.colorLookup(:,this.numCategories,:) = color;
            else 
                color = this.colorLookup(:, this.numCategories,:);
            end
            
            newStruct = struct('categoryID', startingIndex,...
                'categoryName', {categoryName}, ...
                'categoryColor', reshape(squeeze(color), [1, 3]),...
                'categoryIcon', this.generateCategoryIcon(this.numCategories, categoryName));
            
            this.CategoryStruct = [this.CategoryStruct newStruct];
            this.categorySelected = startingIndex;
            numCat = this.numCategories;
        end
        
        %------------------------------------------------------------------
        function flag = isUniqueCategoryName(this, cName)
            categoryNames = {this.CategoryStruct(1:this.numCategories).categoryName};
            flag = ~any(cellfun(@(x) strcmpi(x, cName),categoryNames));
        end
        
        %------------------------------------------------------------------       
        function updateMade = updateCategoryListEntry(this, selectedIndex)
            
            updateMade = true;
            
            if selectedIndex == -1 % when JList is loading for the first time
                selectedIndex = 1;
            else
                selectedIndex = selectedIndex+1; % making it MATLAB based
            end
            
            fileName = this.CategoryStruct(selectedIndex).categoryName;
            
            icon = this.generateCategoryIcon(selectedIndex, fileName);
            this.CategoryStruct(selectedIndex).categoryIcon = icon{1};

            
        end
        
        %------------------------------------------------------------------     
        function icon = generateCategoryIcon(this, numCategory, categoryName)
            
            color = this.colorLookup(:,numCategory,:);
            im = repmat(color,4,1,1);
            im = reshape(im,2,2,3);
            javaImage = im2java2d(imresize(im, [36 36]));
            icon{1} = javax.swing.ImageIcon(javaImage);
            icon{1}.setDescription(categoryName);
            
        end
        
        %------------------------------------------------------------------
        function count = compareCategoryStruct(this, categoryStruct)
            count = numel(categoryStruct);
            for i = 1:numel(categoryStruct)
                nameVec = cellfun(@(x) strcmpi(x, categoryStruct(i).categoryName), {this.CategoryStruct.categoryName});
                colorVec = cellfun(@(x) ismember(x, categoryStruct(i).categoryColor,'rows'),...
                    {this.CategoryStruct(:).categoryColor});
                % Same name: this takes care of the fact that colors in the
                % second session are same or different
                if(any(nameVec))
                    count(i) = this.CategoryStruct(nameVec).categoryID;
                    continue;
                end
                % Different names but same colors
                if(any(colorVec))
                    count(i) = 0;
                else % Different names and different colors
                    count(i) = -1;
                end                
            end
        end
        
        %------------------------------------------------------------------
        function changeCategoryColor(this, newColor, selectedIdx) 
            
            existingColors = this.colorLookup(1,1:this.numCategories,:);
            existingColors = reshape(existingColors, this.numCategories, 3);
            in = ismember(newColor, existingColors,'rows');
            if(any(in))
                errordlg(vision.getMessage('vision:trainingtool:DuplicateColorMessage'));
                return;
            end
            temp = this.colorLookup(1,selectedIdx,:);
            this.colorLookup(1,selectedIdx,:) = newColor;
            this.CategoryStruct(selectedIdx).categoryColor = reshape(this.colorLookup(:,selectedIdx,:),1,3);
            
            unusedColors = this.colorLookup(1,this.numCategories+1:end,:);
            unusedColors = reshape(unusedColors, ...
                size(this.colorLookup,2)-this.numCategories, 3);

            % Swap if the new color is in the list of unused
            % colors
            in = ismember(newColor, unusedColors,'rows');
            if in
                this.colorLookup(1,in,:) = temp;
            end
        end
        
        %------------------------------------------------------------------
        function renameCategory(this, varName, idx)
            
            if(this.isUniqueCategoryName(varName))
                this.CategoryStruct(idx).categoryName = varName;
            else
                errordlg(vision.getMessage('vision:uitools:InvalidCategoryMessage'));
            end
        end
        
        %------------------------------------------------------------------
        function removeCategory(this, selectedIndex)
            
            this.CategoryStruct(selectedIndex) = [];
            this.numCategories = this.numCategories-numel(selectedIndex);
            n = size(this.colorLookup,2);
            tempColor = this.colorLookup(:,selectedIndex,:);
            this.colorLookup(:,selectedIndex,:) = [];
            this.colorLookup(:,size(this.colorLookup,2)+1:n,:) = tempColor;           
        end        
        
    end
    
end

