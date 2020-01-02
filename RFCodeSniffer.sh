#!/bin/bash
#Abort installation if any of the commands fail
set -e

#Install wiringpi if not already installed and fetch the project from github
wiringpi_present=$(gpio -v > /dev/null 2>&1; echo $?)
if [[ $wiringpi_present -gt "1" ]]
then
	echo "Installing WiringPi."
	sudo apt-get install wiringpi
	echo "WiringPi installed."
else
	echo "WiringPi is present. Continuing without adding."
fi

#Create the RFOutlet Directory
if [[ -d "/var/www/rfoutlet" ]]
then
	echo "/var/www/rfoutlet Directory exists. Skipping download."
else
	echo "Downloading RFOutlet source."
	git_present=$(git > /dev/null 2>&1; echo $?)
	if [[ $git_present -gt "1" ]]
	then
		echo "Installing Git."
		sudo apt-get install git
		echo "Git installed."
	else
		echo "Git is present. Continuing without adding."
	fi
	#Clone the RFOutlet from github
	sudo git clone git://github.com/timleland/rfoutlet.git /var/www/rfoutlet
	
	#Update the permissions
	sudo chown root.root /var/www/rfoutlet/codesend
	sudo chmod 755 /var/www/rfoutlet/codesend
	echo "Permission updated."
	
	#Run sniffer to read and save the codes
	OnCodes=()
	OffCodes=()
	i=0
	j=1
	rm CapturedCodes.txt
	echo "Ensure PINs are connected in order { 5V | Empty | GPIO 27 | Ground } when the transmitter's non flat side is facing you."
	sleep 1
	echo Point your remote towards the sensor and be ready.
	echo Starting ON code capture >>  btnout.txt
	while [ $i -lt 5 ]
	do
	  #timeout is used to run the subscript for 5 seconds and exit if subscript is not killed/finished already.
	  #timeout 5 /home/pi/SubSniffer.sh
	  if [ $i -lt 4 ]
	  then
		echo Press ON buton for $j
		#Outout saved to file
		echo ON Code captured for $j  >>  btnout.txt
		#Command that ensures unbufferd write to file that only captures the first line of output.
		stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 >> CapturedCodes.txt
		#Save in Array
		OnCodes[$i]=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1)
		echo "Code captured."
		#Wait so that user is able to move to the next button
		sleep 3
		
		echo Press OFF buton for $j
		echo OFF Code captured for $j  >>  btnout.txt
		#Command that ensures unbufferd write to file that only captures the first line of output.
		stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 >> CapturedCodes.txt
		OffCodes[$i]=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1)
		echo "Code captured."
		sleep 3
		let i+=1
		let j+=1
	  else
	  	#Different message and sleep setting for last code capture.
		echo Press ON buton for $j
		#Outout saved to file
		echo ON Code captured for $j  >>  btnout.txt
		#Command that ensures unbufferd write to file that only captures the first line of output.
		stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 >> CapturedCodes.txt
		#Save in Array
		OnCodes[$i]=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1)
		echo "Code captured."
		#Wait so that user is able to move to the next button
		sleep 3
		
		echo Press OFF buton for $j
		echo OFF Code captured for $j  >>  btnout.txt
		#Command that ensures unbufferd write to file that only captures the first line of output.
		stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1 >> CapturedCodes.txt
		#Save in Array
		OffCodes[$i]=$(stdbuf -i0 -o0 -e0 /var/www/rfoutlet/RFSniffer | head -n 1)
		echo "Code captured."
		let i+=1
		let j+=1
	  fi
	done
echo "--------------------"
rm RFCommands.txt
echo Captured ON Codes:
for n in "${OnCodes[@]}"
do
  echo $n
done

echo Captured OFF Codes:
for n in "${OffCodes[@]}"
do
  echo $n
done	

#Testing Codes
echo "Ensure PINs are connected in order { GPIO17 | 5V | Ground } when the transmitter's non flat side is facing you."
sleep 2
echo "To test we will be tunring ON all switches and then turning them all OFF"
sleep 1
i=1
j=1
echo ON commands >> RFCommands.txt
for n in "${OnCodes[@]}"
do
  echo Turning on $i
  code=$( echo $n | awk '/Received/ {print $2}')
  #echo $code
  /var/www/rfoutlet/codesend $code
  echo /var/www/rfoutlet/codesend $code >> RFCommands.txt
  let i+=1
  sleep 1
done
echo OFF commands >> RFCommands.txt
for n in "${OffCodes[@]}"
do
  echo Turning OFF $j
  code=$( echo $n | awk '/Received/ {print $2}')
  #echo $code
  /var/www/rfoutlet/codesend $code
  echo /var/www/rfoutlet/codesend $code >> RFCommands.txt
  let j+=1
  sleep 1
done

echo "All Done. Exiting."
fi
