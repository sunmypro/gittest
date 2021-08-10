#!/bin/bash
DIR=`pwd`
JDK_FILE="jdk-8u291-linux-x64.tar.gz"
TOMCAT_FILE="apache-tomcat-9.0.48.tar.gz"
JDK_DIR="/usr/local"
TOMCAT_DIR="/usr/local"
SCR_URL="10.0.0.88/src/"

### 安装JDK
#wget 10.0.0.88/src/$JDK_FILE
install_jdk(){
  if ! [ -f "$DIR/$JDK_FILE" ];then
      echo "$JDK_FILE 文件不存在" 
      [ -d "$JDK_DIR" ] || mkdir -pv $JDK_DIR
      wget $SCR_URL$JDK_FILE
    
  elif [ -d $JDK_DIR/jdk ];then
      echo "JDK 已经安装" false
  else
      echo "WTF"
  fi

  [ -f "$DIR/$JDK_FILE" ]&&tar xvf $DIR/$JDK_FILE -C $JDK_DIR

  cd $JDK_DIR && ln -s jdk1.8.* jdk
  ln -sv $JDK_DIR/jdk/bin/java /usr/bin/
}
install_jdk

### 设置环境变量
cat > /etc/profile.d/jdk.sh <<SUN
export JAVA_HOME=$JDK_DIR/jdk
export JRE_HOME=\$JAVA_HOME/jre
export CLASSPATH=\$JAVA_HOME/lib/:\$JRE_HOME/lib/
export PATH=\$PATH:\$JAVA_HOME/bin:\JRE_HOME/bin
SUN
. /etc/profile.d/jdk.sh
java -version && echo "JDK 安装完成" || { echo "JDK 安装失败" false ; exit; }


### 安装tomcat
#wget $SCR_URL$TOMCAT_FILE
install_tomcat(){
### 安装文件检查    
cd ~
   if ! [ -f "$DIR/$TOMCAT_FILE" ];then
      echo "$TOMCAT_FILE 文件不存在" 
      [ -d "$TOMCAT_DIR" ] || mkdir -pv $TOMCAT_DIR
      wget $SCR_URL$TOMCAT_FILE
  elif [ -d $TOMCAT_DIR/tomcat ];then
      echo "TOMCAT 已经安装" false
  else
      echo "WTF"
  fi
### 解包并做软链接

  tar xvf $DIR/$TOMCAT_FILE -C $TOMCAT_DIR
  ln -s $TOMCAT_DIR/apache-tomcat-*/ $TOMCAT_DIR/tomcat
### 添加环境变量
  echo "PATH=$TOMCAT_DIR/tomcat/bin:"'$PATH' > /etc/profile.d/tomcat.sh
#. /etc/profile.d/tomcat.sh
### 创建tomcat用户并赋权
  id tomcat &> /dev/null || useradd -r -s /sbin/nologin tomcat
  chown -R tomcat.tomcat $TOMCAT_DIR/tomcat/
### 在tomcat配置文件中写JDK路径
cat > $TOMCAT_DIR/tomcat/conf/tomcat.conf <<SUN
JAVA_HOME=$JDK_DIR/jdk
SUN
### 创建tomcat启动文件
cat > /lib/systemd/system/tomcat.service <<SUN
[Unit]
Description=Tomcat
#After=syslog.target network.target remote-fs.target nss-lookup.target
After=syslog.target network.target
[Service]
Type=forking
EnvironmentFile=$TOMCAT_DIR/tomcat/conf/tomcat.conf
ExecStart=$TOMCAT_DIR/tomcat/bin/startup.sh
ExecStop=$TOMCAT_DIR/tomcat/bin/shutdown.sh
RestartSec=3
PrivateTmp=true
User=tomcat
Group=tomcat
[Install]
WantedBy=multi-user.target
SUN
### 重新加载服务并启动
  systemctl daemon-reload
  systemctl enable --now tomcat.service
  systemctl is-active tomcat.service &> /dev/null && echo "TOMCAT 安装完成" || { echo "TOMCAT 安装失败" false ; exit; }
}
#install_jdk
#install_tomcat
