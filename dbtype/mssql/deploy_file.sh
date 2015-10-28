function deploy_file() {
  _deploy_file="${1}"
  # ${2} is the name of log file, which is optional

  #create a temp file to hold the concatenate of the pre_deploy, deploy and post_deploy files

  filename="$(echo ${_deploy_file} | awk '{print $NF}')"
  
  tmpfile="/tmp/tmp_${filename}"
 
  echo "$(cat "${fn_basedir}"/dbtype/"${dbtype}"/pre_deploy.sql >> "${tmpfile}")"
  echo "$(cat "${_deploy_file}" | sed "s/\$(DBNAME)/${dbname}/g" >> "${tmpfile}")"
  echo "$(cat "${fn_basedir}"/dbtype/"${dbtype}"/post_deploy.sql >> "${tmpfile}")"

  #deploy_output=$(${db_binary} -d ${dbname} ${server_flag}${port_flag} ${user_flag} ${password_flag} -h -1 -e -b -i "${fn_basedir}"/dbtype/"${dbtype}"/pre_deploy.sql "$_deploy_file" "${fn_basedir}"/dbtype/"$dbtype"/post_deploy.sql)
  
  deploy_output=$(${db_binary} -d ${dbname} ${server_flag}${port_flag} ${user_flag} ${password_flag} -h -1 -e -b -i "${tmpfile}")
  rc=$?

  echo "$(rm -f "${tmpfile}")"  

  echo "${deploy_output}"

  if ! [ -z "${2}" ]
  then 
    echo "${deploy_output}" >> "${2}" 
  fi

  if [[ $deploy_output == *"SqlState 24000, Invalid cursor state"* ]]
  then
    echo
    echo "File failed to deploy within a transaction.  This is most likely due to a bug in the Linux SQLCMD utility.  You can attempt to deploy the file manually using the following command";
    echo ${db_binary} -d ${dbname} ${server_flag}${port_flag} ${user_flag} ${password_flag} -h -1 -e -b -i "$_deploy_file"
    rc=1

  fi

  unset _deploy_file

  if [ ${rc} -eq 0 ]
  then
    return 0
  else
    return 1
  fi
}
