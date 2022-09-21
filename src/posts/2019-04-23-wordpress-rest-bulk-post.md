---
title: "Using Wordpress REST API to bulk post"
date: 2019-04-23
author: kotatsuyaki (Ming-Long Huang)
---

Recently on one of the courses I enrolled, the professor assigned a homework (which takes part in my **midterm grade**) that involves posting massive amount of code onto a wordpress site.

<!-- more -->

# OF COURSE NOT

I have the code in individual files already, but too lazy to post them one-by-one. The solution emmerges immediately: *let's automate this tedious process*. So here we go.

Taking a brief view of the [REST API Handbook](https://developer.wordpress.org/rest-api/) that WordPress provides us with, it seems that they're just some simple `JSON` APIs. But crafting the requests manually isn't wise - we can use [a library called wpapi](https://www.npmjs.com/package/wpapi) that handles it. I chose to use NodeJS for this simple task because I'm quite familiar and actually enjoy working with it.

![You can try out the API in the browser](/images/img-1.png)

To setup, make a new directory and `cd` into it. Run `npm init -y` to initialize and then install node-wpapi by `npm i wpapi --save`. The library usage is pretty straightforward. You need to install [Basic HTTP auth](https://github.com/WP-API/Basic-Auth) plugin on the server manually, and fill in the login credentials inside the constructor of the `WPAPI` object:

```javascript
const WPAPI = require('wpapi');
const fs    = require('fs');

// Create a new instance of WPAPI,
// with your credentials
var wp = new WPAPI({
	endpoint: ROUTE_TO_API_ENDPOINT,
	username: USERNAME,
	password: PASSWORD,
});

// An object that maps filename to the title required
// by the homework
var dict = {
	code_file_1: 'title_to_use_for_code_file_1'
	// ...
	code_file_n: 'title_to_use_for_code_file_n'
};

// A function to get post body text from key
var get_post_text = key => {
	return `[php]
<!--
程式檔名：${key}.php
程式功能：${dict[key]}
-->
` + fs.readFileSync(`./code_files/${key}.php`) + `
[/php]`;
};

// A function to get post title from key
var get_post_title = key => {
	return `${key}：${dict[key]}`;
};

for (var key of Object.keys(dict)) {
	wp.posts().create({
		title: get_post_title(key),
		content: get_post_text(key),
		status: 'publish',
	}).then(res => {
		// This is the post id
		console.log(res.id);
	}).catch(err => {
		console.log(err);
	});
}
```

Note that basic access authentication is vulnerable to attacks such as packet sniffing etc., so you'll like your connection to be secured using TLS/SSL in order to protect your data safety. I don't care much about this for my work, as it's just a throwaway WordPress instance hosted on my VPS.

![The result](/images/img-2.png)

Run the code with `node`, and after a while it'll post all the code onto the site. Yes, I know the theme is not so good-looking. It's not picked by me.
