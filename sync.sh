#!/bin/bash

set -euo pipefail

echo "========================================"
echo "Environment of Coral iSEM10 v2"
echo "========================================"
echo

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

git checkout master
git pull --recurse-submodules

git submodule sync --recursive
git submodule update --init --recursive || true

if [ -f .gitmodules ]; then
    echo
    echo "Syncing submodules from .gitmodules"
    git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read -r key path; do
        module=${key#submodule.}
        module=${module%.path}
        url=$(git config -f .gitmodules "submodule.${module}.url" || true)
        branch=$(git config -f .gitmodules "submodule.${module}.branch" || true)

        if [ -z "$url" ]; then
            echo "-- Skipping $path: missing url in .gitmodules"
            continue
        fi

        path_has_git=false
        if [ -e "$path/.git" ]; then
            path_has_git=true
        fi

        if [ ! -d "$path" ] || [ -z "$(ls -A "$path" 2>/dev/null)" ] || [ "$path_has_git" = false ]; then
            if [ -d "$path" ]; then
                echo "-- Removing invalid or empty path $path"
                rm -rf "$path"
            fi
            echo "-- Cloning $path from $url"
            if [ -n "$branch" ]; then
                git clone --branch "$branch" --single-branch "$url" "$path"
            else
                git clone "$url" "$path"
            fi
            path_has_git=true
        fi

        if [ "$path_has_git" = true ] && [ -e "$path/.git" ]; then
            echo "-- Updating submodule $path"
            git -C "$path" remote set-url origin "$url"
            git -C "$path" fetch origin --prune

            if [ -n "$branch" ]; then
                if git -C "$path" rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
                    git -C "$path" checkout "$branch"
                elif git -C "$path" rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null; then
                    git -C "$path" checkout -B "$branch" "origin/$branch"
                else
                    echo "WARNING: branch "$branch" not found locally or on origin for $path"
                    continue
                fi
                git -C "$path" branch --set-upstream-to="origin/$branch" "$branch"
                git -C "$path" pull --ff-only origin "$branch"

                local_rev=$(git -C "$path" rev-parse HEAD)
                remote_rev=$(git -C "$path" rev-parse "origin/$branch")
                if [ "$local_rev" != "$remote_rev" ]; then
                    echo "ERROR: $path HEAD ($local_rev) does not match origin/$branch ($remote_rev)"
                    exit 1
                fi
            else
                git -C "$path" pull --ff-only
            fi

            if [ -z "$(ls -A "$path" 2>/dev/null)" ]; then
                echo "ERROR: $path is empty after pull"
                exit 1
            fi
        fi
    done
fi

git submodule sync --recursive
git submodule update --init --recursive --force || true

git submodule foreach --recursive '
    if [ -z "$(ls -A . 2>/dev/null)" ]; then
        echo "ERROR: submodule $sm_path is empty"
        exit 1
    fi
'
