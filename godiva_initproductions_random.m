% script to initialize godiva_productions.csv with random phoneme combinations 
if 0
    NEW=0;
    if NEW,
        defaultStream = RandStream.getGlobalStream;
        savedState = defaultStream.State;
        save temp01.mat savedState
    else
        defaultStream = RandStream.getGlobalStream;
        load temp01.mat savedState
        defaultStream.State = savedState;
    end
    disp(['seed values ',num2str(rand(1,5))]);
end

[a,b,c]=textread('godiva_phonemes.csv','%n%s%s%*[^\n]','delimiter',',','headerlines',1);
idx=find(a);
a1=a(idx);b1=b(idx);c1=c(idx);

% creates a set of fixed frames
S={};N={};
frame='CCCVCCC';
nv=strfind(frame,'V');
nc=strfind(frame,'C');
idx=repmat({1:2},[1,numel(nc)]);
clear idxcv;
[idxcv{1:numel(nc)}]=ndgrid(idx{:});
idxcv=cat(numel(nc)+1,idxcv{:});
idxcv=reshape(idxcv,[],numel(nc));
for n1=1:size(idxcv,1),
    s=repmat({'0'},[1,numel(frame)]);%cell(1,numel(frame));
    s{nv}='V';
    idx=find(idxcv(n1,:)>1);
    s(nc(idx))=repmat({'C'},[1,numel(idx)]);
    S(end+1,:)=s;
    N(end+1)={strcat(s{:})};
end
N=char(N); N(N=='0')=' ';N=strtrim(cellstr(N));
idx=[]; for n1=1:numel(N),if ~any(N{n1}==' '), idx=[idx,n1]; end; end
for n1=1:size(S,1),for n2=1:size(S,2),if S{n1,n2}=='0', S{n1,n2}=''; end; end; end
S=S(idx,:);
N=N(idx);
fh=fopen('godiva_frames.csv','wt');
fprintf(fh,'index,label,phoneme1,phoneme2,phoneme3,phoneme4,phoneme5,phoneme6,phoneme7\n');
for n1=1:numel(N),
    fprintf(fh,'%d,%s,%s,%s,%s,%s,%s,%s,%s\n',n1,N{n1},S{n1,1},S{n1,2},S{n1,3},S{n1,4},S{n1,5},S{n1,6},S{n1,7});
end
fclose(fh);

% creates a set of random productions
[a,b]=textread('godiva_frames.csv','%n%s%*[^\n]','delimiter',',','headerlines',1);
idx=find(a);
a2=a(idx);b2=b(idx);
idxv=strfind(cat(1,c1{:})','V');
idxc=strfind(cat(1,c1{:})','C');

%nsamples=16;
%nsamples=[100,100,10,10,10,10];
nsamples=[1000,100,10,10,10,10];
%nsamples=0*[1,1,1,1,1,1];
S={};N={};
for n1=1:numel(a2) % each frame
    nv=strfind(b2{n1},'V');
    nc=strfind(b2{n1},'C');
    if numel(nc)>0
        for n2=1:numel(idxv), % all vowels
            for ns=1:nsamples(min(numel(nsamples),numel(nc))),
                s=repmat({'0'},[1,7]);%cell(1,7);
                s{4}=b1{idxv(n2)};
                for n3=1:numel(nc), % number of consonants in this syllable frame
                    n4=ceil(rand*numel(idxc)); % random consonants
                    s{4+nc(n3)-nv}=b1{idxc(n4)};
                end
                S(end+1,:)=s;
                N(end+1)={strcat(s{:})};
            end
        end
    end
end
for n2=1:numel(idxv), % all vowels
    s=repmat({'0'},[1,7]);%cell(1,7);
    s{4}=b1{idxv(n2)};
    S(end+1,:)=s;
    N(end+1)={strcat(s{:})};
end
for n2=1:numel(idxc), % all consonants
    for n3=[1:3,5:7],
        s=repmat({'0'},[1,7]);%cell(1,7);
        s{n3}=b1{idxc(n2)};
        S(end+1,:)=s;
        N(end+1)={strcat(s{:})};
    end
end
[a,idxsort]=sortrows(strvcat(N));
idx=[find(~all(a(2:end,:)==a(1:end-1,:),2));size(a,1)];
S=S(idxsort(idx),:);
N=N(idxsort(idx));
for n1=1:size(S,1),for n2=1:size(S,2),if isequal(S{n1,n2},'0'), S{n1,n2}=''; end; end; end
for n1=1:numel(N),N{n1}(N{n1}=='0')=[];end
[a,idxsort]=sortrows(strvcat(N));
S=S(idxsort,:);
N=N(idxsort);
fh=fopen('godiva_productions.csv','wt');
fprintf(fh,'index,label,phoneme1,phoneme2,phoneme3,phoneme4,phoneme5,phoneme6,phoneme7\n');
for n1=1:numel(N),
    fprintf(fh,'%d,%s,%s,%s,%s,%s,%s,%s,%s\n',n1,N{n1},S{n1,1},S{n1,2},S{n1,3},S{n1,4},S{n1,5},S{n1,6},S{n1,7});
end
fclose(fh);

