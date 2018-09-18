function vipblk_nd_compatible
if ~strcmp(get_param(gcb,'tag'),'vipblks_nd')
    set_param(gcb,'tag','vipblks_nd');
    set_param(gcbh,'imagePorts','Separate color signals');
end
