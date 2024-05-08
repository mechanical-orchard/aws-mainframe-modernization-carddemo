## Setup

Instructions & scripts in this repo assume that we're targeting a remote system running [Z/OSMF](https://www.ibm.com/products/zos/management-facility). MO's Wazi instances come with Z/OSMF pre-installed.

CardDemo setup scrips in this repo rely on the [Zowe](https://www.zowe.org/) CLI. 

### Installing / configuring Zowe

To install Zowe:

```
asdf plugin add nodejs
asdf install nodejs 20.12.2
asdf local nodejs 20.12.2
npm install
zowe plugins install @zowe/cics-for-zowe-cli@zowe-v2-lts @zowe/zos-ftp-for-zowe-cli@zowe-v2-lts
```

To configure Zowe:

Run `zowe config init` to bootstrap a pair of config files for Zowe. For example:

```
~/projects/carddemo % zowe config init
Enter host (Host name of service on the mainframe.) - Press ENTER to skip: <your hostname or IP address>
Enter user (User name to authenticate to service on the mainframe.) - <your mainframe username>
Enter password (Password to authenticate to service on the mainframe.) - Press ENTER to skip: <password of your mainframe username>
Saved config template to /Users/jb/projects/carddemo/zowe.config.json
```

### Installing CardDemo on the mainframe

CardDemo's out-of-the-box instructions are 


