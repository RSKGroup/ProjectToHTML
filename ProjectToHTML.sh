#!/bin/sh

if [ -e /opt/homebrew/bin/tree ]; then
	treeCommand="/opt/homebrew/bin/tree"
elif [ -e /usr/local/bin/tree ]; then
	treeCommand="/usr/local/bin/tree"
else
	echo "Please install tree"
	exit 1
fi

while [ -z "$projectToHTML" ]; do
	projectToHTML=$(/usr/bin/osascript <<EOF
try 
	set sourcefolder to POSIX path of (choose folder with prompt "Select the project to create HTML:")
on error errMsg number errorNumber
	return errorNumber
end try
EOF
)
	if [ "$projectToHTML" = -128 ]; then
		exit 0
	fi
done

while [ -z "$destinationFolder" ]; do
	destinationFolder=$(/usr/bin/osascript <<EOF
try 
	set destfolder to POSIX path of (choose folder with prompt "Select the destination folder:")
on error errMsg number errorNumber
	return errorNumber
end try
EOF
)
	if [ "$destinationFolder" = -128 ]; then
		exit 0
	fi
done

projectName=$(basename "${projectToHTML}")
enclosingFolder=$(dirname "${projectToHTML}")
htmlfile="${destinationFolder}/${projectName}_info.html"

cat << EOF > "$htmlfile"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>$projectName Info</title>
  </head>
  <body>
EOF

infoFile=$(find "$projectToHTML" -name '*_info.txt')

if [ -n "$infoFile" ]; then
	while read line || [ -n "$line" ]; do 
		echo "${line}<br>" >> "$htmlfile"
	done <"${infoFile}"
fi

echo "<br>" >> "$htmlfile"
echo "<h2>Directory Tree</h2>" >> "$htmlfile"


"$treeCommand" -J "${enclosingFolder}/${projectName}" > "/tmp/${projectName}.json"

while read line; do
	type=$(awk -F\" '{print $4}' <<<"$line")
	name=$(awk -F\" '{print $8}' <<<"$line")
	if [[  "$type" = "directory" ]]; then
		if [[ "$line" = *',"contents":[' ]]; then
			echo "<details><summary>$name</summary><dd>" >> "$htmlfile"
		else
			echo "<details><summary>$name</summary><dd></dd></details>" >> "$htmlfile" 
		fi	
	elif [[ "$type" = "file" ]]; then
		echo "${name}<br>" >> "$htmlfile"
	elif [[ "$line" = *']}'* ]]; then
		echo "</dd></details>" >> "$htmlfile"
	fi
done < "/tmp/${projectName}.json"

echo "</body>" >> "$htmlfile"
echo "</html>" >> "$htmlfile"