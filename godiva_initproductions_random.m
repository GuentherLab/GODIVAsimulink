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

%[a,b,c]=textread('godiva_phonemes.csv','%n%s%s%*[^\n]','delimiter',',','headerlines',1);
[a,b,d,c]=textread('godiva_phonemes.csv','%n%s%s%s%*[^\n]','delimiter',',','headerlines',1);
idx=find(a);
a1=a(idx);b1=b(idx);c1=c(idx);

% creates a set of fixed frames
% combinations of one to seven elements with between one and three vowels
N={}; Np=7;
for nv=1:3 % # of vowels
    for nc=0:Np-nv % # of consonants
        str='CV';
        str=unique(cellstr(str(1+(perms(1:(nc+nv))>nc))));
        N=[N;regexprep(cellstr(str),{'0','1'},{'C','V'})];
    end
end
fh=fopen('godiva_frames.csv','wt');
fprintf(fh,'index,label,phoneme1,phoneme2,phoneme3,phoneme4,phoneme5,phoneme6,phoneme7\n');
for n1=1:numel(N),
    fprintf(fh,'%d,%s',n1,N{n1});
    for n2=1:numel(N{n1}), fprintf(fh,',%c',N{n1}(n2)); end
    for n2=numel(N{n1})+1:Np, fprintf(fh,','); end
    fprintf(fh,'\n');
end
fclose(fh);
% S={};N={};
% % frame='CCCVCCC';
% % nv=strfind(frame,'V');
% % nc=strfind(frame,'C');
% % idx=repmat({1:2},[1,numel(nc)]);
% % clear idxcv;
% % [idxcv{1:numel(nc)}]=ndgrid(idx{:});
% % idxcv=cat(numel(nc)+1,idxcv{:});
% % idxcv=reshape(idxcv,[],numel(nc));
% % for n1=1:size(idxcv,1),
% %     s=repmat({'0'},[1,numel(frame)]);%cell(1,numel(frame));
% %     s{nv}='V';
% %     idx=find(idxcv(n1,:)>1);
% %     s(nc(idx))=repmat({'C'},[1,numel(idx)]);
% %     S(end+1,:)=s;
% %     N(end+1)={strcat(s{:})};
% % end
% % N=char(N); N(N=='0')=' ';N=strtrim(cellstr(N));
% % idx=[]; for n1=1:numel(N),if ~any(N{n1}==' '), idx=[idx,n1]; end; end
% % for n1=1:size(S,1),for n2=1:size(S,2),if S{n1,n2}=='0', S{n1,n2}=''; end; end; end
% % S=S(idx,:);
% % N=N(idx);
% fh=fopen('godiva_frames.csv','wt');
% fprintf(fh,'index,label,phoneme1,phoneme2,phoneme3,phoneme4,phoneme5,phoneme6,phoneme7\n');
% for n1=1:numel(N),
%     fprintf(fh,'%d,%s,%s,%s,%s,%s,%s,%s,%s\n',n1,N{n1},S{n1,1},S{n1,2},S{n1,3},S{n1,4},S{n1,5},S{n1,6},S{n1,7});
% end
% fclose(fh);

% creates a set of random productions
[a,b]=textread('godiva_frames.csv','%n%s%*[^\n]','delimiter',',','headerlines',1);
idx=find(a);
a2=a(idx);b2=b(idx);
idxv=strfind(cat(1,c1{:})','V');
idxc=strfind(cat(1,c1{:})','C');

N=[num2cell(idxv'); num2cell(idxc')]; % all single-vowels & single-consonants
for n1=1:numel(a2) % each frame
    nv=strfind(b2{n1},'V');
    nc=strfind(b2{n1},'C');
    if numel(nc)==1&&numel(nv)==1
        tN=zeros(size(b2{n1}));
        for iidxv=1:numel(idxv)
            for iidxc=1:numel(idxc)
                tN(nv)=idxv(iidxv);
                tN(nc)=idxc(iidxc);
                N{end+1}=tN; 
            end
        end
    elseif numel(nc)+numel(nv)==3
        nsamples=200;
        tN=zeros(size(b2{n1}));
        for ns=1:nsamples
            tN(nv)=idxv(ceil(numel(idxv)*rand(size(nv))));
            tN(nc)=idxc(ceil(numel(idxc)*rand(size(nc))));
            if ~any(cellfun(@(x)isequal(tN,x),N)), N{end+1}=tN; end
        end
    end
end

fh=fopen('godiva_productions.csv','wt');
fprintf(fh,'index,label,phoneme1,phoneme2,phoneme3,phoneme4,phoneme5,phoneme6,phoneme7\n');
for n1=1:numel(N),
    fprintf(fh,'%d,%s',n1,sprintf('%s',b1{N{n1}}));
    for n2=1:numel(N{n1}), fprintf(fh,',%s',b1{N{n1}(n2)}); end
    for n2=numel(N{n1})+1:Np, fprintf(fh,','); end
    fprintf(fh,'\n');
end
fclose(fh);


% %nsamples=[100,10,10,10,10,10];
% nsamples=[1000,100,10,10,10,10];
% %nsamples=0*[1,1,1,1,1,1];
% S={};N={};
% for n1=1:numel(a2) % each frame
%     nv=strfind(b2{n1},'V');
%     nc=strfind(b2{n1},'C');
%     if numel(nc)>0
%         for n2=1:numel(idxv), % all vowels
%             for ns=1:nsamples(min(numel(nsamples),numel(nc))),
%                 s=repmat({'0'},[1,7]);%cell(1,7);
%                 s{4}=b1{idxv(n2)};
%                 for n3=1:numel(nc), % number of consonants in this syllable frame
%                     n4=ceil(rand*numel(idxc)); % random consonants
%                     s{4+nc(n3)-nv}=b1{idxc(n4)};
%                 end
%                 S(end+1,:)=s;
%                 N(end+1)={strcat(s{:})};
%             end
%         end
%     end
% end
% for n2=1:numel(idxv), % all vowels
%     s=repmat({'0'},[1,7]);%cell(1,7);
%     s{4}=b1{idxv(n2)};
%     S(end+1,:)=s;
%     N(end+1)={strcat(s{:})};
% end
% for n2=1:numel(idxc), % all consonants
%     for n3=[1:3,5:7],
%         s=repmat({'0'},[1,7]);%cell(1,7);
%         s{n3}=b1{idxc(n2)};
%         S(end+1,:)=s;
%         N(end+1)={strcat(s{:})};
%     end
% end
% [a,idxsort]=sortrows(strvcat(N));
% idx=[find(~all(a(2:end,:)==a(1:end-1,:),2));size(a,1)];
% S=S(idxsort(idx),:);
% N=N(idxsort(idx));
% for n1=1:size(S,1),for n2=1:size(S,2),if isequal(S{n1,n2},'0'), S{n1,n2}=''; end; end; end
% for n1=1:numel(N),N{n1}(N{n1}=='0')=[];end
% [a,idxsort]=sortrows(strvcat(N));
% S=S(idxsort,:);
% N=N(idxsort);
% fh=fopen('godiva_productions.csv','wt');
% fprintf(fh,'index,label,phoneme1,phoneme2,phoneme3,phoneme4,phoneme5,phoneme6,phoneme7\n');
% for n1=1:numel(N),
%     fprintf(fh,'%d,%s,%s,%s,%s,%s,%s,%s,%s\n',n1,N{n1},S{n1,1},S{n1,2},S{n1,3},S{n1,4},S{n1,5},S{n1,6},S{n1,7});
% end
% fclose(fh);

