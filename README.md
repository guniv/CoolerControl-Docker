# CoolerControl-Docker

This is my insanely basic attempt at putting [CoolerControl](https://gitlab.com/coolercontrol/coolercontrol) in a Docker container. Let me preface with: I don't really know what I'm doing! I barely pulled this together.

Why did I do this? I wanted a good way to manage the fans on my Unraid server, and CoolerControl is currently the best way to manage fans on Linux systems. 

The container is Debian slim running the CoolerControl AppImage.

### Configuration

I recommend running the container initially in privileged mode to see what sensors CoolerControl picks up on its own, and then modifying your docker run command to expose specific directories and devices that were found by CoolerControl.

CoolerControl is configured in this container to bind to 0.0.0.0, so all interfaces available to the container, on port 11987. You should mount ```/etc/coolercontrol/``` in the container to keep your configuration persistent.

You can expose ```/sys/class/hwmon/``` to the container to get access to the vast majority of the sensors that will be detected by CoolerControl.

On my Unraid server I can also expose Nvidia cards to the container by adding ```--runtime=nvidia --gpus=all``` to extra parameters.
