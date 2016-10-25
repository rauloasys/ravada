create table farms (
  `id` integer primary key AUTOINCREMENT,
  `name` char(40),
  `description` char(140),
  `type` char(20),
  UNIQUE (`name`)
);
