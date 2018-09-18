function pcwrite(varargin)
%pcwrite Write a 3-D point cloud to PLY or PCD file.
%   PCWRITE(ptCloud, filename) writes a pointCloud object, ptCloud, to a 
%   PLY or PCD file specified by the string filename. If an extension is 
%   not specified for filename, then the .ply extension is used.
% 
%   PCWRITE(ptCloud, filename, 'Encoding', encodingType) lets you specify
%   the type of character encoding for the output file. Valid values for
%   encodingType are specified as a string and are as follows:
%
%                File Format    Valid Encodings
%                -----------    ---------------------------------
%                   PCD         'ascii' , 'binary' , 'compressed'
%                   PLY         'ascii' , 'binary' 
%
%                Default: 'ascii'
%
%   Example : Write a point cloud to a PCD file from a PLY file
%   ------------------------------------------------------------
%   ptCloud = pcread('teapot.ply'); % read from a PLY file
%   pcwrite(ptCloud,'teapot.pcd');  % re-write the data to PCD format
%
%   See also pointCloud, pcread, pcshow 
 
%  Copyright 2015-2016 The MathWorks, Inc.

% Minimum of 2 inputs and a maximum of 4 inputs
narginchk(2,4);

% Validate the inputs
[ptCloud, filename, format] = validateAndParseInputs(varargin{:});

% Validate the file extension.
ext = getExtFromFilename(filename);

% Check if a different file extension is given
if( ~isempty(ext) && ~(strcmpi(ext, 'ply') || strcmpi(ext, 'pcd')) )
    error(message('vision:pointcloud:unsupportedFileExtension'));
end

% If no extension is specified, use .ply extension
if (isempty(ext))
    filename = [filename, '.ply'];
    ext = 'ply';        
end

% Check for the supported encoding in ply files
if (strcmpi(ext,'ply') && strcmpi(format, 'compressed'))    
    error(message('vision:pointcloud:encodingNotSupported'));
end

% Verify that the file can be written.
fid = fopen(filename, 'a');
if (fid == -1)
    error(message('MATLAB:imagesci:imwrite:fileOpen', filename));
else
    % File can be created.  Get full filename.
    filename = fopen(fid);
    fclose(fid);
end

if (strcmpi(ext,'ply'))
    
    % PLY file does not recognize invalid points.
    pc = removeInvalidPoints(ptCloud);    
   
    % Little endian is the default setvalidatestringting for binary format
    if strcmpi(format, 'binary')
        format = 'binary_little_endian';
    end

    % Write 'vertex' with existing properties
    elementName = 'vertex';
    propertyNames = {'x','y','z'};
    propertyValues = {pc.Location(:,1), pc.Location(:,2), pc.Location(:,3)};
    if ~isempty(pc.Color)
        propertyNames = [propertyNames, {'red','green','blue'}];
        propertyValues = [propertyValues, {pc.Color(:,1),...
                            pc.Color(:,2), pc.Color(:,3)}];
    end
    if ~isempty(pc.Normal)
        propertyNames = [propertyNames, {'nx','ny','nz'}];
        propertyValues = [propertyValues, {pc.Normal(:,1),...
                            pc.Normal(:,2), pc.Normal(:,3)}];
    end
    if ~isempty(pc.Intensity)
        propertyNames = [propertyNames, {'intensity'}];
        propertyValues = [propertyValues, {pc.Intensity}];
    end

    visionPlyWrite(filename, format, elementName, propertyNames, propertyValues);
    
elseif (strcmpi(ext,'pcd'))
    propertyNames = {'x','y','z'};
    [~,~,dim] = size(ptCloud.Location);
    if dim == 1
        isOrganized = 0;
    else
        isOrganized = 1;
    end
    
    if isOrganized
        x = ptCloud.Location(:,:,1)';
        y = ptCloud.Location(:,:,2)';
        z = ptCloud.Location(:,:,3)';
        
        propertyValues = {x(:), y(:), z(:)};
        
        [height, width, ~] = size(ptCloud.Location);
        
    else
        
        propertyValues = {ptCloud.Location(:,1), ptCloud.Location(:,2), ptCloud.Location(:,3)};      
        
        [width, ~] = size(ptCloud.Location);
        height = 1;

    end
    
    if ~isempty(ptCloud.Color)
        % Supports the color information in the PCD standared rgb format
        % If the color information needs to be wriiten separately, please
        % provide the names as {'r','g','b'} instead of {'rgb'}. Also
        % set the isRGBA to 0
        propertyNames = [propertyNames, {'rgb'}];
        
        if isOrganized
            r = ptCloud.Color(:,:,1)';
            g = ptCloud.Color(:,:,2)';
            b = ptCloud.Color(:,:,3)';  
        else
            r = ptCloud.Color(:,1);
            g = ptCloud.Color(:,2);
            b = ptCloud.Color(:,3);
        end

        [m,n,d] = size(r);
        % Combine r,g,b,a
        rgba = bitor(bitor(bitor(bitshift(uint32(zeros(m,n,d)),24),...
            bitshift(uint32(r),16)), bitshift(uint32(g),8) ), uint32(b));
        propertyValues = [propertyValues, {rgba(:)}];
    end
    
    if ~isempty(ptCloud.Normal)
        propertyNames = [propertyNames, {'normal_x','normal_y','normal_z'}];
        
        if isOrganized
             nx = ptCloud.Normal(:,:,1)';
             ny = ptCloud.Normal(:,:,2)';
             nz = ptCloud.Normal(:,:,3)';
             propertyValues = [propertyValues, {nx(:),ny(:),nz(:)}]; 
        else
             propertyValues = [propertyValues, {ptCloud.Normal(:,1),...
                            ptCloud.Normal(:,2), ptCloud.Normal(:,3)}];            
        end
    end    
    
    if ~isempty(ptCloud.Intensity)
        propertyNames = [propertyNames, {'intensity'}];        
        propertyValues = [propertyValues, {ptCloud.Intensity'}];           
    end

    if strcmpi(format, 'compressed')
        format = 'binary_compressed';
    end
    
    visionPcdWrite(filename, format,propertyNames, propertyValues, height, width);        
end

end

%========================================================================== 
function [ptCloud, filename, format] = validateAndParseInputs(varargin)
% Validate and parse inputs

parser = inputParser;
parser.FunctionName  = mfilename;

parser.addRequired('ptCloud', @(x)validateattributes(x, {'pointCloud'},{}));
parser.addRequired('filename', @(x)validateattributes(x, {'char','string'},{'nonempty'}));
parser.addParameter('Encoding', '');
parser.addParameter('PLYFormat', '');

parser.parse(varargin{:});

ptCloud = parser.Results.ptCloud;
filename = parser.Results.filename;

if isstring(filename)
    filename = char(filename);
end

list = {'ascii', 'binary', 'compressed'};
if ~isempty(parser.Results.Encoding)
    format = validatestring(parser.Results.Encoding, list, mfilename, 'Encoding');
elseif ~isempty(parser.Results.PLYFormat)
    format = validatestring(parser.Results.PLYFormat, list, mfilename, 'PLYFormat');    
else
    format = 'ascii';
end

end   

%==========================================================================
function ext = getExtFromFilename(filename)
% Get file extension from string
ext = '';

idx = find(filename == '.');

if (~isempty(idx))  
    ext = filename((idx(end) + 1):end);    
end
end