#!/bin/bash
logger "ACPI event: $*"
setxkbmap "us(altgr-intl)" -option caps:escape;

R='\033[1;31m'
G='\033[1;32m'
N='\033[0;0m'

Version="0.7"
tmpHelpPage=/tmp/dockHelp.tmp
pathConfig=~/.dock
argsNum=0
args=()
optsNum=0
opts=()

MonEA=DP1
MonEB=HDMI-0
MonEC=DVI-0
MonI=LVDS1

msg="Switching to mode:"
msgMode="internal"
msgWhere="nowhere"
chwpModeL="--noop"
chwpInt=false

#Flags
Debug=false
Verbose=false
mode="int"
modeSet="-mi"
modeSetN=0
modeDesign=false
DRYRUN=""

if [ "$#" -lt 0 ]; then
  exit
fi

# load config containing all Mon* variables and Cfg
source $pathConfig/dock.conf

# help information page functions
help_Name () {
  echo -e -n \
  "${R}NAME                        ${N}                                   \n"\
  "    "\
  "dock - change docking station and monitor settings                     \n"\
  "\n"\
  >> $tmpHelpPage
}
help_Synopsis () {
  echo -e -n                                                                 \
  "${R}SYNOPSIS                    ${N}                                   \n"\
  "    "                                                                     \
  "${R}dock${N} [${R}-h|--help${N}] [${R}na|de|sy|op|ex|bu|co|au${N}]   \n\n"\
  "    "                                                                     \
  "${R}    ${N} [${R}-v|-d${N}] [${R}-w${N}] [${R}-mi|-me${N}]"              \
  "[${R}-v1|-v2${N}]"                                                        \
  "${G}designname${N}\n\n"                                                   \
  "    "                                                                     \
  "${R}    ${N} [${R}-v|-d${N}] [${R}-w${N}] [${R}-mb|-md${N}] [${R}-M${N}]" \
  "${G}designname${N}    \n\n"                                               \
  "    "                                                                     \
  "${R}    ${N} [${R}-v|-d${N}] [${R}-W|-m${N}] [${R}-mi|-me${N}]"           \
  "[${R}-v1|-v2${N}]\n\n"                                                    \
  "    "                                                                     \
  "${R}    ${N} [${R}-v|-d${N}] [${R}-A${N}] ${G}designname${N}"             \
  "(${G}wallpaper.jpg${N})\n\n"                                              \
  "    "                                                                     \
  "${R}    ${N} [${R}-v|-d${N}] [${R}-a|-L|-l${N}] \n\n"                     \
  "    "                                                                     \
  "Only the most useful options are listed here; see below the the"          \
  "remainder.\n"                                                             \
  "\n"                                                                       \
  >> $tmpHelpPage
}
help_Description () {
  echo -e -n \
  "${R}DESCRIPTION                 ${N}                                   \n"\
  "    "\
  "${R}dock${N} changes the monitor setting with regard to what devices,  \n"\
  "    "\
  "e.g. dockingstation of only external monitors/beamer are connected.    \n"\
  "    "\
  "Furhtermore, according to the choosen monitor setting, ${R}chwp${N} is"\
  "invoked\n"\
  "    "\
  "to set the wallpaper of all enabled monitors.                       \n"\
  "\n"\
  >> $tmpHelpPage
}
help_Options_General () {
  echo -e -n \
  "  "\
  "${R}Generel Options             ${N}                                   \n"\
  "    "\
  "${R}-h,  --help                 ${N}Print help information             \n"\
  "    "\
  "${R}-V,  --version              ${N}Print the version info and exist   \n"\
  "    "\
  "${R}-v,  --verbose              ${N}Use verbose output                 \n"\
  "    "\
  "${R}-d,  --debug                ${N}Start in debug mode with verbose   \n"\
  "    "\
  "${R}                            ${N}output                             \n"\
  "\n"\
  >> $tmpHelpPage
}
help_Options () {
  echo -e -n \
  "${R}OPTIONS                     ${N}                                   \n"\
  >> $tmpHelpPage
  help_Options_General
  help_Options_Information_Display
  help_Options_Config_Alter
  help_Options_Wallpaper_Setting
  help_Options_Wallpaper_Choosing
}
help_Examples () {
  echo ""
}
help_Bugs () {
  echo -e -n \
  "${R}BUGS                        ${N}                                   \n"\
  "    "\
  "No bugs (except for possible ${R}feh${N} bugs) known so far.           \n"\
  "\n" \
  >> $tmpHelpPage
}
help_Contact () {
  echo -e -n \
  "${R}CONTACT                     ${N}                                   \n"\
  "    "\
  "Please send questions to:                                              \n"\
  "    "\
  "georg.gentzen@informatik.hu-berlin.de                                  \n"\
  "\n"\
  >> $tmpHelpPage
}
help_Author () {
  echo -e -n \
  "${R}AUTHOR                      ${N}                                   \n"\
  "    "\
  "dock is written by Georg Gentzen.                                      \n"\
  "    "\
  "This help page is written by Georg Gentzen.                            \n"\
  "\n"\
  >> $tmpHelpPage
}
help_All () {
  help_Name
  help_Description
  help_Synopsis
  help_Options
  help_Examples
  help_Bugs
  help_Contact
  help_Author
}

function setMonitor() {
  argsL=()
  optsL=()
  argsLNum=0
  optsLNum=0
  msgL=""
  solLA=""
  solLB=""
  solLC=""
  outLA=""
  outLB=""
  outLC=""
  rotLA="normal"
  rotLB="normal"
  rotLC="normal"
  oriLA=""
  oriLB="--right-of"
  oriLC="--left-of"
  posLA="0x0"
  posLB="0x0"
  posLC="0x0"
  prmLA="--primary"
  prmLB=""
  prmLC=""

  #scan for Arguments and options
  for i in "$@"; do
    if [[ $i == -* ]]; then
      optsL+=("$i");
      ((++optsLNum));
    else
      argsL+=("$i");
      ((++argsLNum));
    fi
  done

  #Setting Flags
  for i in "${optsL[@]}"; do
    case $i in
      --msgL=*) ###############################################################
        msgL=${i:7}
        continue
        ;;
      --solA=*) ##############################################################
        solLA=${i:7}
        continue
        ;;
      --solB=*) ##############################################################
        solLB=${i:7}
        continue
        ;;
      --solC=*) ##############################################################
        solLC=${i:7}
        continue
        ;;
      --outA=*) ##############################################################
        outLA=${i:7}
        continue
        ;;
      --outB=*) ##############################################################
        outLB=${i:7}
        continue
        ;;
      --outC=*) ##############################################################
        outLC=${i:7}
        continue
        ;;
      --rotA=*) ##############################################################
        rotLA=${i:7}
        continue
        ;;
      --rotB=*) ##############################################################
        rotLB=${i:7}
        continue
        ;;
      --rotC=*) ##############################################################
        rotLC=${i:7}
        continue
        ;;
      --oriA=*) ##############################################################
        oriLA=${i:7}
        continue
        ;;
      --oriB=*) ##############################################################
        oriLB=${i:7}
        continue
        ;;
      --oriC=*) ##############################################################
        oriLC=${i:7}
        continue
        ;;
      --posA=*) ##############################################################
        posLA=${i:7}
        continue
        ;;
      --posB=*) ##############################################################
        posLB=${i:7}
        continue
        ;;
      --posC=*) ##############################################################
        posLC=${i:7}
        continue
        ;;
      --prmA=*) ##############################################################
        prmLA=${i:7}
        continue
        ;;
      --prmB=*) ##############################################################
        prmLB=${i:7}
        continue
        ;;
      --prmC=*) ##############################################################
        prmLC=${i:7}
        continue
        ;;
      *) #####################################################################
        break
        ;;
    esac
  done

  if [[ "$DRYRUN" == "--dryrun" ]]; then
    echo -e "Dryrun";
  fi

  if [[ $Debug == true ]]; then
    echo -e "outLA = ${outLA}"
    echo -e "solLA = ${solLA}"
    echo -e "rotLA = ${rotLA}"
    echo -e "oriLA = ${oriLA}"
    echo -e "posLA = ${posLA}"
    echo -e "prmLA = ${prmLA}"
    echo -e "outLB = ${outLB}"
    echo -e "solLB = ${solLB}"
    echo -e "rotLB = ${rotLB}"
    echo -e "oriLB = ${oriLB}"
    echo -e "posLB = ${posLB}"
    echo -e "prmLB = ${prmLB}"
    echo -e "outLC = ${outLC}"
    echo -e "solLC = ${solLC}"
    echo -e "rotLC = ${rotLC}"
    echo -e "oriLC = ${oriLC}"
    echo -e "posLC = ${posLC}"
    echo -e "prmLC = ${prmLC}"
    echo -e "chwp  = ${chwpMode}"
  fi

 if [[ $Verbose == true ]]; then
   echo -e "${msgL}";
 fi

 xrandr \
   --display :0.0 \
   ${DRYRUN} \
   --output $MonI \
   --off \
   --output $MonEA \
   --off \
   --output $MonEB \
   --off \
   --output $MonEC \
   --off \

 xrandr \
   --display :0.0 \
   ${DRYRUN} \
   --output ${outLA} \
   --mode ${solLA} \
   --rotate ${rotLA} \
   --pos ${posLA} \
   ${prmLA} \

  if [ $modeSetN -ge 2 ]; then
    if [[ $Debug == true ]]; then
      echo -e -n "Setting second monitor"
    	if [[ $modeSetN -eq 2 ]]; then
    		echo -e "/beamer."
    	elif [[ $modeSetN -eq 3 ]]; then
    		echo -e -n " for docking station.\n"
    	elif [[ $modeSetN -eq 4 ]]; then
    		echo -e -n " for desktop setup.\n"
    	fi
    fi

    xrandr \
      --display :0.0 \
      ${DRYRUN} \
      --output ${outLB} \
      --mode ${solLB} \
      --rotate ${rotLB} \
      ${oriLB} ${outLA} \
      --pos ${posLB} \
   		${prmLB}
  fi

  if [ $modeSetN -eq 4 ]; then
    if [[ $Debug == true ]]; then
      echo -e "Setting third monitor for desktop."
    fi

    xrandr \
      --display :0.0 \
      ${DRYRUN} \
      --output ${outLC} \
      --mode ${solLC} \
      --rotate ${rotLC} \
      ${oriLC} ${outLA} \
      --pos ${posLC} \
   		${prmLC}
  fi

  if [[ $modeDesign == true ]]; then
    echo ${chwpMode}
    chwp ${chwpMode}
  fi
}

function chooseMode () {
  chwpMode="--noop"

  outA=""
  solA=""
  rotA="normal"
  oriA=""
  posA="0x0"
  prmA="--primary"

  outB=""
  solB=""
  rotB="normal"
  oriB="--right-of"
  posB="0x0"
  prmB=""


  for (( x = 0; x<${#Cfg[@]}; x=x+22 )); do
    for i in "$1"; do
      if [ "${Cfg[$x+0]}" == "$i" ]; then
        outA=${Cfg[$x+1]}
        solA=${Cfg[$x+2]}
        rotA=${Cfg[$x+3]}
        oriA=${Cfg[$x+4]}
        posA=${Cfg[$x+5]}
        prmA=${Cfg[$x+6]}
        msgWhere="${i} ${Cfg[$x+7]}"

        outB=${Cfg[$x+8]}
        solB=${Cfg[$x+9]}
        rotB=${Cfg[$x+10]}
        oriB=${Cfg[$x+11]}
        posB=${Cfg[$x+12]}
        prmB=${Cfg[$x+13]}
        chwpMode=${Cfg[$x+14]}

        outC=${Cfg[$x+15]}
        solC=${Cfg[$x+16]}
        rotC=${Cfg[$x+17]}
        oriC=${Cfg[$x+18]}
        posC=${Cfg[$x+19]}
        prmC=${Cfg[$x+20]}
        break
      fi
    done
  done

  setMonitor \
    --outA=${outA} --solA=${solA} --rotA=${rotA} --oriA=${oriA} --posA=${posA} --prmA=${prmA} \
    --outB=${outB} --solB=${solB} --rotB=${rotB} --oriB=${oriB} --posB=${posB} --prmB=${prmB} \
    --outC=${outC} --solC=${solC} --rotC=${rotC} --oriC=${oriC} --posC=${posC} --prmC=${prmC} \
    --msgL="${msg} ${msgMode} with settings: ${msgWhere}." \
    ;
}

#scan for Arguments and options
for i in "$@"; do
  if [[ $i == -* ]]; then
    opts+=("$i");
    ((++optsNum));
  else
    args+=("$i");
    ((++argsNum));
  fi
done

#if arguments contain -h or --help, ignore all other
#arguments, print help text and exit
for i in "${opts[@]}"; do
  case $i in
    -h|--help) #################################################################
      touch $tmpHelpPage        
      case ${args[0]} in
        na)
          help_Name
          ;;
        de)
          help_Description
          ;;
        sy)
          help_Synopsis
          ;;
        op)
          help_Options
          ;;
        ex)
          help_Examples
          ;;
        bu)
          help_Bugs
          ;;
        co)
          help_Contact
          ;;
        au)
          help_Author
          ;;
        *)
          help_All
          ;;
      esac
      less -R $tmpHelpPage
      rm -f $tmpHelpPage
      exit 1;
      ;;
    -V|--version) ##############################################################
      echo "dock $Version"
      exit
      ;;
    *)
      # ignore other arguments and values
      ;;
  esac
done

#Setting Flags
for i in "${opts[@]}"; do
  case $i in
    -v|--verbose) ############################################################
      Verbose=true
      if [ $# == 1 ]; then
        setBlack=true
      fi
      continue
      ;;
    --debug) #################################################################
      Debug=true
      Verbose=true
      echo "***Debuggig Mode***"
      echo "Command: $@"
      continue
      ;; 
    --dryrun) ################################################################
      DRYRUN="--dryrun"
      continue
      ;;
    --chwp) ##################################################################
      modeDesign=true
      continue
      ;;
    -md|--set-three) #########################################################
      modeSet="$i"
      modeSetN=4
      msgMode="desktopThreeMon"
      continue
      ;;
    -md|--set-dock) ##########################################################
      modeSet="$i"
      modeSetN=3
      msgMode="docking station"
      continue
      ;;
    -mb|--set-beamer) ########################################################
      modeSet="$i"
      modeSetN=2
      msgMode="beamer/internal+external"
      continue
      ;;
    -me|--set-ext) ###########################################################
      modeSet="$i"
      modeSetN=1
      msgMode="external"
      continue
      ;;
    -mi|--set-int) ###########################################################
      modeSet="$i"
      modeSetN=0
      msgMode="internal"
      continue
      ;;
    -ci|--chwp-on-int) #######################################################
      chwpInt=true
      continue
      ;;
    *) #######################################################################
      continue; 
      ;;
  esac
done
 
#workaround because event ids for docking and undocking are the same:
#check lan connection
#==> if arguments contain --auto, check for 
#enabled lan connection
for i in "${opts[@]}"; do
  case $i in
    --auto)
      sleep 5;
      tail -100 /var/log/syslog | grep "enp0s25" | grep "> activated";
      if [ $? -eq 0 ]; then
        #overwrite log so it won't produce ambiguities
        for i in $(seq 1 100); do
          logger "Dock overwrite: $i";
        done
        broadcastTI="141.20.33.255"
        broadcastActual=$(ip a s dev enp0s25 | awk '/inet / {print $4}')
        if [ "$broadcastTI" == "$broadcastActual" ]; then
          chooseMode "-md" "ti";
        else
          chooseMode "-md" "home";
        fi
        exit;
      else
        #tail -100 /var/log/syslog | grep "enp0s25" | grep "> unavailable";
        #if [ $? -eq 0 ]; then
          for i in $(seq 1 100); do
            logger "Dock overwrite: $i";
          done
          chooseMode "-mi"
          exit;
        #else
        #  exit 1;
        #fi
      fi
      exit;
      ;;
    *)
      # ignore other arguments and values
      ;;
  esac
done

xrandr --dpi 96

if [ "$argsNum" -ge 1 ]; then
  mode="${args[0]}"
fi

if [[ $Verbose == true ]]; then
  echo "Docking Station setting script";
  echo "----------------------------------------------------------------------"
fi

chooseMode "$mode"

if [ $Verbose == true ]; then
  echo "----------------------------------------------------------------------"
  echo "mode:    $mode"
  echo "modeSet: $modeSet"
  echo "----------------------------------------------------------------------"
fi
i3-msg restart;
exit;
