###Введение
* Для начала ставим себе сам докер, подробности тут https://docs.docker.com/installation/mac/   
* там же читаем что такое докер https://docs.docker.com/introduction/understanding-docker/  
если лень читать, то docker контейнеры можно рассматривать как stateless виртуальные машины с мгновенным стартом, а сам docker это удобная среда для настройки, деплоя и управления контейнерами *(пока она очень удобна для работы с неколькими контейнерами в рамках одной машины, но в след. версиях уже будет удобна и в рамках кластера)*   
* если ставим на Linux то не забываем добавить своего юзера в группу docker
```bash
sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo service docker restart
```
после перезапустить shell (закрыть терминал открыть терминал)

* Почему docker нужен (основное): 
 * Любой код что мы пишем требует какого то окружения (переменные среды, дополнительные сервисы, библиотеки и т.п.), окружение среды у всех разное, что приводит к ошибкам на деплое *(например код работающий на маке отказывается запускаться в облаке google без дополнительных танцев)*
 * Многие библиотеки и сервисы на OSX ведут себя отлично от Linux, до кучи OSX не очень posix система что приводит к гемороям даже для простых bash команд - отличия в sed в awk и куче всего, аналогично различия в системных вызовах на c++ и тп.
 * Есть геморой по подключению, даже ненадолго, девелопера в чужой проект *(например настройка моего окружения по опыту у разработчиков занимает сутки - двое)*, аналогично я легко и быстро могу поправить чужой код на python или ruby если мне при этом не надо читать кучу док про pip gem версионность и тп. *(недавний опыт с питоном показал, что чтоб просто поправить три линии кода пришлось ставить питон -  понимать чем питон 2 отличается от питон 3 и снова ставить питон, потом ставить pip узнавать команды pip  и тп - это куча времени)*
 * Чем больше людей в проектах тем больше вероятность что окружение одного проекта начнет конфликтовать с окружением другого. 
 * До кучи любимая нами ubuntu не везде стоит (в облаке гугл например нет образа ubuntu) те кто после убунту настраивали чистый debian или rhel или не дай бог oracle linux в курсе какого горя порой можно словить просто пытаясь разрулить установку даже привычных программ.
 * Dockerfile описывающий контейнер это легко читаемая последовательность об окружении системы, что немаловажно для администрирования

---

####Голый образ любой системы это не самая удобная вещь, поэтому я сразу напишу как сделать удобный рабочий контейнер
* Всегда удобно взять за основу следующий image - 
"phusion/baseimage:<VERSION>"  
где версию глянуть тут https://github.com/phusion/baseimage-docker/blob/master/Changelog.md  
#####в чем бонусы этого image
 * построен на убунте   
 * сразу настроен runit аналог supervisord, upstart и тп    
 * настроены примочки как удобно просто копированием в Dockerfile добавлять процессы для старта   
 * ENV переменные, сразу стоит ssh сервер (можно отключить)
 * Запущен cron (можно отключить)
 * Еще по мелочи - подробности про image тут https://github.com/phusion/baseimage-docker 

* Качаем версию себе в моем случае <VERSION> == 0.9.13   
docker pull phusion/baseimage:0.9.13

---

###Поиграться сразу можно так
```bash
docker run --rm -e "LANG=en_US.UTF-8" -e "LC_ALL=en_US.UTF-8" -t -i phusion/baseimage:0.9.13 /sbin/my_init -- bash -l
```
####крыжики
* -t выделить псевдо tty
* -i не гасить stdin
* -rm убить контейнер по завершении (без флага можно убитый контейнер закоммитить и тп) вобщем полезняк
* bash -l === exec -l bash
* -- выполнить команду используя my_init - идея что команда будет правильно стартанута чз runit с exec
* -e "LANG=en_US.UTF-8" -e "LC_ALL=en_US.UTF-8" в контейнере по умолчанию херня полная с локалями поэтому пропишем ENV

---

###Теперь сбилдим контейнер на основе Dockerfile
* отклонируем текущий проект себе
```bash
cd projects
git clone git@github.com:istarkov/docker.git
cd docker
```

* **билдим базовый image**
устанавливаем основные зависимости, создаем юзеров,   
прописываем ключи для ssh   
смотрим в Dockerfile там пошагово расписано что мы делаем
```bash
#копируем в билд свой публичный ключ (нужен для ssh)
cp ~/.ssh/id_rsa.pub id_rsa.pub
#билдим базовый image
docker build -t istarkov/base .
```

* создаем image основанный на базовом, что будет происходить смотрим в tmuxexample/Dockerfile  
устанавливаем глобальные зависимости проекта, компилим библиотеку, прописываем deplyment ключ проекта, клонируем проект (и тп.)
```bash
docker build -t istarkov/tmuxexample tmuxexample
```
файлы Dockerfile хорошо откомментированы и легки для прочтения, поэтому подробности что и зачем они делают внутри   


####Cтартуем
* либо так - если чуем, что что то придется доставлять в контейнер и т.п. *(по хорошему у юзера ice созданного на предыдущем шаге не должно быть sudo)* поэтому контейнер будет запущен в интерактивном режиме c запущенным bash
```bash
docker run --rm -t -i -p 3222:22 istarkov/tmuxexample /sbin/my_init -- bash -l
```
* или так - в демон режиме
```bash
docker run -d -p 3222:22 istarkov/tmuxexample
```
* *новые крыжики*
 *  -p 3222:22 замапить порт 3222 на хост машине на порт 22 докера 

---

####Начинаем играть с контейнером
* На маке по ssh к полученному контейнеру коннектимся так
```bash
ssh -p 3222 "ice@`boot2docker ip 2>&1 | sed -n 2,2p | awk -F' ' '{print $9}'`"
```
* на линуксе так
```bash
ssh -p 3222 ice@linux_machine_ip
```
* сконнектившись запускаем команду ./run которая запустит проект - в данном случае tmux менеджер с заранее преконфигуренными опциями




####Полезняки: 
* стереть image так
```bash
docker rmi istarkov/tmuxexample
```

* убить все не сбилженые контейнеры и имажи
```bash
docker rm $(docker ps -a -q)
docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
```
* посмотреть какие есть сбилженые image
```bash
docker images
```
* остальные команды читать тут https://docs.docker.com/userguide/

---



###Офигенная неприяность докера маленький dev/shm размер и геморой с шарингом файловой системы контейнера в хост систему на OSX (Mac)
*Что не дает выделять большие непрерывные куски shared памяти а именно больше 65мб что для многих задач расчета неприемлимо*  
*А шаринг файловой системы нужен как для размещения db файлов на хост системе (лучше рассматривать контейнеры как stateless объекты) так и для удобной разработки - когда правки кода сразу видны в контейнере*

####Как с этим боремся - правим код докера, и код boot2docker если у вас apple мак
* **Вариант 1**
Качаем два уже подготовленных мной файла https://drive.google.com/folderview?id=0B-jWb9pIDkx-NS05TFdwZVNGQm8&usp=sharing   
подменяем ./boot2docker/boot2docker.iso на скачанный boot2docker.iso   
копируем на linux сервера файл docker-1.2.0-dev заходим по ssh и выполняем команду (подменяем установленный докер сервис своим)
```bash
sudo service docker stop ; sudo cp $(which docker) $(which docker)_ ; sudo cp docker-1.2.0-dev $(which docker);sudo service docker 
```


* **Вариант 2**
*билдим docker и boot2docker сами*  
Запускаем linux (*под маком с билдом докера лучше не связываться*) не забываем добавить своего юзера в группу docker
```bash
sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo service docker restart
```
* читаем и настраиваем https://docs.docker.com/contributing/devenvironment/
* в коде vendor/src/github.com/docker/libcontainer/mount/init.go правим размер shm на достойный
```go
{source: "shm", path: filepath.Join(rootfs, "dev", "shm"), device: "tmpfs", flags: defaultMountFlags, data: label.FormatMountLabel("mode=1777,size=ОЧЕНЬМАЛЕНЬКИЙнаОЧЕНЬБОЛЬШОЙ", mountLabel)}
```

* потом билдим докер (см. ссылку) генерим бинарник и выполняем 
```bash
sudo service docker stop ; sudo cp $(which docker) $(which docker)_ ; sudo cp ./bundles/1.2.0-dev/binary/docker-1.2.0-dev $(which docker);sudo service docker start
```

дальше надо этот бинарник заюзать для osx,   
для этого нам надо перебилдить boot2docker.iso или попросить его у меня.



###Создаем build для boot2docker
*(это если в предыдущем пункте был выбран вариант 2)*

* Запускаем linux (*под маком с билдом тоже лучше не связываться*) 
* отпулим себе базовый контейнер билда iso
```bash
docker pull boot2docker/boot2docker
```
* откопируем новый docker себе в папку с boot2docker
```bash
cp /home/ice/docker_test/docker_src/docker/bundles/1.2.0-dev/binary/docker-1.2.0-dev docker-1.2.0-dev
```
* создаем докерфайл
```bash
FROM boot2docker/boot2docker
COPY docker-1.2.0-dev $ROOTFS/usr/local/bin/docker
RUN chmod +x $ROOTFS/usr/local/bin/docker
#тут код для установки guest additions на виртуальную машину который копипастим отсюда https://gist.github.com/mattes/2d0ffd027cb16571895c
RUN /make_iso.sh
CMD ["cat", "boot2docker.iso"]
```
* билдим контейнер который в процесе билда создаст образ
```bash
sudo docker build -t istarkov/boot2docker .
```
* выводим результат себе из контейнера
```bash
sudo docker run --rm istarkov/boot2docker > boot2docker.iso
```
* гасим докер если запущен
```bash
boot2docker down
```
* копируем сбилженое iso к себе
```bash
rsync -e ssh -avz --progress ice@turk:~/docker_test/docker/boot2docker/boot2docker.iso ~/.boot2docker/boot2docker.iso
```
* Шарим фолдер на макоси на виртуалку - чтобы mount volume опция докера работала на макоси также как и на linux
```bash
VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /Users
```
* Апаем boot2docker взад и проверяем что все замапилось нормально
```bash
boot2docker up
#не ленимся прописать export DOCKER_HOST=tcp://смотри вывод boot2docker up:2375
boot2docker ssh
cd /Users
#если все нормально то в папке /Users должны быть директории макоси /Users
exit
```









