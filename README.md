Extended MySQL SQL Database Server Container Image
==

This repository contains script extensions for the default MySQL image.
For more information about the default image please visit: https://github.com/sclorg/mysql-container/tree/master/5.7
For more information about s2i please visit: https://github.com/openshift/source-to-image

Description
==

The default image got no feature that will import existing mysql dumps to the database.
But it can be extended by s2i for custom scripts on various states of the database.
This repo will extend the default image to download and import a mysql dump via HTTP/S.
By default it will import only data if there are no tables present but the import can also beforced.

Installation
==

This image is available on the default registry.

It can also be build from scratch via:

```
git clone https://github.com/bitsbeats/s2i-mysql-container.git
cd s2i-mysql-container
s2i build . centos/mysql-57-centos7 mysql-import-image
```

Usage
==

For this, we assumte that you have build the image locally via s2i (see previous paragraph):

```
$ docker run -d --name mysql_database -e MYSQL_USER=user -e MYSQL_PASSWORD=pass -e MYSQL_DATABASE=db -e MYSQL_DEPLOY_DUMP="<dump_file_on_source_url>" -e MYSQL_DUMP_SOURCE_URL="<source_url>" -e MYSQL_FORCE_DEPLOY_DUMP=false -e MYSQL_DUMP_SOURCE_USER=<source_url_user> -e MYSQL_DUMP_SOURCE_PASSWORD="<source_url_pw>" -p 3306:3306 mysql-import-image
```

This will create a container named mysql_database running MySQL with database db and user with credentials user:pass. Port 3306 will be exposed and mapped to the host. If you want your database to be persistent across container executions, also add a -v /host/db/path:/var/lib/mysql/data argument. This will be the MySQL data directory.

It will download the dumpfile <dump_file_on_source_url> from <source_url> and uses for httpauth the credentials <source_url_user>:<source_url_pw>.
Because of MYSQL_FORCE_DEPLOY_DUMP=false it will only import the dump if there are no tables present (empty database).

You can refresh the database with a new dump via a new deployment / docker run and MYSQL_FORCE_DEPLOY_DUMP=true
WARNING: All tables that are included in the dump will be overridden.

The dump needs to include "DROP TABLE IF EXISTS" to support the refresh and should not be compressed.


Environment variables
==

The image is extended for the following environment variables that you can set during
initialization by passing `-e VAR=VALUE` to the Docker run command.

**`MYSQL_DEPLOY_DUMP`**
       The dumpfile to download and import

**`MYSQL_DUMP_SOURCE_URL`**
       The url to download the dump from (example: http://foo.bar/download/dump)

Optional:

**`MYSQL_FORCE_DEPLOY_DUMP`**
       Import the dump also if there is already existing data? (default: "false")

**`MYSQL_DUMP_SOURCE_USER`**
       User for httpauth on the download url

**`MYSQL_DUMP_SOURCE_PASSWORD`**
       Password for httpauth on the download url
