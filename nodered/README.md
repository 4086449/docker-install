# Node-red with mqtt containers
## With Portainer
In the right taskbar, press:
> stacks
> new stack
Enter name 'nodered' _(no capitols or characters)_
Copy/paste docker-compose.yml
> deploy stack

This could take a minute. A green (or red) notification will appear in the right upper corner of the screen when it is finished.

If it was green, all went well.
To access node-red go to 'http://<ip_address_pi>:1880'
```
http://192.168.178.20:1880
```

You're mqtt broker has the same ip as the pi and uses the normal port for mqtt, __1883__

If the notification after deployment was red however, something went wrong. 
Probably a faulty indentation when copy/pasting.

Solutions?
- Google
- Call Kano

## With docker-compose
### to start
__Always__ go the the folder that contains your 'docker-compose.yml' file. __NEVER__ change this name
```bash
cd ~/docker/node-red
docker-compose up -d
```
### to stop
```bash
docker-compose down
```
