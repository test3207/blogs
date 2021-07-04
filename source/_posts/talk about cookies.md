---
title: 'talk about cookies'
date: 2021-07-04 20:04:18
updated: 2021-07-04 20:04:18
tags:
---

# talk about cookies

it's well known that cookies are used to trace users, maintain user sessions, to support stateful features, in a stateless http environment.

and considering it's part of the infrastructure, we don't have a chance to dig into it often. i recently did something related to cross site request, and tried to solve some of the compatibility issues. so here comes a share.

## some consensus

cookies are actually special headers of request, can only set by server side using response headers with specific rules of your own. say user login success, and server response with headers like:

`set-cookie: __hostname=value; Path=/; Expires=Wed, 07 Jul 2021 01:42:19 GMT; HttpOnly; Secure; SameSite=Lax`

by standard, server can only set one cookie for each request-response.

and with detailed information, browsers will automatically decide whether should set cookie header or not, and which ones should set.

the example above is some kind of common usage. and i think we can look into details now.

## attributes of set-cookie

in conclusion, a common practice should looks like:

```typescript=
res.setHeader('Set-Cookie', '__hostname=cookie', {
    httpOnly: true,
    maxAge,
    path: '/',
    sameSite: 'lax',
    secure: true,
}));
```

### domain

it's allowed to set domain attribute to specific cookie share between domain and subdomain like `xxx.com` and `sub.xxx.com`, but we should really avoid to do this, for compatibility concern.

in elder rfc standard, if set `xxx.com`, then `sub.xxx.com` can't use this cookie; if set `.xxx.com` then `sub.xxx.com` or `anything.xxx.com` can use cookie, while `xxx.com` can't.
 
in newer rfc standard, the only difference is that if set `.xxx.com`, `xxx.com` can still use this cookie.

so in short, some grandpa browsers may implement differently, and therefore may lead to some weird bugs.

best practice in real world, is trying to implement full site same domain. it could be tricky to implment full site cdn, but we usually host static data on cdn, so it won't bother much if your cdn can't use same cookie as your main site.

### expires/maxAge

they are actually the same thing, to decide how long this session you want to maintain. by default, most browsers will expire it when users close the page if you don't set any.

they shares the same duty, the difference is that `expires` uses `Date` while `maxAge` uses `Number`. `maxAge` takes precedence if both set. here it's better to use `maxAge` only, to save a little bytes for requests.

### path

a funny thing is that this attribute only narrow down the routes cookies should set. we should do that on server side even if there are requirements anyway. so it's set as `/` for most time.

### httpOnly

should set to forbid client access cookie. like always. never trust clients lol

### secure

https only. if you are not using https, please do. i can write another post to point out the benifits. but let's focus on the topic now.

### sameSite

it could be `lax`/`strict`/`none`.

`lax` allow frames with cookie, while `strict` doesn't.

`none` is used for cross-site requests, and only allowed when `secure` is set.

usually `lax` suits most situations.

notice that some grandpa browsers doesn't support sameSite attribute, and may not be able to set cookie if it contained any sameSite sttribute. so it would be helpful with some compatibility problems if server check `UA` to decide whether use this attribute.

## cross site related stuff

normally we use `Access-Control` series headers to solve cors problems, some website just use `Access-Control-Allow-Origin: *` to allow all request from any origin.

this mostly happens in cdn requests, so it is ok in most cases. however, if we do provide service for different origin site with cookie verification, it won't work with wildcard. beside, some bad guy can abuse your cdn if you don't have any protection. so a better choice than `Access-Control-Allow-Origin: *` is maintain a whitelist. check origin site when server recieve a request, and set specific allow origin. say

```typescript=
const { origin } = req.headers;
if (!whilelist.includes(origin)) {
    res.writeHead(404);
    res.end();
    return;
}
res.setHeader('Access-Control-Allow-Origin', origin);
```

chrome support `sameSite` attribute to avoid CSRF attack. if we want to support cross site request with cookie, there is one more thing we need to consider.

configuring `sameSite=none`, all websites have the possibility to request your apis, even from `phishing.com`. attackers may build a very similar website as your real one, and mislead users to click some dangerous button. so apart from that configuring, we also need to check the origin that requesting these `sameSite=none` apis, if it is not in the whitelist, ignore the cookie too.

## epilogue

maybe you have noticed that some of the websites now showing a hint when you first entering their pages, saying you can choose or not, to allow website uses cookie. yes people nowadays more privacy-conscious, and i think there is going to be some standard later, to forbid big companies collect user information.

cookies exists for a long long time, maybe a little outdated. google are trying to establish some new mechanism to avoid abusement of cookies, export several specific api in browsers to support login, user trace, etc. it seems promising i have to say, but a bad fact is that there are still tons of users using ie. which means those compatibility issues may still there for a long long time lol.

anyway thanks for your reading. seeya
