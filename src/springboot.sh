#!/bin/bash

sb::up() {
	local ip=$(horde::bridge_ip)
	local hostname=$(horde::hostname)
	local name=$(horde::config::get_name)
	local docs=$(pwd)

	local image=$(horde::config::get_image)

	local env_file=$(horde::config::get_env_file)
	local env_file_arg=""
	if [ "${env_file}" != "null" ] ; then
		env_file_arg="--env-file ${env_file}"
	fi

	horde::ensure_running mysql || return 1
	horde::ensure_running logspout || return 1

	docker run -it \
		--rm \
		--link vault:vault \
		-v `pwd`:/mnt/creds \
		-e VAULT_TOKEN=horde \
		-e APP_NAME="${name}" \
		vault:0.6.5  \
		/bin/sh -c 'export VAULT_ADDR=http://$VAULT_PORT_8200_TCP_ADDR:8200; \
					vault auth-enable approle; \
					vault write auth/approle/role/$APP_NAME bind_secret_id=true; \
					vault read -format=json auth/approle/role/$APP_NAME/role-id > ${APP_NAME}_roleId.json; \
					vault write -f -format=json auth/approle/role/$APP_NAME/secret-id > ${APP_NAME}_secretId.json; \
					mv *.json /mnt/creds;' \
		|| return 1

	docker run -d \
		-P ${env_file_arg} \
		--expose 5005 \
		-e "SERVICE_8080_CHECK_SCRIPT=echo ok" \
		-e "SERVICE_8080_NAME=${name}" \
		-e "SERVICE_8080_TAGS=urlprefix-${hostname}/,springboot" \
		--name "${name}" \
		--dns "${ip}" \
		--link consul:consul \
		--link mysql:mysql \
		"${image}" \
		|| return 1
}

sb_gw::up() {
	local ip=$(horde::bridge_ip)
	local hostname=$(horde::hostname)
	local name=$(horde::config::get_name)
	local docs=$(pwd)

	local image=$(horde::config::get_image)

	local env_file=$(horde::config::get_env_file)
	if [ "${env_file}" != "null" ] ; then
		env_file="--env-file ${env_file}"
	fi

	docker run -d \
		-P\
		--expose 5005 \
		-e "SERVICE_8080_CHECK_SCRIPT=echo ok" \
		-e "SERVICE_8080_NAME=${name}" \
		-e "SERVICE_8080_TAGS=urlprefix-${hostname}/api/,springboot" \
		${env_file} \
		--name "${name}" \
		--dns "${ip}" \
		--link consul:consul \
		--link mysql:mysql \
		"${image}" \
		|| return 1

}


sb_gw_web::up() {
	local ip=$(horde::bridge_ip)
	local hostname=$(horde::hostname)
	local name=$(horde::config::get_name)
	local docs=$(pwd)


	docker run -d \
		-P\
		-e "SERVICE_80_CHECK_SCRIPT=echo ok" \
		-e "SERVICE_80_NAME=${name}" \
		-e "SERVICE_80_TAGS=urlprefix-${hostname}/,angular-web" \
		-e "FLIGLIO_ENV=horde" \
		-v "${docs}/dist:/var/www/httpdocs/" \
		--name "${name}" \
		--dns "${ip}" \
		--link consul:consul \
		--link mysql:mysql \
		benschw/horde-fliglio \
		|| return 1

}
