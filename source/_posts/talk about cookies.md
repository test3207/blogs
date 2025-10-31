---
title: 'Talk About Cookies'
date: 2021-07-04 20:04:18
updated: 2025-10-31 21:34:00
tags:
  - Web Development
  - HTTP
  - Cookies
  - Security
---

It's well known that cookies are used to trace users, maintain user sessions, and support stateful features in a stateless HTTP environment.

Considering it's part of the infrastructure, we don't often have a chance to dig into it deeply. I recently worked on something related to cross-site requests and tried to solve some compatibility issues. Here's what I learned.

> **Note:** For comprehensive documentation on HTTP Cookies, refer to [MDN Web Docs: HTTP Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies) and [MDN Web Docs: Set-Cookie](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie).

## Some Consensus

Cookies are actually special headers in requests, which can only be set by the server side using response headers with specific rules. For example, when a user logs in successfully, the server responds with headers like:

`set-cookie: __hostname=value; Path=/; Expires=Wed, 07 Jul 2021 01:42:19 GMT; HttpOnly; Secure; SameSite=Lax`

By standard, the server can only set one cookie per `Set-Cookie` header (but can send multiple `Set-Cookie` headers).

With detailed information, browsers will automatically decide whether to set the cookie header and which cookies to include.

The example above represents common usage. Let's look into the details now.

## Attributes of Set-Cookie

In conclusion, a common practice should look like:

```typescript
res.setHeader('Set-Cookie', '__hostname=cookie', {
    httpOnly: true,
    maxAge,
    path: '/',
    sameSite: 'lax',
    secure: true,
}));
```

### Domain

It's allowed to set the domain attribute to share cookies between a domain and its subdomains like `xxx.com` and `sub.xxx.com`, but we should avoid this for compatibility reasons.

In the older RFC standard, if you set `xxx.com`, then `sub.xxx.com` can't use this cookie. If you set `.xxx.com`, then `sub.xxx.com` or `anything.xxx.com` can use the cookie, while `xxx.com` can't.

In the newer RFC standard, the only difference is that if you set `.xxx.com`, `xxx.com` can still use this cookie.

In short, some legacy browsers may implement this differently, which may lead to unexpected bugs.

The best practice is to implement a same-domain architecture across your entire site. While implementing site-wide CDN with the same domain can be tricky, we usually host static assets on CDN, so it won't cause issues if your CDN can't share cookies with your main site.

### Expires/MaxAge

These attributes serve the same purpose: determining how long the session should be maintained. By default, most browsers expire cookies when users close the page if neither attribute is set.

Both serve the same function, but `expires` uses a `Date` value while `maxAge` uses a `Number` (in seconds). If both are set, `maxAge` takes precedence. It's better to use `maxAge` only, to save a few bytes in requests.

### Path

An interesting aspect of this attribute is that it only narrows down the routes where cookies should be sent. We should handle this on the server side anyway, so it's usually set to `/`.

### HttpOnly

This should always be set to prevent client-side JavaScript access to cookies. Never trust client-side code.

### Secure

This enforces HTTPS-only transmission. If you're not using HTTPS, please do. I could write another post about the benefits, but let's stay focused on cookies for now.

### SameSite

This can be `lax`, `strict`, or `none`.

`lax` allows cookies in top-level navigations, while `strict` doesn't.

`none` is used for cross-site requests and is only allowed when `secure` is also set.

Usually `lax` suits most situations.

Note that some legacy browsers don't support the `sameSite` attribute and may fail to set cookies if it contains any `sameSite` attribute. It can be helpful to check the `User-Agent` to decide whether to use this attribute for compatibility.

> **Reference:** [MDN: SameSite cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite)

## Cross-Site Related Stuff

Normally we use `Access-Control` series headers to solve CORS problems. Some websites simply use `Access-Control-Allow-Origin: *` to allow all requests from any origin.

> **Reference:** [MDN: Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

This mostly happens in CDN requests, so it's acceptable in most cases. However, if you provide services for different origin sites with cookie verification, it won't work with wildcards. Besides, attackers could abuse your CDN if you don't have any protection. A better choice than `Access-Control-Allow-Origin: *` is to maintain a whitelist. Check the origin site when the server receives a request and set a specific allow origin. For example:

```typescript
const { origin } = req.headers;
if (!whitelist.includes(origin)) {
    res.writeHead(404);
    res.end();
    return;
}
res.setHeader('Access-Control-Allow-Origin', origin);
```

Chrome supports the `sameSite` attribute to avoid CSRF attacks. If we want to support cross-site requests with cookies, there's one more thing we need to consider.

> **Reference:** [MDN: Cross-Site Request Forgery (CSRF)](https://developer.mozilla.org/en-US/docs/Glossary/CSRF)

When configuring `sameSite=none`, all websites have the possibility to request your APIs, even from `phishing.com`. Attackers may build a very similar website to yours and mislead users into clicking dangerous buttons. Apart from that configuration, we also need to check the origin requesting these `sameSite=none` APIs. If it's not in the whitelist, ignore the cookie as well.

## Epilogue

You may have noticed that some websites now show a notification when you first visit their pages, allowing you to choose whether to allow cookies. Yes, people are increasingly privacy-conscious, and I believe there will be standards later to prevent large companies from collecting user information.

Cookies have existed for a long time and may be somewhat outdated. Google is trying to establish new mechanisms to prevent cookie abuse by providing specific APIs in browsers to support login, user tracking, etc. It seems promising, but the reality is that many users still use legacy browsers, which means these compatibility issues may persist for a long time.

> **Update (2025):** Google's Privacy Sandbox initiative has introduced several alternatives to third-party cookies, including Topics API, Protected Audience API, and Attribution Reporting API. However, adoption is still ongoing. Learn more at [Privacy Sandbox](https://privacysandbox.com/).

## Further Reading

- [MDN: HTTP Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies)
- [MDN: Set-Cookie Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie)
- [MDN: Cookie Security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#security)
- [MDN: Third-party Cookies](https://developer.mozilla.org/en-US/docs/Web/Privacy/Third-party_cookies)

Thank you for reading.
