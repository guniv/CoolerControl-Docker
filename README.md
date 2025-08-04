<div align="center" width="100%">
    <div>
        <a target="_blank" href="https://github.com/guniv/CoolerControl-Docker"><img src="https://img.shields.io/github/stars/guniv/CoolerControl-Docker?style=flat&label=Stars" /></a>
        <a target="_blank" href="https://github.com/guniv/CoolerControl-Docker/pkgs/container/coolercontrol-docker"><img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fipitio%2Fbackage%2Findex%2Fguniv%2FCoolerControl-Docker%2Fcoolercontrol-docker.json&query=downloads&label=ghcr.io%20pulls" /></a>
        <a target="_blank" href="https://hub.docker.com/r/gunivx/coolercontrol-docker"><img src="https://img.shields.io/docker/pulls/gunivx/coolercontrol-docker?label=docker%20hub%20pulls" /></a>
    </div>
</div>

# CoolerControl-Docker

> [!WARNING]
> **🚨 DEPRECATION NOTICE - MIGRATION REQUIRED BY NOVEMBER 1st, 2025 🚨**
> 
> This unofficial Docker container is being **SUNSET** due to the release of an official CoolerControl Docker image.
> 
> **Please migrate to the official image:** `coolercontrol/coolercontrold:latest`
> 
> ⚠️ **Continued maintenance of this container is NOT GUARANTEED past the migration deadline.**
> 
> The documentation has also been migrated to the official CoolerControl documentation website: https://docs.coolercontrol.org/installation/unraid.html

This is my insanely basic attempt at putting [CoolerControl](https://gitlab.com/coolercontrol/coolercontrol) in a Docker container. Let me preface with: I don't really know what I'm doing! I barely pulled this together.

Why did I do this? I wanted a good way to manage the fans on my Unraid server, and CoolerControl is currently the best way to manage fans on Linux systems. 

The container is Debian slim running the CoolerControl AppImage.

### Configuration

Visit the [setup guide](https://github.com/guniv/CoolerControl-Docker/blob/main/setup.md) for information on setting this up on Unraid.
