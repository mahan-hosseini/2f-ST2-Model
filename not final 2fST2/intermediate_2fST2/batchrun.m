function batchrun

delaystd = 4;

delaypairs = [
    0 0 delaystd
    8 0 delaystd
    -8 0 delaystd
    0 2 delaystd
    0 8 delaystd
    ];

for pair=1:size(delaypairs, 1)
    runModel(1,0,0,100,1,delaypairs(pair,1),delaypairs(pair,2),delaypairs(pair,3));
    filename = sprintf('key%d_resp%d', delaypairs(pair,1), delaypairs(pair,2));
    savedata(filename);
    st2data2eeglab(filename,0);
end
