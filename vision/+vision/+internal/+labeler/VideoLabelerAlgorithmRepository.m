% This creates a singleton algorithm repository for the videoLabeler and
% groundTruthLabeler.

% Copyright 2017 The MathWorks, Inc.

classdef VideoLabelerAlgorithmRepository < vision.internal.labeler.AlgorithmRepository
    
    properties (Constant)
        %Video Labeler / Ground Truth Labeler should pick up automation
        %algorithms from vision.labeler and from driving.automation (for
        %backward compatibility).
        PackageRoot = {'vision.labeler', 'driving.automation'};
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function repo = getInstance()
            persistent repository
            if isempty(repository) || ~isvalid(repository)
                repository = vision.internal.labeler.VideoLabelerAlgorithmRepository();
            end
            repo = repository;
        end
    end
    
end