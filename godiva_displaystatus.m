%% status graphic display 
function godiva_displaystatus(block)
  global GODIVA_x;
  
  % runtime control
  if ~isfield(GODIVA_x,'control')||~isfield(GODIVA_x.control,'pause'), GODIVA_x.control.pause=0; end
  h=findobj(0,'tag',[mfilename,'_control']);
  if isempty(h)
      figure('units','norm','position',[.66,.85,.32,.1],'tag',[mfilename,'_control'],'menubar','none','numbertitle','off','name','godiva simulation control','color','k');
      uicontrol('style','pushbutton','units','norm','position',[.1,.2,.2,.6],'string','pause','fontweight','bold','callback','set_param(gcs,''SimulationCommand'',''pause'');');
      uicontrol('style','pushbutton','units','norm','position',[.3,.2,.2,.6],'string','one step','fontweight','bold','callback','global GODIVA_x; GODIVA_x.control.pause=1; set_param(gcs,''SimulationCommand'',''continue'');');
      uicontrol('style','pushbutton','units','norm','position',[.5,.2,.2,.6],'string','continue','fontweight','bold','callback','set_param(gcs,''SimulationCommand'',''continue'');');      
      uicontrol('style','pushbutton','units','norm','position',[.7,.2,.2,.6],'string','stop','fontweight','bold','callback','set_param(gcs,''SimulationCommand'',''stop'');');      
  end

  % plots
  M1=block.Dwork(1).Data;
  M2=block.Dwork(2).Data;
  columns=block.Dwork(3).Data;
  switch(block.DialogPrm(1).Data)
      case 'IFS'
          labels=GODIVA_x.network.phonemes.labels;
          pos=[.83,.56,.15,.23];
      case 'PreSMA'
          labels=GODIVA_x.network.frames.labels;
          pos=[.83,.28,.15,.23];
      case 'SSM'
          labels=GODIVA_x.network.productions.labels;
          pos=[.83,.0,.15,.23];
  end
  idxmax1=accumarray(columns,M2,[],@max,nan);
  idxmax2=M2==idxmax1(columns)&M2>0;
  idx1=find(idxmax2);
  if ~isempty(idx1)
      label=cell(1,numel(idx1));
      for n2=1:numel(idx1),
          label{n2}=['\bf\color{black}\fontsize{10}','/',labels{1+rem(idx1(n2)-1,numel(labels))},'/',' \rm\color{gray}\fontsize{6} (cell=',num2str(idx1(n2)),', zone=',num2str(columns(idx1(n2))),', act=',num2str(M2(idx1(n2))),')'];
      end
  else
      label={'--'};
  end
  if numel(label)>10, label=cat(2,label(1:10),{'...'}); end
  h=findobj(0,'tag',[mfilename,'_disp_',block.DialogPrm(1).Data,'_Choice']);
  if isempty(h),
      h=figure('units','norm','position',pos,'menubar','none','numbertitle','off','color','w','tag',[mfilename,'_disp_',block.DialogPrm(1).Data,'_Choice'],'name',[block.DialogPrm(1).Data,' ChoiceCells status']);
      clf;
      maxc=max(columns);
      handlesdisplay.text=text(0,0,char(label),'color','k','horizontalalignment','left');
      set(h,'userdata',handlesdisplay);
      axis off;
      set(gca,'xlim',[0,1],'ylim',[-1,1]);
      drawnow
  else
      handlesdisplay=get(h,'userdata');
      set(handlesdisplay.text,'string',char(label));
      drawnow;
  end
  idxmax1=find(M1>0);
  [nill,idxmax2]=sort(M1(idxmax1)+eps*columns(idxmax1),1,'descend');
  idx1=idxmax1(idxmax2);
  if ~isempty(idx1)
      label=cell(1,numel(idx1));
      for n2=1:numel(idx1),
          label{n2}=['\bf\color{black}\fontsize{10}','/',labels{1+rem(idx1(n2)-1,numel(labels))},'/',' \rm\color{gray}\fontsize{6} (cell=',num2str(idx1(n2)),', zone=',num2str(columns(idx1(n2))),', act=',num2str(M1(idx1(n2))),')'];
      end
  else
      label={'--'};
  end
  pos=pos-[.17,0,0,0];
  if numel(label)>10, label=cat(2,label(1:10),{'...'}); end
  h=findobj(0,'tag',[mfilename,'_disp_',block.DialogPrm(1).Data,'_Plan']);
  if isempty(h),
      h=figure('units','norm','position',pos,'menubar','none','numbertitle','off','color','w','tag',[mfilename,'_disp_',block.DialogPrm(1).Data,'_Plan'],'name',[block.DialogPrm(1).Data,' PlanCells status']);
      clf;
      maxc=max(columns);
      handlesdisplay.text=text(0,0,char(label),'color','k','horizontalalignment','left');
      set(h,'userdata',handlesdisplay);
      axis off;
      set(gca,'xlim',[0,1],'ylim',[-1,1]);
      drawnow
  else
      handlesdisplay=get(h,'userdata');
      set(handlesdisplay.text,'string',char(label));
      drawnow;
  end

  h=findobj(0,'tag',[mfilename,'_control']); if ~isempty(h),set(h,'name',['godiva simulation control (t=',num2str(get_param(gcs,'SimulationTime')),')']); end
  if GODIVA_x.control.pause,
      GODIVA_x.control.pause=0;
      set_param(gcs,'SimulationCommand','pause');
  end
end
