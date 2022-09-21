---
title: "Difference between include_str and include_bytes"
date: 2020-07-31
author: kotatsuyaki (Ming-Long Huang)
---

- [`include_bytes`](https://doc.rust-lang.org/std/macro.include_bytes.html)

    The expression is of type `&'static [u8; N]`, so non-UTF8 data also works.

- [`include_str`](https://doc.rust-lang.org/std/macro.include_str.html)

    The expression is of type `&'static str'`, so the file must be UTF-8 encoded.

# What happens if we `include_str` on non-utf8 files?

Will the Rust compiler detect this? Let's try this out.

<!-- more -->

Create a file with UTF-8 content and then convert it to another encoding.

```sh
$ echo '色は匂へど 散りぬるを 我が世誰ぞ 常ならむ 有為の奥山 今日越えて 浅き夢見じ 酔ひ
もせず
' >> test.txt
$ iconv -t SHIFT-JIS test.txt > test-shift-jis.txt
```

Include the shift-jis encoded file in Rust.

```rust
pub fn main() {
    include_str!("./test-shift-jis.txt");
}
```

It turned out that the compiler will yell at us, just as expected.

```
$ rustc main.rs
error: ./test-shift-jis.txt wasn't a utf-8 file
 --> main.rs:2:5
  |
2 |     include_str!("./test-shift-jis.txt");
  |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  |
  = note: this error originates in a macro (in Nightly builds, run with -Z macro-backtrace for more info)

error: aborting due to previous error
```
