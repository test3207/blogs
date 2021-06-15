---
title: 'some practices of speeding website up'
date: 2021-06-15 15:04:55
updated: 2021-06-15 15:04:55
tags:
---

apart from those daily talking, i want to introduce you a few practices lately used to speed our website up

## ssl inital issue

nowadays we are using let's encrypt a lot, as both safety and free certification. it IS a good choice, for starters, or non-profitable organizations. 

usually it's ok, unless server of let's encrypt is too slow.

why the hell are we talking about server of let's encrypt? let's go back to the [documents](https://letsencrypt.org/docs/) of it:

<img src = 'https://minio.test3207.com/hedgedoc/uploads/upload_9172267b4a78defdf1ebf734c5c2ce41.png' width = 400>

damn yes, the revoke process! people may take the risks of being cheat by a revoked certification. most of the modern browsers will just go check if it's still valid sometimes. (which make it difficult to reproduce: it only checks once in a long time; and it's hard to tell when server of let's encrypt crushed or just too slow)

so here comes one choice: enable OCSP Stapling option on your reverse proxy server, so it will fetch the result for all clients before requests coming.

then again, your server may have some connection issues with server of let's encrypt. and occasionally, users may still encounter the same issue, just before your server get the result.

so here comes an advice: if you do need to ensure ssl issue won't happen on your server at any cost, just buy a certification from local enterprise. (sadly, we can't even sure if those providers are part of the reasons why we connect let's encrypt. QwQ)

if it's not so important, just enable OCSP stapling. it works well most time anyway lol

## adaptive size images

![](https://minio.test3207.com/hedgedoc/uploads/upload_c7c9f8c33a1e712e3a49603da69e7ee9.png) now things are going to be wild, stay still amigo.

we know it's really easy to resize a image in front end, using some html codes like:

```htmlmixed=
<img src = 'image/example.png' width = 400, height = 200>
```

it seems ok for users. but unfortunately, browsers will still download the original unoptimized images, which may takes more than 20mb each!

to reduce the size of clients really need to download, ideally, we need to host different sizes of images. and for new browsers, there are more to do! say chrome support a new compressed format `avif`, which is even smaller than `webp`! (i think `avif` is developed by google itself too)

we are not going to dig into the details of each format, we chosen `squoosh-cli` as our solution, and made some changes to make it possible to run in browsers, because:

1. we need multiple formats support, which shares some fimilar interfaces, so it won't take too long to integrate, and have backups for older version of browsers

2. it should be able to run in browsers, so it could be able to implement some kind of offline mode creations, which also saves both users' time and our server resources

(yes, we support PWA too, which is another optimization, but not really nessesary to talk here, since it's not such a common scenario which most website may need to consider)

i believe there would be more options if you really want best performance, but we will continue the topic here.

so for the content server, we added a proxy level, to handle those image requests, say a chrome is requesting `image_tiny.avif`, the content server will go check if it exists. if not, return the original image, and start a processor to compress the `tiny` image. the next time it will response a tiny image instead.

of course it doesn't have to be `tiny`, you can set up a serial of image sizes according to your real business. and apart from images, there could be a similar optimization on audio/video. we used `ffmpeg` on that. but video optimization could be tricky, and may have to realated to cdn stuff, or some higher level optimization. so we won't discuss those here.

and we still need to be prepared for potential attack. we need to limit the resources this compress process can use, and we need to add a message queue for traffic peaking, which is for operation guys lol, just mention here in case you wrote some stupid code and blame on me looolll

## others

we have seen many ways to speed our website up, some could be common and useful, like things above. some could be okay but not significant good, like `server push`, links [here](https://www.nginx.com/blog/nginx-1-13-9-http2-server-push/) if you do want to read. and some is not that easy to conclude, say cache, mq, better sqls, which are based on real scenario, and may not be useful for all of you.

anyway i hope this really help you guys. and if there are more interesting way to speed things up, please tell me, same account on github.
