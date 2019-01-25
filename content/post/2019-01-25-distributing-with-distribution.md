+++
date = "2019-01-25"
title = "Distributing with Distribution: Upcoming Changes to Helm Chart Repositories"
description = "An overview on some of the changes coming to Helm Chart Repositories for Helm 3"
tags = ["oci", "helm"]
+++

Further reading: Steve Lasker also wrote [a similar blog post on container registries here](https://stevelasker.blog/2019/01/25/cloud-native-artifact-stores-evolve-from-container-registries/).

Helm Chart Repositories were deisgned to store, share and distribute Helm Charts.

After the last Helm Summit, members from Microsoft Azure, Codefresh, Quay and others from the Helm Community have been advocating for a new standard so that Chart Repositories can scale to meet the demands of the broader Helm community.

If we take a look at the broader Cloud Native ecosystem, Docker's Distribution project checks off many of the boxes we were looking for in a successor: a battle-hardened, secure and highly reliable service being used in production today.

The Distribution project is Docker's toolset to pack, ship, store, and deliver container images. But did you know that it was also designed to distribute *any* form of content, not just container images?

In this post, we'll discuss the specifications, APIs and tools that form the Distribution project, walking through how you can use the Distribution project to distribute (see what I did there?) your own content. Using that same walkthrough, we'll showcase a new library developed by the Helm Community to make it simpler to store content in the Distribution project, which can be used in Helm 3 to store Helm charts in Distribution.

## Helm Chart Repositories

At a high level, a Chart Repository is a location where charts can be stored and shared. The Helm client packs and ships Helm Charts to a Chart Repository. Simply put, a Chart Repository is a basic HTTP server that houses an index.yaml file and some packaged charts.

Because a Chart Repository can be any HTTP server that can serve YAML and gzipped tarballs, users have a plethora of options when it comes down to hosting a Chart Repository. For example, cloud vendors like Microsoft Azure, Quay, and Codefresh have adopted Helm Chart Repositories as a first class, managed, supported service. Many users have written Helm plugins for storing Helm Charts in object storage such as Azure Blob Store, Amazon S3, Google Cloud Storage, or even on Github Pages. Additionally, open source projects like [Harbor](https://goharbor.io/) and [Helm's own ChartMuseum project](https://github.com/helm/chartmuseum) were created to host your own Chart Repository on your own infrastructure.

While there are several benefits to the Chart Repository API meeting the most basic storage requirements, a few drawbacks have started to show:

- Chart Repositories have a very hard time abstracting most of the security implementations required in a production environment. Having a standard API for authentication and authorization is very important in production scenarios
- Helm's [Chart provenance tools](https://docs.helm.sh/developing_charts/#helm-provenance-and-integrity) used for signing and verifying the integrity and origin of a chart is an after-thought of the chart publishing process
- In multi-tenant scenarios, the same chart can be uploaded by another tenant, costing twice the storage cost to store the same content. Smarter chart repositories can be designed to handle this, but it's not a part of the spec
- Using a single index file for search, metadata information and fetching charts has made it difficult or clunky to design around in secure multi-tenant implementations.

As we started to see these design issues come up, we started to look to the Cloud Native ecosystem for ideas.

## The Distribution Project

One of the many concepts Docker innovated in the container space was the container registry. While containers provided a means to run processes in a virtualized environment, Docker understood that customers wanted a model where they can pack, ship, store and share the underlying image layers that make a container, a container. By introducing the first version of the [Docker Registry project](https://github.com/docker/docker-registry), customers could simply run `docker run ubuntu:12.04 bash` which would authenticate, fetch, unpack and run a container in a single command. These images were stored in the Docker Index, now re-branded as DockerHub. As a result, registries are core to both the development and production lifecycle of a container, and is a fundamental stanchion of the container ecosystem.

Docker's Distribution project (also known as Docker Registry v2) is the successor to the Docker Registry project, and is the de-facto toolset to pack, ship, store, and deliver Docker images. Many major cloud vendors have a product offering of the Distribution project, and with so many vendors offering the same product, the Distribution project has benefited from many years of hardening, security best practices, and battle-testing, making it one of the most successful unsung heroes of the open source world.

Let's talk about what the Distribution project brings to the table:

- A stable, battle-hardened product with many cloud vendors providing their own flavour of Distribution
- A rich set of libraries for interacting with Distribution
- A pluggable storage backend, including support for local filesystem, Azure, GCS, Aliyun OSS, AWS S3, and Openstack Swift out of the box
- A standard API for authentication/authorization
- Content stored in Distribution is content-addressable via a sha256 checksum. In other words, if two files are uploaded with identical content, only one copy of the content is stored.

## Demo: Pushing a Tarball Using the Oras Project

`oras` is an open source project developed during the Helm 3 discussions to push and pull any content from Distribution. Written in Go, it's both designed to work as a CLI as well as an SDK. It can be quickly imported in other Go projects that wish to benefit from the ability to store their own content, or it can be used in its CLI form to push and pull content using the command line.

Please keep in mind that the demonstration shown here is an early proof-of-concept. The warnings shown in the examples are to be expected, and it is possible that the demonstration may not work the same in the future. Here be dragons.

### Using the CLI

To start, fetch the [latest release](https://github.com/deislabs/oras/releases) of `oras` for your Operating System, unpack it and move the binary somewhere on your $PATH. For those using [GoFish](https://gofi.sh/), you can also use `gofish install oras` to do this for you.

You'll also need to run `distribution` itself. The simplest way to run Distribution is by running it in a container:

```console
$ docker run -dp 5000:5000 --restart=always --name registry registry:2
```

For more advanced deployment setups, have a look at the [Distribution project's documentation](https://github.com/docker/docker.github.io/blob/master/registry/deploying.md) on the subject.

Now let's push a file to Distribution.

```console
$ echo "hello world!" > helloworld.txt
$ oras push localhost:5000/helloworld:latest helloworld.txt:text/plain
WARN[0000] encountered unknown type text/plain; children may not be fetched
WARN[0000] reference for unknown type: text/plain        digest="sha256:0ce3f283969b91e25ea7cffb768a60d225c0f1b57cdd319d4df94081e25b617d" mediatype=text/plain size=30
```

By default, the media type for all files uploaded using the `oras` CLI is `application/vnd.oci.image.layer.v1.tar`, which is the reserved media type used by the OCI for image layers. In this example, we changed it to `text/plain` to signal that the content we're uploading is not a docker image layer, but a text file.

Think of media types as you would think of HTTP content types: it's simply used to tell a client how to handle the returned content; is it a tarball, a JSON object, or just a plain text file?

Now that we've pushed some content to the registry, let's dive into the registry and inspect what was stored:

```console
$ docker exec -it registry sh
/ # cat /var/lib/registry/docker/registry/v2/repositories/helloworld/_manifests/tags/latest/current/link
sha256:ae69fac8c8ce238b9cf53dab5f00bd8f63369af95ef5706529f3bd19ffe53c85
/ # cat /var/lib/registry/docker/registry/v2/blobs/sha256/ae/ae69fac8c8ce238b9cf53dab5f00bd8f63369af95ef5706529f3bd19ffe53c85/data
{
    "schemaVersion": 2,
    "config": {
        "mediaType": "application/vnd.oci.image.config.v1+json",
        "digest": "sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
        "size": 2
    },
    "layers": [
        {
            "mediaType": "text/plain",
            "digest": "sha256:0ce3f283969b91e25ea7cffb768a60d225c0f1b57cdd319d4df94081e25b617d",
            "size": 30,
            "annotations": {
                "org.opencontainers.image.title": "helloworld.txt"
            }
        }
    ]
}
```

Let's break down this object:

- `config`: describes the disposition of the content. Normally, this is used to inform the runtime how to prepare the content (in most cases, the container). This isn't useful for a text file, so we just write `{}` to the object config to satisfy the specification.
- `layers`: traditionally meant to describe the layers that compose of a container image, but in this example we're re-using that object to describe the file we just uploaded.
- `digest`: this is an internal reference to the actual blob (file) stored in the registry, stored by default at `/var/lib/registry/docker/registry/v2/blobs/`.

Let's see the actual content of that blob:

```console
/ # cat /var/lib/registry/docker/registry/v2/blobs/sha256/0c/0ce3f283969b91e25ea7cffb768a60d225c0f1b57cdd319d4df94081e25b617d/data
hello world!
```

There's our file! Now, let's try fetching it from the registry:

```bash
$ rm helloworld.txt # delete the old content so we're not cheating
$ oras pull localhost:5000/helloworld:latest -t text/plain
WARN[0000] reference for unknown type: text/plain        digest="sha256:0ce3f283969b91e25ea7cffb768a60d225c0f1b57cdd319d4df94081e25b617d" mediatype=text/plain size=30
WARN[0000] unknown_type: application/vnd.oci.image.config.v1+json
WARN[0000] encountered unknown type text/plain; children may not be fetched
$ cat helloworld.txt
hello world!
```

By default, only blobs with the media type `application/vnd.oci.image.layer.v1.tar` will be downloaded, so we had to change the media type to `text/plain` in order to ask `oras` to pull it down.

### Using the Go SDK

Let's perform the same example, but in Go! This example is similar to the last example: it will upload an in-memory file to Distribution to the repository `helloworld:latest`, then pull it back down as `helloworld.txt`.

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/containerd/containerd/remotes/docker"
    ocispec "github.com/opencontainers/image-spec/specs-go/v1"
    "github.com/deislabs/oras/pkg/content"
    "github.com/deislabs/oras/pkg/oras"
)

func main() {
    ref := "localhost:5000/helloworld:latest"
    fileName := "helloworld.txt"
    fileContent := []byte("Hello World!\n")
    mediaType := "plain/text"

    ctx := context.Background()
    resolver := docker.NewResolver(docker.ResolverOptions{})

    // Push file(s) with custom mediatype to registry
    memoryStore := content.NewMemoryStore()
    desc := memoryStore.Add(fileName, mediaType, fileContent)
    pushContents := []ocispec.Descriptor{desc}
    fmt.Printf("Pushing %s to %s...\n", fileName, ref)
    if err := oras.Push(ctx, resolver, ref, memoryStore, pushContents); err != nil {
        log.Fatal(err)
    }
    fmt.Println("success!")

    // Pull file(s) from registry and save to disk
    fmt.Printf("Pulling from %s and saving to %s...\n", ref, fileName)
    fileStore := content.NewFileStore("")
    allowedMediaTypes := []string{mediaType}
    if _, err := oras.Pull(ctx, resolver, ref, fileStore, allowedMediaTypes...); err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Success!\nTry running 'cat %s'\n", fileName)
}
```

## Looking Forward

While these samples may look simple, we can start to see why this is so beneficial for the Helm project:

Helm Charts could be hosted on any instance of Distribution with OCI image support. So far, we've tested and confirmed this works for Azure Container Registry and Distribution v2.7+, but there are likely many others that work out of the box.

Another big advantage this brings is the ability to co-locate Helm Charts and Docker images inside the same registry, making it much simpler to establish a chain of trust between a Helm Chart and the Docker images it references in a Deployment template.

Finally, by adopting an existing piece of technology, we get to build on previous discoveries that the OCI and Distribution teams have made over the years, learning through their mentorship and guidance on what it means to run a highly available service at scale.

## A Big Thank You

Everything you saw here in this blog post was written by other members of the community. I want to take a moment to give a *big* thank you to everyone that participated in making this a reality: from attending weekly meetings, discussing ideas in mailing lists, and for collaborating together on projects in a friendly, professional and inclusive manner.

I want to especially thank the following people for their hard work and dedication on this topic:

- Jimmy Zelinskie (Red Hat and member of the Open Container Initiative)
- Stephen Day (member of the Open Container Initiative)
- Josh Dolitsky (Codefresh)
- Matt Farina (Samsung SDS)
- Sajay Antony (Microsoft)
- Steve Lasker (Microsoft)
- Shiwei Zhang (Microsoft)

To everyone in this list and to everyone else that participated: Thank you!
