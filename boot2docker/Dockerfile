FROM boot2docker/boot2docker

ADD automount-shares /tmp/automount-shares

RUN rm $ROOTFS/etc/rc.d/automount-shares && \
cp /tmp/automount-shares $ROOTFS/etc/rc.d/automount-shares

RUN /make_iso.sh

CMD ["cat", "boot2docker.iso"]
