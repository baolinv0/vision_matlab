% Internal implementation of getDefaultFont
function defaultFont = getDefaultFont()

  % pick 'LucidaSansRegular' if it exists; otherwise pick the first entry
  % in fontinfo
  cellFonts = vision.internal.getFontNamesInCell();
  idx = strncmp('LucidaSansRegular',cellFonts,length('LucidaSansRegular'));
  
  if any(idx) % any works even if idx is empty
      % LucidaSansRegular font exists
      defaultFont = cellFonts{idx};
  else
      if (~isempty(idx))
          defaultFont = cellFonts{1};
      else
          defaultFont = '';
      end      
  end  
