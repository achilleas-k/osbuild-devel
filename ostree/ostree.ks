zerombr
clearpart --all --initlabel --disklabel=msdos
autopart --nohome --noswap --type=plain
ostreesetup --nogpg --url=http://192.168.1.113:8000/repo/ --osname=iot --remote=iot --ref=rhel/8/x86_64/edge
reboot
