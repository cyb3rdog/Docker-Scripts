# VECTOR-NODE

A simple container with node.js, vector-web-setup node.js web app, and vector-node-api node.js API to Anki Vector Robot.

## Getting Started

These instructions will cover usage information and for the docker container 

### Prerequisities


In order to run this container you'll need docker installed.

* [Windows](https://docs.docker.com/windows/started)
* [OS X](https://docs.docker.com/mac/started/)
* [Linux](https://docs.docker.com/linux/started/)

### Usage

To run the container, execute following docker command:

```shell
docker run -it --rm --name vector-node -p 80:8000 -w /usr/src/app -d cyb3rdog/vector-node:latest
```

This command will download the image and start the container with the vector-web-setup app
forwarded to port 80 of your virtual machine.


#### vector-web-setup

To check the IP address of your virtual machine, you need to know machine name (ie. 'default')

```shell
docker-machine active
```

After checking the name, you can use it to query the IP address, with this command:
```shell
docker-machine ip <machine_name>
```

And finally, use this IP in the url to vector-web-setup:

```shell
http://<ip_address>:80/
```


#### vector-node-api

In order to use the NODE API, you will need the configuration and certificate file to your Vector Robot.
The easiest way how to obtain those is with official Python SDK.
You can follow steps here (https://developer.anki.com/vector/docs/initial.html) to set up your Vector robot with the SDK.
You can also find more detailed information about the Node API iself here: https://github.com/cyb3rdog/anki-vector-nodejs

Once completed, you can copy the certificate and the config.js file to your container and use it


To copy files to the container, use:

```shell
docker cp example.cert vector-node:/usr/src/app/
docker cp config.js vector-node:/usr/src/app/
```

To shell into your container, run following command

```shell
docker exec -it -u root vector-node /bin/bash
```

To check, that you configured the API correctly, use

```shell
node welcome.js
```

#### Container Parameters

List of the parameters available to the container

#### Environment Variables

* `PORT` - exposed port of vector-web-app, within the container (default 8000)

## Authors

* **cyb3rdog** - (https://github.com/cyb3rdog)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

* People i want to thank:
* https://github.com/anki/vector-python-sdk
* https://github.com/KishCom/anki-vector-nodejs

