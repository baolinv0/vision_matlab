classdef VideoViewerConfiguration < Simulink.scopes.BlockScopeConfiguration
    % SCOPECONFIGURATION Configuration object for the Scope
    %   This object is used to configure the Scope programmatically.
    %   Click on a Scope block and use
    %   get_param(gcb,'ScopeConfiguration') to get the object.
    
    %   Copyright 2015 The MathWorks, Inc.
    properties
        CData
        MapExpression
        Magnification
    end
    
    methods(Hidden)
        function props = getDisplayProperties(this)            
            props = {'Name','Position','Visible','CData','MapExpression','Magnification'} ;
        end
    end
    
    methods
        
        function this = VideoViewerConfiguration(varargin)
                    this@Simulink.scopes.BlockScopeConfiguration(varargin{:});
        end
        
        function value = get.CData(this)
           value = [];
           if isLaunched(this.Specification)
               fw = getUnifiedScope(this.Specification);
               value = get(fw.Visual.Image,'CData');
           end 
        end
        
        % get for MapExpression
        % The colormap should be set using the block parameters useColormap and
        % colorMapValue
        function value = get.MapExpression(this)
            value = getScopeParam(this.Specification,'Visuals','Video',...
                'ColorMapExpression');
        end       
        
        function value = get.Magnification(this)
            value = getScopeParam(this.Specification, 'Tools','Image Navigation Tools',...
                'Magnification');
        end
        
        function set.Magnification(this,value)
            if (isscalar(value) && value > 0)
                if isLaunched(this.Specification)
                    setScopeParam(this.Specification,'Tools','Image Navigation Tools',...
                        'Magnification',value);
                else
                    setScopeParamOnConfig(this.Specification,'Tools','Image Navigation Tools',...
                        'Magnification',value);
                end
            else
                 msgObj = message('Spcuilib:configuration:InvalidSetting',...
                     'Magnification',getBlockName(this),getString(...
                     message('vision:block:InvalidMagnificationSetting')));
                 throwAsCaller(MException(msgObj));
            end
        end
        
    end
    
end

