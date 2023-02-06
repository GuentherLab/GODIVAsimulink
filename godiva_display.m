function godiva_display(region,neuralpool,inputnumber)

global GODIVA_x;
regions=fieldnames(GODIVA_x.States);
neuralpools={'PlanCells','ChoiceCells','InputProjections'};
inputnumbers=cell(1,numel(regions));
for n1=1:numel(regions),
    n=numel(GODIVA_x.States.(regions{n1}).InputProjections);
    inputnumbers{n1}=cellstr([repmat('Input #',[n,1]),num2str((1:n)')]);
end

if nargin<1||isempty(region),region=regions{1};end
if nargin<2||isempty(neuralpool),neuralpool=neuralpools{1};end
if nargin<3||isempty(inputnumber),inputnumber=1;end

regionnumber=strmatch(region,regions,'exact');
neuralpoolnumber=strmatch(neuralpool,neuralpools,'exact');
inputnumber=1;

if isfield(GODIVA_x.States,region)&&isfield(GODIVA_x.States.(region),neuralpool)&&~isempty(GODIVA_x.States.(region).(neuralpool))
    nfigures=1+rem(numel(findobj(0,'tag',mfilename)),8);
    handles.gcf=figure('units','norm','position',[.01+.42*(nfigures>4),.89-(1+rem(nfigures-1,4))*.2,.4,.16],'color','w','menubar','none','numbertitle','off','tag',mfilename);%,'windowbuttondownfcn',@godiva_display_draw);
    handles.h_region=       uicontrol('style','popupmenu','units','norm','position',[.4,.8,.2,.2],'string',regions,'value',regionnumber,'callback',@godiva_display_draw);
    handles.h_neuralpool=   uicontrol('style','popupmenu','units','norm','position',[.6,.8,.2,.2],'string',neuralpools,'value',neuralpoolnumber,'callback',@godiva_display_draw);
    handles.h_inputnumber=  uicontrol('style','popupmenu','units','norm','position',[.8,.8,.2,.2],'string',inputnumbers{regionnumber},'value',inputnumber,'callback',@godiva_display_draw);
    handles.regions=regions;
    handles.neuralpools=neuralpools;
    handles.inputnumbers=inputnumbers;
    set(handles.gcf,'userdata',handles);
    godiva_display_draw;
end
end

function godiva_display_draw(varargin)
global GODIVA_x
if ~nargin, handles=get(gcf,'userdata');
elseif nargin==1, handles=get(varargin{1},'userdata'); 
else handles=get(gcbf,'userdata'); end

regions=fieldnames(GODIVA_x.States);
inputnumbers=cell(1,numel(regions));
for n1=1:numel(regions),
    n=numel(GODIVA_x.States.(regions{n1}).InputProjections);
    inputnumbers{n1}=cellstr([repmat('Input #',[n,1]),num2str((1:n)')]);
end

regionnumber=get(handles.h_region,'value');
neuralpoolnumber=get(handles.h_neuralpool,'value');
set(handles.h_inputnumber,'string',inputnumbers{regionnumber},'value',min(get(handles.h_inputnumber,'value'),numel(inputnumbers{regionnumber})));
inputnumber=get(handles.h_inputnumber,'value');
region=handles.regions{regionnumber};
neuralpool=handles.neuralpools{neuralpoolnumber};
fullname=[region,' ',neuralpool]; if strcmp(neuralpool,'InputProjections'), fullname=[fullname, ' Input #',num2str(inputnumber)]; end

if strcmp(neuralpool,'InputProjections'), set(handles.h_inputnumber,'visible','on'); else set(handles.h_inputnumber,'visible','off'); end
set(handles.gcf,'name',fullname);

columns=GODIVA_x.States.(region).Columns;
if ~isfield(GODIVA_x.States,region)||~isfield(GODIVA_x.States.(region),neuralpool)
    x=[];
elseif ~strcmp(neuralpool,'InputProjections'),
    x=GODIVA_x.States.(region).(neuralpool)';
else
    x=GODIVA_x.States.(region).(neuralpool)(inputnumber).Data';
    if size(x,2)~=numel(columns), columns=ones(size(x,2),1); end
end

if ~isempty(x)
    x0=x;
    ncolumns=max(columns);
    if ncolumns>1,
        x=.95*x/max(x(:))+repmat(columns'-1,[size(x,1),1]);
    end
    [sx,idx1]=sortrows(x');idx2=[1;1+find(~all(sx(2:end,:)==sx(1:end-1,:),2))]; sx=sx(flipud(idx2),:)'; % skip redundant lines drawn
    figure(handles.gcf);
    plot(0:size(x,1)-1,sx);
    box off; set(gca,'units','norm','position',[.1,.3,.8,.4]);
    set(gca,'xlim',[0,size(x,1)-1]);
    if ncolumns>1, set(gca,'ylim',[0,ncolumns+.99]); end
    xlabel('\fontsize{14}Time (ms)');
    if ncolumns>1, ylabel({'\fontsize{14}Activation','\fontsize{8}for each zone'});
    else ylabel('\fontsize{14}Activation'); end
    if size(x,2)>1,%strcmp(neuralpool,'PlanCells')||strcmp(neuralpool,'ChoiceCells')||inputnumber==1||inputnumber==2
        switch(region)
            case 'PreSMA'
                labels=GODIVA_x.network.frames.labels;
            case 'IFS'
                labels=GODIVA_x.network.phonemes.labels;
            case 'SMA'
                labels=GODIVA_x.network.positions.labels;
            case 'PMC'
                labels=GODIVA_x.network.productions.labels;
        end
        idxmax1=accumarray([repmat((1:size(x,1))',[size(x,2),1]),reshape(repmat(columns',[size(x,1),1]),[],1)],x0(:),[],@max,nan);
        idxmax2=x0==idxmax1(:,columns)&x0>0;
        for n1=1:size(x0,1),
            idx1=find(idxmax2(n1,:));
            if ~isempty(idx1), nmax=sum(accumarray([columns(idx1),1+rem(idx1'-1,numel(labels))],1)>0,2); end
            for n2=1:numel(idx1),
                idx2=find(idxmax2(n1+1:end,idx1(n2))==0,1,'first');
                if isempty(idx2), idx2=size(x,1)-n1; end
                idxmax2(n1:n1+idx2,idx1(n2))=0;
                if nmax(columns(idx1(n2)))>1, label='';
                else label=['/',labels{1+rem(idx1(n2)-1,numel(labels))},'/']; end
                %disp(label);
                text(n1+(idx2-1)/2-1,x(n1+round((idx2-1)/2),idx1(n2)),label,'horizontalalignment','center');
            end
        end
    end
end


end
