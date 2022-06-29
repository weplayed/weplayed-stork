wp_message() {
  if [ "$1" = "INFO" ]
  then
    echo -en "\\e[32m$1:\\e[0m"
  elif [ "$1" = "WARNING" ]
  then
    echo -en "\\e[1;33m$1:\\e[0m"
  elif [ "$1" = "ERROR" ]
  then
    echo -en "\\e[1;31m$1:\\e[0m"
  fi
  echo " ${@:2}"
}
