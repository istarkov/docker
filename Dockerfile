#основа ubuntu 14.04 и всякие полезняки
FROM phusion/baseimage:0.9.13

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# ...put your own build instructions here...
#создать юзера с паролем cnerkjhtp, и папку .ssh
RUN /usr/sbin/useradd --create-home --home-dir /home/ice --shell /bin/bash ice && \
echo "ice:cnerkjhtp" | chpasswd && \
usermod -aG sudo ice && \
mkdir -p /home/ice/.ssh && \
chown ice /home/ice/.ssh && \
chmod 700 /home/ice/.ssh

#настроить переменные окружения
ENV HOME /home/ice
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#дадим доступ на чтение переменных окружения другим юзерам
RUN chmod 644 /etc/container_environment.sh

#добавим то что считаем нужным к ~/profile своего юзера см содержимое bash_profile
ADD bash_profile /home/ice/.profile

#откопировать конфигурацию тмукса
ADD .tmux.conf /home/ice/.tmux.conf

#откопировать свой публичный ключ для доступа по ssh
ADD id_rsa.pub /tmp/id_rsa.pub
RUN cat /tmp/id_rsa.pub >> /home/ice/.ssh/authorized_keys && rm -f /tmp/id_rsa.pub && \
chown ice /home/ice/.ssh/authorized_keys && \
chmod 600 /home/ice/.ssh/authorized_keys

#запретить чеканье фингерпринта для bitbucket.org
ADD ssh_config /home/ice/.ssh/config
RUN chown ice /home/ice/.ssh/config && \
chmod 600 /home/ice/.ssh/config


#запустить инсталл зависимостей
RUN add-apt-repository ppa:chris-lea/node.js && \
apt-get update && \
apt-get -y install nodejs && \
apt-get -y install cmake git build-essential tmux g++ gcc libboost-all-dev wget



#сменим права на локаллибы
RUN chown ice /usr/local/lib && \
chown ice /usr/local/include

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
