function rgb = colorspec2RGB(str)
% map colorspec string to RGB triplet. Use Line object to do
% the work of converting string to RGB.
persistent converter;
if isempty(converter)
    converter =  matlab.graphics.chart.primitive.Line;
end
try
    if strncmpi(str,'n',1)
        % 'none' is a valid string for Line, but not a valid
        % colorspec. % set to bad Color value for Line to throw
        % error.
        str = 'xx';
    end
    converter.Color = str;
    rgb = converter.Color;
catch ME
    cmd = 'helpview([docroot, filesep, fullfile(''techdoc'',''ref'',''colorspec.html'')])';
    str = getString(message('vision:pointcloud:colorspecInfo'));
    cmdstr = sprintf('<a href="matlab:%s">%s</a>',cmd,str);
    
    error(message('vision:pointcloud:invalidColorspec',cmdstr));
end
