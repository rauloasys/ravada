CREATE TABLE `farms` (
    `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT 
,    type char(32) NOT NULL
,    name char(32) NOT NULL
,    UNIQUE (name)
);
