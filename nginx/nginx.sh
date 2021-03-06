!/usr/bin/bash
clear
#source res.sh
######################################################################################################
echo "1.检查系统是否安装apache"
rpm -qa | grep httpd*
yum -y remove httpd*
######################################################################################################
echo "2.设置nginx目录"
# 设置web目录
webData=/data/web
webLog=/data/log/web
webPath=/usr/local/nginx
webEtc=/etc/nginx
webTmp=/tmp/nginx
# 设置web用户
webUser=web
webGroup=web
# 创建web目录
mkdir -p $webPath $webData $webLog $webEtc
# 创建用户(组)赋予家目录
groupadd -r $webUser
useradd -g $webUser -r -s /sbin/nologin -M -d $webData $webGroup
# 赋予web权限
chown -R $webUser:$webUser $webData $webPath $webLog
######################################################################################################
echo "3.进入源码目录"
# 进入源码目录
cd /usr/local/src
######################################################################################################
echo "4.安装依赖包"
# http://zlib.net/zlib-1.2.11.tar.gz
# https://www.openssl.org/source/openssl-1.1.0e.tar.gz
# http://nchc.dl.sourceforge.net/project/pcre/pcre/8.40/pcre-8.40.tar.gz
# 下载并安装依赖包 <zlib,openssl,pcre>
# 设置版本号
zlib=zlib-1.2.11
openssl=openssl-1.1.0f
pcre=pcre-8.40
curl -O http://zlib.net/${zlib}.tar.gz
curl -O https://www.openssl.org/source/${openssl}.tar.gz
curl -O http://nchc.dl.sourceforge.net/project/pcre/pcre/8.40/${pcre}.tar.gz
# 解压依赖包
tar -zxf ${zlib}.tar.gz
tar -zxf ${openssl}.tar.gz
tar -zxf ${pcre}.tar.gz
# http://nginx.org/download/nginx-1.12.0.tar.gz
# http://nginx.org/download/nginx-1.12.2.tar.gz
# http://nginx.org/download/nginx-1.14.0.tar.gz
# 下载NG
# 设置版本号
nginx=nginx-1.12.0
curl -O http://nginx.org/download/${nginx}.tar.gz
# 解压NG
tar -zxf $nginx.tar.gz
echo "5.进入nginx目录编译"
cd $nginx
# 查编译配置参数
./configure --help > nginx-configure.txt
#
# [可选]
# --user=$webUser
# --group=$webGroup
# --conf-path=$webEtc/conf/nginx.conf
# --pid-path=$webTmp/nginx.pid
# --lock-path=$webTmp/nginx.lock
# --http-log-path=$webLog/http.log
# --error-log-path=$webLog/error.log
# --with-http_stub_status_module
# --with-openssl=../$openssl
# --with-http_ssl_module
# --with-debug
# --with-stream
# 
#【可选扩展】
# 
# rtmp 流媒体模块（https://codeload.github.com/arut/nginx-rtmp-module/zip/v1.2.1）
# --add-module=../nginx-rtmp-module-1.2.1
# 
# 
# 
./configure --prefix=$webPath --user=$webUser --group=$webGroup --sbin-path=$webPath/sbin/nginx --conf-path=$webEtc/conf/nginx.conf --pid-path=$webTmp/nginx.pid --lock-path=$webTmp/nginx.lock --http-log-path=$webLog/http.log --error-log-path=$webLog/error.log --http-client-body-temp-path=$webTmp/client/ --http-proxy-temp-path=$webTmp/proxy --http-fastcgi-temp-path=$webTmp/fastcgi --http-uwsgi-temp-path=$webTmp/uwsgi --http-scgi-temp-path=$webTmp/scgi --with-pcre=../$pcre --with-zlib=../$zlib --with-threads --with-http_stub_status_module --with-openssl=../$openssl --with-http_ssl_module --with-debug  --with-stream

# 

#
echo "6.开始编译"
make
make install
echo "7.安装完成"
# 配置Nginx
#
# 配置环境变量
sed -i '$a WEB_PATH='${webPath} /etc/profile
sed -i '$a PATH=$PATH:$WEB_PATH/sbin' /etc/profile
sed -i '$a export PATH WEB_PATH' /etc/profile
source /etc/profile

#
# 防火墙开启80端口
# 命令含义
# --zone #作用域 
# --add-port=80/tcp  #添加端口，格式为：端口/通讯协议
# --permanent   #永久生效，没有此参数重启后失效
firewall-cmd --zone=public --add-port=80/tcp --permanent

# 重启防火墙
firewall-cmd --reload
#
#启动： systemctl start firewalld
#查看状态： systemctl status firewalld 
#停止： systemctl disable firewalld
#禁用： systemctl stop firewalld

# 配置service
cat <<EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
EOF
# 开机
systemctl enable nginx
# 启动
systemctl start nginx