% Settings panel
classdef SettingsPanel < vision.internal.uitools.OneButtonPanel
    
   methods
       
       function this = SettingsPanel()                      
           icon = toolpack.component.Icon.SETTINGS_24;
           nameId = 'vision:ocrTrainer:Settings';
           tag = 'Settings';           
           
           this = this@vision.internal.uitools.OneButtonPanel();
           this.createTheButton(icon, nameId, tag);
           this.setToolTip('vision:ocrTrainer:SettingsToolTip');
           
       end
       
   end
end