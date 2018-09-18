function start(this,openAtMdlStart)
%START Start method for Unified Scope coreblock.

%   Copyright 2015 The MathWorks, Inc.

block = this.Handle;
mdlRoot = bdroot(block);
if ~strcmp(get_param(mdlRoot,'simulationmode'),'accelerator') && strcmp(get_param(mdlRoot,'buildingrtwcode'),'on')
    return;
end

% If we are already launched, call mdlStart on the source to
% reset the data buffer.  If we are not yet launched we need to
% do this before existing.  Also reset the visual to blank out
% the previous run. When there are multiple instances of the
% model reference and the current model reference is a copy,
% override the OpenAtSimulationStart flag so that Scopes are
% not opened. See model block normal mode visibility for details.
openScopeOnStart = openAtMdlStart && ...
    ~uiservices.onOffToLogical(get_param(mdlRoot,'ModelReferenceMultiInstanceNormalModeCopy'));


rto = get_param(block,'RunTimeObject');

hasLaunched = isvalid(this.UnifiedScope);
if hasLaunched && openScopeOnStart

    fw = this.UnifiedScope;
    hSource = fw.DataSource;
    runMdlStart = false;

    mdlStart(hSource,rto);
    resetVisual(fw.Visual)
else
    runMdlStart = true;
end

hScopeSpec = get_param(block,'ScopeSpecificationObject');
if isempty(hScopeSpec) && (openScopeOnStart)
    % Because scope specification creation is expensive, we want to defer 
    % that as long as possible.  The current practice is to only create 
    % scope specifications for open scopes.
    this.createScopeSpecificationObject();
    hScopeSpec = get_param(block,'ScopeSpecificationObject');
end

if ~isempty(hScopeSpec)
    
    % If Block is not set, do it now. This can happen when undoing
    % block delete.
    if isempty(hScopeSpec.Block)
        hScopeSpec.Block = this;
    end
    
    % This work only needs to be performed if a scope is open, or will be
    % opened upon simulation
    if openScopeOnStart
        if hasLaunched
            if uiservices.onOffToLogical(get(fw.Parent,'Visible'))
                setUpdateMethod(hScopeSpec,true);

                % Make sure that the figure gains focus if it is already
                % visible.  Do not call the visible method as that will send
                % events that we do not want to issue again.
                figure(fw.Parent);
            else
                visible(fw,'on');
            end
        else
            % Defer visibility of framework to guarantee that the
            % screen message is appropriate (g800883)
            launch(hScopeSpec,false);
            hasLaunched = true;
        end
    elseif strcmp(hScopeSpec.getVisible,'on')
        % If we aren't opening it at model start, it might still be
        % open already.  Fire the listener to reinitialize the
        % 'Update' block method.
        setUpdateMethod(hScopeSpec,true);
    end
end

if hasLaunched

    fw = this.UnifiedScope;
    hSource = fw.DataSource;

    % If we need to run mdlStart on the source, do it now.
    if runMdlStart

        mdlStart(hSource,rto);
        if strcmp(hSource.ErrorStatus,'failure')        
            screenMsg(fw,hSource.ErrorMsg);
            this.FigureOpen = '0'; % closed
        end
        if openScopeOnStart
            visible(fw,'on');
        end
    end

end

if ~isempty(hScopeSpec)
    % Specification start method could perform actions such as disabling
    % widgets associated with non-tunable parameters.
    mdlStart(hScopeSpec);
end

end % function

function prepareForStart(hSource)

    hSource.CachedNumInputs = getNumInputs(hSource); % Cache for performance

end


function b = isLaunched(this)
b = isa( this.ScopeSpecificationObject.Framework, 'uiscopes.Framework' ) ;
end


