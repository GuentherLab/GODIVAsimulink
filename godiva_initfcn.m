function godiva_initfcn(option)

if nargin<1, option='full'; end
global GODIVA_x;

GODIVA_x.States=struct;
GODIVA_x.run=inf;
delete(findobj(0,'-regexp','tag','godiva_displaystatus[^*]'));
delete(findobj(0,'tag','godiva_display'));

if ~strcmp(option,'full'), return; end
hw=waitbar(0,'Initializing weights and target information','name','godiva');
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

[a,b,c1,c2,c3,c4,c5,c6,c7]=textread('godiva_productions.csv','%n%s%s%s%s%s%s%s%s%*[^\n]','delimiter',',','headerlines',1);
idx=find(a);
GODIVA_x.network.productions.index=a(idx);
GODIVA_x.network.productions.labels=b(idx);
GODIVA_x.network.productions.phonemes=[c1(idx),c2(idx),c3(idx),c4(idx),c5(idx),c6(idx),c7(idx)];

n_positions=7;
n_phonemes=numel(GODIVA_x.network.phonemes.index);
n_frames=numel(GODIVA_x.network.frames.index);
n_productions=numel(GODIVA_x.network.productions.index);

GODIVA_x.network.positions.labels=arrayfun(@(n)sprintf('P%d',n),1:n_positions, 'uni',0);

% loads target information
a=godiva_readtargetfile('godiva_targets.txt');
Target_phonemes=zeros([n_phonemes,n_positions]);
m_phonemes=1; % handles multiple 'copies' of each phoneme/position
npos=0;
weight=1;
for n1=1:numel(a.phonemes)
    if isnumeric(a.phonemes{n1}), 
        npos=a.phonemes{n1}; 
        weight=1;
    else
        if ~npos, error(['reading godiva_targets.txt file: missing position descriptor before ',a.phonemes{n1}]); end
        idx=strmatch(a.phonemes{n1},GODIVA_x.network.phonemes.labels,'exact');
        if ~numel(idx), error(['reading godiva_targets.txt file: invalid phoneme descriptor ',a.phonemes{n1}]); end
        idx=idx(1); 
        if Target_phonemes(idx,npos)>0, 
            idx=idx+m_phonemes*n_phonemes; 
            Target_phonemes=cat(1,Target_phonemes,zeros([n_phonemes,n_positions]));
            m_phonemes=m_phonemes+1; 
        end
        Target_phonemes(idx,npos)=weight;
        weight=weight+1;
    end
end
Tmax=repmat(max(Target_phonemes,[],1),[size(Target_phonemes,1),1]); Target_phonemes=(Target_phonemes>0).*(Tmax-Target_phonemes+1)./max(eps,Tmax);

Target_frames=zeros([n_frames,1]);
m_frames=1; % handles multiple 'copies' of each frame 
weight=1;
for n1=1:numel(a.frames)
    idx=strmatch(a.frames{n1},GODIVA_x.network.frames.labels,'exact');
    if ~numel(idx), error(['reading godiva_targets.txt file: invalid frame descriptor ',a.frames{n1}]); end
    idx=idx(1);
    if Target_frames(idx)>0,
        idx=idx+m_frames*n_frames;
        Target_frames=cat(1,Target_frames,zeros([n_frames,1]));
        m_frames=m_frames+1;
    end
    Target_frames(idx)=weight;
    weight=weight+1;
end
Tmax=repmat(max(Target_frames,[],1),[size(Target_frames,1),1]); Target_frames=(Target_frames>0).*(Tmax-Target_frames+1)./max(eps,Tmax);

% defines simulation target variables
Target_phonemes=[0,Target_phonemes(:)'];
Target_frames=[0,Target_frames(:)'];
assignin('base','Target_phonemes',Target_phonemes);
assignin('base','Target_frames',Target_frames);


% defines simulation weight matrices
W=zeros(n_frames,m_frames,n_phonemes,m_phonemes,n_positions);
c=GODIVA_x.network.frames.phonemetypes;
nv=strmatch('V',GODIVA_x.network.phonemes.phonemetypes,'exact');
nc=strmatch('C',GODIVA_x.network.phonemes.phonemetypes,'exact');
for n1=1:n_frames,
    for n2=1:n_positions,
        if isequal(c{n1,n2},'C'),
            W(n1,:,nc,:,n2)=1;
        elseif isequal(c{n1,n2},'V'),
            W(n1,:,nv,:,n2)=1;
        end
    end
end
W=reshape(W,[n_frames*m_frames,n_phonemes*m_phonemes*n_positions]);
save('godiva_weights_PreSMA2IFS.mat','W');

W=zeros(n_frames,m_frames,n_positions);
c=GODIVA_x.network.frames.phonemetypes;
nv=strmatch('V',GODIVA_x.network.phonemes.phonemetypes,'exact');
nc=strmatch('C',GODIVA_x.network.phonemes.phonemetypes,'exact');
for n1=1:n_frames,
    for n2=1:n_positions,
        if isequal(c{n1,n2},'C'),
            W(n1,:,n2)=0.020;
        elseif isequal(c{n1,n2},'V'),
            W(n1,:,n2)=0.100;
        end
    end
end
W=reshape(W,[n_frames*m_frames,n_positions]);
save('godiva_weights_PreSMA2SMA.mat','W');

W=zeros([n_phonemes,m_phonemes,n_positions,n_productions,n_positions]);
c=GODIVA_x.network.productions.phonemes;
for n1=1:n_productions,
    n=0;n0=0;for n2=1:n_positions,n=n+~isempty(c{n1,n2}); if n==1&&~n0, n0=n2; end; end % n0 = first slot in this production; n = number of phonemes in this production
    for nn=1:n
        n2=n0+nn-1;
        idx=strmatch(c{n1,n2},GODIVA_x.network.phonemes.labels,'exact');
        if ~numel(idx), error(['reading godiva_productions.csv file: invalid phoneme descriptor ',c{n1,n2}]); end
        for dn=0:n_positions-n
            W(idx,:,nn+dn,n1,1+dn)=1/n+1/n_positions*1/(2^(nn+dn));
        end
            %W(idx,:,n2+n3-1,n1)=1/n+1/n_positions*1/(2^n2);
            %if n==1, for n3=1:n_positions, W(idx,:,n3,n1)=1/n+1/n_positions*1/(2^n3); end; end
    end
    if ~rem(n1,10),waitbar(n1/n_productions,hw);end
end
W=reshape(W,[n_phonemes*m_phonemes*n_positions,n_productions*n_positions]);
save('godiva_weights_IFS2PMC.mat','W');
W=W';
save('godiva_weights_PMC2IFS.mat','W');

W=zeros([n_positions,n_productions,n_positions]);
c=GODIVA_x.network.productions.phonemes;
for n1=1:n_productions,
    n=0;n0=0;for n2=1:n_positions,n=n+~isempty(c{n1,n2}); if n==1&&~n0, n0=n2; end; end % n0 = first slot in this production; n = number of phonemes in this production
    for nn=1:n
        for dn=0:n_positions-n
            W(nn+dn,n1,1+dn)=1;%1/n+1/n_positions*1/(2^n2);
        end
    end
end
W=reshape(W,[n_positions,n_productions*n_positions])';
save('godiva_weights_PMC2SMA.mat','W');

close(hw);    

