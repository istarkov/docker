FROM boot2docker/boot2docker

COPY docker-1.2.0-dev $ROOTFS/usr/local/bin/docker
RUN chmod +x $ROOTFS/usr/local/bin/docker

#для шареных фолдеров добавим поддержку
#не забыть выполнить VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /Users
RUN apt-get install p7zip-full

#узнать версию можно скриптом vbox_version.sh
ENV VBOX_VERSION 4.3.14
 
RUN mkdir -p /vboxguest && \
    cd /vboxguest && \
    curl -L -o vboxguest.iso http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso && \
    7z x vboxguest.iso -ir'!VBoxLinuxAdditions.run' && \
    sh VBoxLinuxAdditions.run --noexec --target . && \
    mkdir x86 && cd x86 && tar xvjf ../VBoxGuestAdditions-x86.tar.bz2 && cd .. && \
    mkdir amd64 && cd amd64 && tar xvjf ../VBoxGuestAdditions-amd64.tar.bz2 && cd .. && \
    cd amd64/src/vboxguest-$VBOX_VERSION && KERN_DIR=/linux-kernel/ make && cd ../../.. && \
    cp amd64/src/vboxguest-$VBOX_VERSION/*.ko $ROOTFS/lib/modules/$KERNEL_VERSION-tinycore64 && \
    mkdir -p $ROOTFS/sbin && cp x86/lib/VBoxGuestAdditions/mount.vboxsf $ROOTFS/sbin/
 
RUN echo "" >> $ROOTFS/etc/motd; \
    echo "  boot2docker with VirtualBox guest additions version $VBOX_VERSION" >> $ROOTFS/etc/motd; \
    echo "" >> $ROOTFS/etc/motd
 
# make mount permanent @todo it works, but its ugly. where should this go?
RUN echo '#!/bin/sh' >> $ROOTFS/etc/rc.d/vbox-guest-additions-permanent-mount; \
    echo 'sudo modprobe vboxsf && sudo mkdir /Users && sudo mount -t vboxsf -o defaults,uid=$(id -u docker),gid=$(id -g docker) home /Users' >> $ROOTFS/etc/rc.d/vbox-guest-additions-permanent-mount
RUN chmod +x $ROOTFS/etc/rc.d/vbox-guest-additions-permanent-mount
RUN echo '/etc/rc.d/vbox-guest-additions-permanent-mount' >> $ROOTFS/opt/bootsync.sh
 
RUN depmod -a -b $ROOTFS $KERNEL_VERSION-tinycore64


RUN /make_iso.sh
CMD ["cat", "boot2docker.iso"]
