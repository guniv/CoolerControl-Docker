# Setting up CoolerControl in Unraid

Setting up CoolerControl in Unraid is fairly straightforward but does require a little manual work to make sure it's working correctly. This tutorial will walk through setting it up.

## Table of Contents

- [Prerequisites](#prerequisites)
  - [Enabling hard drive temperature reporting](#enabling-hard-drive-temperature-reporting)
  - [Confirm your fans are visible to Unraid](#confirm-your-fans-are-visible-to-unraid)
  - [Nvidia GPU support](#nvidia-gpu-support)
- [Initial CoolerControl setup](#initial-coolercontrol-setup)
  - [Adding Nvidia GPUs](#adding-nvidia-gpus)
  - [Privileged mode](#privileged-mode)
- [Checking your devices in CoolerControl](#checking-your-devices-in-coolercontrol)
- [Configuring CoolerControl](#configuring-coolercontrol)


## Prerequisites

There is some setup required to get the full functionality of CoolerControl on Unraid. Community Applications needs to be installed on the server for CoolerControl and this setup.

### Enabling hard drive temperature reporting

CoolerControl relies on the [Linux Hardware Monitoring kernel API](https://docs.kernel.org/hwmon/hwmon-kernel-api.html) (hwmon) to collect information from the system like sensor temperatures. By default, SATA devices like hard drives do not have their temperatures reported to hwmon. Enabling it in Unraid is simple: open the Unraid terminal and enter the command ```sudo modprobe drivetemp```. 

This command has to be run every time the system is booted. To do this, use the User Scripts plugin from Andrew Zawadzki. In User Scripts, add a new script, and then edit the script to include that command:

<p align="center">  
  <img 
    src="tutorial/userscript.jpeg" 
    alt="sudo modprobe drivetemp is entered into the user scripts edit field"
    width="700" 
  />
</p>

Save the script, and then edit the schedule for the script to run on first array start.

<p align="center">  
  <img 
    src="tutorial/schedule.jpeg" 
    alt="the schedule for the script is set to At First Array Start Only"
    width="700" 
  />
</p>

### Confirm your fans are visible to Unraid

To check if fans are already visible to Unraid, install the Dynamix System Temp plugin from Bergware. In the settings for this plugin, it is possible to select which fan you want to show on your Unraid dashboard footer.

<p align="center">  
  <img 
    src="tutorial/systemtemp.jpeg" 
    alt="in the Dynamix System Temp settings, we see settings set for CPU temp, Mainboard temp, and Array fan speed"
    width="700" 
  />
</p>

If no fans are available under the "Array fan speed" menu, it means the system fans are not currently visible to Unraid.

A potential fix for this is drivers from Community Applications. The ITE IT87 Driver from ich777 has worked for others in making the fans available. The Nuvoton NCT6687 Driver from ich777 may also work.

### Nvidia GPU support

To add Nvidia GPUs to CoolerControl, the Nvidia-Driver plugin from Community Applications needs to be installed and the plugin must be used to install a Nvidia driver on the system.

If these are installed, Nvidia GPUs will be able to show up in CoolerControl. See the [Nvidia section below](#adding-nvidia-gpus) for information on how to set this up.

## Initial CoolerControl setup

The Unraid template has three settings by default: the configuration storage, the WebUI port, and read-only access to hwmon on your Unraid system.

<p align="center">  
  <img 
    src="tutorial/template.jpeg" 
    alt="in the Unraid template, the CoolerControl configuration, WebUI port, and hwmon are all set to their default values"
    width="700" 
  />
</p>

The CoolerControl configuration host path can be changed to store it somewhere else if needed, and the port can be changed if it conflicts with another container.

### Adding Nvidia GPUs

To add Nvidia GPUs to CoolerControl, change "Basic View" to "Advanced view" in the top right of the "Add Container" or "Update Container" page when configuring the container.

<p align="center">  
  <img 
    src="tutorial/advancedview.jpeg" 
    alt="showing where advanced view and basic view are"
    width="700" 
  />
</p>

Next, edit the "Extra Parameters" section to add ```--runtime=nvidia --gpus=all```.

<p align="center">  
  <img 
    src="tutorial/extraparameters.jpeg" 
    alt="extra parameters is edited to include --runtime=nvidia --gpus=all"
    width="700" 
  />
</p>

### Privileged mode

Finally, while following this tutorial and performing initial setup on the container, run it in privileged mode.

<p align="center">  
  <img 
    src="tutorial/privileged.jpeg" 
    alt="extra parameters is edited to include --runtime=nvidia --gpus=all"
    width="700" 
  />
</p>

## Checking your devices in CoolerControl

check devices for hwmon
any "controllable" devices need to be added
any non-hwmon devices need to be added
remove privileged mode and check fans

## Configuring CoolerControl

Identify and name devices
Creating a profile
Assigning a fan to a profile
Creating a custom sensor for HDDs
