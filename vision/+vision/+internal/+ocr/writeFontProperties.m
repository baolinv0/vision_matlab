function writeFontProperties(fontnames, outputdir, props)
% Writes a file named <fontname>.tr with the following information:
% <fontname> <italic> <bold> <fixed> <serif> <fraktur>

fontnames = cellstr(fontnames);

if nargin == 2 || isempty(props)            
    props.isItalic  = false;
    props.isBold    = false;   
    props.isFixed   = false;
    props.isSerif   = false;
    props.isFraktur = false;
    
    props = repmat(props, 1, numel(fontnames));
end

filename   = fullfile(outputdir, strcat('font_properties'));
[fid, msg] = fopen(filename, 'w', 'native', 'UTF-8');
closeFile  = onCleanup(@()fclose(fid));

if fid < 0
    error(msg);
end

for i = 1:numel(fontnames)
    fprintf(fid, '%s %d %d %d %d %d\n', ...
        fontnames{i}, ...
        props(i).isItalic, ...
        props(i).isBold, ...
        props(i).isFixed, ...
        props(i).isSerif, ...
        props(i).isFraktur);    
end