lang en_GB.UTF-8
keyboard gb
timezone UTC
zerombr
clearpart --all --initlabel
autopart
reboot
ostreesetup --nogpg --url=http://192.168.1.113:8000/repo/ --osname=iot --remote=iot --ref=rhel/8/x86_64/edge
