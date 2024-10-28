#!/bin/bash

# Define your timezone
timezone=Asia/Ho_Chi_Minh

# Define game version
version=1.7.3

# Target game zip to be download and extracted
DIR_WORKSPACES=/home
DIR_WORKSPACES_HOME=$DIR_WORKSPACES/home # VERY IMPORTANT! This location varies depending on your gameServer.zip structure.
URL_DOWNLOAD="https://drive.usercontent.google.com/download?id=1UebfhrwJIWfP5cZvdra1tNWVZb8Is9PE&export=download&authuser=0&confirm=t&uuid=5c5a1d80-c934-4688-a7a9-6630f844de42"

# Define database configuration
dbName=pw
dbHost=127.0.0.1
dbUser=dba
dbPassword=dba

# Define website configuration
pwAdminUsername="admin"
pwAdminRawPw="admin"
pwAdminEmail="admin@gmail.com"

# Common variables
currentSQLDate=$(date +'%F %T');
logfile="/setup.log"
now=$(date +%Y%m%d_%H%M%S)
startTime=$(date +%s)
pwAdminPasswordHashBase64=""
hostnamesResolution="
127.0.0.1 AUDATA
127.0.0.1 GameDB
127.0.0.1 GameDBClient
127.0.0.1 LOCAL0
127.0.0.1 LogServer
127.0.0.1 PW-Server
127.0.0.1 audb
127.0.0.1 aumanager
127.0.0.1 auth
127.0.0.1 backup
127.0.0.1 database
127.0.0.1 dbserver
127.0.0.1 delivery
127.0.0.1 game1
127.0.0.1 game2
127.0.0.1 game3
127.0.0.1 game4
127.0.0.1 gamedbserver
127.0.0.1 gdelivery
127.0.0.1 gm_server
127.0.0.1 gmserver
127.0.0.1 link1
127.0.0.1 link2
127.0.0.1 link3
127.0.0.1 link4
127.0.0.1 localhost
127.0.0.1 localhost.localdomain
127.0.0.1 manager
127.0.0.1 nfsroot
127.0.0.1 perfectworld
127.0.0.1 ubuntu
"

function log(){
    local message=$1
    echo "$message" | tee -a "$logfile"
    # Example of use: log "This is a log message"
}

function finallyExit(){
    log "Script END."
}

function switchTimezone(){
    ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
}

function installSeverPackages(){

    dpkg --add-architecture i386
    apt update
    apt install -y sudo
    apt install -y dialog apt-utils > /dev/null 2>&1
    apt install -y mc nano wget curl sed bash grep dpkg net-tools iputils-ping > /dev/null 2>&1
    apt install -y p7zip-full > /dev/null 2>&1

    # This is a tool to download specific folders from a Github repository.
    curl -sSLfo ./fetch https://github.com/gruntwork-io/fetch/releases/download/v0.4.6/fetch_linux_amd64
    chmod 777 ./fetch

    # These libraries ensure that your game server can run smoothly on a 64-bit system while supporting any 32-bit components it might rely on.
    apt install -y libstdc++5:i386 gcc-multilib zlib1g:i386 zlib1g libxml2:i386 libstdc++6:i386 > /dev/null 2>&1

}

function installDevPackages(){
    apt install -y default-jre > /dev/null 2>&1     # This is for apache 2
    apt install -y apache2 > /dev/null 2>&1
    apt install -y mariadb-server > /dev/null 2>&1

    # TODO:     
    #tar -xzf jdk-7u80-linux-x64.tar.gz
    #mv -f jdk1.7.0_80 /usr/lib/jvm/

}

function downloadGameServer(){

    chmod 777 -R $DIR_WORKSPACES
    wget -c $URL_DOWNLOAD -O $DIR_WORKSPACES/pw.7z
}

function extractGameServer(){

    7z x -aoa $DIR_WORKSPACES/pw.7z -sccutf-8 -scsutf-8 -o$DIR_WORKSPACES
    chmod 777 -R $DIR_WORKSPACES
    rm -f $DIR_WORKSPACES/pw.7z

    # Use my pwadmin (iweb)
    rm -rf $DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin
    ./fetch --repo="https://github.com/hoangnguyent/pwWebTools" --ref="master" --source-path="/pwadmin" $DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin

    # TODO: scan and check folder structure

}

function setupDb() {

    # This algorithm must not be changed!!!
    # Generate MD5 hash in binary format and base64 encode it
    pwAdminPasswordSalt=$(echo "${pwAdminUsername}${pwAdminRawPw}" | tr '[:upper:]' '[:lower:]')
    pwAdminPasswordHashBase64=$(echo -n "$pwAdminPasswordSalt" | openssl dgst -md5 -binary | base64)

    wget -c https://raw.githubusercontent.com/hoangnguyent/pwWebTools/refs/heads/master/pwa.sql -O "$DIR_WORKSPACES/pw.sql"

    service mariadb start

    # Grant DB permission.
    mariadb -u"root" -p"123456" <<EOF
        DROP USER IF EXISTS '$dbUser'@'$dbHost';
        CREATE USER '$dbUser'@'$dbHost' IDENTIFIED BY '$dbPassword';
        GRANT ALL PRIVILEGES ON *.* TO '$dbUser'@'$dbHost';
        DROP USER IF EXISTS '$dbUser'@'%';
        CREATE USER '$dbUser'@'%' IDENTIFIED BY '$dbPassword';
        GRANT ALL PRIVILEGES ON *.* TO '$dbUser'@'%';
        FLUSH PRIVILEGES;
EOF

    service mariadb restart

    mariadb -u"$dbUser" -p"$dbPassword" <<EOF
        DROP DATABASE IF EXISTS $dbName;
        CREATE DATABASE $dbName CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

    mariadb -u"$dbUser" -p"$dbPassword" "$dbName" < "$DIR_WORKSPACES/pw.sql"
    rm "$DIR_WORKSPACES/pw.sql"

    mariadb -u"$dbUser" -p"$dbPassword" "$dbName" <<EOF
        CALL adduser("$pwAdminUsername", "$pwAdminPasswordHashBase64", "0", "0", "super admin", "0.0.0.0", "$pwAdminEmail", "0", "0", "0", "0", "0", "0", "0", "$currentSQLDate", " ", "$pwAdminPasswordHashBase64");
EOF

    lastInsertedUserId=$(mariadb -u"$dbUser" -p"$dbPassword" "$dbName" -se "SELECT ID from users WHERE name=\"$pwAdminUsername\"");
    echo "last inserted id: $lastInsertedUserId";
    if [[ "$lastInsertedUserId" =~ ^[0-9]+$ ]]; then
        mariadb -u"$dbUser" -p"$dbPassword" "$dbName" <<EOF
            CALL addGM("$lastInsertedUserId", "1");
            INSERT INTO usecashnow (userid, zoneid, sn, aid, point, cash, status, creatime) VALUES ("$lastInsertedUserId", "1", "0", "1", "0", "100000", "1", "$currentSQLDate") ON DUPLICATE KEY UPDATE cash = cash + 100000;
EOF
    fi

}

function enableToConnectDbFromOutsideContainer(){

    service mariadb start

    mariadb -u"root" -p"123456" <<EOF
        DROP USER IF EXISTS '$dbUser'@'localhost';
        CREATE USER '$dbUser'@'localhost' IDENTIFIED BY '$dbPassword';
        GRANT ALL PRIVILEGES ON *.* TO '$dbUser'@'localhost';
        DROP USER IF EXISTS '$dbUser'@'127.0.0.1';
        CREATE USER '$dbUser'@'127.0.0.1' IDENTIFIED BY '$dbPassword';
        GRANT ALL PRIVILEGES ON *.* TO '$dbUser'@'127.0.0.1';
        DROP USER IF EXISTS '$dbUser'@'172.17.0.1';
        CREATE USER '$dbUser'@'172.17.0.1' IDENTIFIED BY '$dbPassword';
        GRANT ALL PRIVILEGES ON *.* TO '$dbUser'@'172.17.0.1';
        FLUSH PRIVILEGES;
EOF

    service mariadb restart

    # Allow all IP addresses outside the container.
    if grep -q "^\[mysqld\]" /etc/mysql/my.cnf; then
        # Append settings to the [mysqld] section
        sed -i '/^\[mysqld\]/a \
log_error = /var/log/mysql/error.log\n
bind-address = 0.0.0.0\n
skip-name-resolve' /etc/mysql/my.cnf
    else
        # Add [mysqld] section and settings at the end of the file
        echo -e "\n[mysqld]\nlog_error = /var/log/mysql/error.log\nbind-address = 0.0.0.0\nskip-name-resolve" | sudo tee -a /etc/mysql/my.cnf
    fi

}

function setupRegisterPhp(){

    websitePath=/var/www/html

    # Install PHP packages
    DEBIAN_FRONTEND=noninteractive apt install -y libapache2-mod-php
    apt install -y php php-mysql php-curl mcrypt

    # Donwload register.php
    wget -c https://raw.githubusercontent.com/hoangnguyent/pwWebTools/refs/heads/master/register.php -O "$websitePath/register.php"
    chmod 777 -R "$websitePath"

    # Override file /register.php: replace the line starts with a text with another text
    sed -i "/^\$config = \[\];/c\$config = ['host' => '$dbHost', 'user' => '$dbUser', 'pass' => '$dbPassword', 'name' => '$dbName', 'gold' => '1000000000',];" "$websitePath/register.php"

    service apache2 restart
}

function setupIwebJava(){

    # TODO: nên cài tomcat vào opt/tomcat. Thay vì đang để chung 1 đống với game như hiện tại.
    # Tomcat 7.0.108. 
    # wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.108/bin/apache-tomcat-7.0.108.tar.gz -P /tmp
    # sudo tar xf /tmp/apache-tomcat-7.0.108.tar.gz -C /opt/tomcat

    # java version "1.7.0_80". apt-get install openjdk-8-jdk
    # apt-get install openjdk-8-jdk

    # Override file /home/server: DB connection; [pwadmin] web tool location; and other info. Replace the line that starts with a text with another text
    sed -i "/^# Last Updated:/c\# Last Updated: $(date +'%Y/%m/%d')" "$DIR_WORKSPACES_HOME/server"
    sed -i "/^# Require:/c\# Require: Perfect World server v$version" "$DIR_WORKSPACES_HOME/server"
    sed -i "/^ServerDir=/c\ServerDir=$DIR_WORKSPACES_HOME" "$DIR_WORKSPACES_HOME/server"
    sed -i "/^USR=/c\USR=$dbUser" "$DIR_WORKSPACES_HOME/server"
    sed -i "/^PASSWD=/c\PASSWD=$dbPassword" "$DIR_WORKSPACES_HOME/server"
    sed -i "/^DB=/c\DB=$dbName" "$DIR_WORKSPACES_HOME/server"
    sed -i "/^pwAdmin_dir=/c\pwAdmin_dir=$DIR_WORKSPACES_HOME/pwadmin/bin" "$DIR_WORKSPACES_HOME/server"

    # Override file /home/pwadmin/webapps/pwadmin/WEB-INF/.pwadminconf.jsp: DB connection; game location; MD5 of iweb password.
    iwebPasswordSalt=$(echo "${pwAdminRawPw}" | tr '[:upper:]' '[:lower:]')
    iwebPasswordHashBase64=$(echo -n "$pwAdminRawPw" | openssl dgst -md5 -binary | base64)
    sed -i "/String db_host = /c\String db_host = \"$dbHost\";" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/WEB-INF/.pwadminconf.jsp"
    sed -i "/String db_user = /c\String db_user = \"$dbUser\";" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/WEB-INF/.pwadminconf.jsp"
    sed -i "/String db_password = /c\String db_password = \"$dbPassword\";" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/WEB-INF/.pwadminconf.jsp"
    sed -i "/String db_database = /c\String db_database = \"$dbName\";" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/WEB-INF/.pwadminconf.jsp"
    sed -i "/String iweb_password = /c\String iweb_password = \"$iwebPasswordHashBase64\";" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/WEB-INF/.pwadminconf.jsp"
    sed -i "/String pw_server_path = /c\String pw_server_path = \"$DIR_WORKSPACES_HOME/\";" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/WEB-INF/.pwadminconf.jsp"

    # Override file /home/pwadmin/webapps/pwadmin/addons/Top Players - Manual Refresh/index.jsp: DB connection. Replace the line that contains a text with a whole new line
    sed -i "/connection = DriverManager.getConnection(/c\connection = DriverManager.getConnection(\"jdbc:mysql://$dbHost:3306/$dbName?useUnicode=true&characterEncoding=utf8\", \"$dbUser\", \"$db_password\");" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/addons/Top Players - Manual Refresh/index.jsp"

}

function setupPhpMyAdmin(){

    apt install -y phpmyadmin

    # Create the phpMyAdmin configuration file
    cat <<EOF > /etc/apache2/phpMyAdmin.conf
Alias /phpmyadmin /usr/share/phpMyAdmin

<Directory /usr/share/phpMyAdmin/>
    AddDefaultCharset UTF-8

    <IfModule mod_authz_core.c>
        # Apache 2.4
        <RequireAny>
            # Uncomment and specify your IP addresses for better security
            # Require ip 127.0.0.1
            # Require ip ::1
            Require all granted
        </RequireAny>
    </IfModule>

    <IfModule !mod_authz_core.c>
        # Apache 2.2
        Order Deny,Allow
        Deny from All
        # Uncomment and specify your IP addresses for better security
        # Allow from 127.0.0.1
        # Allow from ::1
    </IfModule>
</Directory>
EOF

    # Restart Apache to apply changes
    service apache2 restart

}

function translateMapsIntoVietnamese() {

    echo "yes,gs01,Thế Giới
yes,is61,Thế Giới Người Mới (1.5.3)
no,is62,Khung Thế Giới (1.5.1)
no,is01,Thành Phố Tội Ác
no,is02,Đường Hầm Bí Mật
no,is03,na
no,is04,na
no,is05,Hang Động Lửa
no,is06,Hang Sói Điên
no,is07,Hang Động Tàn Ác
no,is08,Đại Sảnh Lừa Dối
no,is09,Cổng Ảo Giác
no,is10,Thành Phố Băng Giá Bí Mật
no,is11,Thung Lũng Thảm Họa
no,is12,Tàn Tích Rừng
no,is13,Hang Động Vui Sướng Tàn Bạo
no,is14,Cổng Ma Quái
no,is15,Hào Trench Ảo Giác
no,is16,Eden
no,is17,Hố Lửa
no,is18,Đền Rồng
no,is19,Đảo Tiếng Thét Đêm
no,is20,Đảo Rắn
yes,is21,Lothranis
yes,is22,Momaganon
no,is23,Ngai Tòa Đau Khổ
no,is24,Ma Vực Đào Nguyên
no,is25,Chiến Ca Chi Thành
no,is26,Luân Hồi Điện
no,is27,Thần Nguyệt Cốc
no,is28,Thần Vô Cốc
no,is29,Phúc Sương Thành
no,is31,Hoàng Hôn Thánh Điện
no,is32,Vận Mệnh Ma Phương
no,is33,Thiên Lệ Chi Thành
no,is34,Khung cảnh Hôn Lễ
no,is35,Phụ bản Bang Phái
no,is37,Bồng Lai Huyễn Cảnh
no,is38,Phượng Minh Cốc
no,is39,Vô Định Trụ
no,is40,Thần Độc Chi Gian
no,is41,Vô ĐỊnh Trụ-mô thức cấp cao
no,is42,Chiến Thần Cốc
no,is43,Ngũ Đế Chi Đô
no,is44,Quốc Chiến-Cô Đảo Đoạt Kì
no,is45,Quốc Chiến-Đoạn Kiều Đối Trì
no,is46,Quốc Chiến-Thủy Tinh Tranh Đoạt
no,is47,Lạc Nhật Cốc
no,is48,Bất Xá Đường
no,is49,Long Ẩn Quật
no,is50,Linh Đàn Huyễn Cảnh
yes,is63,Nhân Giới
no,is66,Lưu Ngân Cung
no,is67,Phục Ba Đường
yes,is68,Mô thức Câu chuyện Nhân Giới
yes,is69,Bồng Minh Động
no,is70,Vận Mệnh Ma Phương (2)
no,is71,Thiện Long Cốc
no,is72,Tru Thiên Phù Đồ Tháp (base)
no,is73,Tru Thiên Phù Đồ Tháp (is73)
no,is74,Tru Thiên Phù Đồ Tháp (is74)
no,is75,Tru Thiên Phù Đồ Tháp (is75)
no,is76,Huyễn Hải Kì Đàm
no,is77,Thurs Fights Cross
yes,is78,Đại Lục Hoàn Mĩ - Tây Lục
no,is80,Lăng Vân Giới
no,is81,Lăng Vân Giới
no,is82,Lăng Vân Giới
no,is83,Lăng Vân Giới
no,bg01,Đấu trường T-3 PvP
no,bg02,Đấu trường T-3 PvE
no,bg03,Đấu trường T-2 PvP
no,bg04,Đấu trường T-2 PvE
no,bg05,Đấu trường T-1 PvP
no,bg06,Đấu trường T-1 PvE
no,arena01,Đấu trường Kiếm Tiên Thành
no,arena02,Đấu trường Vạn Hóa Thành
no,arena03,Đấu trường Tích Vũ Thành
no,arena04,Đấu trường Tổ Long Thành
no,rand03,Huyễn Sa Thận Cảnh
no,rand04,Mê Sa Huyễn Cảnh
" > "$DIR_WORKSPACES_HOME/maps"

}

function translateIwebIntoVietnamese() {

    sed -i '1i <%@page contentType="text/html; charset=UTF-8" %>' "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp" #to display UTF-8

    # Replace a text with another text
    sed -i "s#City of Abominations#Minh Thú Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Secret Passage#Anh Hùng Trủng#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Firecrag Grotto#Hỏa Nham Động Huyệt#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Den of Rabid Wolves#Cuồng Lang Sào Huyệt#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Cave of the Vicious#Xà Hạt Động#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Hall of Deception#Thanh Y Trủng#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Gate of Delirium#U Minh Cư#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Secret Frostcover Grounds#Lí Sương Bí Cảnh#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Valley of Disaster#Thiên Kiếp Cốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Forest Ruins#Tùng Lâm Di Tích#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Cave of Sadistic Glee#Quỷ Vực Huyễn Cảnh#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Wraithgate#Oán Linh Chi Môn#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Hallucinatory Trench#Bí Bảo Quật#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Eden#Tiên Huyễn Thiên#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Brimstone Pit#Ma Huyễn Thiên#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Temple of the Dragon#Long Cung#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Nightscream Island#Dạ Khốc Đảo#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Snake Isle#Vạn Xà Đảo#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Lothranis#Tiên giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Momaganon#Ma giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Seat of Torment#Thiên Giới Luyện Ngục#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Abaddon#Ma Vực Đào Nguyên#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Warsong City#Chiến Ca Chi Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Palace of Nirvana#Luân Hồi Điện#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Lunar Glade#Thần Nguyệt Cốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Valley of Reciprocity#Thần Vô Cốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Frostcover City#Phúc Sương Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Twilight Temple#Hoàng Hôn Thánh Điện#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Cube of Fate#Vận Mệnh Ma Phương#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Chrono City#Thiên Lệ Chi Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Perfect Chapel#Khung cảnh Hôn Lễ#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Guild Base#Phụ bản Bang Phái#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Morai#Bồng Lai Huyễn Cảnh#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Phoenix Valley#Phượng Minh Cốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Endless Universe#Vô Định Trụ#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Blighted Chamer#Thần Độc Chi Gian#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Endless Universe#Vô ĐỊnh Trụ-mô thức cấp cao#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Wargod Gulch#Chiến Thần Cốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Five Emperors#Ngũ Đế Chi Đô#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Nation War 2#Quốc Chiến-Cô Đảo Đoạt Kì#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Nation Wa TOWER#Quốc Chiến-Thủy Tinh Tranh Đoạt#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Nation War CRYSTAL#Quốc Chiến-Đoạn Kiều Đối Trì#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Sunset Valley#Lạc Nhật Cốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Shutter Palace#Bất Xá Đường#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Dragon Hidden Den#Long Ẩn Quật#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Realm of Reflection#Linh Đàn Huyễn Cảnh#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#startpoint#Linh Độ Đinh Châu#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Origination#Khung Thế Giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Primal World#Nhân Giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Flowsilver Palace#Lưu Ngân Cung#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Undercurrent Hall#Phục Ba Đường#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Mortal Realm#Mô thức Câu chuyện Nhân Giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#LightSail Cave#Bồng Minh Động#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Cube of Fate (2)#Vận Mệnh Ma Phương (2)#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#dragon counqest#Thiện Long Cốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#heavenfall temple#Tru Thiên Phù Đồ Tháp#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#heavenfall temple#Tru Thiên Phù Đồ Tháp#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#heavenfall temple#Tru Thiên Phù Đồ Tháp#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#heavenfall temple#Tru Thiên Phù Đồ Tháp#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Uncharted Paradise#Huyễn Hải Kì Đàm#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Thurs Fights Cross#Thurs Fights Cross#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Western Steppes#Đại Lục Hoàn Mĩ - Tây Lục#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Homestead, Beyond the Clouds#Lăng Vân Giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Homestead, Beyond the Clouds#Lăng Vân Giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Homestead, Beyond the Clouds#Lăng Vân Giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Homestead, Beyond the Clouds#Lăng Vân Giới#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Grape Valley, Grape Valley#Grape Valley#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Nemesis Gaunntlet, Museum#Linh Lung Cục#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Dawnlight Halls, Palace of the Dawn (DR 1)#Thự Quang Điện (DR 1)#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Mirage Lake, Mirage Lake#Huyễn Cảnh Thận Hồ#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Rosesand Ruins, Desert Ruins#Côi Mạc Tàn Viên#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Nightmare Woods, Forest Ruins#Yểm Lâm Phế Khư#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Advisors Sanctum, Palace of the Dawn (DR 2)#Thự Quang Điện (DR 2)#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Wonderland, Adventure Kingdom (Park)#Kì Lạc Mạo Hiểm Vương Quốc#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#The Indestructible City#Mô thức câu chuyện Tây Lục#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Phoenix Sanctum, Hall of Fame#Phoenix Sanctum, Hall of Fame#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Town of Arrivals, Battlefield - Dusk Outpost#Ước chiến Liên server - Long Chiến Chi Dã#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Icebound Underworld, Ice Hell (LA)#Băng Vọng Địa Ngục#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Doosan Station, Arena of the Gods#Doosan Station, Arena of the Gods#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Alt TT Revisited, Twilight Palace#Alt TT Revisited, Twilight Palace#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Spring Pass, Peach Abode (Mentoring)#Spring Pass, Peach Abode (Mentoring)#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Abode of Dreams#Abode of Dreams#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#White Wolf Pass#White Wolf Pass#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Imperial Battle#Imperial Battle#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Northern Lands#Northern Lands#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Altar of the Virgin#Altar of the Virgin#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Imperial Battle#Imperial Battle#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Northern Lands#Northern Lands#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Full Moon Pavilion#Full Moon Pavilion#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Abode of Changes#Abode of Changes#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#quicksand maze#quicksand maze#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#quicksand maze#quicksand maze#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Territory War T-3 PvP#Đấu trường T-3 PvP#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Territory War T-3 PvE#Đấu trường T-3 PvE#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Territory War T-2 PvP#Đấu trường T-2 PvP#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Territory War T-2 PvE#Đấu trường T-2 PvE#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Territory War T-1 PvP#Đấu trường T-1 PvP#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Territory War T-1 PvE#Đấu trường T-1 PvE#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Etherblade Arena#Đấu trường Kiếm Tiên Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Lost Arena#Đấu trường Vạn Hóa Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Plume Arena#Đấu trường Tích Vũ Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Archosaur Arenas#Đấu trường Tổ Long Thành#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Quicksand Maze (Sandstorm Mirage)#Huyễn Sa Thận Cảnh#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Quicksand Maze (Mirage of the wandering sands)#Mê Sa Huyễn Cảnh#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"
    sed -i "s#Tomb of Whispers#Tomb of Whispers#g" "$DIR_WORKSPACES_HOME/pwadmin/webapps/pwadmin/serverctrl.jsp"

    # Có nhiều map mình không tìm được tên tiếng Việt, thậm chí dịch bừa. Ai biết, xin chỉ giùm nhé.
}

function setupWebTools() {

    setupRegisterPhp
    setupIwebJava

    # Other tools
    #setupPhpMyAdmin: still unable to access
}

function composeStartAndStopScript(){

    # Download start/stop script
    wget -O /start https://raw.githubusercontent.com/hoangnguyent/pwWebTools/refs/heads/master/start
    wget -O /stop https://raw.githubusercontent.com/hoangnguyent/pwWebTools/refs/heads/master/stop

    # Override the 'start' file
    sed -i "s|^PW_PATH=.*|PW_PATH=$DIR_WORKSPACES_HOME|" "start"
    hostCommand="
    if ! grep -q \"127.0.0.1 AUDATA\" /etc/hosts; then
        echo \"Docker Container revertes the /etc/hosts whenever it restarts. We are re-adding the hostnames resolution automatically...\"
        echo \"$hostnamesResolution\" >> /etc/hosts
    fi"
    echo "$hostCommand" >> start
    echo "sleep 10" >> start

    connectionStringCommand="echo \"To connect to the DB from outside the Container, use: jdbc:mariadb://$dbHost:3306/$dbName?user=$dbUser&password=$dbPassword\""
    echo "$connectionStringCommand" >> start

    echo "echo \"=== COMPLETED! ======\"" >> start
    echo "echo \"\"" >> start

    chmod -R 777 $DIR_WORKSPACES_HOME
    chmod 777 start stop

}

function setupGameServer(){

    # Update file /etc/hosts, firewall
    ./fetch --repo="https://github.com/hoangnguyent/pwWebTools" --ref="master" --source-path="/copy" /copy
    #Copy the whole folder exept /copy/etc/hosts
    rsync -av --exclude='/hosts' /copy/etc/ /etc/
    cp -rf /copy/lib/* /lib
    cp -rf /copy/lib64/* /lib64
    rm -rf /copy

    # Override file /etc/table.xml: replace the line that starts with a text with a whole new line.
    sed -i "/^<connection name=\"auth0\" poolsize=\"3\" url=\"jdbc:mysql/c\<connection name=\"auth0\" poolsize=\"3\" url=\"jdbc:mysql://$dbHost:3306/$dbName?useUnicode=true&amp;characterEncoding=utf8&amp;jdbcCompliantTruncation=false\" username=\"$dbUser\" password=\"$dbPassword\"/>" "/etc/table.xml"
    cp -f /etc/table.xml $DIR_WORKSPACES_HOME/authd/table.xml
    
    # Override file /etc/GMServer.conf: replace the line that starts with a text with a whole new line.
    # TODO: trong [copy] có file GMServer.conf, gmopgen.xml, đang dùng IP linh tinh. Hãy check lại, có quan trọng không?
    sed -i "/^address/c\address                 =       127.0.0.1" "/etc/table.xml"

    # Override /home/authd/authd
    sed -i 's##!/bin/sh#export CLASSPATH=lib/dt.jar:lib/tools.jar#g' "$DIR_WORKSPACES_HOME/authd"
    cp -f /etc/table.xml $DIR_WORKSPACES_HOME/authd/table.xml

    # Override file /home/gamed/gs.conf: replace the line that starts with a text with a whole new line.
    sed -i "/^Root	/c\Root				= $DIR_WORKSPACES_HOME/gamed/config" "$DIR_WORKSPACES_HOME/gamed/gs.conf" #TODO: /home/gamed/gs.conf hình như cần sửa path
    #TODO: nếu sửa toàn toàn bộ gdeliveryd/gamesys.conf thành 0.0.0.0, sẽ không báo lỗi [err : CrossRelated Connect to central delivery failed] nữa

    # Sync files to folder /home/gamed/config. These 9 files should be copied manually.
    # 1. aipolicy.data
    # 2. elements.data
    # 3. gshop.data
    # 4. gshop1.data
    # 5. gshop2.data
    # 6. gshopsev.data
    # 7. gshopsev1.data
    # 8. gshopsev2.data
    # 9. tasks.data

}

function enableGameServerConnection(){

    # Override file /home/glinkd/gamesys.conf: first 7 matches will be 0.0.0.0. Other matches will be 127.0.0.1. # TODO: Thay toàn bộ là 0.0.0.0 chưa chắc đúng.
    counter=0
    sed -i.bak"$now" -e '/address/ {
        # Increment the counter
        counter=$((counter + 1))
        # Check the counter value and replace accordingly
        if [ $counter -le 7 ]; then
            s/address.*/address		=	0.0.0.0/
        else
            s/address.*/address		=	127.0.0.1/
        fi
    }' your_file.txt

    # Override file /home/gdeliveryd/gamesys.conf: replace the line that starts with a text with a whole new line. Allow only this local machine to connect.
    sed -i "/^address/c\address				=	127.0.0.1" "$DIR_WORKSPACES_HOME/gdeliveryd/gamesys.conf"

}

function disableFirewall(){
    sudo ufw disable
    sudo systemctl disable ufw

}

function cleanUp(){
    :
}

case "$1" in
    installPackages)
        installSeverPackages
        installDevPackages
        switchTimezone
        ;;
    setupDb)
        setupDb
        enableToConnectDbFromOutsideContainer
        ;;
    setupWebTools)
        setupWebTools
        ;;
    composeScript)
        composeStartAndStopScript
        ;;
    translate)
        translateMapsIntoVietnamese
        translateIwebIntoVietnamese
        ;;
    disableFirewall)
        disableFirewall
        ;;
    *)
    echo "Usage: $0 {installPackages|setupDb|setupWebTools|composeScript|translate|disableFirewall}"
    exit 1
    ;;
esac

function main(){
    log "Script START."
    log "Each step requires several minutes so be patient..."
    trap finallyExit EXIT

    log "Step 1: Install the required ubuntu packages and i386 libs."
    installSeverPackages

    log "Step 2: Install the development related packages (apache2, mariaDB, java)."
    installDevPackages
    switchTimezone

    log "Step 3: Download Perfect World Server."
    downloadGameServer

    log "Step 4: Extract the Perfect World Server."
    extractGameServer

    log "Step 5: Setup the database."
    setupDb
    enableToConnectDbFromOutsideContainer

    log "Step 6: Setup the web tools."
    setupWebTools

    log "Step 7: Setup the Perfect World Server."
    setupGameServer
    enableGameServerConnection
    composeStartAndStopScript

    log "Step 8: Translate."
    translateMapsIntoVietnamese
    translateIwebIntoVietnamese

    log "Step 9: disable Firewall."
    disableFirewall

    log "Step 10: Clean up."
    cleanUp

    log "###########################################################################"
    log "The Perfect World ${version} game server has been completed."
    log "Run [./start] to start. Or [./start log] to start and tracing game issues."
    log "###########################################################################"

    endTime=$(date +%s)
    elapsedTime=$((endTime - startTime))
    elapsedMinutes=$((elapsedTime / 60))
    log "Total time: $elapsedMinutes minutes"
}

# Execute
#main