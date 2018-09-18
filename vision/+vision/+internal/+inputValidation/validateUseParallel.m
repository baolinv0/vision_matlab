function useParallel = validateUseParallel(useParallel)
% validate UseParallel and check if there is a pool to use. If a pool is
% not available return false.

vision.internal.inputValidation.validateLogical(useParallel, 'UseParallel');

if useParallel
    try
        % gcp() will error if the Parallel Computing Toolbox is not
        % installed, or if it is unable to check out a license
        currPool = gcp();
        if isempty(currPool)           
            useParallel = false;                  
        end        
    catch        
        useParallel = false;
    end
end

