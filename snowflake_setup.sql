-- Shinyproxy Example database setup and RBAC
-- This setup SQL will run on a trial Snowflake account.  No External Access Integration (egress from snowflake) can be configured on Trial accounts.
--
--
--  Example DB
--   +- Image
--   |   +- Repository (image repository)
--   |
--   +- ShinyProxy
--   |   +- ShinyProxy (service)
--   |   +- SP_SERVICE_xxx (managed user app services)
--
--
-- Role/ object ownership
--  UserAdmin role
--   +- Database_admin role
--   |     +- Example    (database)
--   |     +- Image     (schema)
--   |     +- ShinyProxy (schema)
--   |
--   +- Image_admin role
--   |   +- Repository   (image repository)
--   |
--   +- Image_publisher role
--   +- Image_publisher user
--   |
--   +- ShinyProxy role
--   |   +- ShinyProxy   (service)
--   |     +- shinyproxy!shinyproxy (Service role)
--   |
--   +- ShinyProxy_Apps role 
--   |   +- SP_SERVICE_xxx (managed user app services)
--   |
--   +- ShinyProxy_Admins (ShinyProxy UI user access)
--   +- ShinyProxy_Users  (ShinyProxy UI user access)
--  SecurityAdmin role
--   +- image_publisher (network policy)
--   +- example_warehouse
--   +- example_compute_pool
--
--
-- Role Permissions Inheritance
--  SysAdmin  (accountadmin role can use any role/object)
--   +- Database_admin role    (Usage)
--   +- Image_admin role       (Usage)
--   +- Image_Publisher role   (Usage)
--   +- ShinyProxy_Apps role   (Usage)
--   +- ShinyProxy role        (Usage)
--      +- ShinyProxy_Apps role   (Usage)
--   +- ShinyProxy_Admins role (Usage)
--   +- ShinyProxy_Users role  (Usage)
--
--  ShinyProxy
--   +- Example Database       (Usage)
--   +- Image Schema          (Usage)
--   +- Repository             (Read)
--   +- ShinyProxy Schema      (Usage, Create Service)
--   +- Example_warehouse      (Usage, Caller Usage)
--   +- example_compute_pool   (Usage)
--   +- Account                (Bind service endpoint)
--   +- ShinyProxy_App role    (Usage)
--   +- shinyproxy!shinyproxy service role (Usage)
--
--  ShinyProxy_App  (isolate permissions of private user services from shinyproxy service)
--   +- Example Database       (Usage)
--   +- Image Schema          (Usage)
--   +- Repository             (Read)
--   +- ShinyProxy Schema      (Usage, Create Service)
--   +- Example_warehouse      (Usage)
--   +- example_compute_pool   (Usage)
--
--  ShinyProxy_Users
--   +- shinyproxy!shinyproxy service role (Usage)
--
--  Image_Publisher
--   +- Example Database       (Usage)
--   +- Image Schema          (Usage)
--   +- Repository             (Read,Write)
--   +- Image_Publisher User   (role member)



-- 1. setup snowflake account roles, databases, schemas, and warehouses
use role accountadmin;

-- database admin owns database and schema
create role if not exists database_admin;
grant ownership on role database_admin to role UserAdmin;
grant role database_admin to role sysadmin;

-- Image admin owns image repository
create role if not exists image_admin;
grant ownership on role image_admin to role UserAdmin;
grant role image_admin to role sysadmin;

-- Image publisher and user for cicd docker build and push
create role if not exists image_publisher;
grant ownership on role image_publisher to role UserAdmin;
grant role image_publisher to role sysadmin;

-- owner and execution role of shinyproxy service
create role if not exists shinyproxy;
grant ownership on role shinyproxy to role UserAdmin;
grant role shinyproxy to role sysadmin;
grant bind service endpoint on account to role shinyproxy;

-- owner and execution role of user proxy services
create role if not exists shinyproxy_apps;
grant ownership on role shinyproxy_apps to role UserAdmin;
grant role shinyproxy_apps to role sysadmin;
grant role shinyproxy_apps to role shinyproxy;

-- membership role for UI
create role if not exists shinyproxy_admins;
grant ownership on role shinyproxy_admins to role UserAdmin;
grant role shinyproxy_admins to role sysadmin;

-- Update: users which will have admin access in shinyproxy
grant role shinyproxy_admins to user <current user name>;

-- membership role for UI
create role if not exists shinyproxy_users;
grant ownership on role shinyproxy_users to role UserAdmin;
grant role shinyproxy_users to role sysadmin;

-- Update: users which will have app access in shinyproxy
grant role shinyproxy_users to user <current user name>;


-- database where image repository and shinyproxy service will be created
create database if not exists example;
grant ownership on database example to role database_admin;
-- schema for image repository object
create schema if not exists example.Image;
grant ownership on schema example.Image to role database_admin;
-- schema for shinyproxy service and user services
create schema if not exists example.shinyproxy;
grant ownership on schema example.shinyproxy to role database_admin;

grant usage on database example to role image_admin;
grant usage on database example to role image_publisher;
grant usage on database example to role shinyproxy;
grant usage on database example to role shinyproxy_apps;
grant usage on schema example.image to role image_admin;
grant usage on schema example.image to role image_publisher;
grant usage on schema example.image to role shinyproxy;
grant usage on schema example.image to role shinyproxy_apps;
grant usage,create service on schema example.shinyproxy to role shinyproxy;
grant usage,create service on schema example.shinyproxy to role shinyproxy_apps;

-- image repository
create image repository if not exists example.Image.repository;
grant ownership on image repository example.Image.repository to role image_admin;
grant read,write on image repository example.Image.repository to role image_publisher;
grant read on image repository example.Image.repository to role shinyproxy;
grant read on image repository example.Image.repository to role shinyproxy_apps;


-- warehouse.   used by shinyproxy to get users current roles
create warehouse if not exists example_warehouse
  with warehouse_size = 'XSMALL'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

grant ownership on warehouse example_warehouse to role SecurityAdmin;

grant usage on warehouse example_warehouse to role shinyproxy;
-- allow warehouse to be used as container with executeAsCaller: true, and service identity.caller identity
grant caller usage on warehouse example_warehouse to role shinyproxy;
grant usage on warehouse example_warehouse to role shinyproxy_apps;
-- allow warehouse to be used as container with executeAsCaller: true, and service identity.caller identity
grant caller usage on warehouse example_warehouse to role shinyproxy_apps;



-- create compute pool for containers
create compute pool if not exists example_compute_pool
  min_nodes = 1
  max_nodes = 32
  instance_family = 'CPU_X64_XS'
  auto_resume = true;

grant ownership on compute pool example_compute_pool to role SecurityAdmin;
grant usage on compute pool example_compute_pool to role shinyproxy;
grant usage on compute pool example_compute_pool to role shinyproxy_apps;




-- 2. CICD user to publish docker Image to the image repository
use role accountadmin;

-- Update: use whats my ip to get your egress IP to firewall where snowflake user can have access from.
create network policy if not exists image_publisher
    allowed_ip_list = ('x.x.x.x');
grant ownership on network policy image_publisher to role SecurityAdmin;

create user if not exists image_publisher
  type = 'service'
  default_role = image_publisher
  default_warehouse = example_warehouse
  default_namespace = "example.Image"
  network_policy = image_publisher;

grant ownership on user image_publisher to role UserAdmin;
grant role image_publisher to user image_publisher;

-- STOP: run this single statement Interactively and copy token_secret as PAT for docker push
alter user image_publisher add programmatic access token cicd
    role_restriction=image_publisher
    days_to_expiry = 30
    comment = 'docker image publishing cicd user';



-- 3. Push shinyproxy image with SPCS application.yml config to image repository and other test Image
-- See snowflake_docker script
-- Set the repository_url to use in the docker build and push
show image repositories in schema example.Image;
-- View published Image
show images in image repository example.Image.repository;




-- 4. Create shinyproxy service
-- Trial Snowflake accounts you will get this error "SQL access control error: Insufficient privileges to operate on schema 'SHINYPROXY'."
-- service is run as shinyproxy role, so must be owner of service, also needs create service permissions on schema to create user proxies.
-- executeAsCaller allows shinyproxy service to retrieve users current roles via impersonation.
use role shinyproxy;
create service example.shinyproxy.shinyproxy
  in compute pool example_compute_pool
  auto_resume = true
  min_instances = 1
  max_instances = 1
  comment = 'shinyproxy application portal'
  from specification $$
    spec:
      containers:
        - name: shinyproxy
          image: /example/Image/repository/shinyproxy:latest
          resources:
            requests:
              cpu: 1.0
              memory: 1G
      endpoints:
        - name: http
          port: 8080
          protocol: http
          public: true
    capabilities:
      securityContext:
        executeAsCaller: true
    serviceRoles:
      - name: shinyproxy
        endpoints:
          - http
    $$;

grant service role example.shinyproxy.shinyproxy!shinyproxy to role shinyproxy_users;
-- show grants to service role example.shinyproxy.shinyproxy!shinyproxy;
-- show grants of service role example.shinyproxy.shinyproxy!shinyproxy;

-- STOP: should see instance_status: PENDING then READY.  60-90seconds for public endpoints
show service containers in service example.shinyproxy.shinyproxy;
-- get ingress_url
show endpoints in service example.shinyproxy.shinyproxy;
-- view service logs in Snowsight
-- https://app.snowflake.com/<org>/<account>/#/compute/service/EXAMPLE/SHINYPROXY/SHINYPROXY/logs?instanceId=0&containerName=shinyproxy


-- 5. via UI start user proxies services for the apps
-- should see SP_SERVICE_xxx services being created
show services in schema example.shinyproxy;

-- 6.  when new shinyproxy image has been updated to restart the service and load the new image
use role shinyproxy;
alter service example.shinyproxy.shinyproxy  
  from specification $$
    spec:
      containers:
        - name: shinyproxy
          image: /example/Image/repository/shinyproxy:latest
          resources:
            requests:
              cpu: 1.0
              memory: 1G
      endpoints:
        - name: http
          port: 8080
          protocol: http
          public: true
    capabilities:
      securityContext:
        executeAsCaller: true
    serviceRoles:
      - name: shinyproxy
        endpoints:
          - http
    $$;

-- should see instance_status: TERMINATING, then PENDING then READY
show service containers in service example.shinyproxy.shinyproxy;
show endpoints in service example.shinyproxy.shinyproxy;
