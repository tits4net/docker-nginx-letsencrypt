#!/bin/sh

nginx_cfg_single_backend_line() {
	echo "server ${1} max_fails=3 fail_timeout=5s max_conns=${PROXY_TUNING_UPSTREAM_MAX_CONNS};"
}

nginx_cfg_backend_string () {
	retval="upstream backend_server {
  ip_hash;"
	for backend in ${PROXY_BACKENDS}; do
		retval="${retval}
  $(nginx_cfg_single_backend_line ${backend})"
	done
	retval="${retval}
}"
	echo "$retval"
}
