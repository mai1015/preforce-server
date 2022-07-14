FROM centos:7

RUN cd /lib/systemd/system/sysinit.target.wants/ && \
	for i in *; do \
		[ $i == systemd-tmpfiles-setup.service ] || rm -vf $i ; \
	done ; \
	rm -vf /lib/systemd/system/multi-user.target.wants/* && \
	rm -vf /etc/systemd/system/*.wants/* && \
	rm -vf /lib/systemd/system/local-fs.target.wants/* && \
	rm -vf /lib/systemd/system/sockets.target.wants/*udev* && \
	rm -vf /lib/systemd/system/sockets.target.wants/*initctl* && \
	rm -vf /lib/systemd/system/basic.target.wants/* && \
	rm -vf /lib/systemd/system/anaconda.target.wants/* && \
	mkdir -p /etc/selinux/targeted/contexts/ && \
	echo '<busconfig><selinux></selinux></busconfig>' > /etc/selinux/targeted/contexts/dbus_contexts

# ARG S6_OVERLAY_VERSION=3.1.1.2

# RUN curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar Jxpf - -C / --keep-directory-symlink --exclude ./usr/bin/execlineb && \
#     curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz | tar Jxpf - -C / --keep-directory-symlink --exclude ./usr/bin/execlineb && \
#     curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz | tar Jxpf - -C / --keep-directory-symlink --exclude ./usr/bin/execlineb && \
#     curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz | tar Jxpf - -C / --keep-directory-symlink --exclude ./usr/bin/execlineb

RUN sed -ir '/\[updates\].*/a enabled=1' /etc/yum.repos.d/CentOS-Base.repo && \
    yum install -y epel-release cronie-anacron tar gzip curl openssl which sudo initscripts sysvinit at && \
    echo -ne '[perforce]\nname=Perforce\nbaseurl=http://package.perforce.com/yum/rhel/7/x86_64\nenabled=1\ngpgcheck=1\n' > /etc/yum.repos.d/perforce.repo && \
    rpm --import https://package.perforce.com/perforce.pubkey && \
    yum clean all --enablerepo='*' && \
    rm -rf /var/cache/yum

RUN yum clean all --enablerepo='*' \
    && yum clean metadata --enablerepo='*' \
    && yum install --enablerepo=perforce -y helix-p4d.x86_64 helix-cli.x86_64 \
    && yum clean all --enablerepo='*' \
    && rm -rf /var/cache/yum

EXPOSE 1666
ENV NAME p4depot
ENV P4CONFIG .p4config
ENV DATAVOLUME /data
ENV P4PORT 1666
ENV P4USER p4admin
VOLUME ["$DATAVOLUME"]

ADD ./p4-users.txt /root/
ADD ./p4-groups.txt /root/
ADD ./p4-protect.txt /root/
ADD ./setup-perforce.sh /usr/local/bin/
ADD ./run.sh  /

CMD ["/run.sh"]