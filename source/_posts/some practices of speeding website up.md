---
title: 'Some Practices of Speeding Website Up'
date: 2021-06-15 15:04:55
updated: 2025-10-31 21:34:00
tags:
  - Web Performance
  - Optimization
  - SSL
  - Image Optimization
---

Apart from the daily discussions, I want to introduce a few practices we recently used to speed up our website.

## SSL Initial Issue

Nowadays we are using Let's Encrypt extensively, as it provides both security and free certification. It is a good choice for starters or non-profit organizations.

Usually it works fine, unless the Let's Encrypt server is too slow.

Why are we discussing the Let's Encrypt server? Let's go back to their [documentation](https://letsencrypt.org/docs/):

![Let's Encrypt OCSP Documentation](https://minio.test3207.com/hedgedoc/uploads/upload_9172267b4a78defdf1ebf734c5c2ce41.png)

Yes, the certificate revocation process! Users may be at risk from revoked certificates. Most modern browsers periodically check certificate validity. (This makes it difficult to reproduce: browsers only check occasionally, and it's hard to determine whether the Let's Encrypt server has crashed or is just slow.)

One solution is to enable OCSP Stapling on your reverse proxy server, which will pre-fetch the validation result for all clients before requests arrive.

However, your server may still experience connection issues with the Let's Encrypt server. Occasionally, users may encounter the same problem before your server retrieves the result.

Here's my advice: if you absolutely must ensure SSL issues never occur on your server, consider purchasing a certificate from a commercial provider. (Unfortunately, connectivity issues with these providers might also exist.)

If high availability isn't critical, simply enable OCSP stapling. It works well most of the time.

## Adaptive Size Images

![Adaptive Images](https://minio.test3207.com/hedgedoc/uploads/upload_c7c9f8c33a1e712e3a49603da69e7ee9.png)

This section covers more advanced optimization techniques.

We know it's easy to resize images on the front end using HTML code like:

```html
<img src = 'image/example.png' width = 400, height = 200>
```

This appears acceptable to users. However, browsers still download the original unoptimized images, which can exceed 20MB each!

To reduce the actual download size, we need to host different image sizes. Modern browsers support even better options! For example, Chrome supports the `avif` format, which is even smaller than `webp`. (Note: AVIF is developed by AOMedia, an alliance including Google, Apple, Mozilla, and others.)

We won't dig into the details of each format. We chose `squoosh-cli` as our solution and modified it to run in browsers because:

1. We need multiple format support with similar interfaces, making integration straightforward and providing fallbacks for older browsers

2. It can run in browsers, enabling offline mode creation, which saves both user time and server resources

(We also support PWA, which is another optimization topic. However, it's not a common scenario for most websites, so we won't discuss it here.)

There are certainly more options available for achieving optimal performance, but let's continue with this approach.

For our content server, we added a proxy layer to handle image requests. For example, when Chrome requests `image_tiny.avif`, the content server checks if it exists. If not, it returns the original image and starts a background process to compress the tiny version. Subsequent requests will receive the optimized image.

The size doesn't have to be `tiny` — you can configure a series of image sizes based on your specific requirements. Similar optimizations can be applied to audio and video files. We use `ffmpeg` for media processing. However, video optimization can be complex and may involve CDN integration or more advanced techniques, which are beyond the scope of this article.

We must also protect against potential attacks. It's essential to limit the resources available to the compression process and implement a message queue to handle traffic spikes. These precautions ensure system stability and prevent resource exhaustion.

## Others

We have explored various methods to improve website performance. Some are commonly applicable and highly effective, like the techniques above. Others may have limited benefits, such as HTTP/2 Server Push (see [Nginx documentation](https://www.nginx.com/blog/nginx-1-13-9-http2-server-push/) for details).

> **Update (2025):** HTTP/2 Server Push has been deprecated by major browsers including Chrome. Modern alternatives include HTTP 103 Early Hints or resource preloading via `<link rel="preload">`.

Other optimizations like caching, message queues, and SQL optimization are scenario-dependent and may not be universally applicable.

I hope these insights are helpful for your performance optimization work.
