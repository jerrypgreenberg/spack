files=`ls *.sh`
for file in $files;do
sed -i s/\$\{HOME\}// $file
done
