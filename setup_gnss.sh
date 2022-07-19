#!/bin/bash -xe


########################
#  RTCM configuration  #
########################
declare -A RTCM_ID
RTCM_ID["0x694dc2d11a"]=0
RTCM_ID["0x7b4d421598"]=1
RTCM_ID["0x7b4d3a115d"]=2
BASE=0x7b4d3a115d

NTRIP_BASE_ID=1031





ubxtool="$(which ubxtool) -P 27"
gpsd="localhost:2947"
ttys=($(find /dev -name 'ttyACM*'))

declare -A recievers
for t in ${ttys[@]}; do
        echo "Checking ${t}"
        id=$(./get_id.sh ${t})
        if [[ ! -z "${id}" ]]; then
                recievers[${id}]=${t}
                echo "${id}->${t}"
        fi
done

declare -A config_base
declare -A config_rover
declare -A config_all
config_base["CFG-USBOUTPROT-RTCM3X"]=1
config_base["CFG-USBINPROT-RTCM3X"]=1
config_base["CFG-MSGOUT-RTCM_3X_TYPE1074_USB"]=1
config_base["CFG-MSGOUT-RTCM_3X_TYPE1084_USB"]=1
config_base["CFG-MSGOUT-RTCM_3X_TYPE1094_USB"]=1
config_base["CFG-MSGOUT-RTCM_3X_TYPE1124_USB"]=1
config_base["CFG-MSGOUT-RTCM_3X_TYPE1230_USB"]=1
config_base["CFG-MSGOUT-RTCM_3X_TYPE4072_0_USB"]=1
config_base["CFG-MSGOUT-UBX_NAV_HPPOSECEF_USB"]=1
config_base["CFG-MSGOUT-UBX_NAV_HPPOSLLH_USB"]=1

config_rover["CFG-USBINPROT-RTCM3X"]=1
config_rover["CFG-USBOUTPROT-RTCM3X"]=0
config_rover["CFG-MSGOUT-RTCM_3X_TYPE1074_USB"]=0
config_rover["CFG-MSGOUT-RTCM_3X_TYPE1084_USB"]=0
config_rover["CFG-MSGOUT-RTCM_3X_TYPE1094_USB"]=0
config_rover["CFG-MSGOUT-RTCM_3X_TYPE1124_USB"]=0
config_rover["CFG-MSGOUT-RTCM_3X_TYPE1230_USB"]=0
config_rover["CFG-MSGOUT-RTCM_3X_TYPE4072_0_USB"]=0
config_rover["CFG-MSGOUT-UBX_NAV_RELPOSNED_USB"]=1
config_rover["CFG-MSGOUT-UBX_NAV_HPPOSECEF_USB"]=1
config_rover["CFG-MSGOUT-UBX_NAV_HPPOSLLH_USB"]=1

config_all["CFG-MSGOUT-UBX_RXM_RTCM_USB"]=1

protocols_all=("BINARY" "ECEF" "NED" "NMEA" "RAWX" "SFRBX" "TP")
constellations_all=("BEIDOU" "GALILEO" "GLONASS" "GPS" "SBAS")

config_session=$(date +%Y-%m-%d_%H-%M-%S)

for k in "${!recievers[@]}"; do
        port=${recievers[${k}]}
        cmdline=${ubxtool}
        for proto in ${protocols_all[@]}; do
                cmdline="${cmdline} -e ${proto}"
        done
        for cons in ${constellations_all[@]}; do
                cmdline="${cmdline} -e ${cons}"
        done

        if [[ "${BASE}" -eq "$k" ]]; then
                echo "${port} will be configured as base"

                for ck in "${!config_base[@]}"; do
                        cmdline="${cmdline} -z ${ck},${config_base[${ck}]}"
                done
                cmdline="${cmdline} -z CFG-RTCM-DF003_IN,NTRIP_BASE_ID"
                cmdline="${cmdline} -z CFG-RTCM-DF003_IN_FILTER,2"
        else
                echo "${recievers[${k}]} will be configured as rover"
                for ck in "${!config_rover[@]}"; do
                        cmdline="${cmdline} -z ${ck},${config_rover[${ck}]}"
                done
                cmdline="${cmdline} -z CFG-RTCM-DF003_IN,0"
                cmdline="${cmdline} -z CFG-RTCM-DF003_IN_FILTER,2"
        fi
        for ck in "${!config_all[@]}"; do
                cmdline="${cmdline} -z ${ck},${config_all[${ck}]}"
        done
        cmdline="${cmdline} -z CFG-RTCM-DF003_OUT,${RTCM_ID[${k}]}"
        ${cmdline} ${gpsd}:${port} | tee /tmp/${config_session}.log
done

echo "done" > /tmp/gnss-setup
