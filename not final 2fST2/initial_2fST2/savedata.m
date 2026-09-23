function savedata(condition)

load STSToutput_1targ_100ms;
load STSTerp_1targ_100ms;
%load STST_T1T2trace_1targ_100ms
save(condition);
copyfile('runlog.txt', [condition '_log.txt']);
end
