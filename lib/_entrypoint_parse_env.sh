#!/bin/sh

# Prepare environment variables and set up defaults
prepare_proxy_variables(){
	# Set default value of PROXY_MODE to "prod"
	if [ -z "${PROXY_MODE}" ]
	then
		export PROXY_MODE="prod"
	fi

	# If PROXY_MODE is dev, then a self-signed certificate will be issued
	# to the domain localhost.
	if [ "${PROXY_MODE}" = "dev" ]
	then
		logger_warn "Running in dev mode. Will use self-signed certificates."
		logger_warn "Not recommended for integration and production setup."
		logger_warn "Only localhost will be used as a host name."
		export PROXY_DOMAIN="localhost"
	fi

	# PROXY_DOMAIN must be set, or there is no use in starting the proxy.
	if [ -z "${PROXY_DOMAIN}" ]
	then
		logger_fatal "PROXY_DOMAIN is not set."
		return 1
	else
		le_path="/etc/letsencrypt/live/$PROXY_DOMAIN"
		le_privkey="$le_path/privkey.pem"
		le_fullchain="$le_path/fullchain.pem"
	fi

	# PROXY_BACKENDS must be set.
	if [ -z "${PROXY_BACKENDS}" ]
	then
		logger_fatal "PROXY_BACKENDS is not set."
		return 1;
	fi

	# In PROXY_MODE other than dev, PROXY_CERTBOT_MAIL must be set
	if [ ! "${PROXY_MODE}" = "dev" ] && [ -z "${PROXY_CERTBOT_MAIL}" ]
	then
		logger_fatal "PROXY_CERTBOT_MAIL is not set. It is required for letsencrypt."
		return 1
	fi

	# In PROXY_MODE dev, we want the cert_method to be selfsigned
	if [ "${PROXY_MODE}" = "dev" ]
	then
		cert_method="selfsigned"
	else
		cert_method="certbot"
	fi

	# Default values for some variables
	if [ -z $PROXY_HTTP_PORT ]; then
		export PROXY_HTTP_PORT="80"
	fi
	if [ -z $PROXY_HTTPS_PORT ]; then
		export PROXY_HTTPS_PORT="443"
	fi
	if [ -z $PROXY_TUNING_WORKER_CONNECTIONS ]; then
		# Many docker containers have a 1024 file descriptor limit
		export PROXY_TUNING_WORKER_CONNECTIONS="512"
	fi
	if [ -z $PROXY_TUNING_UPSTREAM_MAX_CONNS ]; then
		export PROXY_TUNING_UPSTREAM_MAX_CONNS="0";
	fi

	# PROXY_AUTH_USER and PROXY_AUTH_PASSWORD are completely optional.
	# However, if PROXY_AUTH_USER is set, PROXY_AUTH_PASSWORD must also be set.
	if [ ! -z $PROXY_AUTH_USER ] && [ -z $PROXY_AUTH_PASSWORD ]
	then
		logger_fatal "PROXY_AUTH_USER was set. PROXY_AUTH_PASSWORD must then also be set."
		return 1
	fi

	logger_debug "Entrypoint.sh has initialised all variables. Here is the complete environment:"
	logger_debug "$(env)"

}

# Prepare names of all variables to replace (beginning with PROXY_)
prepare_envreplace(){
	local env_names=$(env_startswith PROXY_)
	echo "$env_names"
	logger_debug "String of variables to replace: $env_names"
}

# Unset all environment variables starting with a certain pattern
# Parameter:
# 1. String that an environment variable starts with
# Example `env_unset_startswith PROXY_`
env_unset_startswith(){
	local start=$1
	local env_names=$(env_startswith $start)
	local env_name
	for env_name in $env_names
	do
		unset $env_name
	done
}

# Output a list of matching environment variables as a list of space-separated names
# Parameter
# 1. String, that the environment variable name starts with
# Example: `env_startswith PROXY_`
env_startswith(){
	local start=$1
	local grep_pattern="^$start.*="
	local sed_pattern="s/^($start.*?)=/\\1/g"
	local matching_envs=$(env | grep -Eo $grep_pattern | sed -E $sed_pattern | sort -bd)
	local single_line=$(echo -n "$matching_envs" | tr '\n' ' ')
	echo "$single_line"
}
