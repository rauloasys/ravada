CREATE TABLE vms(
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` char(255) NOT NULL,
    `vtype` char(32) NOT NULL,
    `host` char(128) NOT NULL default 'localhost',
    PRIMARY KEY(`id`),
    UNIQUE KEY `name` (`name`)
);

