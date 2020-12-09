#!/bin/bash

folders_without_tf=("images" "playbooks" "node-rds" "code" "dist" "custom_policies")
not_ready_modules=("Management")
not_root_modules=("module")

folders=("${folders_without_tf[@]}" "${not_ready_modules[@]}" "${not_root_modules[@]}")

formatter() {
  for f in *;  do
    if [ -d $f  -a ! -h $f ] && [[ ! " ${folders[@]} " =~ " $f " ]];
    then
        cd -- "$f"
          w=80
          l=$(($w-${#f[@]}))
          s=$(printf "%-${l}s" "*")
          g=$(printf "%-$(($w-10))s" "-")
          r=$(printf "%-$(($w-9))s" "-")
          echo -e "\e[34m\e[1m[$f] ${s// /*}\e[0m";

          if test -f "main.tf";
          then

          echo -e "\e[2m[Formatting] ${g// /-}\e[0m";
          terraform fmt;
          echo -e "\e[0m\e[2m[Resources] ${r// /-}\e[0m";

          if test -f "configure_variables.sh";
          then
            . ./configure_variables.sh
          fi

          terraform plan -detailed-exitcode &> /dev/null;

            if [ $? ];
            then
              echo -e "terraform plan: WORKING"
            else
              echo -e "\e[31mterraform plan: NOT WORKING\e[0m"
            fi

            if test -f "terraform.tfstate";
            then
              echo -e "tfstate: YES"
              RES=$(jq '.resources | length' terraform.tfstate)
              if [ $RES = 0 ];
              then
                echo -e "resources: "$RES
              else
                echo -e "\e[31mresources: $RES\e[0m"
              fi
            else
              echo -e "tfstate: NO"
            fi

          else
            echo -e "N/A"
          fi

        formatter
        cd ..
    fi
  done;
}

formatter
