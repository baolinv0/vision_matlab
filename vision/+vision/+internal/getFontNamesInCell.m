% Internal implementation of getFontNamesInCell
function cellFonts = getFontNamesInCell

% Calls to coder.extrinsic may only appear at the top-level.
coder.extrinsic('listTrueTypeFonts');
persistent cellFontsChache

if isSimMode
  if isempty(cellFontsChache)
      fontStruct = listTrueTypeFonts;
      % now, to remove duplicates (which seems to happen on some unix
      % platforms) UDD enums have to be unique in a case-insensitive way,
      % so we'll uniquify the lowered version, grab the indices, and then
      % use the indices in the original version
      [~,inds] = unique(lower(fontStruct));
      cellFonts = fontStruct(inds); 
      cellFontsChache = cellFonts;
  else
      cellFonts = cellFontsChache;
  end
else
  %  coder.extrinsic('listTrueTypeFonts');
  cellFonts =coder.internal.const(listTrueTypeFonts);
end 

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);