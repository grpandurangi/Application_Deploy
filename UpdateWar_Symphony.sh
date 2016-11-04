#!/bin/bash

Application="Symphony"
BASE_PATH="/home/azureuser/$Application"
ZIP_File="symphony.zip"
ZIP_Path="zip_file"
TMP_Folder="downloads"
SOURCE_CONFIG="new_files"
DESTINATION="destination_zip"

if [[ ! -d $BASE_PATH ]]; then
mkdir -p $BASE_PATH
fi

rm -rf "$BASE_PATH/$TMP_Folder"

if [[ ! -d "$BASE_PATH/$SOURCE_CONFIG" ]]; then
echo "New files folder does not exit Created. $BASE_PATH/$SOURCE_CONFIG. Copy the new files. Exiting" 
mkdir -p "$BASE_PATH/$SOURCE_CONFIG"
exit
fi

if [[ ! -d "$BASE_PATH/$TMP_Folder" ]] ; then
mkdir -p "$BASE_PATH/$TMP_Folder"
fi

#### Configuration File changes ####
echo "----------------------------------------------------------------------"
if [[ ! -e "$BASE_PATH/$ZIP_Path/$ZIP_File" ]]; then
echo "ZIP file $ZIP_File does not exist at $BASE_PATH/$ZIP_Path .Please check. Exiting"
exit
else
echo "Unpacking the ZIP file $BASE_PATH/$ZIP_Path/$ZIP_File"
unzip "$BASE_PATH/$ZIP_Path/$ZIP_File" -d "$BASE_PATH/$TMP_Folder" >/dev/null
fi

REP_NEW_FILE_LIST="$BASE_PATH/rep_new_file_list"
find "$BASE_PATH/$SOURCE_CONFIG" -type f > "$REP_NEW_FILE_LIST"

no_of_files=$(cat "$REP_NEW_FILE_LIST"| wc -l)

if [[ "$no_of_files" -gt "0" ]] ; then

echo "----------------------------------------------------------------------"
echo "List of all new files to be replaced:"
echo "----------------------------------------------------------------------"
cat "$REP_NEW_FILE_LIST"
SOURCE_LIST="$BASE_PATH/source_file_list"
find "$BASE_PATH/$TMP_Folder" -type f  > "$SOURCE_LIST"

echo "----------------------------------------------------------------------"
echo "File replacement Status:"
echo "----------------------------------------------------------------------"
IFS=$'\n'
for newline in `cat "$REP_NEW_FILE_LIST"`
do

oldline=`grep $(basename $newline) "$SOURCE_LIST"`

if [[ "$?" -eq "0" ]]; then

diff $oldline $newline >/dev/null

if [[ "$?" -eq "0" ]] ; then

echo "**)No difference between $oldline and $newline"
else

echo "##)Replaced $oldline with $newline"
cp -f $newline $oldline

fi

else

echo "??)New file $newline does not exist in source file list"

fi

done

else
echo "----------------------------------------------------------------------"
echo "No new files to be replaced. Exiting"
rm -r $BASE_PATH/$TMP_Folder  $REP_NEW_FILE_LIST  $SOURCE_LIST
exit
fi

if [[ ! -d "$BASE_PATH/$DESTINATION" ]]; then
mkdir -p "$BASE_PATH/$DESTINATION"
fi
cd $BASE_PATH
zip -r "$BASE_PATH/$DESTINATION/$ZIP_File" $TMP_Folder/* >/dev/null

if [[ "$?" -eq "0" ]]; then

echo "---------------------------------------------------------------------------"
echo "New Updated ZIP file for $Application is created: $BASE_PATH/$DESTINATION/$ZIP_File"
echo "---------------------------------------------------------------------------"
ls -lrt "$BASE_PATH/$DESTINATION/$ZIP_File" "$BASE_PATH/$ZIP_Path/$ZIP_File"
fi 

rm -r $BASE_PATH/$TMP_Folder  $REP_NEW_FILE_LIST  $SOURCE_LIST
