FROM ubuntu

MAINTAINER Mike Gardiner <conversationing@gmail.com>

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get -y install sudo
RUN apt-get -y install openssh-server
RUN apt-get -y install git

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# To avoid annoying "perl: warning: Setting locale failed." errors,
# do not allow the client to pass custom locals, see:
# http://stackoverflow.com/a/2510548/15677
RUN sed -i 's/^AcceptEnv LANG LC_\*$//g' /etc/ssh/sshd_config

RUN mkdir /var/run/sshd

RUN adduser --system --group --shell /bin/sh git
RUN su git -c "mkdir /home/git/bin"

RUN cd /home/git; su git -c "git clone git://github.com/sitaramc/gitolite";
RUN cd /home/git/gitolite; su git -c "git checkout master";
RUN cd /home/git; su git -c "gitolite/install -ln";

# https://github.com/docker/docker/issues/5892
RUN chown -R git:git /home/git

# http://stackoverflow.com/questions/22547939/docker-gitlab-container-ssh-git-login-error
RUN sed -i '/session    required     pam_loginuid.so/d' /etc/pam.d/sshd

# Remove SSH host keys, so they will be generated by /init
RUN rm -f /etc/ssh/ssh_host_*

ADD ./init.sh /init

# Addind volume to repositories directory
VOLUME /home/git/repositories
VOLUME /etc/ssh

RUN chmod +x /init
ENTRYPOINT ["/init", "/usr/sbin/sshd", "-D"]

EXPOSE 22
