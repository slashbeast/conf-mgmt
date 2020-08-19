#!/bin/sh

_ssh_agent_spawn() {
    local state_dir env_path socket_path ssh_agent_env

    state_dir="$HOME/.ssh/agent"
    env_path="${state_dir}/env"
    socket_path="${state_dir}/socket"

    if [ -f "${env_path}" ]; then
        . "${env_path}"
        if [ -d "/proc/${SSH_AGENT_PID}" ] && [ "$(cat "/proc/${SSH_AGENT_PID}/comm")" = "ssh-agent" ]; then
            return
        fi
    fi

    mkdir --mode 0700 -p "${state_dir}"

    rm -f "${socket_path}"

    if ssh_agent_env="$(ssh-agent -s -a "${socket_path}")"; then
        echo "${ssh_agent_env/echo Agent pid *;/}" >"${env_path}"
        . "${env_path}"
    else
        echo "Failed to start ssh-agent"
    fi
}

_ssh_agent_spawn

unset -f _ssh_agent_spawn
