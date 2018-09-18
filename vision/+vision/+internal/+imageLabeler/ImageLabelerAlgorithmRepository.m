% This creates a singleton algorithm repository for the imageLabeler.

% Copyright 2017 The MathWorks, Inc.

classdef ImageLabelerAlgorithmRepository < vision.internal.labeler.AlgorithmRepository
    
    properties (Constant)
        %PackageRoot    Image Labeler should only pick up labeler
        %               algorithms from vision.labeler.
        PackageRoot = 'vision.labeler';
        
        %TemporalContextClass   Full class name for temporal context mixin
        %                       class.
        TemporalContextClass = 'vision.labeler.mixin.Temporal';
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function repo = getInstance()
            persistent repository
            if isempty(repository) || ~isvalid(repository)
                repository = vision.internal.imageLabeler.ImageLabelerAlgorithmRepository();
            end
            repo = repository;
        end
    end
    
    methods
        %------------------------------------------------------------------
        function tf = isAutomationAlgorithm(this, metaClass)
            
            tf = isAutomationAlgorithm@vision.internal.labeler.AlgorithmRepository(this, metaClass);
            
            tf = tf && ~hasTemporalContext(this, metaClass);
        end
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function tf = hasTemporalContext(this, metaClass)
            % get the superclass, and return true if the class inherits
            % from the temporal mixin class.
            
            metaSuperclass = metaClass.SuperclassList;
            superclasses   = {metaSuperclass.Name};
            
            expectedClass = this.TemporalContextClass;
            tf = ismember(expectedClass, superclasses);
        end
    end
end