#!/bin/bash

Application="Symphony"
BASE_PATH="/home/azureuser/$Application"
ZIP_File="symphony.zip"
ZIP_Path="zip_file"
TMP_Folder="downloads"
SOURCE_CONFIG="new_files"
DESTINATION="destination_zip"

CNF1=".xml"
CNF3=".sh"
CNF2=".properties"

if [[ ! -d $BASE_PATH ]]; then
mkdir -p $BASE_PATH
fi

rm -rf "$BASE_PATH/$TMP_Folder"

if [[ ! -d "$BASE_PATH/$SOURCE_CONFIG" ]]; then
mkdir -p "$BASE_PATH/$SOURCE_CONFIG"
fi

if [[ ! -d "$BASE_PATH/$DESTINATION" ]]; then
mkdir -p "$BASE_PATH/$DESTINATION"
fi

if [[ ! -d "$BASE_PATH/$TMP_Folder" ]] ; then
mkdir -p "$BASE_PATH/$TMP_Folder"
fi

#### Configuration File changes ####

if [[ ! -e "$BASE_PATH/$ZIP_Path/$ZIP_File" ]]; then
echo "ZIP file $ZIP_File does not exist at $BASE_PATH/$ZIP_Path."
else
echo "Unpacking the ZIP file $BASE_PATH/$ZIP_Path/$ZIP_File"
unzip "$BASE_PATH/$ZIP_Path/$ZIP_File" -d "$BASE_PATH/$TMP_Folder" >/dev/null
fi

JAR=`which jar`

if [[ $? -gt "0" ]]; then
echo "jar command does not exist. Install java-devel. Exiting."
exit
fi

REP_NEW_FILE_LIST="$BASE_PATH/rep_new_file_list"
echo $REP_NEW_FILE_LIST

echo "List of all new files to be replaced:"
find "$BASE_PATH/$SOURCE_CONFIG" -type f -name "*$CNF1" -o -name "*$CNF3"  > "$REP_NEW_FILE_LIST"

SOURCE_LIST="$BASE_PATH/source_file_list"
find "$BASE_PATH/$TMP_Folder" -type f -name "*$CNF1" -o -name "*$CNF3" > "$SOURCE_LIST"
cat $SOURCE_LIST

echo "File replacement Status:"
IFS=$'\n'
for newline in `cat "$REP_NEW_FILE_LIST"`
do

oldline=`grep $(basename $newline) "$SOURCE_LIST"`

if [[ "$?" -eq "0" ]]; then

diff $oldline $newline >/dev/null

if [[ "$?" -eq "0" ]] ; then

echo "No difference between $oldline and $newline"
else

echo "Replaced $oldline with $newline"
cp -f $newline $oldline

fi

else

echo "New file $(basename $newline) does not exist in source file list"

fi

done

rm -rf $REP_NEW_FILE_LIST  $SOURCE_LIST

REST_NEW_FILE_LIST="$BASE_PATH/rest_new_file_list"
echo "List of all files to be updated:"
find "$BASE_PATH/$SOURCE_CONFIG" -type f ! -name *"$CNF1" ! -name *"$CNF3" > $REST_NEW_FILE_LIST

cat $REST_NEW_FILE_LIST

rm -rf $BASE_PATH/$TMP_Folder $REST_NEW_FILE_LIST
