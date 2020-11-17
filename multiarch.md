# Multiarch support

This was done using podman on RHEL8.

The "static-file-server" is the perfect micro web server for a raspberry
pi.  I have a rPi 4 as part of my mini kubernetes cluster, so I want this
image to run on both amd64 and also arm64.

Note: not tested on rPi 3 or earlier.  It may be possible to extend the
multiarch support further with, e.g., "armv7" but I don't have a platform
to test that on.


## Dockerfile changes

We add an ARG (build time parameter) to allow the user to specify 
a different architecture.  Golang is particularly convenient for this
type of cross-compilation so we simply pass GOARCH=.  Note that if we
want the "go test" to succeed we must **NOT** pass GOARCH= to this step,
else the cross-compiled binaries cannot run, and thus the test cases all
fail.


## Building

Using podman; docker should be a drop in replacement.


Build for amd64, assumed to be the default

```
podman build  . -t static-file-server:latest-amd64
```


Build for arm64 / raspberry pi cross compile.  We tell the build
process that our container has a different architecture; also pass
in the ARG that gets added to the actual `go build` step.

```
podman build --arch=arm64 --build-arg=ARCH=arm64 . -t static-file-server:latest-arm64
```


## Create Manifest

Using podman; docker has a slightly different syntax
- see https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/

```
podman manifest create multiarch --all \
  static-file-server:latest-amd64      \
  static-file-server:latest-arm64
```

This creates a container image, literally named `multiarch` that contains
references to the sub-images.


## Pushing

Using podman; docker will also have different syntax

We push `multiarch` to the respective repository.  We use `--all` to
upload the attached images as well as the manifest file which refers
to them.


```
export DOCKERID=repo-owner-here

podman login docker.io $DOCKERID
...

podman manifest push --all multiarch \
       docker://docker.io/$DOCKERID/static-file-server:latest
```

Alternatively for quay:
```
export QUAYID=repo-owner-here

podman login quay.io $QUAYID

podman manifest push --all multiarch \
       docker://quay.io/$QUAYID/static-file-server:latest
```



Note that immediately after the upload, I see blank values for OS/Arch,
last pull, compressed size on the docker hub web interface.



