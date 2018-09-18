function load(this)
%LOAD Load function for the Video Viewer block
%   Copyright 2015 The MathWorks, Inc.
%   If a given Scope was serialized before 16a, then this method
%   should be called in order to perform various
%   necessary upgrades to the serialized Scope, so that it works
%   correctly in 16a and later.

block = this.Handle;
block_diagram_handle = bdroot(block);
scopeSpec = get_param(block,'ScopeSpecificationObject');
scopeCfgString = get_param(block,'ScopeSpecificationString');
ud = get_param( block, 'UserData' );

if ~isempty(ud) || isempty(scopeCfgString)
    
    % 15a and earlier used the 'UserData' parameter -- check to see if it
    % exists, and if so, update to current spec and clear UserData
    if (isstruct( ud ) && isfield( ud, 'Scope' ))
        scopeSpec = get_param(block,'ScopeSpecification');
        if isempty(scopeSpec)
            % Transfer scopeCfg from UserData to param
            if isprop(ud.Scope,'ScopeCfg')
                scopeSpec = ud.Scope.ScopeCfg;
            elseif ~isempty(scopeCfgString)
                scopeSpec = eval(scopeCfgString);
            else
                scopeSpec = vipscopes.VideoViewerScopeCfg;
            end
        end
        scopeCfgString = scopeSpec.toString(false, true);
        % Clean-up UserData
        set_param(block,'UserData',[],'UserDataPersistent','off');
    else
        scopeSpec = vipscopes.VideoViewerScopeCfg;
        scopeCfgString = scopeSpec.toString(false, true);
        set_param(block,'UserData',[],'UserDataPersistent','off');
    end
    
    % Older models might have loaded a ScopeSpec object immediately, and
    % need to be cleaned up.
    if ~isempty(scopeSpec)
        
        % Old models might have loaded a ScopeBlock object which needs to be
        % deleted
        if ~isempty(scopeSpec.Scope)
            delete(scopeSpec.Scope);
            scopeSpec.Scope = [];
            scopeSpec.Block = [];
        end
        
        % Ensure scope spec has access to the block
        scopeSpec.Block = this;
        
        % For pre-15a existing models that have saved configuration, we
        % need to make sure the DefaultConfigurationName is set to
        % the correct configuration class file.
        
        set_param(block, ...
            'DefaultConfigurationName',class(scopeSpec), ...
            'ScopeSpecificationObject',scopeSpec, ...
            'ScopeSpecification',[]);
    end
    
    set_param(block, 'ScopeSpecificationString', scopeCfgString);
    
    % Remove block callbacks we may have defined in Scopes belonging to
    % pre-15a models. These are handled via coreblock now.
    resetCallbacks(block,'OpenFcn');
    resetCallbacks(block,'DeleteFcn');
    resetCallbacks(block,'PreDeleteFcn');
    resetCallbacks(block,'NameChangeFcn');
    resetCallbacks(block,'PreSaveFcn');
    resetCallbacks(block,'CloseFcn');
    resetCallbacks(block,'DestroyFcn');
    resetCallbacks(block,'CopyFcn');
    
else
    if isempty(scopeSpec)
        scopeSpec = eval(scopeCfgString);
    end
    scopeSpec.Block = this;
    set_param(block, ...
        'DefaultConfigurationName',class(scopeSpec), ...
        'ScopeSpecificationObject',scopeSpec, ...
        'ScopeSpecification',[]);
end

% Return early if block is in a library
% (All libraries are unlocked during load time, so only check
% block diagram type -- checking 'lock' would always return 'off')
if strcmp(get_param(block_diagram_handle,'BlockDiagramType'),'library')
    return;
end

visibleAtModelOpen = strcmp(scopeSpec.VisibleAtModelOpen,'on');

if visibleAtModelOpen
    mdlObj = get_param(block_diagram_handle,'Object');
    preShowCallBackExists = true;
    this.PreShowCallbackExists = preShowCallBackExists;
    callBack = @() open(this, preShowCallBackExists);
    mdlObj.addCallback('PreShow',['Scope',num2hex(block)],callBack);
end

end
