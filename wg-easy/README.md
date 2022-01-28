# Wireguard VPN
Super easy to use VPN server in a docker container

## Clients
Full list can be found [here](https://www.wireguard.com/install/): https://www.wireguard.com/install/
[Macos (app store)](https://itunes.apple.com/us/app/wireguard/id1451685025?ls=1&mt=12)
[iOS (app store)](https://itunes.apple.com/us/app/wireguard/id1441195209?ls=1&mt=8)
[Windows Installer](https://download.wireguard.com/windows-client/wireguard-installer.exe)

## Before deployment
### Dynamic DNS
Link a uri to you public ip

Popular dns providers are [duckdns](https://www.duckdns.org/) and [freedns](https://freedns.afraid.org/) 
They let you link you ip to a domain name of them. eg. https://leosddnsadres.duckdns.org/
This will let you route traffic back home.
To find your public IP (you must be on your home network and) simply google ['What is my IP'](https://www.google.nl/search?q=what+is+my+ip)

_After you have created an account and requested a subdomain,_ Enter the ip you googled before in the subdomain settings. 

__don't forget to update the created subdomain in de docker-compose.yml file__

### Port Forwarding
Go to your router's home page
For Ziggo: http://192.168.178.1/

Go to Advanced Settings -> Security -> Port Forwarding
<img src="lib/ZiggoWelcome.png" width="50%" >

Press "Create New Rule"
Add your IP '192.168.178.20'
Enter port "51820" 4 times
Choose "UDP" protocol
And set to enabled 
'Add Rule'
'Apply Changes'
<img src="lib/ZiggoPortForward.png" width="50%" >

## Deploying Container
Browse to your pi's IP on port '9000' to go to portainer 'http://<ip_address_pi>:9000'
```
http://192.168.178.20:9000
```
Press 'local' 
<img src="lib/PortainerEnvironment.png" width="50%" >

In the right taskbar, press:
> stacks
> new stack
Enter name 'wireguardvpn' _(no capitols or characters)_
Copy/paste docker-compose.yml
> deploy stack

This could take a minute. A green (or red) notification will appear in the right upper corner of the screen when it is finished.

If it was green, all went well.
To access the wireguard admin page, go to 'http://<ip_address_pi>:51821'
```
http://192.168.178.20:51821 
```
You're mqtt broker has the same ip as the pi and uses the normal port for mqtt, __1883__

If the notification after deployment was red however, something went wrong. 
Probably a faulty indentation when copy/pasting.

Solutions?
- Google
- Call Kano

