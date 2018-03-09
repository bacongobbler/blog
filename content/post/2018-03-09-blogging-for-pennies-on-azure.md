+++
date = "2018-03-09"
title = "Blogging for Pennies on Azure"
description = "A tutorial for deploying static websites on Azure Blob storage"
tags = ["azure"]
+++

<img alt="azure billing portal" src="/img/2018-03-09-blogging-for-pennies-on-azure/pennies.png" style="width:30%;height:30%" />

I'm an absolute sucker for free (or at least incredibly cheap) stuff. If you're reading this, you probably are too.

As a semi-recent hire at Microsoft, one of the employee perks is an Azure subscription with a monthly quota worth $150USD. For Canadians, that translates to $190CAD per month. While that is plenty enough to host a few websites on several fairly beefy VMs, why not optimize costs and host for as little as $0.02 per month? With that kind of cost savings, we could host THOUSANDS of sites and hardly put a dent in our wallet.

Of course, if you're feeling like a baller and just want to make it rain, [spin up that WordPress on Azure in minutes](https://azure.microsoft.com/en-gb/blog/how-to-host-a-scalable-and-optimized-wordpress-for-azure-in-minutes/) and blog like it's 1999.

For the rest of us, this post will go through how to host statically generated sites using Hugo on Azure, using Azure Blob storage and Azure CDN.

## How it's Made: Static Websites

Before we dive into the setup, let's first explain the semi-recent tech movement that enables this cloud-native paradigm shift: static site generation.

Not to be confused with purely static websites, a static site generator (SSG) is a tool that takes content (typically written in a markup language like [markdown](https://daringfireball.net/projects/markdown/syntax)), apply it against a set of layouts, templates, and themes to generate a purely static website. Just heat and serve.

Statis site generation provides several noticable advantages over traditional CMS tooling:

### 1. Decentralized Revision Control

In a traditional CMS, content is typically stored in a centralized database like MySQL. While most CMS's retain previous revisions of edits that can be rolled back and forward, the database is a single point of failure in the system. If you lose your database, it's lights out for your content. That is, unless you happen to have backups... And if you're reading this blog, you prefer to live on the edge and/or are probably too cheap for backups.

With a static site generator, because the site is generated from content stored on disk, that content can be backed by a decentralized version control system like [git](https://git-scm.com/) or [subversion](https://subversion.apache.org/) (eww).

In fact, this blog is available on [github](https://github.com/bacongobbler/blog), which brings to my next point...

### 2. The Holy Grail: Reproducible Builds

In devops culture, reproducible builds is king. If you have the source code for a given service, you should be able to spin up a development instance of that service on your laptop, and it should behave *exactly* like it would in production.

Because the site is statically generated, the end result is a set of static HTML files. When opened in a browser, it will look *exactly* like what it will look when it's published on the site. This is *huge* when testing new features, as it will behave exactly like it will in production.

### 3. Build Once, Run Anywhere

Sorta stealing Docker's OG tagline here, but it rings true for static site generation. Because this content is statically generated, it is completely free of vendor lock-in. You can build the site once, from any machine, and run it anywhere.

Wanna throw it on Amazon Web Services? Sure, just toss the content in an S3 bucket, point your domain at the S3 bucket and move onto bigger and better things.

How about Google Cloud Storage? Same story here; just toss the content in a Cloud Storage bucket and you're off to the races.

Got a few extra pennies? Want to be a little more fancy and use a CDN like Cloudflare? Sure, just point Cloudflare at your S3/GCS/ABS container.

## The Weapon of Choice: Hugo

I've tried a few different static site generators across my (admittedly short) career: [Github's Jekyll](https://jekyllrb.com/), [Tom Christie's mkdocs](http://www.mkdocs.org/), and now [Steve Francia's Hugo](https://gohugo.io/).

All of the above are fantastic static site generators, but what makes Hugo stand out from the crowd is its *stupid fast* compilation time, allowing it to run circles around Jekyll (written in Ruby) and MkDocs (written in Python). This is mostly thanks to being built entirely in Go, but Steve Francia's brilliant engineering work and contributions to the open source community with projects like [Cobra](https://github.com/spf13/cobra), [viper](https://github.com/spf13/viper) and [pflag](https://github.com/spf13/pflag) likely contributed to the project's wild success. While Jekyll and MkDocs measure static site generation in seconds, identical sites generated through Hugo are generated in sub-millisecond time.

Steve, if you're reading this, thank you for your amazing work in the Go community.

## Azure Blob Storage and Azure CDN

Azure Blob storage is a cloud service that stores unstructured data in the cloud as objects/blobs. Blob storage can store any type of text or binary data, such as a document, media file, or application installer. Blob storage is also referred to as object storage.

Objects stored in Azure Blob storage can be literally anything. Cat GIFs, videos, blobs of data, it doesn't care. The service is as dumb as it gets, and that is exactly what we need: something simple to host our static content in the cloud.

One of the backdraws of Azure Blob storage, though, is the lack of geo-replicated blobs across the globe. That's perfectly fine for our use case though, because that's where Azure CDN comes in.

Azure CDN, as the name suggests, is a Content Delivery Network. Thanks to its distributed global scale, CDNs can handle sudden traffic spikes and heavy loads - like when a popular post gets hugged to death by Reddit - but without having to handle the hassle of standing up that infrastructure (and the cost, a key data point, remember?). This will be useful to help distribute our content across the globe, and it only tacks on a few pennies per month for a low traffic website.

Okay, enough backstory. Let's dive into the tutorial!

## Tutorial: Hosting a Static Website on Azure

### Create a Storage Account

To get started, start by using the Azure Portal to set up a new Azure Storage Account. Follow through the prompts and give it a name. The name isn't too important at this point.

<img alt="azure storage account portal" src="/img/2018-03-09-blogging-for-pennies-on-azure/create_azure_storage_account.png" style="width:30%;height:30%" />

### Create a CDN

Once you created a storage account, we'll need to create a CDN to front the assets. Just make sure to choose the "P1 Premium Verizon" plan, as Verizon's CDN allows us to create URL rewrite rules, which is important because Azure Blob storage does not have a default document to serve on root URLs like index.html... [at least not yet](https://feedback.azure.com/forums/217298-storage/suggestions/6417741-static-website-hosting-in-azure-blob-storage).

Azure Blob storage is dumb, remember?

<img alt="azure CDN portal" src="/img/2018-03-09-blogging-for-pennies-on-azure/azure_cdn.png" style="width:30%;height:30%" />

### Link the CDN to the Storage Account

Next step: linking our storage account with the CDN.

<img alt="azure CDN portal" src="/img/2018-03-09-blogging-for-pennies-on-azure/link_cdn.png" style="width:30%;height:30%" />

### CDN URL Rewrite Rules

Now let's open up Verizon's management window and edit the CDN's URL rewrite rules. We can get there by hitting the "Manage" button from the new endpoint's "Advanced Features" page, shown on the bottom right of this picture.

<img alt="azure CDN portal" src="/img/2018-03-09-blogging-for-pennies-on-azure/manage_portal.png" style="width:30%;height:30%" />

Once you're there, hit the "Rule Engine" page under the "HTTP Large" tab.

Essentially what we're going to do is allow the CDN to

1. rewrite requests for any root URL to fetch index.html
2. rewrite clean path URLs to fetch the corresponding html file. e.g. /foo will fetch /foo.html

To do this, add one new rule to the CDN with the following features:

- IF: Always
- Features:
   - URL Rewrite
      - source: `((?:[^\?]*/)?)($|\?.*)`
      - destination: `$1index.html$2`
   - URL Rewrite
      - source: `((?:[^\?]*/)?[^\?/.]+)($|\?.*)`
      - destination: `$1.html$2`

<img alt="azure CDN portal" src="/img/2018-03-09-blogging-for-pennies-on-azure/rewrite_rules.png" style="width:70%;height:70%" />

It will take a few hours for this rule to propagate, so don't worry if your site doesn't immediately rewrite these URLs.

### Custom Domain

After this, you'll probably want to have a custom domain to serve your assets such as <http://blog.bacongobbler.com>. This setup is largely up to you, but the gist of it is:

1. Grab your CDN's endpoint URL, found in the overview page
2. Go to your nameserver admin page and create a CNAME record pointing to the endpoint URL
3. Wait for DNS to propagate
4. Add that custom hostname to your Azure CDN instance

<img alt="azure custom domain portal" src="/img/2018-03-09-blogging-for-pennies-on-azure/custom_domain.png" style="width:30%;height:30%" />

### Further CDN Considerations/Readings

Just to drop a few tidbits of things to consider after this setup that I don't have enough time to go through, but should be considered:

- consider adding your [own custom TLS certificates](https://docs.microsoft.com/en-us/azure/cdn/cdn-custom-ssl) to the CDN
- if not, [disable TLS support from the CDN](https://docs.microsoft.com/en-us/azure/cdn/cdn-custom-ssl#disabling-https)
- consider [optimizing your CDN](https://docs.microsoft.com/en-us/azure/cdn/cdn-optimization-overview) based on what content you're serving
- improve performance by [compressing files in Azure CDN](https://docs.microsoft.com/en-us/azure/cdn/cdn-improve-performance)

Or better yet, [read the freaking manual](https://docs.microsoft.com/en-us/azure/cdn)! It's actually a great read if you enjoy pouring over documentation on how to better optimize serving your content to users.

### Create a Static Site

Okay, time for the final piece... Generating a static site and tossing it up on Azure Blob storage!

First, grab Hugo. If you're on macOS and using Homebrew, you can install Hugo by running

```
$ brew install hugo
```

For any other platform, follow the instructions as laid out on <https://gohugo.io/getting-started/installing/>.

Once you've grabbed Hugo, let's generate a basic website.

```
$ hugo new site blog
$ cd blog/
```

The above will create a new Hugo site in a folder named `blog`.

Let's add some content:

```
$ hugo new posts/my-first-post.md
```

Edit the newly created content file. Once you're finished, change the `draft` flag in the file to `false`. It should end up looking like this...

```
---
title: "My First Post"
date: 2018-03-09T08:30:00-08:00
draft: false
---

ohai!
```

Open up `config.toml` in a text editor:

```
baseURL = "https://example.org/"
languageCode = "en-us"
title = "My New Hugo Site"
```

Replace the title above with something more personal. Also set the `baseURL` to the custom domain we attached to the CDN earlier.

Now once you're ready, generate the site and upload it to Azure!

```
$ hugo

                   | EN
+------------------+----+
  Pages            |  4
  Paginator pages  |  0
  Non-page files   |  0
  Static files     |  0
  Processed images |  0
  Aliases          |  0
  Sitemaps         |  1
  Cleaned          |  0

Total in 23 ms
```

The content is now available in the `public/` folder. Upload it manually through the Azure portal, or if you've got the Azure CLI installed, use that instead!

```
$ az storage blob upload-batch --source public/ --destination mycontainer
```

And there we go! One static site, hosted on Azure Blob Storage for $0.02. Have fun with all your cloud hosting savings!
