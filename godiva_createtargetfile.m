function godiva_createtargetfile
global GODIVA_x;

% loads network information
[a,b,d,c]=textread('godiva_phonemes.csv','%n%s%s%s%*[^\n]','delimiter',',','headerlines',1);
idx=find(a);
GODIVA_x.network.phonemes.index=a(idx);
GODIVA_x.network.phonemes.labels=b(idx);
GODIVA_x.network.phonemes.labels_ipa=d(idx);
GODIVA_x.network.phonemes.phonemetypes=c(idx);

[a,b,c1,c2,c3,c4,c5,c6,c7]=textread('godiva_frames.csv','%n%s%s%s%s%s%s%s%s%*[^\n]','delimiter',',','headerlines',1);
idx=find(a);
GODIVA_x.network.frames.index=a(idx);
GODIVA_x.network.frames.labels=b(idx);
GODIVA_x.network.frames.phonemetypes=[c1(idx),c2(idx),c3(idx),c4(idx),c5(idx),c6(idx),c7(idx)];
    
n_positions=7;
n_phonemes=numel(GODIVA_x.network.phonemes.index);
n_frames=numel(GODIVA_x.network.frames.index);

try
    filename=which(mfilename);
    [filepath,filename,fileext]=fileparts(filename);
    temp=load(fullfile(filepath,'godiva_targets.mat'),'target'); handles.data=temp.target; 
%     if ~isfield(handles.data,'labels'),
%         for idx=1:numel(handles.data.phonemes), handles.data.labels{idx,1}=strcat(handles.data.phonemes{idx}{:}); end
%     end
%     if ~isfield(handles.data,'str'),
%         handles.data.str=godiva_createtargetfile_data2text(handles.data);
%     end
catch
    handles.data=struct('frames',{{}},'phonemes',{{}},'labels',{{}},'str',{{}});
end
handles.vowels=GODIVA_x.network.phonemes.labels(strfind(cat(1,GODIVA_x.network.phonemes.phonemetypes{:})','V'));
handles.consonants=GODIVA_x.network.phonemes.labels(strfind(cat(1,GODIVA_x.network.phonemes.phonemetypes{:})','C'));
handles.hfig=figure('units','norm','position',[.1,.1,.3,.8],'color','w','menubar','none','numbertitle','off','name','godiva: Create Word Input');
uicontrol('style','frame','units','norm','position',[.2,.35,.6,.45]);
uicontrol('style','text','units','norm','position',[.2,.8,.6,.03],'string','edit syllable','horizontalalignment','left','backgroundcolor','w');
handles.htext=uicontrol('style','edit','unit','norm','position',[.2,.15,.6,.1],'max',2,'string',handles.data.str,'horizontalalignment','left','backgroundcolor','w','foregroundcolor',.5*[1,1,1],'callback',{@godiva_createtargetfile_update,'edit'});
handles.htextword=uicontrol('style','text','units','norm','position',[.0,.9,1,.1],'string','','horizontalalignment','left','foregroundcolor','w','backgroundcolor','k','fontweight','bold','fontsize',14,'horizontalalignment','center');
uicontrol('style','text','unit','norm','position',[.2,.25,.6,.03],'string','Word input representation: godiva_targets.txt file','horizontalalignment','left','backgroundcolor','w','foregroundcolor',.5*[1,1,1]);
handles.hadd=uicontrol('style','pushbutton','unit','norm','position',[.2,.3,.2,.04],'string','Add','callback',{@godiva_createtargetfile_update,'add'},'enable','off');
handles.hremove=uicontrol('style','pushbutton','unit','norm','position',[.4,.3,.2,.04],'string','Remove','callback',{@godiva_createtargetfile_update,'remove'},'enable','off');
handles.hmodify=uicontrol('style','pushbutton','unit','norm','position',[.60,.3,.2,.04],'string','Modify','callback',{@godiva_createtargetfile_update,'modify'},'enable','off');
handles.hselect=uicontrol('style','popupmenu','unit','norm','position',[.5,.8,.30,.04],'string',cat(1,{'Select syllable'},handles.data.labels),'callback',{@godiva_createtargetfile_update,'select'},'value',1,'enable','off');
handles.hdone=uicontrol('style','pushbutton','unit','norm','position',[.6,.01,.2,.04],'string','Done','callback',{@godiva_createtargetfile_update,'done'});
handles.hclear=uicontrol('style','pushbutton','unit','norm','position',[.2,.01,.2,.04],'string','Clear all','callback',{@godiva_createtargetfile_update,'clear'});
handles.hcancel=uicontrol('style','pushbutton','unit','norm','position',[.4,.01,.2,.04],'string','Cancel','callback',{@godiva_createtargetfile_update,'cancel'});
handles.hframe=uicontrol('style','popupmenu','unit','norm','position',[.3,.75,.4,.04],'string',cat(1,{'Select structural frame'},GODIVA_x.network.frames.labels),'callback',{@godiva_createtargetfile_update,'frame'},'value',1);
for n1=1:n_positions,
    handles.hphonemepos(n1)=uicontrol('style','text','unit','norm','position',[.3,.75-.05*n1,.1,.04],'string',[num2str(n1),':'],'visible','off','horizontalalignment','center');
    handles.hphoneme(n1)=uicontrol('style','popupmenu','unit','norm','position',[.4,.75-.05*n1,.3,.04],'string',cat(1,{'Select phoneme'},GODIVA_x.network.phonemes.labels),'callback',{@godiva_createtargetfile_update,'phoneme',n1},'value',1,'visible','off');
end
if get(handles.hselect,'value')>1, set([handles.hremove,handles.hmodify],'enable','on');
else set(handles.hremove,'enable','off'); end
if isempty(handles.data.frames), set(handles.hselect,'string',{'Select syllable'},'enable','off','value',1); set(handles.htextword,'string','');
else set(handles.hselect,'string',cat(1,{'Select syllable'},handles.data.labels),'enable','on','value',1); set(handles.htextword,'string',sprintf('%s-',handles.data.labels{:}));end
set(handles.hfig,'userdata',handles);
end

function str=godiva_createtargetfile_data2text(data)
n_positions=7;
str={};
str{end+1}='#phonemes';
for n1=1:n_positions
    tstr='';
    for n2=1:numel(data.frames),
        if ~isempty(data.phonemes{n2}{n1}),
            tstr=cat(2,tstr,data.phonemes{n2}{n1},' ');
        end
    end
    if ~isempty(tstr)
        str{end+1}=[num2str(n1),' ',tstr];
    end
end
str{end+1}='#frames';
tstr='';
for n2=1:numel(data.frames),
    tstr=cat(2,tstr,data.frames{n2},' ');
end
if ~isempty(tstr), str{end+1}=tstr; end
end

function godiva_createtargetfile_update(varargin)
global GODIVA_x;
if 1||isempty(varargin{1}), handles=get(gcbf,'userdata');
else handles=get(varargin{1},'userdata'); end
switch(varargin{3}),
    case 'clear',
        handles.data=struct('frames',{{}},'phonemes',{{}},'labels',{{}});
        set(handles.hphoneme,'value',1);
        handles.data.str=godiva_createtargetfile_data2text(handles.data);
        set(handles.htext,'string',handles.data.str);
        set(handles.hselect,'value',1);
        if get(handles.hselect,'value')>1, set([handles.hadd,handles.hremove,handles.hmodify],'enable','on');
        else set([handles.hadd,handles.hremove,handles.hmodify],'enable','off'); end
        if isempty(handles.data.frames), set(handles.hselect,'string',{'Select syllable'},'enable','off','value',1);set(handles.htextword,'string','');
        else set(handles.hselect,'string',cat(1,{'Select syllable'},handles.data.labels),'enable','on','value',1); set(handles.htextword,'string',sprintf('%s-',handles.data.labels{:})); end
    case 'cancel',
        close(handles.hfig);
        return
    case 'done',
        filename=which(mfilename);
        [filepath,filename,fileext]=fileparts(filename);
        fh=fopen(fullfile(filepath,'godiva_targets.txt'),'wt');
        for n1=1:numel(handles.data.str),
            fprintf(fh,'%s\n',handles.data.str{n1});
        end
        fclose(fh);
        target=handles.data; save(fullfile(filepath,'godiva_targets.mat'),'target');
        close(handles.hfig);
        return
    case 'edit',
        handles.data.str=cellstr(get(handles.htext,'string'));
    case 'select',
        n=get(handles.hselect,'value')-1;
        if n>0,
            frames=get(handles.hframe,'string');
            nframe=strmatch(handles.data.frames{n,1},frames,'exact');nframe=nframe(1);
            set(handles.hframe,'value',nframe);
            for n1=1:numel(handles.hphoneme),
                if ~isempty(GODIVA_x.network.frames.phonemetypes{nframe-1,n1})
                    if strcmp(GODIVA_x.network.frames.phonemetypes{nframe-1,n1},'V'), str=cat(1,{'Select Vowel'},handles.vowels); else str=cat(1,{'Select Consonant'},handles.consonants); end
                    set(handles.hphoneme(n1),'string',str,'visible','on');
                    set(handles.hphonemepos(n1),'visible','on');
                else
                    set(handles.hphoneme(n1),'visible','off');
                    set(handles.hphonemepos(n1),'visible','off');
                end
                phonemes=get(handles.hphoneme(n1),'string');
                if ~isempty(handles.data.phonemes{n,1}{n1}),
                    nphoneme=strmatch(handles.data.phonemes{n,1}{n1},phonemes,'exact');nphoneme=nphoneme(1);
                    set(handles.hphoneme(n1),'value',nphoneme,'visible','on');
                    set(handles.hphonemepos(n1),'visible','on');
                else
                    set(handles.hphoneme(n1),'visible','off');
                    set(handles.hphonemepos(n1),'visible','off');
                end
            end
        end
        if get(handles.hselect,'value')>1, set([handles.hadd,handles.hremove,handles.hmodify],'enable','on');
        else set([handles.hremove,handles.hmodify],'enable','off'); end
    case 'remove',
        n=get(handles.hselect,'value')-1;
        if n>0,
            idx=[1:n-1,n+1:numel(handles.data.frames)];
            handles.data.frames=handles.data.frames(idx);
            handles.data.phonemes=handles.data.phonemes(idx);
            handles.data.labels=handles.data.labels(idx);
        end
        handles.data.str=godiva_createtargetfile_data2text(handles.data);
        set(handles.htext,'string',handles.data.str);
        set(handles.hselect,'value',1);
        if get(handles.hselect,'value')>1, set([handles.hadd,handles.hremove,handles.hmodify],'enable','on');
        else set([handles.hremove,handles.hmodify],'enable','off'); end
        if isempty(handles.data.frames), set(handles.hselect,'string',{'Select syllable'},'enable','off','value',1); set(handles.htextword,'string','');
        else set(handles.hselect,'string',cat(1,{'Select syllable'},handles.data.labels),'enable','on','value',1); set(handles.htextword,'string',sprintf('%s-',handles.data.labels{:})); end
    case {'add','modify'}
        idx=0;
        frames=get(handles.hframe,'string');
        nframe=get(handles.hframe,'value');
        if nframe>1
            frame=frames{nframe};
            if strcmp(varargin{3},'add')
                idx=numel(handles.data.frames)+1;
            else
                idx=get(handles.hselect,'value')-1;
            end
            if idx>0
                handles.data.frames{idx,1}=frame;
                for n1=1:numel(handles.hphoneme),
                    phonemes=get(handles.hphoneme(n1),'string');
                    nphoneme=get(handles.hphoneme(n1),'value');
                    if strcmp(get(handles.hphoneme(n1),'visible'),'on')&&nphoneme>1
                        phoneme=phonemes{nphoneme};
                        handles.data.phonemes{idx,1}{n1}=phoneme;
                    else
                        handles.data.phonemes{idx,1}{n1}=[];
                    end
                end
                handles.data.labels{idx,1}=strcat(handles.data.phonemes{idx}{:});
            end
        end
        handles.data.str=godiva_createtargetfile_data2text(handles.data);
        set(handles.htext,'string',handles.data.str);
        if isempty(handles.data.frames), set(handles.hselect,'string',{'Select syllable'},'enable','off','value',1); set(handles.htextword,'string','');
        else set(handles.hselect,'string',cat(1,{'Select syllable'},handles.data.labels),'enable','on','value',idx+1); set(handles.htextword,'string',sprintf('%s-',handles.data.labels{:})); end
        if get(handles.hselect,'value')>1, set([handles.hadd,handles.hremove,handles.hmodify],'enable','on');
        else set([handles.hremove,handles.hmodify],'enable','off'); end
    case {'frame','phoneme'}
        frames=get(handles.hframe,'string');
        nframe=get(handles.hframe,'value');
        filled=1;
        if nframe>1
            for n1=1:numel(handles.hphoneme),
                if ~isempty(GODIVA_x.network.frames.phonemetypes{nframe-1,n1})
                    if strcmp(GODIVA_x.network.frames.phonemetypes{nframe-1,n1},'V'), str=cat(1,{'Select Vowel'},handles.vowels); else str=cat(1,{'Select Consonant'},handles.consonants); end
                    set(handles.hphoneme(n1),'string',str,'visible','on');
                    set(handles.hphonemepos(n1),'visible','on');
                    filled=filled&(get(handles.hphoneme(n1),'value')>1);
                else
                    set(handles.hphoneme(n1),'visible','off');
                    set(handles.hphonemepos(n1),'visible','off');
                end
            end
        else
            filled=0;
            for n1=1:numel(handles.hphoneme),
                set(handles.hphoneme(n1),'visible','off');
                set(handles.hphonemepos(n1),'visible','off');
            end
        end
        if filled, set([handles.hadd],'enable','on'); else set([handles.hadd],'enable','off'); end
        if get(handles.hselect,'value')>1&&filled, set([handles.hadd,handles.hremove,handles.hmodify],'enable','on');
        else set([handles.hremove,handles.hmodify],'enable','off'); end
end
set(handles.hfig,'userdata',handles);
end
