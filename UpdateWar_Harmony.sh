#!/bin/bash

Application="Harmony"
BASE_PATH="/home/azureuser/$Application"
WAR_File="hmytrn.war"
ZIP_File="harmony.zip"
ZIP_Path="zip_file"
TMP_Folder="downloads"
SOURCE_CONFIG="new_files"
DESTINATION="destination_zip"
HARMONY_PROPERTY="harmony.properties"

if [[ ! -d $BASE_PATH ]]; then
mkdir -p $BASE_PATH
fi

rm -rf "$BASE_PATH/$TMP_Folder"

if [[ ! -d "$BASE_PATH/$SOURCE_CONFIG" ]]; then
echo "New files folder does not exit Created. $BASE_PATH/$SOURCE_CONFIG. Copy the new files. Exiting" 
mkdir -p "$BASE_PATH/$SOURCE_CONFIG"
exit
fi


#### Configuration File changes ####
echo "----------------------------------------------------------------------"
if [[ ! -e "$BASE_PATH/$ZIP_Path/$ZIP_File" ]]; then
echo "ZIP file $ZIP_File does not exist at $BASE_PATH/$ZIP_Path .Please check. Exiting"
if [[ ! -d "$BASE_PATH/$ZIP_Path" ]] ; then
mkdir -p "$BASE_PATH/$ZIP_Path"
fi
exit
else
if [[ ! -d "$BASE_PATH/$TMP_Folder" ]] ; then
mkdir -p "$BASE_PATH/$TMP_Folder"
fi
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
echo "No new files to be replaced."
fi
#********************************************
JAR=`which jar`

if [[ $? -gt "0" ]]; then

echo "jar command does not exist. Install java-devel exiting."
exit

fi
if [[ ! -f $BASE_PATH/$HARMONY_PROPERTY ]]; then

echo "----------------------------------------------------------------------"
echo "Harmony Property file does not exist. No changes would be done to files inside JAR files"
echo "----------------------------------------------------------------------"

else

echo "----------------------------------------------------------------------"
echo "For files mentioned in $HARMONY_PROPERTY file"
echo "----------------------------------------------------------------------"


GET_WAR_FILE=$( find $BASE_PATH/$TMP_Folder/ -type f -name hmytrn.war)

temp_folder_1="war_folder"
mkdir -p "$BASE_PATH/$TMP_Folder/$temp_folder_1"; cd "$BASE_PATH/$TMP_Folder/$temp_folder_1"
$JAR -xvf $GET_WAR_FILE >/dev/null


IFS=$'\n'
for line in `cat $BASE_PATH/$HARMONY_PROPERTY`
do

file=$(echo $line |awk -F "=" '{print $1}')
path=$(echo $line |awk -F "=" '{print $2}')

if [ -d "$BASE_PATH/$TMP_Folder/$temp_folder_1/$path" ] ; then
    if [[ -f "$BASE_PATH/$TMP_Folder/$temp_folder_1/$path/$file" ]] ; then
    new_file=$(grep $file $REP_NEW_FILE_LIST) 
    echo "File $file located at $BASE_PATH/$TMP_Folder/$temp_folder_1/$path"
    cp $new_file $BASE_PATH/$TMP_Folder/$temp_folder_1/$path/$file 
    fi 
else
    if [ -f "$BASE_PATH/$TMP_Folder/$temp_folder_1/$path" ]; then
     tempname=$(basename $path)
     foldername="temp_$tempname"
     mkdir -p "$BASE_PATH/$TMP_Folder/$temp_folder_1/$foldername"
     cd "$BASE_PATH/$TMP_Folder/$temp_folder_1/$foldername"
     $JAR -xvf $BASE_PATH/$TMP_Folder/$temp_folder_1/$path >/dev/null
     zip_old_file=$(find "$BASE_PATH/$TMP_Folder/$temp_folder_1/$foldername" -type f -name $file) 
     echo "File $file is located at $BASE_PATH/$TMP_Folder/$temp_folder_1/$foldername"
     zip_new_file=$(grep $file $REP_NEW_FILE_LIST)
     cp  $zip_new_file $zip_old_file
     cd $BASE_PATH/$TMP_Folder/$temp_folder_1/$foldername 
     $JAR -cvf $BASE_PATH/$TMP_Folder/$temp_folder_1/$path * >/dev/null
     rm -rf $BASE_PATH/$TMP_Folder/$temp_folder_1/$foldername
    else
        echo "File $file is not located in $BASE_PATH/$TMP_Folder/$temp_folder_1/$path";
        exit 1
    fi
fi

done

cd $BASE_PATH/$TMP_Folder/$temp_folder_1
$JAR -cvf $GET_WAR_FILE * >/dev/null
rm -rf $BASE_PATH/$TMP_Folder/$temp_folder_1

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

#********************************************
rm -r $BASE_PATH/$TMP_Folder  $REP_NEW_FILE_LIST  $SOURCE_LIST
