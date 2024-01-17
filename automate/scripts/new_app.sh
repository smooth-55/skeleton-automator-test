#!/bin/bash

set -e



os_name=$(uname)
ROOT=$(pwd)
read -r _ project_name _ <go.mod
project_name=$(echo $project_name | tr -d '\r')
app_directory="${ROOT}/apps"


printf " App name should be in snake_case eg: my_app *\n"
printf "\n*Enter app name: "
read app_name

# check if app name is empty or not
if [ -z "$app_name" ]; then
    echo "App name is empty. Please enter a non-empty name."
    exit
fi

# Check if the app exists
if [ -d "$app_directory/${app_name}" ]; then
  echo "$app_name already exists try with different app name."
  exit
else
  mkdir ${app_directory}/${app_name}
  cd ${app_directory}/${app_name}
  mkdir controllers services repository models routes init
fi

# convert string to pascal case
make_pascal_case_str() {
  pascal_case=""
  # Split the string into an array using '_' as the delimiter
  IFS="_" read -ra words <<< "$1" #spliting string by _
  # Loop through the words and capitalize the first letter of each word
  for word in "${words[@]}"; do
    # Capitalize the first letter of the word
    capitalized_word=$(echo "$word" | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')
    pascal_case="${pascal_case}${capitalized_word}"
  done

  echo "$pascal_case"
}

#create file
create_file() {
    #pass first parameter as entity name
    #pass second parameter as file to write
    entity_name=$1
    file_to_write=$2

    cat "${ROOT}/automate/templates/new_app/${entity_name}.txt" >>$file_to_write

    for item in "${placeholder_value_hash[@]}"; do
        placeholder="${item%%:*}"
        value="${item##*:}"
        if [[ $os_name == "Darwin" ]]; then
            sed -i "" "s/$placeholder/$value/g" $file_to_write
            continue
        fi
        sed -i "s/$placeholder/$value/g" $file_to_write

    done
}

printf "* Creating new app: ${app_name} *\n"
method_name=$(make_pascal_case_str $app_name)
router_package_name="${app_name}_router"

placeholder_value_hash=(
  "{{app_name}}:$app_name"
  "{{project_name}}:$project_name"
  "{{app_uppercase}}:$method_name"
)

entity_path_hash=(
  "controllers:${ROOT}/apps/${app_name}/controllers"
  "dtos:${ROOT}/apps/${app_name}"
  "init:${ROOT}/apps/${app_name}/init"
  "helpers:${ROOT}/apps/${app_name}"
  "models:${ROOT}/apps/${app_name}/models"
  "repository:${ROOT}/apps/${app_name}/repository"
  "routes:${ROOT}/apps/${app_name}/routes"
  "services:${ROOT}/apps/${app_name}/services"
)



for entity in "${entity_path_hash[@]}"; do
    entity_name="${entity%%:*}"
    entity_path="${entity##*:}"
    file_to_write="$entity_path/${entity_name}.go"
    create_file $entity_name $file_to_write

done

# setting up constructors and routes
config_path="${ROOT}/config/conf.go"
router_path="${ROOT}/config/router.go"
import_name="${project_name}/apps/${app_name}/init"
import_name_router="${project_name}/apps/${app_name}/routes"

fx_installed_app_string="var InstalledApps = fx.Options("

if [[ $os_name == "Darwin" ]]; then

  sed -i '' -e "/^import (/a\\
  ${app_name} \"$import_name\"
  " $config_path

 
  sed -i "" "s/${fx_installed_app_string}/${fx_installed_app_string}\n\t  ${app_name}.Module,/g" $config_path
else
sed -i "s/${fx_installed_app_string}/${fx_installed_app_string}\n\t  ${app_name}.Module,/g" $config_path
fi

# # router

if [[ $os_name == "Darwin" ]]; then
  sed -i '' -e "/^import (/a\\
  ${app_name} \"$import_name_router\"
  " $router_path

  sed -i "" "s/func RoutersConstructor(/func RoutersConstructor(\n\t ${method_name}Routes  ${app_name}.${method_name}Route,/g" $router_path
  sed -i "" "s/return Routes{/return Routes{\n\t ${method_name}Routes,/g" $router_path

else
  sed -i "s/func RoutersConstructor(/func RoutersConstructor(\n\t ${method_name}Routes ${app_name}.${method_name}Route,/g" $router_path
  sed -i "s/return Routes{/return Routes{\n\t ${method_name}Routes,/g" $router_path
fi

printf "* ${app_name} app created successfully. *\n"

