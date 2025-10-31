---
title: '[Node][NexusPHP Based Forum Auto Login]'
date: 2020-10-25 08:54:28
updated: 2025-10-31 21:34:00
tags:
  - Node.js
  - Automation
  - Web Scraping
  - NexusPHP
---

## Why NexusPHP Based Forum

![xixixi.png](/images/why.jpg)

Alright in fact, some forums have a rule that if you don't login for some days, you will be kicked out, to keep users active. Meanwhile those sites are not easy to join in.

And here in China, most of those good forums are hosted by NexusPHP. I don't know why, the webpages are not well optimized. But here it is lol.

## How to Do It

First of all, we need to find out related APIs. Luckily not much different for most sites.

Most of the sites are using Cloudflare to fight against crawlers, that should be concerned. And some of the sites are using some old-fashion captcha system to save money, while some sites should be using hCaptcha. Need to solve those problems too.

### Related APIs

The easiest part. Just press F12 to see which APIs are they using. In fact here comes the list:

```typescript
const defaultIndex = '/index.php'; // main page inside their websites after login
const defaultLogin = '/login.php'; // login page, not the login API
const defaultTakeLogin = '/takelogin.php'; // real login API
const defaultSignIn = ['/attendance.php', '/sign_in.php', '/show_up.php']; // sign-in API, to earn some credits everyday
const defaultCaptcha = '/image.php?action=regimage&imagehash=$HASH'; // save-money version captcha lol
```

### Captcha

The reason why I need the login page, is that it passes CF-related-cookie and save-money version captcha imagehash.

It seems ok even if I don't use CF-cookie, but I will still use it like real browsers do, in case of some counts-based anti-crawler rules. I just don't really care about those rules, anyway I'm acting like a real browser, fetching a bunch of garbage too lol.

For save-money version captcha, there seems to be some kind of pattern: characters come from only 0-9A-Z, the word spacing seems to be fixed.

Again hurrah for WASM!!! Tesseract now has a Node module named [tesseract.js](https://tesseract.projectnaptha.com/). Using the default setting, the accuracy of tess seems not so good, with original images. But I optimized the process with the pattern I found above: chop image into single-character pieces, and use specific recognized mode: recognized as single-character in custom charlist. Here comes the [repo](https://github.com/test3207/ptcr) if you want to know the detail. But I didn't use URL as example says, instead I download image with CF-cookie first and then pass it as stream, for safety.

If you triggered hCaptcha unluckily, here comes a [guide](https://blog.skk.moe/post/bypass-hcaptcha/#) to bypass it. Basically using accessibility bug, pretending you can't actually see anything lol.

## Finally

Tada, with CF-cookie, your username, password and captchacode, and maybe user-agent in headers too for much safer concern, you can finally login without any Puppeteer stuff. After login, you will receive a bunch of cookies name cf_uid, c_secure_login, balabala. You can use it to visit index page and sign in. You don't actually need to login every day, you can just save your cookie somewhere safe, and use it to visit index page every day before it expired.
