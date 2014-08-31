FROM istarkov/base

#откопировать deployment key для bitbucket
ADD id_deployment_key /home/ice/.ssh/id_rsa
RUN chown ice /home/ice/.ssh/id_rsa && \
chmod 600 /home/ice/.ssh/id_rsa


#зависимый код от репо - глобальные зависимости проекта 
RUN npm install -g node-gyp && \
npm install -g supervisor && \
npm install -g grunt-cli && \
chown ice -R /home/ice/.npm

#сменим юзера на ice и дальше весь акшен от его имени
USER ice

#отклонировать репо дать ссылку на ран
RUN cd /home/ice && \
git clone git@bitbucket.org:cybice/testn.git && \
ln -n -s /home/ice/testn/tmux_run /home/ice/runme

#установим либу из сети
RUN mkdir -p /home/ice/jansonn && \
cd /home/ice/jansonn && \
wget http://www.digip.org/jansson/releases/jansson-2.6.tar.gz && \
tar -zxvf jansson-2.6.tar.gz && \
cd jansson-2.6 && \
./configure && \
make && \
make check && \
make install


#вернем юзера на рут, запустим ldconfig ибо часть путей библиотек могла прописаться в /etc/ld.so.conf или /etc/ld.so.conf.d
USER root
RUN ldconfig

# Clean APT if need.
