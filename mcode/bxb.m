function varargout=bxb(varargin)
%
% report=bxb(recName,refAnn,testAnn,reportFile,beginTime,stopTime,matchWindow)
%
%    Wrapper to WFDB BXB:
%         http://www.physionet.org/physiotools/wag/bxb-1.htm
%
% Creates a report file ("reportFile) using
% ANSI/AAMI-standard beat-by-beat annotation comparator.
%
% Ouput Parameters:
%
% report (Optional)
%       Returns a structure containing information on the 'reportFile'.
%       This can be used to read report File that has been previously
%       generated by BXB (see Example 2 below), into the workspace.
%       The structure has the following fields:
%       report.data     - 7x7 matrix of counters:
%          (1,1) normal beats labelled as normal
%          (1,2) normal beats labelled as supraventricular
%          (1,3) normal beats labelled as ventricular
%          (1,4) normal beats labelled as fusion
%          (1,5) normal beats labelled as paced/unknown
%          (1,6) normal beats not detected
%          (1,7) normal beats labelled as unreadable
%          (2,1) supraventricular beats labelled as normal
%           ...
%          (3,1) ventricular beats labelled as normal
%           ...
%          (4,1) fusion beats labelled as normal
%           ...
%          (5,1) paced/unknown beats labelled as normal
%           ...
%          (6,1) falsely detected beats labelled as normal
%           ...
%          (6,6) unused (NaN)
%          (6,7) unused (NaN)
%          (7,1) beats detected in unreadable regions, labelled as normal
%           ...
%          (7,6) unused (NaN)
%          (7,7) unused (NaN)
%
%Input Parameters:
% recName
%       String specifying the WFDB record file.
%
% refAnn
%       String specifying the reference WFDB annotation file.
%
% testAnn
%       String specifying the test WFDB annotation file.
%
% reportFile
%       String representing the file at which the report will be
%       written to.
%
% beginTime (Optional)
%       String specifying the begin time in WFDB time format. The
%       WFDB time format is described at
%       http://www.physionet.org/physiotools/wag/intro.htm#time.
%       Default starts comparison after 5 minutes.
%
% stopTime (Optional)
%       String specifying the stop time in WFDB format (default is end of
%       record).
%
% matchWindow (Optional)
%       1x1 WFDB Time specifying the match window size (default = 0.15 s).
%
%
% Written by Ikaro Silva, 2013
% Last Modified: May 28, 2014
% Version 1.1
% Since 0.9.0
%
% %Example (this will generate a /mitdb/100.qrs file at your directory):
% %Compares SQRS detetor with the MITDB ATR annotations
%
% [refAnn]=rdann('mitdb/100','atr');
% sqrs('mitdb/100');
% [testAnn]=rdann('mitdb/100','qrs');
% report=bxb('mitdb/100','atr','qrs','bxbReport.txt')
%
%
% %Example 2 - Load variables from a report file that has been previously
% %generated
%  report=bxb([],[],[],'bxbReport.txt')
%
%
% See also RDANN, MXM, WFDBTIME

%endOfHelp

javaWfdbExec=getWfdbClass('bxb');

%Set default pararamter values
inputs={'recName','refAnn','testAnn','reportFile','beginTime','stopTime','matchWindow'};
recName=[];
refAnn=[];
testAnn=[];
reportFile=[];
beginTime=[];
stopTime=[];
matchWindow=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

if(~isempty(recName))
    %Only execute this if recName is defined, otherwise we assume 
    %that the user just want to load the 'reporFile' variable into the 
    %workspace based on a previously generated 'reportFile' 
    wfdb_argument={'-r',recName,'-a',refAnn,testAnn,'-S',reportFile};
    if(~isempty(beginTime))
        wfdb_argument{end+1}='-f';
        wfdb_argument{end+1}=beginTime;
    end
    if(~isempty(stopTime))
        wfdb_argument{end+1}='-t';
        wfdb_argument{end+1}=stopTime;
    end
    if(~isempty(matchWindow))
        wfdb_argument{end+1}='-w';
        wfdb_argument{end+1}=matchWindow;
    end
    report=javaWfdbExec.execToStringList(wfdb_argument);
end

if(nargout>0)
    varargout{1}=bxbReader(reportFile);
end

function reportData = bxbReader(fileName)
d=[];
n=0;
f=fopen(fileName,'rt');
s=fgetl(f);
while(ischar(s) && isempty(strfind(s,'|')))
    s=fgetl(f);
end
while(ischar(s) && ~isempty(strfind(s,'|')))
    v=strread(s(strfind(s,'|')+1:end),'%f');
    while(length(v)<n)
        v=[v;nan];
    end
    n=length(v);
    d=[d v];
    s=fgetl(f);
end
fclose(f);

reportData=struct();
reportData.data = d';
