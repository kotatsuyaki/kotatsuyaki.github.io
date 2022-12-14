---
title: "Reducing Gitlab Page Load Time"
date: 2020-07-29
author: kotatsuyaki (Ming-Long Huang)
---

I've been migrating the old blog to here for a while.
The site is now generated using [Zola](https://www.getzola.org/documentation/getting-started/installation/) instead of Hexo,
because I'd like to ditch Node.js based tools in favor of those written in Rust,
and partly just for fun.

---

# Minimize and Inline CSS

The site is using slightly modified [zola-henry](https://github.com/sirodoht/zola-henry) theme at the moment, which contains just a single CSS file.
We first minimize it.

```sh
$ cssnano < henry-full.cs > henry.css
```

Then, modify the theme template to inline the CSS file instead of using a `<link>` tag.

```html
{% set henry_css = load_data(path="themes/henry/static/henry.css") %}
<style>{{ henry_css | safe }}</style>
```

<!-- more -->

# Gzip Compression

Although it's not found anywhere in their official documentation,
gzip compression is actually supported for Gitlab Pages.
Compression can be enabled by simply placing `.gz` files alongside the static files.
We achieve this by adding a single line to the CI config file.

```yaml
script:
  # ...
  - gzip --keep --best $(find public -type f)
```

The result can be verified using curl[^1].

```sh
$ curl -s 'https://akitaki.gitlab.io/optimize-gitlab-pages-loadtime/' | wc -c
9094
$ curl -sH 'Accept-Encoding: gzip,deflate' https://akitaki.gitlab.io/optimize-gitlab-pages-loadtime/ | wc -c
3205
```

[^1]: Ideally with `curl -I` one can see the `Content-Length` header, so it shouldn't be necessary to count length with `wc`. However, [there's a bug](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/315) causing the length field to be missing.

# References

- <https://github.com/getzola/zola/issues/605>
- <https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/25>
