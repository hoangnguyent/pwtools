#!/bin/bash

# Declare resources
DIR_WORKSPACE="" # As you wish
DOWNLOAD_URL="https://drive.usercontent.google.com/download?id=1UebfhrwJIWfP5cZvdra1tNWVZb8Is9PE&export=download&authuser=0&confirm=t&uuid=5c5a1d80-c934-4688-a7a9-6630f844de42"
DOWNLOAD_FILE="pw.7z"

# Declare the structure of file/folder that must exist in the DOWNLOAD_FILE
STRUCTURE='{
    "gfactiond": "dir",
    "glinkd": "dir",
    "logservice": "dir",
    "uniquenamed": "dir",
    "authd": "dir",
    "gacd": "dir",
    "gamed": "dir",
    "gamedbd": "dir",
    "gdeliveryd": "dir",
}'

# Declare database configuration
dbHost=127.0.0.1
dbName=pw
dbUser=dba
dbPassword=dba

# Declare web tool configuration
pwAdminUsername="admin"
pwAdminRawPw="admin"
pwAdminEmail="admin@gmail.com"

# Declare hash algorithm
#algorithm="hexEncoding"
algorithm="md5AndThenBase64encoding"

# Declare your timezone
timezone=Asia/Ho_Chi_Minh

# Declare game version
version=1.7.3

# Common variables
startTime=""
now=$(date +%Y%m%d_%H%M%S)
currentSQLDate=$(date +'%F %T');
DIR_WORKSPACE_HOME="${DIR_WORKSPACE}/home"
logfile="${DIR_WORKSPACE_HOME}/${now}_setup.log"
tmpFolder="${DIR_WORKSPACE_HOME}/tmp_${now}"
iwebPasswordHash=""
pwAdminPasswordHash=""

# Text colors
B="[40;36m"
W="[0m"
G="[1;32m"
R="[1;31m"
Y="[1;33m"
P="[1;95m"


function log(){
    local message=$1
    echo -e "$message" | tee -a "$logfile"
    # Example of use: log "This is a log message"
}

function switchTimezone(){
    ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
}

function replaceLinesStart() {
    local file=$1
    local startWithText=$2
    local newLineReplacement=$3

    sed -i "/^${startWithText}/c\\${newLineReplacement}" "${file}"
}

function replaceLinesContain() {
    local file=$1
    local containText=$2
    local newLine=$3

    sed -i "/${containText}/c\\${newLine}" "${file}"
}

function replaceTexts() {
    local file=$1
    local containText=$2
    local newText=$3

    sed -i "s#${containText}#${newText}#g" "${file}"
}

replaceLineInBlock() {
    local file=$1
    local blockName=$2
    local startWithText=$3
    local newLineReplacement=$4

    # Escape special characters in blockName and startWithText
    local escapedBlockName=$(printf '%s\n' "$blockName" | sed 's/[]\/$*.^[]/\\&/g')
    local escapedStartWithText=$(printf '%s\n' "$startWithText" | sed 's/[]\/$*.^[]/\\&/g')

    # Check if the blockName exists in the file by starting with the blockName
    local blockIndex=$(grep -n "^${escapedBlockName}" "${file}" | cut -d: -f1 | head -n 1)
    if [ -z "${blockIndex}" ]; then
        log $R"Block starting with '${blockName}' not found in the file."$W
        return 1
    fi

    # Find the nearest line that starts with startWithText after the blockIndex
    local lineIndex=$(awk -v blockIndex="${blockIndex}" -v startWithText="${escapedStartWithText}" 'NR > blockIndex && $0 ~ "^" startWithText {print NR; exit}' "${file}")
    if [ -z "${lineIndex}" ]; then
        log $R"No line starting with '${startWithText}' found after block starting with '${blockName}'."$W
        return 1
    fi

    # Replace the line at lineIndex with newLineReplacement
    sed -i "${lineIndex}s/.*/${newLineReplacement}/" "${file}"
}

function extractArchive() {

    local archiveFile=$1
    local to=$2

    # Check if the file exists
    if [ ! -f "${archiveFile}" ]; then
        echo "File '${archiveFile}' does not exist."
        return 1
    fi

    # Create the target directory if it doesn't exist
    mkdir -p "${to}"

    # Extract the file extension
    local extension="${archiveFile##*.}"

    # Extract the archive based on its extension
    case "${extension}" in
        7z)
            7z x -aoa -sccutf-8 -scsutf-8 -o"${to}" "${archiveFile}"
            ;;
        rar)
            unrar x -o+ "${archiveFile}" "${to}"
            ;;
        zip)
            unzip -o "${archiveFile}" -d "${to}"
            ;;
        *)
            echo "Unsupported file extension: ${extension}"
            return 1
            ;;
    esac

    log "Extracted ${archiveFile} to ${to} successfully."
}

function installSeverPackages(){

    dpkg --add-architecture i386
    apt update
    apt install -y sudo
    apt install -y dialog apt-utils > "$logfile" 2>&1
    apt install -y mc nano wget curl sed bash grep locales dpkg net-tools iputils-ping > "$logfile" 2>&1
    apt install p7zip-full p7zip-rar unrar unzip > "$logfile" 2>&1

    # This is a tool to download specific folders from a Github repository.
    curl -sSLfo ./fetch https://github.com/gruntwork-io/fetch/releases/download/v0.4.6/fetch_linux_amd64
    chmod 777 ./fetch

    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

}

function installJdk6Manually(){
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/jdk/jdk-6u45-linux-x64.bin" "${tmpFolder}"

    chmod 777 "${tmpFolder}"/jdk-6u45-linux-x64.bin
    cd "${tmpFolder}"
    jdk-6u45-linux-x64.bin
    mv "${tmpFolder}/jdk1.6.0_45" "${DIR_WORKSPACE_HOME}"
    cd /
}

function installDevPackages(){

    installJdk6Manually
    apt install -y mariadb-server > "$logfile" 2>&1

    apt install -y libnss-nisplus libnss-db libnss-nis zlib1g > "$logfile" 2>&1
    # These are 32-bit libraries required for running 32-bit applications on a 64-bit system.
    apt install -y gcc-multilib libstdc++5:i386 libstdc++6:i386 libgcc1:i386 libxml2:i386 zlib1g:i386 libncurses5:i386 libc6:i386 > "$logfile" 2>&1

    # Copy additional libraries
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/additional-libs" "${tmpFolder}/additional-libs"
    cp "${tmpFolder}/additional-libs/*.*" /lib
    ldconfig

}

function downloadGameServer(){
    wget -c $DOWNLOAD_URL -O "${tmpFolder}/${DOWNLOAD_FILE}" > "$logfile" 2>&1
}

function extractGameServer(){

    extractArchive "${tmpFolder}/${DOWNLOAD_FILE}" "${tmpFolder}/pw" > "$logfile" 2>&1

    pathFound=$(findSubFolderWithStructure "${tmpFolder}/pw" "${STRUCTURE}")
    if [ -n "${pathFound}" ]; then
        keys=$(echo "${STRUCTURE}" | jq -r 'keys[]')
        for item in ${keys}; do
            mv -f "${pathFound}/${item}" "${DIR_WORKSPACE_HOME}"
        done
    else
        log $R"No sub-folder with the specified structure found."$W
    fi

    chmod 777 -R "${DIR_WORKSPACE_HOME}"

}

function findSubFolderWithStructure() {
    local dirToScan=$1
    local structure=$2

    # Check if the directory to scan exists
    if [ ! -d "${dirToScan}" ]; then
        echo "Directory '${dirToScan}' does not exist."
        return ""
    fi

    # Parse the JSON structure
    local keys=$(echo "${structure}" | jq -r 'keys[]')
    local allMatch

    # Scan sub-folders
    for subDir in "${dirToScan}"/*/; do
        allMatch=true
        for key in ${keys}; do
            local type=$(echo "${structure}" | jq -r --arg key "$key" '.[$key]')
            if [ "${type}" == "dir" ]; then
                if [ ! -d "${subDir}${key}" ]; then
                    allMatch=false
                    break
                fi
            elif [ "${type}" == "file" ]; then
                if [ ! -f "${subDir}${key}" ]; then
                    allMatch=false
                    break
                fi
            fi
        done

        if [ "$allMatch" = true ]; then
            echo "${subDir}"
            return
        fi
    done

    # If no matching sub-folder is found, return an empty string
    echo ""
}

function encodePassword(){
    # salt = user + pass
    iwebPasswordSalt=$(echo "${pwAdminRawPw}" | tr '[:upper:]' '[:lower:]')
    pwAdminPasswordSalt=$(echo "${pwAdminUsername}${pwAdminRawPw}" | tr '[:upper:]' '[:lower:]')

    if [ $algorithm == "hexEncoding" ]; then
        iwebPasswordHash=$(hexEncoding "$iwebPasswordSalt")
        pwAdminPasswordHash=$(hexEncoding "$pwAdminPasswordSalt")
    else
        iwebPasswordHash=$(echo -n "$pwAdminRawPw" | openssl dgst -md5 -binary | base64)
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

    wget -c https://raw.githubusercontent.com/hoangnguyent/pwtools/refs/heads/main/pwa.sql -O "$DIR_WORKSPACE/pw.sql" > "$logfile" 2>&1

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

    mariadb -u"$dbUser" -p"$dbPassword" "$dbName" < "${DIR_WORKSPACE}/pw.sql"
    rm "${DIR_WORKSPACE}/pw.sql"

    mariadb -u"$dbUser" -p"$dbPassword" "$dbName" <<EOF
        CALL adduser("$pwAdminUsername", "$pwAdminPasswordHash", "0", "0", "super admin", "0.0.0.0", "$pwAdminEmail", "0", "0", "0", "0", "0", "0", "0", "$currentSQLDate", " ", "$pwAdminPasswordHash");
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

function setupIwebJava(){

    if [ ! -d "${DIR_WORKSPACE_HOME}/tomcat" ]; then
        mkdir "${DIR_WORKSPACE_HOME}/tomcat"
    else
        rm -rf "${DIR_WORKSPACE_HOME}/tomcat"/*
    fi
    wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.108/bin/apache-tomcat-7.0.108.tar.gz && tar -xzf apache-tomcat-7.0.108.tar.gz -C "${DIR_WORKSPACE_HOME}/tomcat" --strip-components=1 > "$logfile" 2>&1

    # Use my pwadmin (iweb)
    rm -rf "${DIR_WORKSPACE_HOME}"/tomcat/webapps/pwadmin
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/pwadmin" "${DIR_WORKSPACE_HOME}"/tomcat/webapps/pwadmin

    # Override file /home/server: DB connection; [pwadmin] web tool location; and other info.
    replaceLinesStart "${DIR_WORKSPACE_HOME}/server" "# Last Updated:" "# Last Updated: $(date +'%Y/%m/%d')"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/server" "# Require:" "# Require: Perfect World server v$version"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/server" "ServerDir=" "ServerDir=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/server" "USR=" "USR=$dbUser"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/server" "PASSWD=" "PASSWD=$dbPassword"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/server" "DB=" "DB=$dbName"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/server" "DIR_TOMCAT_BIN=" "DIR_TOMCAT_BIN=${DIR_WORKSPACE_HOME}/tomcat/bin"

    # Override file /home/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp: DB connection; game location; hash algorithm for iweb password.
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_host = " "String db_host = \"$dbHost\";"
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_user = " "String db_user = \"$dbUser\";"
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_password = " "String db_password = \"$dbPassword\";"
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String db_database = " "String db_database = \"$dbName\";"
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String algorithm = " "String algorithm = \"$algorithm\";"
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String iweb_password = " "String iweb_password = \"$iwebPasswordHash\";"
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/WEB-INF/.pwadminconf.jsp" "String pw_server_path = " "String pw_server_path = \"${DIR_WORKSPACE_HOME}/\";"

    # Override file /home/tomcat/webapps/pwadmin/addons/Top Players - Manual Refresh/index.jsp: DB connection. Replace the line that contains a text with a whole new line
    replaceLinesContain "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/addons/Top Players - Manual Refresh/index.jsp" "connection = DriverManager.getConnection(" "connection = DriverManager.getConnection(\"jdbc:mysql://$dbHost:3306/$dbName?useUnicode=true&characterEncoding=utf8\", \"$dbUser\", \"$db_password\");"

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
" > "${DIR_WORKSPACE_HOME}/maps"

}

function translateIwebIntoVietnamese() {

    # Enable UTF-8 on the page.
    sed -i '1i <%@page contentType="text/html; charset=UTF-8" %>' "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp"

    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "City of Abominations" "Minh Thú Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Secret Passage" "Anh Hùng Trủng"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Firecrag Grotto" "Hỏa Nham Động Huyệt"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Den of Rabid Wolves" "Cuồng Lang Sào Huyệt"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cave of the Vicious" "Xà Hạt Động"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Hall of Deception" "Thanh Y Trủng"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Gate of Delirium" "U Minh Cư"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Secret Frostcover Grounds" "Lí Sương Bí Cảnh"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Valley of Disaster" "Thiên Kiếp Cốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Forest Ruins" "Tùng Lâm Di Tích"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cave of Sadistic Glee" "Quỷ Vực Huyễn Cảnh"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Wraithgate" "Oán Linh Chi Môn"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Hallucinatory Trench" "Bí Bảo Quật"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Eden" "Tiên Huyễn Thiên"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Brimstone Pit" "Ma Huyễn Thiên"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Temple of the Dragon" "Long Cung"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nightscream Island" "Dạ Khốc Đảo"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Snake Isle" "Vạn Xà Đảo"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Lothranis" "Tiên giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Momaganon" "Ma giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Seat of Torment" "Thiên Giới Luyện Ngục"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Abaddon" "Ma Vực Đào Nguyên"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Warsong City" "Chiến Ca Chi Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Palace of Nirvana" "Luân Hồi Điện"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Lunar Glade" "Thần Nguyệt Cốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Valley of Reciprocity" "Thần Vô Cốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Frostcover City" "Phúc Sương Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Twilight Temple" "Hoàng Hôn Thánh Điện"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cube of Fate" "Vận Mệnh Ma Phương"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Chrono City" "Thiên Lệ Chi Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Perfect Chapel" "Khung cảnh Hôn Lễ"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Guild Base" "Phụ bản Bang Phái"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Morai" "Bồng Lai Huyễn Cảnh"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Phoenix Valley" "Phượng Minh Cốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Endless Universe" "Vô Định Trụ"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Blighted Chamer" "Thần Độc Chi Gian"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Endless Universe" "Vô ĐỊnh Trụ-mô thức cấp cao"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Wargod Gulch" "Chiến Thần Cốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Five Emperors" "Ngũ Đế Chi Đô"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nation War 2" "Quốc Chiến-Cô Đảo Đoạt Kì"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nation Wa TOWER" "Quốc Chiến-Thủy Tinh Tranh Đoạt"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nation War CRYSTAL" "Quốc Chiến-Đoạn Kiều Đối Trì"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Sunset Valley" "Lạc Nhật Cốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Shutter Palace" "Bất Xá Đường"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Dragon Hidden Den" "Long Ẩn Quật"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Realm of Reflection" "Linh Đàn Huyễn Cảnh"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "startpoint" "Linh Độ Đinh Châu"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Origination" "Khung Thế Giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Primal World" "Nhân Giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Flowsilver Palace" "Lưu Ngân Cung"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Undercurrent Hall" "Phục Ba Đường"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Mortal Realm" "Mô thức Câu chuyện Nhân Giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "LightSail Cave" "Bồng Minh Động"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Cube of Fate (2)" "Vận Mệnh Ma Phương (2)"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "dragon counqest" "Thiện Long Cốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "heavenfall temple" "Tru Thiên Phù Đồ Tháp"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Uncharted Paradise" "Huyễn Hải Kì Đàm"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Thurs Fights Cross" "Thurs Fights Cross"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Western Steppes" "Đại Lục Hoàn Mĩ - Tây Lục"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Homestead, Beyond the Clouds" "Lăng Vân Giới"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Grape Valley, Grape Valley" "Grape Valley"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nemesis Gaunntlet, Museum" "Linh Lung Cục"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Dawnlight Halls, Palace of the Dawn (DR 1)" "Thự Quang Điện (DR 1)"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Mirage Lake, Mirage Lake" "Huyễn Cảnh Thận Hồ"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Rosesand Ruins, Desert Ruins" "Côi Mạc Tàn Viên"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Nightmare Woods, Forest Ruins" "Yểm Lâm Phế Khư"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Advisors Sanctum, Palace of the Dawn (DR 2)" "Thự Quang Điện (DR 2)"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Wonderland, Adventure Kingdom (Park)" "Kì Lạc Mạo Hiểm Vương Quốc"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "The Indestructible City" "Mô thức câu chuyện Tây Lục"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Phoenix Sanctum, Hall of Fame" "Phoenix Sanctum, Hall of Fame"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Town of Arrivals, Battlefield - Dusk Outpost" "Ước chiến Liên server - Long Chiến Chi Dã"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Icebound Underworld, Ice Hell (LA)" "Băng Vọng Địa Ngục"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Doosan Station, Arena of the Gods" "Doosan Station, Arena of the Gods"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Alt TT Revisited, Twilight Palace" "Alt TT Revisited, Twilight Palace"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Spring Pass, Peach Abode (Mentoring)" "Spring Pass, Peach Abode (Mentoring)"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Abode of Dreams" "Abode of Dreams"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "White Wolf Pass" "White Wolf Pass"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Imperial Battle" "Imperial Battle"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Northern Lands" "Northern Lands"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Altar of the Virgin" "Altar of the Virgin"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Imperial Battle" "Imperial Battle"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Northern Lands" "Northern Lands"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Full Moon Pavilion" "Full Moon Pavilion"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Abode of Changes" "Abode of Changes"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "quicksand maze" "quicksand maze"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "quicksand maze" "quicksand maze"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-3 PvP" "Đấu trường T-3 PvP"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-3 PvE" "Đấu trường T-3 PvE"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-2 PvP" "Đấu trường T-2 PvP"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-2 PvE" "Đấu trường T-2 PvE"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-1 PvP" "Đấu trường T-1 PvP"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Territory War T-1 PvE" "Đấu trường T-1 PvE"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Etherblade Arena" "Đấu trường Kiếm Tiên Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Lost Arena" "Đấu trường Vạn Hóa Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Plume Arena" "Đấu trường Tích Vũ Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Archosaur Arenas" "Đấu trường Tổ Long Thành"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Quicksand Maze (Sandstorm Mirage)" "Huyễn Sa Thận Cảnh"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Quicksand Maze (Mirage of the wandering sands)" "Mê Sa Huyễn Cảnh"
    replaceTexts "${DIR_WORKSPACE_HOME}/tomcat/webapps/pwadmin/serverctrl.jsp" "Tomb of Whispers" "Tomb of Whispers"

    # Có nhiều map mình không tìm được tên tiếng Việt, thậm chí dịch bừa. Ai biết, xin chỉ giùm nhé.
}

function setupWebTools() {

    setupIwebJava

    # Other tools will be placed here.
}

function composeStartAndStopScript(){

    connectionStringCommand="echo \"To connect to the DB from outside the Container, use: ${G}jdbc:mariadb://$dbHost:3306/$dbName?user=$dbUser&password=$dbPassword\""

    # Download start/stop script
    ./fetch --repo="https://github.com/hoangnguyent/pwtools" --ref="main" --source-path="/bash" "${tmpFolder}/bash" > "$logfile" 2>&1
    cp "${tmpFolder}/bash/*.*" "${DIR_WORKSPACE_HOME}"

    # Override the 'start' file
    replaceLinesStart "${DIR_WORKSPACE_HOME}/start" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    echo -e "$connectionStringCommand" >> start

    # Override the test files (9). You should run them in this order.
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_logservice" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_uniquenamed" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_authd" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_gamedbd" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_gacd" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_gfactiond" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_gdeliveryd" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_glinkd" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/test_start_gamed" "PW_PATH=" "PW_PATH=${DIR_WORKSPACE_HOME}"

    # Create file restart
    echo -e "stop\nstart" > restart

    # Grant permission
    chmod -R 777 "${DIR_WORKSPACE_HOME}"

}

function setupGameServer(){

    # Override file /home/authd/authd
    cat << 'EOF' > "${DIR_WORKSPACE_HOME}"/authd/authd
#!/bin/sh
while true; do
    /home/jdk1.6.0_45/bin/java -cp lib/application.jar:.:lib/commons-collections-3.1.jar:lib/commons-dbcp-1.2.1.jar:lib/commons-logging-1.0.4.jar:lib/commons-pool-1.2.jar:lib/jio.jar:lib/log4j-1.2.9.jar:lib/mysql-connector-java-5.1.10-bin.jar:.:.:/home/jdk1.6.0_45/lib/dt.jar:/home/jdk1.6.0_45/lib/tools.jar authd table.xml
    sleep 2
done
EOF

    # Override file /authd/table.xml and copy it to /etc
    replaceLinesStart "${DIR_WORKSPACE_HOME}/authd/table.xml" "<connection name=\"auth0\" poolsize=\"3\" url=\"jdbc:mysql" "<connection name=\"auth0\" poolsize=\"3\" url=\"jdbc:mysql://$dbHost:3306/$dbName?useUnicode=true&amp;characterEncoding=utf8&amp;jdbcCompliantTruncation=false\" username=\"$dbUser\" password=\"$dbPassword\"/>"
    cp -f "${DIR_WORKSPACE_HOME}/authd/table.xml" "/etc/table.xml"

    # Override file /authd/log4j.properties
    echo "### direct log messages to CONSOLE ###
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Target=System.out
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=gauthd: %d{dd MMM yyyy HH:mm:ss,SSS} %5p %c{1}:%L - %m%n
log4j.appender.CONSOLE.Threshold=TRACE

log4j.appender.SYSLOG=org.apache.log4j.net.SyslogAppender
log4j.appender.SYSLOG.facility=127.0.0.1 
log4j.appender.SYSLOG.layout=org.apache.log4j.PatternLayout 
log4j.appender.SYSLOG.layout.ConversionPattern=gauthd: %-5p - %m%n 
log4j.appender.SYSLOG.SyslogHost=manager
log4j.appender.SYSLOG.Threshold=TRACE

# Set root logger to TRACE level
log4j.rootLogger=trace, CONSOLE, SYSLOG
" > "${DIR_WORKSPACE_HOME}"/authd/log4j.properties

    # Override file /home/gamed/gs.conf
    replaceLinesStart "${DIR_WORKSPACE_HOME}/gamed/gs.conf" "Root" "Root = ${DIR_WORKSPACE_HOME}/gamed/config"

    # Override file /home/gdeliveryd/gamesys.conf
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[LogclientClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[LogclientTcpClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[GDeliveryServer]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[GAuthClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[GProviderServer]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[UniqueNameClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[GameDBClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[GAntiCheatClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[GFactionClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[CentralDeliveryServer]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/gdeliveryd/gamesys.conf" "[CentralDeliveryClient]" "address" "address = host.docker.internal"

    # Override file /home/glinkd/gamesys.conf
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GLinkServer1]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GLinkServer2]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GLinkServer3]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GLinkServer4]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GLinkServer5]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GLinkServer6]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GLinkServer7]" "address" "address = 0.0.0.0"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GDeliveryClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GProviderServer1]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GProviderServer2]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GProviderServer3]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GProviderServer4]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GProviderServer5]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GProviderServer6]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GProviderServer7]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[GFactionClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[LogclientClient]" "address" "address = 127.0.0.1"
    replaceLineInBlock "/${DIR_WORKSPACE_HOME}/glinkd/gamesys.conf" "[LogclientTcpClient]" "address" "address = 127.0.0.1"

    # Override /home/logservice/logservice.conf
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "threshhold" "threshhold = LOG_TRACE"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_err" "${DIR_WORKSPACE_HOME}/logs/pw.err"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_log" "${DIR_WORKSPACE_HOME}/logs/pw.log"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_formatlog" "${DIR_WORKSPACE_HOME}/logs/pw.formatlog"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_trace" "${DIR_WORKSPACE_HOME}/logs/pw.trace"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_chat" "${DIR_WORKSPACE_HOME}/logs/pw.chat"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_cash" "${DIR_WORKSPACE_HOME}/logs/pw.cash"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_statinfom" "${DIR_WORKSPACE_HOME}/logs/statinfom"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_statinfoh" "${DIR_WORKSPACE_HOME}/logs/statinfoh"
    replaceLinesStart "${DIR_WORKSPACE_HOME}/logservice/logservice.conf" "fd_statinfod" "${DIR_WORKSPACE_HOME}/logs/statinfod"

    # Sync files in folder /home/gamed/config between client and server. These 9 files should be copied manually.
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
    rm -rf /copy
}

function main(){

    switchTimezone
    startTime=$(date +%s)

    log "${G}Script started!${W}"
    log "Each step requires several minutes so be patient..."
    trap 'echo "${G}Script ended!${W}"' EXIT

    log "Step 1: Install the required ubuntu packages and i386 libs."
    installSeverPackages

    log "Step 2: Install the development related packages (mariaDB, java)."
    installDevPackages

    log "Step 3: Download Perfect World Server."
    downloadGameServer

    log "Step 4: Extract the Perfect World Server."
    extractGameServer

    log "Step 5: Encode passwords."
    encodePassword

    log "Step 6: Setup the database."
    setupDb
    enableToConnectDbFromOutsideContainer

    log "Step 7: Setup the web tools."
    setupWebTools

    log "Step 8: Setup the Perfect World ${version} Server."
    setupGameServer
    composeStartAndStopScript

    log "Step 9: Translate."
    #translateMapsIntoVietnamese
    translateIwebIntoVietnamese

    log "Step 10: Clean up."
    cleanUp

    log "#######################################################################"
    log "The Perfect World ${version} game server has been completed."
    log "Run ${G}./start${W} to start or ${G}./start trace${W} to start and tracing game issues."
    log "#######################################################################"
    echo ""
    echo -e "If you are able to login and create character but ${P}unable to enter the game${W},"
    echo -e "please re-check the C/C++ libraries installation step."
    echo ""
    endTime=$(date +%s)
    elapsedTime=$((endTime - startTime))
    elapsedMinutes=$((elapsedTime / 60))
    log "Total time: $elapsedMinutes minutes"
}

# Execute
main
