---
title: '[Node][NexusPhp based forum auto login]'
date: 2020-10-25 08:54:28
updated: 2020-10-25 08:54:28
tags:
---

## why the fk is nexusphp based forum

![xixixi.png](/images/why.jpg)

Alright in fact, some forums have a rule that if you don't login for some days, you will be kicked out, to keep users active. Meanwhile those sites are not easy to join in.

And here in china, most of those good forums are hosted by NexusPHP. I don't know why, php sucks, and the webpages are soooo broken. But here it is lol.

## how to do it

First of all, we need to find out related apis. Luckily not much different for most sites.

Most of the sites are using cloudflare to fight against crawlers, that should be concerned. And some of the sites are using some old-fishion captcha system to save money, while some sites should be using god damn it hCaptcha. need to solve those problems too.

### related apis

the easist part. just press f12 to see which apis are they using. in fact here comes the list:

```typescript
const defaultIndex = '/index.php'; // main page inside their websites after login
const defaultLogin = '/login.php'; // login page, not the login api
const defaultTakeLogin = '/takelogin.php'; // real login api
const defaultSignIn = ['/attendance.php', '/sign_in.php', '/show_up.php']; // signin api, to earn some credits everyday
const defaultCaptcha = '/image.php?action=regimage&imagehash=$HASH'; // save-money version captcha lol
```

### captcha

The reason why i need the login page, is that it passes cf-related-cookie and save-money version captcha imagehash.

it seems ok even if i don't use cf-cookie, but i will still use it like real browsers do, in case of some counts-based anti-crawler rules. i just don't really care about those rules, anyway i'm acting like a real browser, fetching a bunch of garbage too lol.

for save-money version captcha, there seems too be some kind of pattern: characters come from only 0-9A-Z, the word spacing seems to be fixed.

again hurrah for wasm!!! tesseract now has a node module named [tesseract.js](https://tesseract.projectnaptha.com/). Using the default setting, the accuracy of tess seems not so good, with original images. but i optimized the process with the pattern i found above: chop image into single-character pieces, and use specific recognized mode: recognized as single-character in custome charlist. here comes the [repo](https://github.com/test3207/ptcr) if you want to know the detail. but i didn't use url as example says, instead i download image with cf-cookie first and then pass it as stream, for safety.

if you triggered hCaptcha unluckily, here comes a [guide](https://blog.skk.moe/post/bypass-hcaptcha/#) to bypass it. basiclly using accessibility bug, pretending you can't actually see anything lol.

## finally

tada, with cf-cookie, your username, password and captchacode, and maybe user-agent in headers too for much safer concern, you can finally login without any creepy pupeteer stuff. after login, you will recieve a bunch of cookies name cf_uid, c_secure_login, balabala. you can use it to visit index page and sign in. you don't actually need to login every day, you can just save your cookie somewhere safe, and use it to visit index page every day before it expired.
