#!/bin/bash -xem


gpsd="localhost:2947"
ttys=($(find /dev -name 'ttyACM*'))

declare -A recievers
for t in ${ttys[@]}; do
	echo "Checking ${t}"
	id=$(get_id.sh ${t})
	if [[ ! -z "${id}" ]]; then
		recievers[${id}]=${t}
		echo "${id}->${t}"
	fi
done

record_session=$(date +%Y-%m-%d_%H-%M-%S)

declare -A pids
for k in "${!recievers[@]}"; do
	port=${recievers[${k}]}
	gpspipe -R ${gpsd}:${port} > /var/gnss/${record_session}.${k}.ubx &
	pids[${k}]=$!
done

for k in "${!pids[@]}"; do
	wait ${pids[${k}]}
done
