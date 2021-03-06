# RFUtilScript

Automated script to configure RF433 outlets

This script combines and streamlines the installation/configuration of RF433 utilities on Raspberry Pi.
It uses the WiringPi and RFOutlet to control RF 433 outlets.
I have tested them out on ETeckCity outlets but it should work on other 433s without issues.

## Getting Started
Connect to your Raspberry Pi via SSH (or directly using Terminal) and follow installation instructions.

Connect your 433 RF outlets to wall socket and use your RF remote to confirm they are working.

### Prerequisites
<li>Basic computer/Raspberry Pi know how</li>
<li>Working Raspberry Pi</li>
<li>SSH access to Raspberry Pi</li>
<li>Access to Internet</li>

#### Optional Hardware
<li> <a href="https://www.amazon.com/gp/product/B00M2CUALS">RF Transmitter + Reciever</a></li>
<li> <a href="https://www.amazon.com/Etekcity-Household-Appliances-Unlimited-Connections/dp/B00DQELHBS">RF Plugs + Remote</a></li>
<br/>

Before running the script please ensure that you have connected the PINs correctly for RF433 transmitter as well as reciever module.

For Reciever: (5V | Empty | GPIO 27 | Ground)


For Transmitter: ( GPIO17 | 5V | Ground )


One also needs to ensure that your outlets are connected and respective RF remote is working.

### Installing
Download the script using command <code>wget https://raw.githubusercontent.com/piyushkumarjiit/RFUtilScript/master/RF433Setup.sh</code>

Update permissions using <code>chmod 755 RF433Setup.sh.sh</code>

Run the script <code>./RF433Setup.sh | tee RF433Setup.log</code>

### Testing
Upon capture completion, the script power cycles through all the connected RF outlets and provides user a way to verify correct code capture as well as setup.

Individual outlets can also be tested by executing commands saved by the script in the file "RFCommands.txt".

## Authors
**Piyush Kumar** - (https://github.com/piyushkumarjiit)

## License
This project is licensed under the Apache License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments
Thanks to below URLs for providing me the necessary understanding and libraries to create this script.
<li>https://www.DuckDuckGo.com</li>
<li>https://github.com/timleland/rfoutlet/tree/master/RFSource</li>
<li>https://projects.drogon.net/raspberry-pi/wiringpi/the-gpio-utility/</li>
