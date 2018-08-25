#ss-panel-v3-mod_UIChanges
#Author: 十一
#Blog: blog.67cc.cn
#Time：2018-8-25 11:05:33
#!/bin/bash
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
function check_system(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
	if [[ ${release} = "centos" ]] && [[ ${bit} == "x86_64" ]]; then
	echo -e "你的系统为[${release} ${bit}],检测\033[32m 可以 \033[0m搭建。"
	else 
	echo -e "你的系统为[${release} ${bit}],检测\033[31m 不可以 \033[0m搭建。"
	echo -e "\033[31m 正在退出脚本... \033[0m"
	exit 0;
	fi
}
function install_ss_panel_mod_UIm(){
    yum remove httpd -y
	yum install unzip zip git -y
	wget -c --no-check-certificate https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/lnmp1.4.zip && unzip lnmp1.4.zip && rm -rf lnmp1.4.zip && cd lnmp1.4 && chmod +x install.sh && ./install.sh lnmp
	cd /home/wwwroot/
	cp -r default/phpmyadmin/ .  #复制数据库
	cd default
	rm -rf index.html
	#克隆项目
	git clone https://github.com/NimaQu/ss-panel-v3-mod_Uim.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	wget -N -P  /home/wwwroot/default/config/ "https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/.config.php"
	#复制配置文件
	# cp config/.config.php.example config/.config.php
	#设置文件权限
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	#下载lnmp配置文件
	wget -N -P  /usr/local/nginx/conf/ --no-check-certificate "https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/nginx.conf"
	wget -N -P  /home/wwwroot/default/sql/ --no-check-certificate "https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/sspanel.sql"
	service nginx restart #重启Nginx
	# mysql -uroot -proot -e"create database sspanel;" 
	# mysql -uroot -proot -e"use sspanel;" 
	# mysql -uroot -proot sspanel < /home/wwwroot/default/sql/sspanel.sql
	mysql -hlocalhost -uroot -proot --default-character-set=utf8mb4<<EOF
create database ssrpanel;
use ssrpanel;
source /home/wwwroot/default/sql/sspanel.sql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
flush privileges;
EOF
	cd /home/wwwroot/default
	#安装composer
	php composer.phar install
	php xcat syncusers            #同步用户
	php xcat initQQWry            #下载IP解析库
	php xcat resetTraffic         #重置流量
	php xcat initdownload         #下载ssr程式
	mv tool/alipay-f2fpay vendor/
	mv -f tool/cacert.pem vendor/guzzle/guzzle/src/Guzzle/Http/Resources/
	mv -f tool/autoload_classmap.php vendor/composer/
	#创建监控
	yum -y install vixie-cron crontabs
	rm -rf /var/spool/cron/root
	echo 'SHELL=/bin/bash' >> /var/spool/cron/root
	echo 'PATH=/sbin:/bin:/usr/sbin:/usr/bin' >> /var/spool/cron/root
	echo '0 0 * * * php -n /home/wwwroot/default/xcat dailyjob' >> /var/spool/cron/root
	echo '*/1 * * * * php /home/wwwroot/default/xcat checkjob' >> /var/spool/cron/root
	echo "*/1 * * * * php /home/wwwroot/default/xcat synclogin" >> /var/spool/cron/root
	echo "*/1 * * * * php /home/wwwroot/default/xcat syncvpn" >> /var/spool/cron/root
	echo '*/20 * * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1' >> /var/spool/cron/root
	echo '30 22 * * * php /home/wwwroot/default/xcat sendDiaryMail' >> /var/spool/cron/root
	echo '*/1 * * * * php -n /home/wwwroot/default/xcat syncnas' >> /var/spool/cron/root
	/sbin/service crond restart
	if [ -d "/home/wwwroot/default/" ];then
	clear
	echo "ss-panel-v3-mod_UIChanges安装成功~"
	else
	echo "安装失败，请格盘重装~"
	fi
}
# 一键添加SS-panel节点
function install_centos_ssr(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	LIB='download.libsodium.org'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$GIT" ];then
		libAddr='https://raw.githubusercontent.com/marisn2017/ss-panel-v3-mod_Uim/master/libsodium-1.0.13.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.13.tar.gz'
	fi
	rm -f ping.pl
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	yum -y install python-setuptools
	easy_install supervisor
	cd /root
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	cd /root/shadowsocks
	yum -y install lsof lrzsz
	yum -y install python-devel
	yum -y install libffi-devel
	yum -y install openssl-devel
	pip install -r requirements.txt
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
function install_node(){
	clear
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	read -p "请输入你的对接域名或IP(请加上http:// 如果是本机请直接回车): " Userdomain
	read -p "请输入muKey(在你的配置文件中 如果是本机请直接回车):" Usermukey
	read -p "请输入你的节点编号(非常重要，必须填，不能回车):  " UserNODE_ID
	install_centos_ssr
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	Userdomain=${Userdomain:-"http://${IPAddress}"}
	sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
	Usermukey=${Usermukey:-"marisn"}
	sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
	UserNODE_ID=${UserNODE_ID:-"3"}
	sed -i '2d' /root/shadowsocks/userapiconfig.py
	sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	# 启用supervisord守护
	echo_supervisord_conf > /etc/supervisord.conf
  sed -i '$a [program:ssr]\ncommand = python /root/shadowsocks/server.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	echo "#############################################################"
	echo "#          安装完成，节点即将重启使配置生效                 #"
	echo "#############################################################"
	reboot now
}
function install_BBR(){
     wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh&&chmod +x bbr.sh&&./bbr.sh
}
function install_RS(){
     wget -N --no-check-certificate https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh && bash serverspeeder.sh
}
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
rm -rf script*
clear
check_system
sleep 2
echo -e "\033[31m#############################################################\033[0m"
echo -e "\033[32m#欢迎使用一键ss-panel-v3-mod_UIChanges搭建脚本 and 节点添加 #\033[0m"
echo -e "\033[34m#Blog: http://blog.67cc.cn/                                 #\033[0m"
echo -e "\033[35m#请选择你要搭建的脚本：                                     #\033[0m"
echo -e "\033[36m#1.  一键ss-panel-v3-mod_UIChanges搭建                      #\033[0m"
echo -e "\033[37m#2.  一键添加SS-panel节点                                   #\033[0m"
echo -e "\033[37m#3.  一键  BBR加速  搭建                                    #\033[0m"
echo -e "\033[36m#4.  一键锐速破解版搭建                                     #\033[0m"
echo -e "\033[33m#                              PS:建议先搭建加速再搭建面板  #\033[0m"
echo -e "\033[32m#                                   支持   Centos  7.x  系统#\033[0m"
echo -e "\033[31m#############################################################\033[0m"
echo
read num
if [[ $num == "1" ]]
then
install_ss_panel_mod_UIm
elif [[ $num == "2" ]]
then
install_node
elif [[ $num == "3" ]]
then
install_BBR
elif [[ $num == "4" ]]
then
install_RS
else 
echo '输入错误';
exit 0;
fi;