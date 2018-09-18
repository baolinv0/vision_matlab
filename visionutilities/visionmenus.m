function schema = visionmenus( funcname, cbinfo )
%   Copyright 2015 The MathWorks, Inc.
    fnc = str2func(funcname);
    schema = fnc(cbinfo);
end

function schema = MPlayVideoViewer( ~ ) %#ok<DEFNU>
    schema          = sl_action_schema;
    schema.tag      = 'Simulink:MPlayVideoViewer';
    schema.label    = DAStudio.message( 'Simulink:studio:MPlayVideoViewer' );
    schema.callback = @MPlayVideoViewerCB;
    schema.autoDisableWhen = 'Busy';
end

function MPlayVideoViewerCB( ~ ) % ( cbinfo )
    implay;
end

% EOF
