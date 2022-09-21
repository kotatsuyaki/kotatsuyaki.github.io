---
title: "Extracting template parameters during compile time in C++"
date: 2020-02-13
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

Recently when working on my toy projects, I came across a scenario, which can be simplified into the following example. Suppose that we have a struct template that looks like this:

```cpp
template <std::size_t S> struct Obj { /* ... */ };
```

It turned out that I also wanted to write a template where the return type is dependent on that `size_t S` template parameter. Yes, this is certainly doable, with the help of a custom traits that extracts the template parameter. Note that you need a compiler that supports at least C++11 or higher for this to work.

<!-- more -->

```cpp
#include <algorithm>
#include <array>
#include <iostream>

/* The demo struct template */
template <std::size_t S = 10> struct Obj {
    void operator=(int value) { this->value = value; }
    operator int() const { return value; }
    int value;
};

template <typename T> struct get_size;

/* Template parameter extractor */
template <template <std::size_t> class O, std::size_t S> struct get_size<O<S>> {
    constexpr static const std::size_t value = S;
};

/*
 * A function that determines its return type
 * based on template parameters of type T
 */
template <typename T>
auto make_arr(T&& t)
    -> std::array<typename std::remove_reference<T>::type,
                  get_size<typename std::remove_reference<T>::type>::value> {
    // Return an empty array
    return {};
}

int main(int argc, char* argv[]) {
    // If using C++17, the parameter can be omitted.
    Obj<10> o;
    auto arr = make_arr(o);
    
    /* Use the array to do something useful */
    std::fill(arr.begin(), arr.end(), 87);
    for (const auto& el : arr) {
        std::cout << el << '\n';
    }
    return 0;
}
```
