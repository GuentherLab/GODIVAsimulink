function out=godiva_readtargetfile(filename)

comment=0;
out=[];
fieldname='arg';
s=textread(filename,'%s');
for n1=1:length(s),
    if comment || isempty(s{n1}),
    elseif strncmp(s{n1},'%{',2), % comment open
        comment=1;
    elseif strncmp(s{n1},'%}',2), % comment close
        comment=0;
    elseif s{n1}(1)=='#', % field name
        fieldname=lower(s{n1}(2:end));
        out.(fieldname)=[];
    else % field value
        n=str2double(s{n1});
        ok=all(s{n1}>'0'&s{n1}<'9');
        if ok, newvalue={n}; else newvalue={s{n1}}; end
        if isfield(out,fieldname) && ~isempty(out.(fieldname)),
            out.(fieldname)=cat(1,out.(fieldname),newvalue);
        else
            out.(fieldname)=newvalue;
        end
    end
end

    