function savedata(condition)

load STSToutput_1targ_100ms;
load STSTerp_1targ_100ms;
save(condition, '-v7.3');
copyfile('runlog.txt', [condition '_log.txt']);
end
