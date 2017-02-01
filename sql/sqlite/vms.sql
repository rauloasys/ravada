CREATE TABLE vms(
    `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT
,    `name` char(255) NOT NULL
,    `vtype` char(32) NOT NULL
,    `host` char(128) NOT NULL default 'localhost'
,    UNIQUE (`name`)
);
