function deploy_file() {
  _db_to_deploy="${1}"
  _deploy_file="${2}"
  # ${3} is the name of log file, which is optional

  #create a temp file to hold the concatenate of the pre_deploy, deploy and post_deploy files

  filename="$(echo ${_deploy_file} | awk '{print $NF}')"
  
  tmpfile="/tmp/tmp_${filename}"
 
  cat "${fn_basedir}"/dbtype/"${dbtype}"/pre_deploy.sql > "${tmpfile}"
  cat "${_deploy_file}" | sed "s/\$(DBNAME)/${_db_to_deploy}/g" >> "${tmpfile}"

  
 #Check if a procedure, if so add GO to the post_deploy

        if grep -qi "procedure" "${tmpfile}"
        then
             echo  >> "${tmpfile}"  
             echo " GO " >> "${tmpfile}"
                
        fi

  cat "${fn_basedir}"/dbtype/"${dbtype}"/post_deploy.sql >> "${tmpfile}"

  _date_start=$(date -u +"%s")

  deploy_output=$(${db_binary} -d ${_db_to_deploy} ${server_flag}${port_flag} ${user_flag} ${password_flag} -h -1 -e -b -i "${tmpfile}")

  rc=$?

  _date_end=$(date -u +"%s")

  _script_duration=$(($_date_end-$_date_start))
  rm -f "${tmpfile}"  
  
  echo "${deploy_output}"
  echo "Script duration $(($_script_duration / 60)) minutes and $(($_script_duration % 60)) seconds." 

  if ! [ -z "${2}" ]
  then 
    echo "${deploy_output}" >> "${2}" 
  fi

  if [[ $deploy_output == *"SqlState 24000, Invalid cursor state"* ]]
  then
    echo
    echo "File failed to deploy within a transaction.  This is most likely due to a bug in the Linux SQLCMD utility.  You can attempt to deploy the file manually using the following command";
    echo ${db_binary} -d ${_db_to_deploy} ${server_flag}${port_flag} ${user_flag} ${password_flag} -h -1 -e -b -i "$_deploy_file"
    rc=1

  fi

  unset _db_to_deploy
  unset _deploy_file

  if [ ${rc} -eq 0 ]
  then
    return 0
  else
    return 1
  fi
}
