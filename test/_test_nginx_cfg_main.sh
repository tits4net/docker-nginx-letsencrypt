#! /bin/sh

. ${libdir}/_nginx_cfg_main.sh

setUp(){
	unset PROXY_DOMAIN
	unset PROXY_AUTH_USER
	unset PROXY_AUTH_PASSWORD
}

# Test the http section (empty)
testHttpSectionEmpty(){
	expected="http {

  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                    '\$status \$body_bytes_sent \"\$http_referer\" '
                    '\"\$http_user_agent\" \"\$http_x_forwarded_for\" ';

  access_log  /var/log/nginx/access.log  main;

  server_tokens off;

  sendfile        on;
  keepalive_timeout  65;

  include /etc/nginx/conf.d/http_*.conf;
}"
	actual=$(nginx_cfg_http_section)
	assertEquals "$expected" "$actual"
}

# Test the http section (empty)
testHttpSectionBasicAuth(){
	export PROXY_DOMAIN="test.example.org"
	export PROXY_AUTH_USER="testuser"
	export PROXY_AUTH_PASSWORD="testpassword"
	expected="http {

  auth_basic \"test.example.org\";
  auth_basic_user_file /etc/nginx/conf.d/auth_basic.inc;

  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                    '\$status \$body_bytes_sent \"\$http_referer\" '
                    '\"\$http_user_agent\" \"\$http_x_forwarded_for\" ';

  access_log  /var/log/nginx/access.log  main;

  server_tokens off;

  sendfile        on;
  keepalive_timeout  65;

  include /etc/nginx/conf.d/http_*.conf;
}"
	actual=$(nginx_cfg_http_section)
	assertEquals "$expected" "$actual"
}

# Test the main configuration
testMainConfigEmpty(){
	expected="
daemon off;
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log warn;
pid       /var/run/nginx.pid;

events {
  worker_connections 128;
}

http {

  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                    '\$status \$body_bytes_sent \"\$http_referer\" '
                    '\"\$http_user_agent\" \"\$http_x_forwarded_for\" ';

  access_log  /var/log/nginx/access.log  main;

  server_tokens off;

  sendfile        on;
  keepalive_timeout  65;

  include /etc/nginx/conf.d/http_*.conf;
}

stream {
  include /etc/nginx/conf.d/stream_*.conf;
}"
	actual=$(nginx_cfg_main)
	assertEquals "$expected" "$actual"
}

. ${extlibdir}/shunit2/shunit2

