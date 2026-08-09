#!/usr/bin/awk -f
function exit_err(msg){
	exit_end=1
	exit system("cat 1>&2 <<EOF\n" msg "\n" "EOF\n" "false")
}
function err(msg){
	exit system("cat 1>&2 <<EOF\n" msg "\n" "EOF\n")
}
function shell_quote(text){
	gsub(/'/,"'\\''",text)
	return "'" text "'"
}
function shell_assignment(var,val)
{
	if (var !~ /^[_a-zA-Z][_a-zA-Z0-9]*$/) {exit_err("Invalid var name: " var);}
	return var"="shell_quote(val);
}
function arr2shell_assignments(arr){
	for (key in arr)
	{
		asses=asses (asses?"\n":"") shell_assignment(key,arr[key]);
	}
	return asses;
}

function verline_parse(out_version, verline)
{
	split(verline,vernums,".");
	if (length(vernums) < 3 || length(vernums) > 4) {
		exit_err("Incorrect number of version elements!\n >>>> " verline);
	}
	year=  vernums[1]
	month= vernums[2]
	day=   vernums[3]
	patch= vernums[4]

	if (length(year)!=4 || year < 0){
		exit_err("Incorrect year!\n >>>> " verline);
	}
	if (length(month)!=2 || month<1 || month>12){
		exit_err("Incorrect month!\n >>>> " verline);
	}
	# Not gonna check the maximum day of each month, 31 will do.
	if (length(day)!=2 || day<1 || day>31){
		exit_err("Incorrect day!\n >>>> " verline);
	}
	if (patch != "" && patch<1){
		exit_err("Incorrect patch!\n >>>> " verline);
	}

	out_version["patch"]=patch+0
	out_version["day"]  =day  +0
	out_version["month"]=month+0
	out_version["year"] =year +0
}
function version_compare(left_version, right_version){
	split("year month day patch",elements)
	for(i=1; i in elements; i++) # This way we ensure comparison order.
	{
		elm=elements[i]
		if     (left_version[elm] < right_version[elm]) {return "<"}
		else if(left_version[elm] > right_version[elm]) {return ">"}
		
	}
	return "="
}
BEGIN{
	RS="[[:space:]]*[[:space:]]*"
	exit_end=0;
	single_file=0;
	if (ARGC == 4){
		single_file=1
		# Argument parsing.
		old_file=ARGV[1]; # Just for completeness.
		message_var=ARGV[2]; delete ARGV[2]
		old_ver_var=ARGV[3]; delete ARGV[3]
		ARGC=2
	}
	else if (ARGC != 7){
		exit_err("This script takes six or three arguments:\n"\
				 "version.awk" \
				 " old_version_file version_file message_var ver_cmp_var" \
				 "old_ver_var new_ver_var\n"\
				 "OR:\n"\
				 "version.awk" \
				 " old_version_file message_var old_ver_var"\
				 )
	}
	else
	{
		# Argument parsing.
		old_file=ARGV[1];
		new_file=ARGV[2];
		message_var=ARGV[3]; delete ARGV[3]
		ver_cmp_var=ARGV[4]; delete ARGV[4]
		old_ver_var=ARGV[5]; delete ARGV[5]
		new_ver_var=ARGV[6]; delete ARGV[6]
		ARGC=3



		if (old_file==new_file){

			exit_err("Arguments should be distinct files.")
		}
	}
}

## Single file
# Reading the top (incomplete) record as message, and the last
# complete record as the version.
single_file {
	if (FNR==1) { 
		message_latest=$0
	}
	if (FNR==2) { 
		split($0,arr,"\n")
		old_verline=arr[1] 
		verline_parse(old_version, old_verline);
	}
	next
}

## Multi-file "diffing" mode.
# Old file.
FILENAME == old_file {
	if (FNR==2) { 
		split($0,arr,"\n")

		old_verline=arr[1] 
		verline_parse(old_version, old_verline);
	}
	old_fnr=FNR
}

# New file.
FILENAME == new_file {
	if (FNR==1) { 
		message_latest=$0
	}
	if (FNR==2) { 
		split($0,arr,"\n")

		new_verline=arr[1] 
		verline_parse(new_version, new_verline);

		for (i=2; i<=length(arr); i++){
			message=message (message?"\n":"") arr[i] 
		}
	}
	new_fnr=FNR
}

END {
	if (!exit_end){
		if (single_file){
			shell_return[message_var]=message_latest
			shell_return[old_ver_var]=old_verline
			print arr2shell_assignments(shell_return);
			exit
		}

		if (old_fnr < 2 || new_fnr < 2) {
			exit_err("Insufficient number of records.");	
		}
		if (old_fnr > new_fnr) {
			exit_err("Number of version records has decreased!");	
		}
		ver_cmp=version_compare(old_version,new_version)
		if (old_fnr == new_fnr) {
			err("No new versions added.");
			message=message_latest
		}
		else {
			if (ver_cmp != "<") {
				exit_err("New version is less than or equal to the last version!");	
			}
		}

		shell_return[message_var]=message
		shell_return[ver_cmp_var]=ver_cmp
		shell_return[old_ver_var]=old_verline
		shell_return[new_ver_var]=new_verline
		print arr2shell_assignments(shell_return);
	}
}


# vi: ts=4 sw=4 tw=80 cc=80
