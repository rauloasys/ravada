CREATE TABLE `farms` (
    `id` int(11) NOT NULL AUTO_INCREMENT ,
    type char(32) NOT NULL,
    name char(32) NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE (name)

);
