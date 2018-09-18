function visionblockhelp
% VISIONBLOCKHELP Blockset on-line help function.
%   Points help browser to the help page for the current Simulink block.
%   Its intended use is in blockset blocks.  A block can be enabled to
%   use this function by issuing the following command:
%      set_param(gcbh,'MaskHelp','eval(''visionblockhelp'');');

% Copyright 2001-2010 The MathWorks, Inc.

% Prerequisites for use of this function:
%
% 1.) vipbherr.html must be located in 
%     toolbox/vision/vision
%
% 2.) vipobsoleteblocks, vip<blockname> tags must exist in the
%     documentation for a particular block
%
% <blockname> is a string that corresponds to the name of the block that's
% all lower case and without spaces and dashes.  For example, 
% Computer Vision System Toolbox block called '2-D Variance' would have a
% <blockname> set to '2dvariance'
%
% EXCEPTIONS:
% ===========
% This function cannot be used in following block types:
% 1.) when a block is no longer linked to the library from which it 
%     originated
% 2.) when its mask uses an s-function and documentation from a different
%     product (i.e. mask lives in one product and the rest of the block
%     is in another product)
%
% In such cases the command listed below should be placed in the block's
% 'Mask help' which can be accessed through a mask editor:
%    helpview(fullfile(docroot,'toolbox','vision','vision.map'),
%                     '<doc_tag>');

mapfile_location = fullfile(docroot,'toolbox','vision','vision.map');
% Note that we don't check for existence of map files. On Japanese
% Windows, the actual file does not exist, but helpview properly falls
% back to the English map file. See geck 323905 for more details.

% Derive help file name from mask type:
doc_tag = getblock_help_file(gcbh);
helpview(mapfile_location, doc_tag);

% --------------------------------------------------------
function libname = get_lib_name(blk)

refBlock = get_param(blk,'ReferenceBlock');
if ~isempty(refBlock)
   libname = strtok(refBlock, '/');
else
    % Not a linked library block (the block link is disabled or broken).
    % Check if block has an ancestor (i.e. indicates it is a disabled link).
    % If so, use the ancestor block information for library block help page.
    ancBlock = get_param(blk,'AncestorBlock');
    
    if ~isempty(ancBlock) 
        % Use ancestor library block info
        libname = strtok(ancBlock, '/');
    else
        % Use present parent (sub)system directly
        libname = get_param(blk,'Parent'); 
    end
end

% --------------------------------------------------------
function help_file = getblock_help_file(blk)

% Get all library names
s = vision.internal.librarylist;

% Get Computer Vision System Toolbox libraries with Reference Pages
libs_with_ref_page = [s.current, s.toremove]; % include obsolete blocks

libname = get_lib_name(blk);

% s.current list of libraries for a product must hold the library named
% in libname string
if isempty(strcmp(libname,libs_with_ref_page))
    % No online help is available.  This must be an old block, that
    % does not exist any more.
    v = ver('vision');
    product_name = v.Name;
    error(message('vision:blocksethelp:obsoleteBlock', product_name));
else
    % Only masked blocks call visionblockhelp, so if we get here, we know 
    % we can get the MaskType string:
    fileStr = get_param(blk,'MaskType');
end

if strncmp(libname, 'vip',3)
    doc_prefix = 'vip';
else
    doc_prefix = 'vision';
end

help_file = [doc_prefix help_name(fileStr)];

return

% ---------------------------------------------------------
function y = help_name(x)
% Returns proper help tag
%
% Invoke same naming convention as used with the auto-generated help 
% conversions for the blockset on-line manuals.
%
% - only allow a-z, 0-9, and underscore

if isempty(x), x='default'; end
y = lower(x);

digit_idx      = (y>='0' & y<='9');
underscore_idx = (y=='_');
valid_char_idx = isletter(y) | digit_idx | underscore_idx;

y(~valid_char_idx) = '';  % Remove invalid characters

return

