#!/usr/bin/env bash

# Init variables
# account_name="$1"
# file_config_account="./config_$account_name"
# file_config_current="./config_current"
# file_config_output="./config"
# file_config_local="${HOME}/.ssh/config"
# file_config_backup="${HOME}/.ssh/config_backup"

file_current_name="./config_current"
file_account_name="./config_nearsoft" # + account
file_config_output="config"

# Creating lists
declare -a list_file_current    # listTXT1
declare -a list_file_current2
declare -a list_file_account    # listTXT2
declare -a list_file_account2
block=""
block2=""
endBlock=false 

###########################
# Read a file liby by line
########################### IFS= 
input_original="${file_current_name}"
while IFS= read -r line
do
    original_line=$line
    formatted_line=`echo ${line} | sed 's/ //g'`

    if [ "$formatted_line" == "" ]; then
        endBlock=true

    elif $endBlock ; then  # is the same like [$endBlock = true]
        list_file_current=("${list_file_current[@]}""${block}")
        list_file_current2=("${list_file_current2[@]}""${block2}\n")

        # Clean variable
        block=""
        block="${formatted_line}"

        block2=""
        block2="${original_line}\n"

        endBlock=false
    else
        # Se va armando el bloque
        block="${block}${formatted_line}"

        block2="${block2}${original_line}\n"
    fi
done < "${input_original}"

if [ "$block" != "" ]; then
    # echo "***FINAL***"
    # echo $block
    list_file_current=("${list_file_current[@]}""${block}")
    list_file_current2=("${list_file_current2[@]}""${block2}\n")
fi

# echo "${list_file_current[@]}"
# echo "${list_file_current2[@]}"


#====================================================================
block=""
block2=""
endBlock=false 


input_account="${file_account_name}"
while IFS= read -r line
do
    original_line=$line
    formatted_line=`echo ${line} | sed 's/ //g'`

    if [ "$formatted_line" == "" ]; then
        endBlock=true

    elif $endBlock ; then  # is the same like [$endBlock = true]
        list_file_account=("${list_file_account[@]}""${block}")
        list_file_account2=("${list_file_account2[@]}""${block2}\n")

        # Clean variable
        block=""
        block="${formatted_line}"

        block2=""
        block2="${original_line}\n"

        endBlock=false
    else
        # Se va armando el bloque
        block="${block}${formatted_line}"

        block2="${block2}${original_line}\n"
    fi
done < "${input_account}"

if [ "$block" != "" ]; then
    # echo "***FINAL***"
    # echo $block
    list_file_account=("${list_file_account[@]}""${block}")
    list_file_account2=("${list_file_account2[@]}""${block2}")
fi

# echo "${list_file_current[@]}"
# echo ""
# echo "${list_file_current2[@]}"````
# echo "${list_file_account[@]}"
# echo ""
# echo "${list_file_account2[@]}"


#====================================================================
# simple array list and loop for display
i=0
flag=true
for obj2 in ${list_file_account[@]}; do
    for obj3 in ${list_file_current[@]}; do
        if [ "$obj2" == "$obj3" ]; then
            flag=false
            echo "ENTRO"
        fi
    done 

    if $flag ; then
        list_file_current=("${list_file_current[@]}""${obj2}")
        list_file_current2=("${list_file_current2[@]}""${list_file_account2[$i]}")
    fi

    flag=true
    i="`expr $i + 1`"
done


> output_file
echo "${list_file_current2[@]}" > output_file

cat output_file > config


