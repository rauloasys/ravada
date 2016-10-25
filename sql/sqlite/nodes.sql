CREATE TABLE `nodes` (
  `id` integer primary key AUTOINCREMENT,
  `id_farm` integer not null,
  `address` char(32) not null,
);
