###Введение
* Для начала ставим себе сам докер, подробности тут https://docs.docker.com/installation/mac/   
* там же читаем что такое докер https://docs.docker.com/introduction/understanding-docker/  
если лень читать, то docker контейнеры можно рассматривать как stateless виртуальные машины с мгновенным стартом, а сам docker это удобная среда для настройки, деплоя и управления контейнерами *(пока она очень удобна для работы с неколькими контейнерами в рамках одной машины, но в след. версиях уже будет удобна и в рамках кластера)*   
* если ставим на Linux то не забываем добавить своего юзера в группу docker
  ```sh
  sudo groupadd docker
  sudo gpasswd -a ${USER} docker
  sudo service docker restart
  ```
* добавляем след команды в (`~/.profile` или если пользуете ssh без логин крыжика то сюда `~/.bash_profile` на линуксе,  `~/.bash_profile` на маке)
не забываем `source ~/.profile` после добавления
  ```sh
  #подсветка stderr
  errh()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
  #бывает у докера на osx слетает ip этой командой можно восстановить
  dreloadhost()
  {
    SYSTEM=`uname`
    [ "$SYSTEM" = "Darwin" ] && export DOCKER_HOST="tcp://`boot2docker ip 2>&1 | sed -n 2,2p | awk -F' ' '{print $9}'`:2375"
  }
  dreloadhost
  #докер убить всех dkill -a 
  dkill ()
  {
    while :
    do
      case $1 in
          -a | --all)
              [ "$(docker ps -a -q)" ] && docker rm -f $(docker ps -a -q)
              shift 1
              ;;

          *)  # no more options. Stop while loop          
              [ "$1" ] && docker rm -f "$1"
              break
              ;;
      esac
    done
    [ "$(docker images | grep "^<none>" | awk "{print $3}")" ] && docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
  }
  #приконнектица к контейнеру по ssh {port}
  dssh ()
  {
  ssh -p $1 ice@`boot2docker ip 2>&1 | sed -n 2,2p | awk -F' ' '{print $9}'`
  }
  alias dps="docker ps"
  #утилитка для макоси для легкой установки nsenter
  denter() {
    CONTAINER=$1
    shift 1
    SYSTEM=`uname`
    if [ "$SYSTEM" = "Darwin" ]
    then
      boot2docker ssh '[ -f /var/lib/boot2docker/nsenter ] || docker run --rm -v /var/lib/boot2docker/:/target jpetazzo/nsenter'
      #если стартовать как положено то зайдет под root и не будет tty а без tty тмукса не видать, поэтому стартуем script 
      #и внимательно следим чтобы у всех контейнеров стоял крыжик -t
      boot2docker ssh -t "sudo /var/lib/boot2docker/docker-enter $CONTAINER su - ice -c 'script -q /dev/null'"
    else
      [ -f /var/lib/boot2docker/nsenter ] || docker run --rm -v /usr/local/bin:/target jpetazzo/nsenter
      #если не будет работать прописать полный путь /usr/local/bin/docker-enter
      sudo docker-enter $CONTAINER su - ice -c 'script -q /dev/null'
    fi
  }
  ```

* после перезапустить shell (закрыть терминал открыть терминал)

####Почему docker нужен (основное): 
 * Любой код что  мы пишем требует какого то окружения (переменные среды дополнительные сервисы, библиотеки и т.п.), окружение среды у всех разное, что приводит к ошибкам на деплое *(например код работающий на маке отказывается запускаться в облаке google без дополнительных танцев)*
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

* Качаем версию себе в моем случае <VERSION> == 0.9.13 `docker pull phusion/baseimage:0.9.13`

---

###Поиграться сразу можно так
```sh
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
* или полный ребилд (он нужен например если произошли изменения во внешних файлах и тп)
```sh
docker build --no-cache=true -t istarkov/tmuxexample tmuxexample
```



файлы Dockerfile хорошо откомментированы и легки для прочтения, поэтому подробности что и зачем они делают внутри   
####Cтартуем
* либо так - если чуем, что что то придется доставлять в контейнер и т.п. *(по хорошему у юзера ice созданного на предыдущем шаге не должно быть sudo)* поэтому контейнер будет запущен в интерактивном режиме c запущенным bash
```bash
docker run --name ice --rm -t -i -p 3222:22 -e HOSTNAME=tmuxexample istarkov/tmuxexample /sbin/my_init -- bash -l
```
* или так - в демон режиме
```bash
docker run --name ice -d -t -p 3222:22 -e HOSTNAME=tmuxexample istarkov/tmuxexample
```
* *новые крыжики*
 *  -p 3222:22 замапить порт 3222 на хост машине на порт 22 докера 

---

---

####Начинаем играть с контейнером
* На маке по ssh к полученному контейнеру можем сконнектится так `dssh 3222`

* На линуксе так `ssh -p 3222 ice@linux_machine_ip`
* **На сам докер на линуксе и на маке лучше всего не заходить по ssh** (_иногда надо_) а использовать прекрасную утилитку nsenter
Если вы прописали alias в .bash_profile, просто запустить denter {container-id} и он установится
Если пользуете tmux то не используйте родной docker-enter а пользуйте мой alias, родной не дает tty откуда все интерактивные утилиты работать не будут. (_точнее tty то дает но не в контексте докера, а использует tty хоста, имеем редкий случай shell interactive а tty нет, isatty() возврщает true, и при этом /dev/pts/ пустой_)
  * _ssh нужен например когда нет желания или возможности дать права кому либо на хост сервер_
  * _по хорошему не нужен и является дырой в безопасности и лишним гемороем_
* Убить все контейнеры `dkill -a`, убить конкретный `dkill {начало_id}` или `dkill {name}` (_бывают ситуации когда контейнеры несмотря на крыжик --rm не умирают после закрытия поэтому dkill ваш друг_)
* Посмотреть какие контейнеры есть в системе dps -a
* Если вы зашли по nsenter то вся сессия логируеца в ~/typescript (см script команда) - посмотреть можно когда юзер отлогинился
* [Почему вам не нужен sshd в Docker-контейнере] (http://habrahabr.ru/company/infopulse/blog/237737/)


####Различные заморочки с правами
* **Шаринг хост файловой системы**   
на контейнере что мы создали у юзера ice uid==1000 (обычно первый юзер получает такой)   
отсюда он прекрасно будет и сможет работать с папками разшаренными ему из под хост системы у которых owner тоже с uid=1000   
вобщем запоминаем прекрасные команды
  ```sh
  #прибить все процессы юзера
  pkill -u {user}
  #сменить uid у юзера
  sudo usermod -u 1000 {user}
  ```
(_в случае osx шара на виртуальной linux машине привязана к docker пользователю с uid=1000 поэтому нам надо на серверах чтобы окружение было одинаковым ставить uid равный 1000 юзеру от которого будем пускать контейнер_)

* __Запуск из под другого пользователя__ если нам надо будет пускать контейнеры например из psql или с вебсервера - то есть в ситуациях когда юзер от имени которого надо стартануть контейнер не дефолтный user c uid=1000 тогда надо будет прописать в sudoers разрешение юзеру запускать любые команды от имени другого юзера
  ```sh
  visudo
  # добавить строчку psql ALL=(ice) NOPASSWD:ALL
  # означает разрешить юзеру psql выполнять любые команды от имени ice
  ```
и затем вызывать команды либо используя 
  ```sh
  sudo -u ice COMMAND [args...]
  ```
либо использовать утилитку setuser (https://raw.githubusercontent.com/phusion/baseimage-docker/master/image/bin/setuser) которая помимо юзера настроит еще и некоторые переменные среды
  ```sh
  ../utils/setuser ice COMMAND [args...]
  ```


####Ошарить порты на мак машину
```sh
for i in {3010..3100}; do
 VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port$i,tcp,,$i,,$i";
 VBoxManage modifyvm "boot2docker-vm" --natpf1 "udp-port$i,udp,,$i,,$i";
done
```

####Логи из контейнера (_два варианта_)
* первый универсальный (_перенаправлять tail -F логфайл в stdout_) тут см пример https://github.com/phusion/passenger-docker/tree/master/image/runit _nginx, nginx-log-forwarder_
* конкретно для nginx этого делать ненадо у него есть крыжики выводить логи в stdout тут http://blog.froese.org/2014/05/15/docker-logspout-and-nginx/
* собирать логи с контейнеров на хосте лучше так https://github.com/progrium/logspout (использует недавно выкаченное api для контейнеров и сам пашет в контейнере)

####Ручные Полезняки: 
* стереть image так
  ```sh
  docker rmi sentimeta/python_all_scikit
  ```

* убить все не сбилженые контейнеры и имажи
  ```sh
  docker rm -f $(docker ps -a -q)
  docker rm -f $(docker ps -a -q --filter 'exited=0')
  docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
  ```
* посмотреть какие есть сбилженые image
  ```sh
  docker images
  ```
* остальные команды читать тут https://docs.docker.com/userguide/
* как настроить image coreos чтобы сразу на приватное репо без пароля https://coreos.com/docs/enterprise-registry/configure-machines/

---

####Косяки
* надо очень аккуратно с head командами https://github.com/docker/docker/issues/8027
* при работе с большими файлами gnu parallel не чует что место на диске кончилось и гонит лажу,
если очень надо с ними работать именно на маке - то надо увеличить размер диска виртуальной машины
https://docs.docker.com/articles/b2d_volume_resize/

####Правильный деплой
  ```sh
  1>/dev/null git fetch --all && 1>/dev/null git checkout --force origin/master
  ```

####Как работать с приватными репо (зависит от бюджета) 
* вот эти самые нормуль https://quay.io/tour/organizations


###Офигенная неприяность докера маленький dev/shm размер и геморой с шарингом файловой системы контейнера в хост систему на OSX (Mac)
*Что не дает выделять большие непрерывные куски shared памяти а именно больше 65мб что для многих задач расчета неприемлимо*  
*А шаринг файловой системы нужен как для размещения db файлов на хост системе (лучше рассматривать контейнеры как stateless объекты) так и для удобной разработки - когда правки кода сразу видны в контейнере*

####Как с этим боремся - правим код докера, и код boot2docker если у вас apple мак
* __Вариант 1__
Качаем два уже подготовленных мной файла https://drive.google.com/folderview?id=0B-jWb9pIDkx-NS05TFdwZVNGQm8&usp=sharing   
подменяем ./boot2docker/boot2docker.iso на скачанный boot2docker.iso   
Шарим фолдер на макоси на виртуалку - чтобы mount volume опция докера работала на макоси также как и на linux
  ```sh
  VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /Users
  ```

копируем на linux сервера файл docker-1.2.0-dev заходим по ssh и выполняем команду (подменяем установленный докер сервис своим)
  ```sh
  sudo service docker stop ; sudo cp $(which docker) $(which docker)_ ; sudo cp docker-1.2.0-dev $(which docker);sudo service docker 
  ```


* **Вариант 2**
__билдим docker и boot2docker сами__   
Запускаем linux (*под маком с билдом докера лучше не связываться*) не забываем добавить своего юзера в группу docker
  ```sh
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
  ```sh
  sudo service docker stop ; sudo cp $(which docker) $(which docker)_ ; sudo cp ./bundles/1.2.0-dev/binary/docker-1.2.0-dev $(which docker);sudo service docker start
  ```

дальше надо этот бинарник заюзать для osx,   
для этого нам надо перебилдить boot2docker.iso или попросить его у меня.

###Создаем build для boot2docker
*(это если в предыдущем пункте был выбран вариант 2)*

* Запускаем linux (*под маком с билдом тоже лучше не связываться*) 
* отпулим себе базовый контейнер билда iso
  ```sh
  docker pull boot2docker/boot2docker
  ```
* откопируем новый docker себе в папку с boot2docker
  ```sh
  cp /home/ice/docker_test/docker_src/docker/bundles/1.2.0-dev/binary/docker-1.2.0-dev docker-1.2.0-dev
  ```
* создаем докерфайл
  ```sh
  FROM boot2docker/boot2docker
  COPY docker-1.2.0-dev $ROOTFS/usr/local/bin/docker
  RUN chmod +x $ROOTFS/usr/local/bin/docker
  #тут код для установки guest additions на виртуальную машину который копипастим отсюда https://gist.github.com/mattes/2d0ffd027cb16571895c
  RUN /make_iso.sh
  CMD ["cat", "boot2docker.iso"]
  ```
* билдим контейнер который в процесе билда создаст образ
  ```sh
  sudo docker build -t istarkov/boot2docker .
  ```
* выводим результат себе из контейнера
  ```sh
  sudo docker run --rm istarkov/boot2docker > boot2docker.iso
  ```
* гасим докер если запущен
  ```sh
  boot2docker down
  ```
* копируем сбилженое iso к себе
  ```sh
  rsync -e ssh -avz --progress ice@turk:~/build_boot_2_docker/docker/boot2docker/boot2docker.iso ~/.boot2docker/boot2docker.iso
  ```
* Шарим фолдер на макоси на виртуалку - чтобы mount volume опция докера работала на макоси также как и на linux
  ```sh
  VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /Users
  ```
* Апаем boot2docker взад и проверяем что все замапилось нормально
  ```sh
  boot2docker up
  #не ленимся прописать export DOCKER_HOST=tcp://смотри вывод boot2docker up:2375
  boot2docker ssh
  cd /Users
  #если все нормально то в папке /Users должны быть директории макоси /Users
  exit
  ```




