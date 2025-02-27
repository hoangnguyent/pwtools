#!/bin/bash

# Declare your virtualization info.
YOUR_VIRTUALIZATION=vmware # "docker" or "vmware" or empty
YOUR_VIRTUALIZATION_IP=192.168.23.131
# If this IP is not localhost or 127.0.0.1, you may have to add it to /etc/hosts. Remember, this file is reset every time the Container reboots.

# Declare resources
DIR_MOUNT=/home # This must be one of your mount folders.
DIR_WORKING=/game # As you wish. "" is also fine.
DOWNLOAD_URL="https://drive.usercontent.google.com/download?id=1UebfhrwJIWfP5cZvdra1tNWVZb8Is9PE&export=download&authuser=0&confirm=t&uuid=5c5a1d80-c934-4688-a7a9-6630f844de42"
YOUR_COMPRESSED_FILE="173v344.7z" 

# Declare the structure of the file/folder that must stay inside the YOUR_COMPRESSED_FILE
STRUCTURE='{
    "authd"         : "dir",
    "gacd"          : "dir",
    "gamed"         : "dir",
    "gamedbd"       : "dir",
    "gdeliveryd"    : "dir",
    "gfactiond"     : "dir",
    "glinkd"        : "dir",
    "logservice"    : "dir",
    "uniquenamed"   : "dir"
}' # Do NOT left any trailing comma!!!

# Declare database configuration
DB_NAME=pw
DB_USER=dba
DB_PASSWORD=dba

# Declare web tool configuration
PW_ADMIN_USER="admin"
PW_ADMIN_RAW_PW="admin"
PW_ADMIN_MAIL="admin@gmail.com"

# Declare hash algorithm. "hexEncoding" or "md5AndThenBase64encoding" or empty
#ALGORITHM="hexEncoding"
ALGORITHM="md5AndThenBase64encoding"

# Declare your info
GAME_VERSION=1.7.3
TIMEZONE=Asia/Ho_Chi_Minh

####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################

# Common variables
startTime=""
now=$(date +%Y%m%d_%H%M%S)
currentSQLDate=$(date +'%F %T');
iwebPasswordHash=""
pwAdminPasswordHash=""
workspace=""
if [ -n "${DIR_MOUNT}" ]; then
    workspace="${DIR_MOUNT}"
fi
if [ -n "${DIR_WORKING}" ]; then
    if [ -n "${workspace}" ]; then
        workspace="${workspace}/${DIR_WORKING}"
    else
        workspace="${DIR_WORKING}"
    fi
fi
if [[ "${workspace}" != /* ]]; then
    workspace="/${workspace}"
fi
workspace=$(echo "${workspace}" | sed 's|//|/|g')
setupFolder="${workspace}/${now}_setup"
setupLogFile="${workspace}/${now}_setup.log"
mkdir -p "${setupFolder}"
mkdir -p "${setupFolder}/pw"
chmod -R 755 "${workspace}"

# Text colors
B="[40;36m"
W="[0m"
G="[1;32m"
R="[1;31m"
Y="[1;33m"
P="[1;95m"

hostnamesResolution="127.0.0.1 AUDATA\n127.0.0.1 audb\n127.0.0.1 aumanager\n127.0.0.1 auth\n127.0.0.1 backup\n127.0.0.1 database\n127.0.0.1 delivery\n127.0.0.1 game1\n127.0.0.1 game2\n127.0.0.1 gm_server\n127.0.0.1 gmserver\n127.0.0.1 link1\n127.0.0.1 LOCAL0\n127.0.0.1 localhost\n127.0.0.1 localhost.localdomain\n127.0.0.1 LogServer\n127.0.0.1 manager\n127.0.0.1 PW-Server"
#hostCommand="if ! grep -q \"127.0.0.1 AUDATA\" /etc/hosts; then echo \"The Docker container reverts the /etc/hosts whenever it restarts. We are re-adding the hostnames resolution automatically...\"; echo -e \"${hostnamesResolution}\" >> /etc/hosts; fi"

function downloadGameServer(){
    #wget -c $DOWNLOAD_URL -O "${setupFolder}/${YOUR_COMPRESSED_FILE}"

    # If you don't want to download file but use an existing one,
    # just place the file everywhere inside your DIR_MOUNT and use this command:
    find "${DIR_MOUNT}" -type f -name "$YOUR_COMPRESSED_FILE" -exec rsync -avh {} "${setupFolder}" \; -quit

}

function switchTimezone(){
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
}

function replaceLinesStart() {
    local file=$1
    local startWithText=$2
    local newLineReplacement=$3 # single line only

    # Escape backslashes and forward slashes in the newLineReplacement variable
    newLineReplacement=$(echo "${newLineReplacement}" | sed 's/[\/&]/\\&/g')

    if ! sed -i "/^${startWithText}/c\\${newLineReplacement}" "${file}"; then
        echo -e "replaceLinesStart failed with file ${file}"
        return 1
    fi
}

function replaceLinesContain() {
    local file=$1
    local containText=$2
    local newLineReplacement=$3 # single line only

    # Escape backslashes and forward slashes in the newLineReplacement variable
    newLineReplacement=$(echo "${newLineReplacement}" | sed 's/[\/&]/\\&/g')

    if ! sed -i "/${containText}/c\\${newLineReplacement}" "${file}"; then
        echo -e "replaceLinesContain failed with file ${file}"
        return 1
    fi
}

function replaceTexts() {
    local file=$1
    local containText=$2
    local newText=$3 # single line only

    # Escape backslashes and forward slashes in the newText variable
    newText=$(echo "${newText}" | sed 's/[\/&]/\\&/g')
    
    if ! sed -i "s#${containText}#${newText}#g" "${file}"; then
        echo -e "replaceTexts failed with file ${file}"
        return 1
    fi
}

function replaceLineStartInBlock() {
    local file=$1
    local blockName=$2
    local startWithText=$3
    local newLineReplacement=$4 # single line only

    # Escape special characters in blockName and startWithText
    local escapedBlockName=$(printf '%s\n' "$blockName" | sed 's/[]\/$*.^[]/\\&/g')
    local escapedStartWithText=$(printf '%s\n' "$startWithText" | sed 's/[]\/$*.^[]/\\&/g')

    # Check if the blockName exists in the file by starting with the blockName
    local blockIndex=$(grep -n "^${escapedBlockName}" "${file}" | cut -d: -f1 | head -n 1)
    if [ -z "${blockIndex}" ]; then
        echo -e "Block starting with '${blockName}' not found in the file ${file}."
        return 1
    fi

    # Find the nearest line that starts with startWithText after the blockIndex
    local lineIndex=$(awk -v blockIndex="${blockIndex}" -v startWithText="${escapedStartWithText}" 'NR > blockIndex && $0 ~ "^" startWithText {print NR; exit}' "${file}")
    if [ -z "${lineIndex}" ]; then
        echo -e "No line starting with '${startWithText}' found after block starting with '${blockName}'."
        return 1
    fi

    # Escape backslashes and forward slashes in the newLineReplacement variable
    newLineReplacement=$(echo "${newLineReplacement}" | sed 's/[\/&]/\\&/g')

    # Replace the line at lineIndex with newLineReplacement
    if ! sed -i "${lineIndex}s|.*|${newLineReplacement}|" "${file}"; then
        echo -e "replaceLineStartInBlock failed with file ${file}"
        return 1
    fi
}

function installSeverPackages(){

    dpkg --add-architecture i386
    apt-get update && apt-get -y upgrade
    apt update && apt -y upgrade

    apt-get install -y aptitude
    apt-get install -y bash curl dpkg iputils-ping jq grep locales mc nano net-tools rsync sed wget
    apt-get install -y p7zip-full p7zip-rar unrar unzip

    # This is a tool to download specific folders from a Github repository.
    curl -sSLfo ./fetch https://github.com/gruntwork-io/fetch/releases/download/v0.4.6/fetch_linux_amd64
    chmod 755 ./fetch

}

function installDevPackages(){

    apt install -y aptitude
    aptitude install -y build-essential gcc-multilib:i386 libstdc++5:i386 libstdc++6:i386 libgcc1:i386 libxml2:i386 libncurses5:i386 libc6:i386
    aptitude install -y libnss-db libnss-nisplus libnss-nis zlib1g

    echo -e "Download additional libraries."
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/additional-libs" "${setupFolder}/additional-libs"
    chmod -R 755 "${setupFolder}/additional-libs"
    cp -f "${setupFolder}/additional-libs/lib"/libcom_err.so.3 /lib
    cp -f "${setupFolder}/additional-libs/lib"/libcrypto.so.4 /lib
    cp -f "${setupFolder}/additional-libs/lib"/libpcre.so.0 /lib
    cp -f "${setupFolder}/additional-libs/lib"/libtask.so /lib

    ldconfig

}

function installJdk8Manually(){

    apt update
    apt install -y openjdk-8-jdk

    export JAVA_8=$(find /usr/lib/jvm -type d -name "java-*-openjdk*" -print -quit)
    export JAVA_HOME=$JAVA_8
    export PATH=$JAVA_8/bin:$PATH
    java -version

}

function encodePassword(){

    # salt = user + pass
    iwebPasswordSalt=$(echo "${PW_ADMIN_RAW_PW}" | tr '[:upper:]' '[:lower:]')
    pwAdminPasswordSalt=$(echo "${PW_ADMIN_USER}${PW_ADMIN_RAW_PW}" | tr '[:upper:]' '[:lower:]')

    if [ "$ALGORITHM" == "hexEncoding" ]; then
        iwebPasswordHash=$(hexEncoding "$iwebPasswordSalt")
        pwAdminPasswordHash=$(hexEncoding "$pwAdminPasswordSalt")
    else
        iwebPasswordHash=$(echo -n "$PW_ADMIN_RAW_PW" | openssl dgst -md5 -binary | base64)
        pwAdminPasswordHash=$(echo -n "$pwAdminPasswordSalt" | openssl dgst -md5 -binary | base64)
    fi

}

function hexEncoding() {
    local salt="$1"
    local md5sum
    local hex_string="0x"

    # Generate MD5 hash
    md5sum=$(echo -n "$salt" | md5sum | awk '{print $1}')

    # Convert to uppercase and format as needed
    for (( i=0; i<${#md5sum}; i+=2 )); do
        hex_byte="${md5sum:$i:2}"
        hex_string+="$hex_byte"
    done

    echo "$hex_string"
}

function setupDb() {

    chmod -R 755 /etc/mysql
    chmod -R 755 /var/lib/mysql

    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/pwa.sql" "${setupFolder}/pwa.sql"

    # Remove database if exist
    service mariadb stop
    apt remove -y --purge mariadb-server mariadb-client
    #apt remove -y --purge mariadb-common # I remove this command because it requires confirmation manually
    apt autoremove -y
    apt autoclean -y

    # Update package list and install database
    apt update
    apt install -y mariadb-server
    service mariadb start

    # Create the database and insert 1 first record.
    mariadb -u"root" -p"123456" <<EOF
        DROP DATABASE IF EXISTS ${DB_NAME};
        CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

    mariadb -u"root" -p"123456" "${DB_NAME}" < "${setupFolder}/pwa.sql"

    mariadb -u"root" -p"123456" "${DB_NAME}" <<EOF
        CALL adduser("${PW_ADMIN_USER}", "${pwAdminPasswordHash}", "0", "0", "super admin", "0", "${PW_ADMIN_MAIL}", "0", "0", "0", "0", "0", "0", "0", "${currentSQLDate}", " ", "${pwAdminPasswordHash}");
EOF

    lastInsertedUserId=$(mariadb -u"root" -p"123456" "${DB_NAME}" -se "SELECT ID from users WHERE name=\"$PW_ADMIN_USER\"");
    echo "last inserted id: ${lastInsertedUserId}";
    if [[ "${lastInsertedUserId}" =~ ^[0-9]+$ ]]; then
        mariadb -u"root" -p"123456" "${DB_NAME}" <<EOF
            CALL addGM("${lastInsertedUserId}", "1");
            INSERT INTO usecashnow (userid, zoneid, sn, aid, point, cash, status, creatime) VALUES ("${lastInsertedUserId}", "1", "0", "1", "0", "100000", "1", "${currentSQLDate}") ON DUPLICATE KEY UPDATE cash = cash + 100000;
EOF
    fi

}

function enableToConnectDbFromOutside(){

    service mariadb start

    # Grant permissions
    user_exists=$(mysql -u"root" -p"123456" -se "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER' AND host = 'localhost');")
    if [ "$user_exists" -eq 1 ]; then
        mysql -u"root" -p"123456" -e "DROP USER '$DB_USER'@'localhost';"
    fi
    mysql -u"root" -p"123456" -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"

    user_exists=$(mysql -u"root" -p"123456" -se "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER' AND host = '${YOUR_VIRTUALIZATION_IP}');")
    if [ "$user_exists" -eq 1 ]; then
        mysql -u"root" -p"123456" -e "DROP USER '$DB_USER'@'${YOUR_VIRTUALIZATION_IP}';"
    fi
    mysql -u"root" -p"123456" -e "CREATE USER '$DB_USER'@'${YOUR_VIRTUALIZATION_IP}' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'${YOUR_VIRTUALIZATION_IP}';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'${YOUR_VIRTUALIZATION_IP}';"

    user_exists=$(mysql -u"root" -p"123456" -se "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER' AND host = '%');")
    if [ "$user_exists" -eq 1 ]; then
        mysql -u"root" -p"123456" -e "DROP USER '$DB_USER'@'%';"
    fi
    mysql -u"root" -p"123456" -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';"

    user_exists=$(mysql -u"root" -p"123456" -se "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER' AND host = '172.17.0.1');") # these are for Docker container only
    if [ "$user_exists" -eq 1 ]; then
        mysql -u"root" -p"123456" -e "DROP USER '$DB_USER'@'172.17.0.1';"
    fi
    mysql -u"root" -p"123456" -e "CREATE USER '$DB_USER'@'172.17.0.1' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'172.17.0.1';"
    mysql -u"root" -p"123456" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'172.17.0.1';"


    mysql -u"root" -p"123456" -e "FLUSH PRIVILEGES;"

    # Allow all IP addresses from the outside.
    chmod 755 /etc/mysql/my.cnf
    if grep -q "^\[mysqld\]" /etc/mysql/my.cnf; then
        # Append settings to the [mysqld] section
        sed -i '/^\[mysqld\]/a \
log_error = /var/log/mysql/error.log\n
bind-address = 0.0.0.0\n
skip-name-resolve' /etc/mysql/my.cnf
    else
        # Add [mysqld] section and settings at the end of the file
        echo -e "\n[mysqld]\nlog_error = /var/log/mysql/error.log\nbind-address = 0.0.0.0\nskip-name-resolve" | tee -a /etc/mysql/my.cnf
    fi

    service mariadb restart

}

function setupIwebJava(){

    if [ ! -d "${workspace}/tomcat" ]; then
        mkdir "${workspace}/tomcat"
        chmod -R 755 "${workspace}/tomcat"
    else
        rm -rf "${workspace}/tomcat"/*
    fi

    # Download Tomcat
    wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.108/bin/apache-tomcat-7.0.108.tar.gz && tar -xzf apache-tomcat-7.0.108.tar.gz -C "${workspace}/tomcat" --strip-components=1
    chmod -R 755 "${workspace}/tomcat/bin"

    # Use my pwadmin (iweb)
    rm -rf "${workspace}"/tomcat/webapps/pwadmin
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/pwadmin" "${workspace}"/tomcat/webapps/pwadmin

    # Override file /tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp: DB connection; game location; hash algorithm for iweb password.
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_host = " "String db_host = \"$YOUR_VIRTUALIZATION_IP\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_user = " "String db_user = \"$DB_USER\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_password = " "String db_password = \"$DB_PASSWORD\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_database = " "String db_database = \"$DB_NAME\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String algorithm = " "String algorithm = \"$ALGORITHM\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String iweb_password = " "String iweb_password = \"$iwebPasswordHash\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String pw_server_path = " "String pw_server_path = \"${workspace}/\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String pw_server_name = " "String pw_server_name = \"${workspace}\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String pw_server_exp = " "String pw_server_exp = \"1\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String pw_server_sp = " "String pw_server_sp = \"1\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String pw_server_drop = " "String pw_server_drop = \"1\";"
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String pw_server_coins = " "String pw_server_coins = \"1\";"

    # Override file /tomcat/webapps/pwadmin/addons/Top Players - Manual Refresh/index.jsp
    replaceLinesContain "${workspace}/tomcat/webapps/pwadmin/addons/Top Players - Manual Refresh/index.jsp" "connection = DriverManager.getConnection(" "connection = DriverManager.getConnection(\"jdbc:mysql://$YOUR_VIRTUALIZATION_IP:3306/$DB_NAME?useUnicode=true&characterEncoding=utf8\", \"$DB_USER\", \"$db_password\");"

    # Override file /tomcat/webapps/pwadmin/WEB-INF/classes/iweb.conf. Then move it to /etc/ to enable commands from the Web tools.
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/iweb.conf" "version" "version = ${GAME_VERSION}"
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/iweb.conf" "update" "update = $(date +'%Y/%m/%d')"
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/iweb.conf" "comment" "comment = Auto configured."
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/iweb.conf" "game" "game = Perfect World"
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/iweb.conf" "build" "build = $(now)"
    mv -f "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/iweb.conf" /etc

    # Override file /tomcat/webapps/pwadmin/WEB-INF/classes/version.conf
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/version.conf" "version" "version = ${GAME_VERSION}"
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/version.conf" "comment" "comment = Auto configured."
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/version.conf" "game" "game = Perfect World"
    replaceLinesStart "${workspace}/tomcat/webapps/pwadmin/WEB-INF/classes/version.conf" "build" "build = $(now)"

}

function translateMapsIntoVietnamese() {

    echo -e "yes,gs01,Thế Giới
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
" > "${workspace}/maps"

}

function translateIwebIntoVietnamese() {

    # Enable UTF-8 on the page.
    sed -i '1i <%@page contentType="text/html; charset=UTF-8" %>' "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp"

    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "City of Abominations" "Minh Thú Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Secret Passage" "Anh Hùng Trủng"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Firecrag Grotto" "Hỏa Nham Động Huyệt"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Den of Rabid Wolves" "Cuồng Lang Sào Huyệt"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cave of the Vicious" "Xà Hạt Động"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Hall of Deception" "Thanh Y Trủng"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Gate of Delirium" "U Minh Cư"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Secret Frostcover Grounds" "Lí Sương Bí Cảnh"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Valley of Disaster" "Thiên Kiếp Cốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Forest Ruins" "Tùng Lâm Di Tích"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cave of Sadistic Glee" "Quỷ Vực Huyễn Cảnh"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Wraithgate" "Oán Linh Chi Môn"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Hallucinatory Trench" "Bí Bảo Quật"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Eden" "Tiên Huyễn Thiên"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Brimstone Pit" "Ma Huyễn Thiên"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Temple of the Dragon" "Long Cung"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nightscream Island" "Dạ Khốc Đảo"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Snake Isle" "Vạn Xà Đảo"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Lothranis" "Tiên giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Momaganon" "Ma giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Seat of Torment" "Thiên Giới Luyện Ngục"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Abaddon" "Ma Vực Đào Nguyên"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Warsong City" "Chiến Ca Chi Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Palace of Nirvana" "Luân Hồi Điện"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Lunar Glade" "Thần Nguyệt Cốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Valley of Reciprocity" "Thần Vô Cốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Frostcover City" "Phúc Sương Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Twilight Temple" "Hoàng Hôn Thánh Điện"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cube of Fate" "Vận Mệnh Ma Phương"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Chrono City" "Thiên Lệ Chi Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Perfect Chapel" "Khung cảnh Hôn Lễ"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Guild Base" "Phụ bản Bang Phái"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Morai" "Bồng Lai Huyễn Cảnh"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Phoenix Valley" "Phượng Minh Cốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Endless Universe" "Vô Định Trụ"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Blighted Chamer" "Thần Độc Chi Gian"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Endless Universe" "Vô ĐỊnh Trụ-mô thức cấp cao"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Wargod Gulch" "Chiến Thần Cốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Five Emperors" "Ngũ Đế Chi Đô"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nation War 2" "Quốc Chiến-Cô Đảo Đoạt Kì"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nation Wa TOWER" "Quốc Chiến-Thủy Tinh Tranh Đoạt"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nation War CRYSTAL" "Quốc Chiến-Đoạn Kiều Đối Trì"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Sunset Valley" "Lạc Nhật Cốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Shutter Palace" "Bất Xá Đường"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Dragon Hidden Den" "Long Ẩn Quật"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Realm of Reflection" "Linh Đàn Huyễn Cảnh"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "startpoint" "Linh Độ Đinh Châu"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Origination" "Khung Thế Giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Primal World" "Nhân Giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Flowsilver Palace" "Lưu Ngân Cung"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Undercurrent Hall" "Phục Ba Đường"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Mortal Realm" "Mô thức Câu chuyện Nhân Giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "LightSail Cave" "Bồng Minh Động"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cube of Fate (2)" "Vận Mệnh Ma Phương (2)"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "dragon counqest" "Thiện Long Cốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Uncharted Paradise" "Huyễn Hải Kì Đàm"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Thurs Fights Cross" "Thurs Fights Cross"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Western Steppes" "Đại Lục Hoàn Mĩ - Tây Lục"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Grape Valley, Grape Valley" "Grape Valley"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nemesis Gaunntlet, Museum" "Linh Lung Cục"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Dawnlight Halls, Palace of the Dawn (DR 1)" "Thự Quang Điện (DR 1)"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Mirage Lake, Mirage Lake" "Huyễn Cảnh Thận Hồ"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Rosesand Ruins, Desert Ruins" "Côi Mạc Tàn Viên"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nightmare Woods, Forest Ruins" "Yểm Lâm Phế Khư"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Advisors Sanctum, Palace of the Dawn (DR 2)" "Thự Quang Điện (DR 2)"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Wonderland, Adventure Kingdom (Park)" "Kì Lạc Mạo Hiểm Vương Quốc"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "The Indestructible City" "Mô thức câu chuyện Tây Lục"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Phoenix Sanctum, Hall of Fame" "Phoenix Sanctum, Hall of Fame"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Town of Arrivals, Battlefield - Dusk Outpost" "Ước chiến Liên server - Long Chiến Chi Dã"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Icebound Underworld, Ice Hell (LA)" "Băng Vọng Địa Ngục"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Doosan Station, Arena of the Gods" "Doosan Station, Arena of the Gods"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Alt TT Revisited, Twilight Palace" "Alt TT Revisited, Twilight Palace"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Spring Pass, Peach Abode (Mentoring)" "Spring Pass, Peach Abode (Mentoring)"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Abode of Dreams" "Abode of Dreams"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "White Wolf Pass" "White Wolf Pass"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Imperial Battle" "Imperial Battle"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Northern Lands" "Northern Lands"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Altar of the Virgin" "Altar of the Virgin"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Imperial Battle" "Imperial Battle"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Northern Lands" "Northern Lands"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Full Moon Pavilion" "Full Moon Pavilion"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Abode of Changes" "Abode of Changes"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "quicksand maze" "quicksand maze"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "quicksand maze" "quicksand maze"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-3 PvP" "Đấu trường T-3 PvP"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-3 PvE" "Đấu trường T-3 PvE"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-2 PvP" "Đấu trường T-2 PvP"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-2 PvE" "Đấu trường T-2 PvE"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-1 PvP" "Đấu trường T-1 PvP"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-1 PvE" "Đấu trường T-1 PvE"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Etherblade Arena" "Đấu trường Kiếm Tiên Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Lost Arena" "Đấu trường Vạn Hóa Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Plume Arena" "Đấu trường Tích Vũ Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Archosaur Arenas" "Đấu trường Tổ Long Thành"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Quicksand Maze (Sandstorm Mirage)" "Huyễn Sa Thận Cảnh"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Quicksand Maze (Mirage of the wandering sands)" "Mê Sa Huyễn Cảnh"
    replaceTexts "${workspace}/tomcat/webapps/pwadmin/serverctrl.jsp" "Tomb of Whispers" "Tomb of Whispers"

    # Có nhiều map mình không tìm được tên tiếng Việt, thậm chí dịch bừa. Ai biết, xin chỉ giùm nhé.
}

function setupWebTools() {

    setupIwebJava

    # Other tools will be placed here.
}

function extract() {

    local compressedFile=$1
    local to=$2

    # Check if the file exists
    if [ ! -f "${compressedFile}" ]; then
        echo "File '${compressedFile}' does not exist."
        return 1
    fi

    # Detect the file extension
    local extension="${compressedFile##*.}"

    # Extract the file based on it's extension
    case "${extension}" in
        7z)
            timeout 600 7z x -aoa -sccutf-8 -scsutf-8 -o"${to}" "${compressedFile}"
            ;;
        rar)
            timeout 600 unrar x -o+ "${compressedFile}" "${to}"
            ;;
        zip)
            timeout 600 unzip -o "${compressedFile}" -d "${to}"
            ;;
        gz)
            timeout 600 tar -xzf "${compressedFile}" -C "${to}"
            ;;
        *)
            echo "Unsupported file extension: ${extension}"
            return 1
            ;;
    esac

    echo -e "Extracted ${compressedFile} to ${to} successfully."
    return 0
}

function findSubFolderWithStructure() {
    local dirToScan=$1
    local structure=$2

    # Check if the directory to scan exists
    if [ ! -d "${dirToScan}" ]; then
        echo "Directory '${dirToScan}' does not exist."
        return 1
    fi

    # Parse the JSON structure
    local keys=$(echo "${structure}" | jq -r 'keys[]')
    local firstKey=$(echo "${keys}" | head -n 1)
    local firstType=$(echo "${structure}" | jq -r --arg key "$firstKey" '.[$key]')

    # Find all paths that contain the first key with the correct type
    local foundPaths=()
    if [ "${firstType}" == "dir" ]; then
        while IFS= read -r -d '' path; do
            foundPaths+=("$path")
        done < <(find "${dirToScan}" -type d -name "${firstKey}" -print0)
    elif [ "${firstType}" == "file" ]; then
        while IFS= read -r -d '' path; do
            foundPaths+=("$path")
        done < <(find "${dirToScan}" -type f -name "${firstKey}" -print0)
    fi

    # Check each found path for the remaining structure
    for path in "${foundPaths[@]}"; do
        local parentDir=$(dirname "$path")
        local allMatch=true

        for key in ${keys}; do
            local type=$(echo "${structure}" | jq -r --arg key "$key" '.[$key]')
            if [ "${type}" == "dir" ]; then
                if [ ! -d "${parentDir}/${key}" ]; then
                    allMatch=false
                    break
                fi
            elif [ "${type}" == "file" ]; then
                if [ ! -f "${parentDir}/${key}" ]; then
                    allMatch=false
                    break
                fi
            fi
        done

        if [ "$allMatch" = true ]; then
            echo "${parentDir}"
            return
        fi
    done

    # If no matching sub-folder is found, return an empty string
    echo ""
}

function moveGameServerToCorrectLocation(){

    pathFound=$(findSubFolderWithStructure "${setupFolder}/pw" "${STRUCTURE}")

    if [ -n "${pathFound}" ]; then
        echo -e "Moving Game server from ${pathFound} to ${setupFolder}/pw}"

        keys=$(echo "${STRUCTURE}" | jq -r 'keys[]')
        for item in ${keys}; do
            rsync -avh "${pathFound}/${item}" "${workspace}"
            chmod -R 755 "${workspace}/${item}"
        done

    else
        echo -e "No sub-folder that contains the specified structure of the Game Server found."
    fi

}

function composeStartAndStopScript(){

    # Download scripts
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/bash" "${setupFolder}/bash"
    chmod -R 755 "${setupFolder}/bash"
    cp "${setupFolder}/bash"/server "${workspace}"
    cp "${setupFolder}/bash"/start "${workspace}"
    cp "${setupFolder}/bash"/stop "${workspace}"

    # Override file 'server' file : DB connection; [pwadmin] web tool location; and other info.
    replaceLinesStart "${workspace}/server" "# Last Updated:" "# Last Updated: $(date +'%Y/%m/%d')"
    replaceLinesStart "${workspace}/server" "# Require:" "# Require: Perfect World server v$GAME_VERSION"
    replaceLinesStart "${workspace}/server" "ServerDir=" "ServerDir=${workspace}"
    replaceLinesStart "${workspace}/server" "USR=" "USR=$DB_USER"
    replaceLinesStart "${workspace}/server" "PASSWD=" "PASSWD=$DB_PASSWORD"
    replaceLinesStart "${workspace}/server" "DB=" "DB=$DB_NAME"
    replaceLinesStart "${workspace}/server" "DIR_TOMCAT_BIN=" "DIR_TOMCAT_BIN=${workspace}/tomcat/bin"

    # Override the 'start' file
    replaceLinesStart "${workspace}/start" "PW_PATH=" "PW_PATH=${workspace}"
    export JAVA_LOCATION=$(find /usr/lib/jvm -type d -name "java-*-openjdk*" -print -quit)
    replaceLinesContain "${workspace}/start" "nohup sh -c" "nohup sh -c \"JAVA_HOME=${JAVA_LOCATION} \${PW_PATH}/tomcat/bin/startup.sh\" &"
    replaceLinesContain "${workspace}/start" "# display pwadmin url here" "    echo \${G}\"http://${YOUR_VIRTUALIZATION_IP}:8080/pwadmin\"\${W}"
    replaceLinesContain "${workspace}/start" "# display warning about hosts here" "${hostCommand}"
    jdbcCommand="    echo \"Use: \${G}jdbc:mysql://$YOUR_VIRTUALIZATION_IP:3306/$DB_NAME?user=$DB_USER&password=$DB_PASSWORD\${W} to connect to the DB from the outside.\""
    replaceLinesContain "${workspace}/start" "# display jdbc string here" "${jdbcCommand}"

    # Override the test files (9). You should run them in this order.
    #cp "${setupFolder}/bash/test_"* "${workspace}"
    #replaceLinesStart "${workspace}/test_start_logservice" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_uniquenamed" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_authd" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_gamedbd" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_gacd" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_gfactiond" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_gdeliveryd" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_glinkd" "PW_PATH=" "PW_PATH=${workspace}"
    #replaceLinesStart "${workspace}/test_start_gamed" "PW_PATH=" "PW_PATH=${workspace}"
    #chmod 755 "${workspace}/test_"*

    # Move start/stop to /
    mv -f "${workspace}/start" /
    mv -f "${workspace}/stop" /

    # Create file restart
    echo -e "./stop\n./start \"\$@\"" > "restart"

    # Grant permission
    chmod 755 "start"
    chmod 755 "stop"
    chmod 755 "restart"

}

function setupGameServer(){

    # Use my authd instead of the original authd
    echo -e "Backup the original [authd]."
    mv "${workspace}/authd" "${workspace}/authd_original" 
    echo -e "Download [authd]."
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/authd" "${workspace}/authd"
    chmod -R 755 "${workspace}/authd"

    # Override file /authd/authd.
    path_table_xml=$(find "${workspace}/authd" -name "table.xml" -print -quit)

    if [ -n "${path_table_xml}" ]; then
        export JAVA_LOCATION=$(find /usr/lib/jvm -type d -name "java-*-openjdk*" -print -quit)
        authd_path=$(dirname "${path_table_xml}")
        cat << EOF > "${authd_path}/authd"
#!/bin/sh
while true; do
    "${JAVA_LOCATION}/bin/java" -cp lib/application.jar:.:lib/commons-collections-3.1.jar:lib/commons-dbcp-1.2.1.jar:lib/commons-logging-1.0.4.jar:lib/commons-pool-1.2.jar:lib/jio.jar:lib/log4j-1.2.9.jar:lib/mysql-connector-java-5.1.10-bin.jar:.:.:"${JAVA_LOCATION}/lib/dt.jar":"${JAVA_LOCATION}/lib/tools.jar" authd table.xml
    sleep 2
done
EOF
    fi

    # Override file /authd/authd.conf
    replaceLineStartInBlock "${authd_path}/authd.conf" "[GAuthServer]" "mtrace" "mtrace = ${authd_path}/mtrace.authd"

    # Override file /authd/table.xml and copy it to /etc
    replaceLinesStart "${path_table_xml}" "<connection name=\"auth0\" poolsize=\"3\" url=\"jdbc:mysql" "<connection name=\"auth0\" poolsize=\"3\" url=\"jdbc:mysql://$YOUR_VIRTUALIZATION_IP:3306/$DB_NAME?useUnicode=true&amp;characterEncoding=utf8&amp;jdbcCompliantTruncation=false\" username=\"$DB_USER\" password=\"$DB_PASSWORD\"/>"

    # Override file /authd/log4j.properties
    echo "### direct log messages to CONSOLE ###
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Target=System.out
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=gauthd: %d{dd MMM yyyy HH:mm:ss,SSS} %5p %c{1}:%L - %m%n
log4j.appender.CONSOLE.Threshold=TRACE

log4j.appender.SYSLOG=org.apache.log4j.net.SyslogAppender
log4j.appender.SYSLOG.facility=LOCAL0 
log4j.appender.SYSLOG.layout=org.apache.log4j.PatternLayout 
log4j.appender.SYSLOG.layout.ConversionPattern=gauthd: %-5p - %m%n 
log4j.appender.SYSLOG.SyslogHost=localhost
log4j.appender.SYSLOG.Threshold=TRACE

# Set root logger to TRACE level
log4j.rootLogger=trace, CONSOLE, SYSLOG
" > "${authd_path}/log4j.properties"

    # Override file /gacd/gamesys.conf
    replaceLinesContain "${workspace}/gacd/gamesys.conf" "mtrace" "mtrace = ${workspace}/logs/gacd.log"

    # Override file /gamed/gmserver.conf
    replaceLinesStart "${workspace}/gamed/gmserver.conf" "address" "address = 127.0.0.1"

    # Override file /gamed/gs.conf
    replaceLinesStart "${workspace}/gamed/gs.conf" "Root" "Root = ${workspace}/gamed/config"
    replaceLineStartInBlock "${workspace}/gamed/gs.conf" "[MsgTCPSession]" "address" "address = 127.0.0.1"

    # Override file /gamed/gsalias.conf
    replaceLinesStart "${workspace}/gamed/gsalias.conf" "Root" "Root = ./config/"

    # Override file /gamedbd/gamesys.conf
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storage]" "homedir" "homedir = ${workspace}/gamedbd/dbhome"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storage]" "datadir" "datadir = dbdata"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storage]" "logdir" "logdir = dblogs"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storage]" "backupdir" "backupdir = ${workspace}/gamedbd/dbhome/backup"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storage]" "cachesize" "cachesize = 99999999"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storagewdb]" "homedir" "homedir = ${workspace}/gamedbd/dbhomewdb"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storagewdb]" "datadir" "datadir = dbdata"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storagewdb]" "logdir" "logdir = dblogs"
    replaceLineStartInBlock "${workspace}/gamedbd/gamesys.conf" "[storagewdb]" "backupdir" "backupdir = ${workspace}/gamedbd/dbhomewdb/backup"

    # Override file /gdeliveryd/gamesys.conf
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[LogclientClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[LogclientTcpClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[GDeliveryServer]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[GAuthClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[GProviderServer]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[UniqueNameClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[GameDBClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[GAntiCheatClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[GFactionClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[CentralDeliveryServer]" "address" "address = 0.0.0.0"
    yourVirtualization=$(echo "${YOUR_VIRTUALIZATION}" | tr '[:upper:]' '[:lower:]')
    if [[ "${yourVirtualization}" == *"docker"* ]]; then
        replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[CentralDeliveryClient]" "address" "address = host.docker.internal"
    else
        replaceLineStartInBlock "${workspace}/gdeliveryd/gamesys.conf" "[CentralDeliveryClient]" "address" "address = ${YOUR_VIRTUALIZATION_IP}"
    fi

    # Override file /glinkd/gamesys.conf
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GLinkServer1]" "address" "address = 0.0.0.0"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GLinkServer2]" "address" "address = 0.0.0.0"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GLinkServer3]" "address" "address = 0.0.0.0"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GLinkServer4]" "address" "address = 0.0.0.0"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GLinkServer5]" "address" "address = 0.0.0.0"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GLinkServer6]" "address" "address = 0.0.0.0"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GLinkServer7]" "address" "address = 0.0.0.0"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GDeliveryClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GProviderServer1]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GProviderServer2]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GProviderServer3]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GProviderServer4]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GProviderServer5]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GProviderServer6]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GProviderServer7]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[GFactionClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[LogclientClient]" "address" "address = 127.0.0.1"
    replaceLineStartInBlock "${workspace}/glinkd/gamesys.conf" "[LogclientTcpClient]" "address" "address = 127.0.0.1"

    # Override /logservice/logservice.conf
    replaceLinesStart "${workspace}/logservice/logservice.conf" "threshhold" "threshhold = LOG_TRACE"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_err" "fd_err = ${workspace}/logs/pw.err"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_log" "fd_err = ${workspace}/logs/pw.log"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_formatlog" "fd_formatlog = ${workspace}/logs/pw.formatlog"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_trace" "fd_trace = ${workspace}/logs/pw.trace"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_chat" "fd_chat = ${workspace}/logs/pw.chat"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_cash" "fd_cash = ${workspace}/logs/pw.cash"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_statinfom" "fd_statinfom = ${workspace}/logs/statinfom"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_statinfoh" "fd_statinfoh = ${workspace}/logs/statinfoh"
    replaceLinesStart "${workspace}/logservice/logservice.conf" "fd_statinfod" "fd_statinfod = ${workspace}/logs/statinfod"

    # Override /uniquenamed/gamesys.conf
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storage]" "homedir" "homedir = ${workspace}/uniquenamed/uname"
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storage]" "datadir" "datadir = dbdata"
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storage]" "logdir" "logdir = dblogs"
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storage]" "backupdir" "backupdir = ${workspace}/uniquenamed/uname/backup"
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storagewdb]" "homedir" "homedir = ${workspace}/uniquenamed/uname"
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storagewdb]" "datadir" "datadir = dbdata"
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storagewdb]" "logdir" "logdir = dblogs"
    replaceLineStartInBlock "${workspace}/uniquenamed/gamesys.conf" "[storagewdb]" "backupdir" "backupdir = ${workspace}/uniquenamed/backup"

    # Sync files in folder /gamed/config between client and server. These 9 files should be copied manually.
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

function cleanUp(){
    rm -rf "${setupFolder}"
    rm -f /apache-tomcat-7.0.108.tar.gz
}

function note(){
    echo ""
    echo -e "If you are able to login and create character but ${P}unable to enter the game${W},"
    echo -e "please re-check the \"installDevPackages\" step."
    echo -e "Run this command to check which libraries are missing:"
    echo -e "ldd ${workspace}/gacd/gacd ${workspace}/gamed/gs ${workspace}/gamedbd/gamedbd ${workspace}/gdeliveryd/gdeliveryd ${workspace}/gfactiond/gfactiond ${workspace}/glinkd/glinkd ${workspace}/logservice/logservice ${workspace}/uniquenamed/uniquenamed"
    echo ""
}

function finallyEnd(){

    echo "${G}Script ended!${W}"

    endTime=$(date +%s)
    elapsedTime=$((endTime - startTime))
    elapsedMinutes=$((elapsedTime / 60))
    echo -e "\nTotal time: ${elapsedMinutes} minutes"

    note
}

function main(){

    switchTimezone
    startTime=$(date +%s)

    echo -e "${G}Script started!${W}"
    echo -e "Each step requires several minutes so be patient..."
    trap finallyEnd EXIT

    cd /

    echo -e "\nStep 1: Install the required packages."
    installSeverPackages

    echo -e "\nStep 2: Install the development packages (C/C++, i386 libs)."
    installDevPackages

    echo -e "\nStep 3: Install Java."
    installJdk8Manually

    echo -e "\nStep 4: Encode passwords."
    encodePassword

    echo -e "\nStep 5: Setup the database."
    setupDb
    enableToConnectDbFromOutside

    echo -e "\nStep 6: Setup the web tools."
    setupWebTools

    echo -e "\nStep 7: Download Perfect World Server."
    downloadGameServer

    echo -e "\nStep 8: Extract the Perfect World Server. It may take a long time."
    extract "${setupFolder}/${YOUR_COMPRESSED_FILE}" "${setupFolder}/pw"
    chmod -R 755 "${setupFolder}/pw"
    moveGameServerToCorrectLocation

    echo -e "\nStep 9: Setup the Perfect World ${GAME_VERSION} Server."
    setupGameServer
    composeStartAndStopScript
    find "${workspace}/authd" -type f -name "authd.conf" -exec cp {} "/etc" \; -quit
    find "${workspace}/authd" -type f -name "table.xml" -exec cp {} "/etc" \; -quit

    echo -e "\nStep 10: Translate."
    #translateMapsIntoVietnamese
    translateIwebIntoVietnamese

    cleanUp

    echo -e "#######################################################################"
    echo -e "The Perfect World ${GAME_VERSION} game server has been completed."
    echo -e "Run ${G}/start${W} to start or ${G}/start trace${W} to start and trace game issues."
    echo -e "#######################################################################"

}

# Execute
main
#main >> "$setupLogFile" 2>&1
