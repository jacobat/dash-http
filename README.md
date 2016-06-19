Dash HTTP Statuses
==================

Generate Dash docset for HTTP statuses based on RFC 2616.

Usage
-----

Generate the docset by running the build script:

```sh
sh build.sh
```

This generates the `http.tgz` file containing the docset.

Installation
------------

Installing the docset is done by starting a webserver:

```sh
ruby -run -e httpd . -p 3000
```

Then go to the Dash preferences, the downloads tab and add the feed at
http://localhost:3000/http.xml
