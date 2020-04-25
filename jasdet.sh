#!/bin/bash

echo '
      _               _      _   
     | |             | |    | |  
     | | __ _ ___  __| | ___| |_ 
 _   | |/ _` / __|/ _` |/ _ \ __|
| |__| | (_| \__ \ (_| |  __/ |_ 
 \____/ \__,_|___/\__,_|\___|\__|
=======================================
Just Another SubDomain Enumeration Tool                                                             
=======================================
=================R0@r==================
'

#==========================================
# Here's where we try reading arguements as a combo-wambo
#==========================================
if [ $# -eq 0 ] || [[ -z "$1" ]]; then
	echo "Usage: ./jasdet.sh [-v] [-h] [root domain] [options]";
	echo "	-w /path/to/wordlist"
	echo "	-o /output/to/file"
	echo "	-ip outputs resolved ip addresses"	
   exit	
#if arguement 1 passed is not asking for help/version/empty
elif [[ "$1" != '-v' ]] || [[ "$1" != '-h' ]]; then
	domain=$1
	if [[ -e "/usr/share/fierce/hosts.txt" ]]; then #our defualt wordlist is set to Fierce's wordlist
                wordlist='/usr/share/fierce/hosts.txt'
	else
               	#lets get SecLists top 5000 for brute forcing
               	wget -O ~/wordlist.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/deepmagic.com-prefixes-top50000.txt > /dev/null 2>&1
               	wordlist='~/wordlist.txt'
       	fi
fi
# first case statement for help & version on arguement 1
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -v | --version )
    echo "vesion 1.3"
    exit
    ;;
  -h | --help )
	echo "Usage: ./jasdet.sh [-v] [-h] [root domain] [options]";
	echo "	-w /path/to/wordlist"
	echo "	-o /output/to/file"
	echo "	-ip outputs resolved ip addresses"	
    exit
    ;;
esac; done

# second case statement for options on arguement 2
while [[ "$2" =~ ^- && ! "$2" == "--" ]]; do case $2 in
  -w | --wordlist )	#check for wordlist
	if [ -z "$3" ] || [[ "$3" =~ ^-.* ]]; then # check next arguemnt to see if its empty or starts with '-'
		echo "No wordlist supplied! Using default";
		if [[ -e "/usr/share/fierce/hosts.txt" ]]; then #our defualt wordlist is set to Fierce's wordlist
                	wordlist='/usr/share/fierce/hosts.txt'
		else
               		#lets get SecLists top 5000 for brute forcing
                	wget -O ~/wordlist.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/deepmagic.com-prefixes-top50000.txt > /dev/null 2>&1
                	wordlist='~/wordlist.txt'
        	fi
	else
		if [[ -e "$3" ]]; then
			wordlist="$3"; #if both -w and a wordlist has been passed, fire away
			echo "Using wordlist: $wordlist"
		else
			#check for default worlist file
 			if [[ -e "/usr/share/fierce/hosts.txt" ]]; then
                		wordlist='/usr/share/fierce/hosts.txt'
			else
               		#lets get SecLists top 5000 for brute forcing
                		wget -O ~/wordlist.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/deepmagic.com-prefixes-top50000.txt > /dev/null 2>&1
                		wordlist='~/wordlist.txt'
        		fi
		fi
	fi
	shift;
    ;;
  -o | --output )
	echo $2
	echo $3
	output=1;
	if [[ "$3" =~ ^-.* ]]; then
		filename=$domain.txt
	else
		if [ ! -z "$3" ]; then
			filename="$3"
		fi
		shift;
	fi
;;
	
  -ip | --ip )
    ip=1;
    ;;
esac; shift; done
if [[ "$2" == '--' ]]; then shift; fi

#check for wildcard using a rand number .root.domain
randy=$(( RANDOM % 15000))
	if host "$randy.$domain" > /dev/null; then
		echo "Wildcard Subdomain detected. Exiting."
	else
	#If wildcard doesnt exist, start the brute force
	while read sub; do		
		if host "$sub.$domain" &> /dev/null; then
			if [ "$ip" == 1 ]; then
				current_ip=$(host $sub.$domain | grep address | awk '{print $4}' | head -n 1)
				full="$sub.$domain : $current_ip"
				if [ "$output" == 1 ]; then
					if [[ -n "$filename" ]]; then
						echo "$full" >> $filename
					else
						echo "$full" >> $domain.txt	
					fi
				else
					echo "$full"
				fi
			else
				if [ "$output" == 1 ]; then
					if [[ -n "$filename" ]]; then
						echo "$sub.$domain" >> $filename
					else
						echo "$sub.$domain" >> $domain.txt	
					fi
				else
					echo "$sub.$domain"
				fi
			fi
		fi
	done < $wordlist | xargs -n1 -P50 
	fi 