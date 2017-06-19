## kubeadm installer for CoreOS, Ubuntu, Debian, CentOS and Fedora


[![Docker Automated buil](https://img.shields.io/docker/automated/jrottenberg/ffmpeg.svg?style=flat-square)](https://hub.docker.com/r/xakra/kubeadm-installer/)
[![Docker Build Statu](https://img.shields.io/docker/build/jrottenberg/ffmpeg.svg?style=flat-square)](https://hub.docker.com/r/xakra/kubeadm-installer/)


### Note

The [entrypoint](files/entrypoint.sh) script will try to get the **latest** release version tagged on Github (starting version `0.4.0`).

The version of each software can be overridden with ENV variables provided on the `docker run` cmd (starting version `0.4.1`).

The actual versions used and installed should be printed on the output during usage (starting version `0.4.2`).


### Usage

#### How to run install kubeadm

Given docker already is installed (otherwise, run `curl get.docker.com | bash`), you can install kubeadm easily!

```bash
$ docker run -it \
	-v /etc:/rootfs/etc \
	-v /opt:/rootfs/opt \
	-v /usr/bin:/rootfs/usr/bin \
	xakra/kubeadm-installer ${your_os_here}
```

`${your_os_here}` can be `coreos`, `ubuntu`, `debian`, `fedora` or `centos`


#### How to uninstall/revert

```bash
$ docker run -it 	\
	-v /etc:/rootfs/etc \
	-v /opt:/rootfs/opt \
	-v /usr/bin:/rootfs/usr/bin \
	xakra/kubeadm-installer ${your_os_here} uninstall
```


### What's inside?

 - kubeadm
 - kubernetes
 - cni

Give a look to the [build.sh](scripts/build.sh) script.


### License

MIT
