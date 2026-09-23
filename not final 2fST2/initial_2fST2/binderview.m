function binderview(lag)
global BinderHistory NUMBINDERS

figure
subplot(1,2,1)

a = size(BinderHistory,2);

imagesc(reshape(BinderHistory(lag,:,1,:),[a,NUMBINDERS]));
subplot(1,2,2)
imagesc(reshape(BinderHistory(lag,:,2,:),[a,NUMBINDERS]));
