%visualWords Object for storing visual words
%
%  visualWords Object stores the visual words representing an image.
%
%  A visualWords object is used to store visual word data encoded from an
%  image using the bag of features algorithm. The words and their locations
%  within an image are stored.
%
%  visualWords are returned by the bagOfFeatures encode method, and the
%  retrieveImages function. Rely on these functions to create visualWord
%  objects.
%
%  visualWords read-only properties:
%    Word           - A vector of visual word identifiers.
%    Location       - Visual word locations within an image.
%    VocabularySize - Number of visual words in the vocabulary.
%    Count          - Number of visual words held by the object.
%
%  visualWords methods:
%    spatialMatch - Find matching visual words using spatial constraints.
%
% Example
% -------
%  setDir  = fullfile(toolboxdir('vision'),'visiondata','imageSets');
%  imgSets = imageSet(setDir, 'recursive');
%
%  trainingSets = partition(imgSets, 2); % pick the first 2 images from each set
%  bag = bagOfFeatures(trainingSets);    % bag creation can take a few minutes
%
%  I = read(imgSets(1), 1);
%  [wordHistogram, words] = encode(bag, I);
%
% See also bagOfFeatures, retrieveImages, indexImages, invertedImageIndex

classdef visualWords           
    properties(GetAccess = public, SetAccess = private)
        % WordIndex - A vector of visual word identifiers
        WordIndex
        % Location - Visual word locations within an image.
        Location 
        % VocabularySize - Number of visual words in the vocabulary.
        VocabularySize
    end
    
    %======================================================================
    properties(Dependent)
        % Count - Number of visual words held by the object.
        Count
    end
    
    %======================================================================
    methods
        function this = visualWords(words, locations, sz)
            if nargin ~= 0
                vision.internal.visualWords.checkInputs(words, locations, sz);
                
                this.WordIndex      = uint32(words(:));
                this.Location       = locations;
                this.VocabularySize = double(full(sz));
            end
        end               
        
        %------------------------------------------------------------------              
        function n = get.Count(this)
            n = numel(this.WordIndex);
        end
        
    end
    
    %======================================================================
    methods(Hidden, Static, Access=private)
        function params = parseSpatialMatchInput(words1, words2, varargin)
            
            vision.internal.visualWords.checkWords(words1,'words1');            
            vision.internal.visualWords.checkWords(words2,'words2');
            
            if words1.VocabularySize ~= words2.VocabularySize
                error(message('vision:visualWords:vocabSizeNotEqual'));
            end                        
            
            defaults.NumNeighbors   = 10;
            defaults.MatchThreshold = 1;  
            
            p = inputParser;          
            
            p.addParameter('NumNeighbors',   defaults.NumNeighbors,... 
                @(x)vision.internal.visualWords.checkScalar(x,'NumNeighbors'));
            
            p.addParameter('MatchThreshold', defaults.MatchThreshold,...
                @(x)vision.internal.visualWords.checkScalar(x,'MatchThreshold'));
                     
            parse(p, varargin{:});                       
                        
            params.NumNeighbors   = double(p.Results.NumNeighbors);
            params.MatchThreshold = double(p.Results.MatchThreshold);
            
            if params.MatchThreshold > params.NumNeighbors
                error(message('vision:visualWords:thresholdGTNumNeighbors'));
            end            
                           
        end
        
        % -----------------------------------------------------------------
        function checkWords(words,name)
            validateattributes(words, {'vision.internal.visualWords'},...                
                {'scalar'}, mfilename, name);            
        end
        
        % -----------------------------------------------------------------
        function checkInputs(words, locations, sz)
            
            validateattributes(words, {'numeric'},...
                {'vector','nonsparse','real'},...
                mfilename, 'WordIndex', 1);
            
            validateattributes(locations, {'single'},...
                {'size', [NaN 2], 'nonsparse', 'real'},...
                mfilename, 'Location', 2);
            
            validateattributes(sz, {'numeric'}, ...
                {'scalar', 'positive', 'integer', 'real'}, ...
                mfilename, 'VocabularySize', 3);
            
            if numel(words) ~= size(locations,1)
                error(message('vision:visualWords:invalidNumelWords'));
            end
            
        end
        
        % -----------------------------------------------------------------
        function h = createSparseHistogram(words)            
            w = words.WordIndex;
            h = sparse(1,double(w),1,1,words.VocabularySize);
        end       
    end
    
    %======================================================================
    methods(Hidden)
        function s = saveobj(this)
            s.WordIndex      = this.WordIndex;
            s.Location       = this.Location;
            s.VocabularySize = this.VocabularySize;
        end
        
        % -----------------------------------------------------------------
        function this = addROIOffset(this,roi)
            % Add offset to location to compensate for ROI.
            this.Location = vision.internal.detector.addOffsetForROI(this.Location, roi, true);
        end
        
        %------------------------------------------------------------------              
        function [indexPairs, score] = spatialMatch(words1, words2, varargin)
            %spatialMatch Find matching visual words using spatial constraints
            %
            % indexPairs = spatialMatch(words1, words2) returns a M-by-2
            % matrix containing indices to the visual words most likely to
            % correspond between words1 and words2. words1 and words2 must
            % be visualWords objects. Visual words in words1 are matched to
            % those in words2 only if they share at least 1 common
            % neighbor.
            %
            % [..., score] = spatialMatch(...) optionally returns a score
            % metric based on the number of matching visual words. The
            % score ranges between 0 and 1. The score is 1 when all the
            % visual words in words1 are spatially matched to visual words
            % in words2.
            %             
            % [...] = spatialMatch(..., Name,Value) specifies additional
            % name-value pair arguments described below:
            %
            %   'NumNeighbors'    Specify the number of nearest neighbors
            %                     to consider when looking for shared
            %                     neighbors between a pair of words.
            % 
            %                     Default: 10
            %                  
            %   'MatchThreshold'  Specify the number of common neighbors
            %                     required for a match.
            % 
            %                     Default: 1              
            %        
                        
            params = vision.internal.visualWords.parseSpatialMatchInput(words1,words2,varargin{:});
            
            hist1 = vision.internal.visualWords.createSparseHistogram(words1);
            hist2 = vision.internal.visualWords.createSparseHistogram(words2);
            
            matchingWords = uint32(find(hist1 & hist2));
            
            indexPairs = visionSpatialMatchVisualWords(words1.WordIndex,...
                words2.WordIndex, words1.Location, words2.Location,...
                matchingWords, params.NumNeighbors, params.MatchThreshold);
            
            % The score is the number of spatially matched words over total
            % number of words. A perfect score is 1.                       
            numMatched = size(indexPairs,1);
                        
            score = numMatched ./ (words1.Count + eps);
            
        end
        
    end
    
    %======================================================================
    methods(Static, Hidden, Access = private)
        function checkScalar(val,name)
            validateattributes(val, {'numeric'},...
                {'scalar','integer','positive','real','nonsparse'},...
                mfilename, name);
        end
    end
    
    %======================================================================
    methods(Static,Hidden)
        function this = loadobj(s)            
            this = vision.internal.visualWords(s.WordIndex, s.Location, s.VocabularySize);
        end
    end
    
end