#!/bin/bash
#TeaSpeak updater ved Nicer
#Testet på Debian

#farvekoder fra https://raw.githubusercontent.com/Sporesirius/TeaSpeak-Installer/master/teaspeak_install.sh
function warn() {
    echo -e "\\033[33;1m${@}\033[0m"
}

function error() {
    echo -e "\\033[31;1m${@}\033[0m"
}

function info() {
    echo -e "\\033[36;1m${@}\033[0m"
}

function green() {
    echo -e "\\033[32;1m${@}\033[0m"
}

function cyan() {
    echo -e "\\033[36;1m${@}\033[0m"
}

function red() {
    echo -e "\\033[31;1m${@}\033[0m"
}

function yellow() {
    echo -e "\\033[33;1m${@}\033[0m"
}


#kontrol for parametre
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--force)
    FORCE="TRUE"
    shift # tidligere argument
    ;;
    -p|--path)
    FOLDER="$2"
    shift # tidligere argument
    shift # tidligere vurdere
    ;;
    -s|--start)
    START="$2"
    shift # tidligere argument
    shift # tidligere vurdere
    if [[ -z $START ]]
    then
      START="teastart.sh start"
    fi
    ;;
    *)    # ukendt mulighed
    POSITIONAL+=("$1") # gemme det i et array til senere
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # gendanne positionsparametre

#main
if [ -z "$FOLDER" ]
then
        FOLDER="$(dirname "$(readlink -f "$0")")"
else
        if [[ $FOLDER == */ ]]
        then
            FOLDER=${FOLDER:0:(-1)}
        fi
fi

if [ ! -f "$FOLDER/buildVersion.txt" ] 
then
	error "buildVersion.txt ikke fundet, kan ikke fortsætte med opdatering!";
	exit 1;
fi

if [[ "$(uname -m)" == "x86_64" ]];
then
    arch="amd64"
else
    arch="x86"
fi

latest_version=$(curl -k --silent https://repo.teaspeak.de/server/linux/$arch/latest)
current_version=$(head -n 1 "$FOLDER/buildVersion.txt")
current_version=${current_version:11}

if [[ "$latest_version" == "$current_version" ]];
then
   green "Du bruger allerede den nyeste version af TeaSpeak. Der er intet at opdatere :)";
   exit 0;
fi

if [[ -z $FORCE ]];
then
	read -n 1 -r -s -p "$(yellow En opdatering er tilgængelig, vil du opdatere? [y/n])"
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]];
	then
		error "Afbryder opdatering"
		exit 0;
	fi
else
	info "Fundet ny version ($latest_version), starter opdatering"
fi

info "Tjekker om server kører..."
if [[ $($FOLDER/teastart.sh status) == "Server kører" ]];
then
	info "Server kører stadig! Lukker det ned...."
	$FOLDER/teastart.sh stop
fi
info "Sikkerhedskopiering af gammel server som TeaSpeakBackup_$current_version.tar.gz"
tar -C $FOLDER/ -zcvf TeaSpeakBackup_$current_version.tar.gz config.yml TeaData.sqlite --overwrite >/dev/null
info "Downloader serverversion $latest_version";
wget -q -O /tmp/TeaSpeak.tar.gz https://repo.teaspeak.de/server/linux/$arch/TeaSpeak-$latest_version.tar.gz;
info "Udpakker det til $FOLDER/";
tar -C $FOLDER/ -xzf /tmp/TeaSpeak.tar.gz --overwrite
info "Fjernelse af midlertidig fil";
rm /tmp/TeaSpeak.tar.gz
green "Opdatering afsluttet!";

if [[ ! -z $START ]]
then
  info "Starter server op";
  $FOLDER/$START;
fi
exit 0;
