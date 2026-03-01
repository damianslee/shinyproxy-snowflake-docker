use role accountadmin;
drop service if exists example.shinyproxy.shinyproxy;
drop user if exists image_publisher;
drop network policy if exists image_publisher;
drop compute pool if exists example_compute_pool;
drop warehouse if exists example_warehouse;
drop image repository if exists example.images.repository;
drop schema if exists example.shinyproxy;
drop schema if exists example.image;
drop database if exists example;

drop role if exists shinyproxy_users;
drop role if exists shinyproxy_admins;
drop role if exists shinyproxy_apps;
drop role if exists shinyproxy;
drop role if exists image_publisher;
drop role if exists image_admin;
drop role if exists database_admin;
