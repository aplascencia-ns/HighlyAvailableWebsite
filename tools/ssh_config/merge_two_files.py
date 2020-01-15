# Python Program - Merge Two Files

import shutil   # https://docs.python.org/3/library/shutil.html
import os       # https://docs.python.org/3/library/os.html?highlight=os#module-os

# Input account name
account = input("Enter account name: ")

# Exec bash for getting info from AWS and generate the files
cmd = 'sh ssh_config.sh ' + account
os.system(cmd)

# Init variables
file_current_name = "config_current"
file_account_name = "config_" + account
file_config_output = "config"

# Creating lists
list_file_current = []
list_file_account = []
block = []

###########################################
# Open config's current file and init loop
###########################################
file_current = open(file_current_name, "r")
# It reads the individual lines
file_current_rl = file_current.readlines()

# Iterate over a list
for line in file_current_rl:
    line_text = line
    # print(len(line_text))
    # print(line_text)

    # End of block
    if (len(line_text.strip()) == 0):
        # add last line before to restart
        list_file_current.append(block)

        # restart block
        block = []

        continue
    else:
        # create a list of lists
        block.append(line_text)

# print(block)
# print("############### list_file_current ###############")
# print(list_file_current)


# restart block
block = []

###########################################
# Open config's account file and init loop
###########################################
file_account = open(file_account_name, "r")
# It reads the individual lines
file_account_rl = file_account.readlines()

# Iterate over a list
for line in file_account_rl:
    line_text = line #.strip()

    # End of block
    if (len(line_text.strip()) == 0):
        # add last line before to restart
        list_file_account.append(block)

        # restart block
        block = []

        continue
    else:
        # create a list of lists
        # line_text += "\n"
        block.append(line_text)

# print("############### list_file_account ###############")
# print(list_file_account)

# getting length of list current
lenght = len(list_file_current)
equal = False

# Loop over list inside another list
for item_account in list_file_account:
    # print(item)
    for item_current in range(lenght):
        # Validate if the items have the same info in order to skip it
        if (item_account == list_file_current[item_current]):
            # Change flag 
            equal = True
            # print("EQUAL")
            # print(list_file_current[item_current])

    # Adding new items to the current file config
    if (not equal):
        list_file_current.append(item_account)
    
    # Change flag 
    equal = False

# print("##############################")
# print(list_file_current)

# Concatenate item in list to strings
joined = [''.join(row) for row in list_file_current]

# Final result
output = '\n'.join(joined) + "\n"
# print(output)

# Generating config file
file_config = open(file_config_output, "w+")
file_config.write(output)
file_config.close()

print("\nContent merged successfully.!")

# Overwrite config file
os.system('cat ./config > ~/.ssh/config')

