#!/usr/bin/env bash
#
# This file is part of REANA.
# Copyright (C) 2017, 2018, 2019, 2020, 2021, 2024 CERN.
#
# REANA is free software; you can redistribute it and/or modify it
# under the terms of the MIT License; see LICENSE file for more details.

set -o errexit
set -o nounset

check_commitlint () {
    from=${2:-master}
    to=${3:-HEAD}
    pr=${4:-[0-9]+}
    npx commitlint --from="$from" --to="$to"
    found=0
    while IFS= read -r line; do
        commit_hash=$(echo "$line" | cut -d ' ' -f 1)
        commit_title=$(echo "$line" | cut -d ' ' -f 2-)
        commit_number_of_parents=$(git rev-list --parents "$commit_hash" -n1 | awk '{print NF-1}')
        if [ "$commit_number_of_parents" -gt 1 ]; then
            if echo "$commit_title" | grep -qP "^chore\(.*\): merge "; then
                break
            else
                echo "✖   Merge commits are not allowed in feature branches: $commit_title"
                found=1
            fi
        elif echo "$commit_title" | grep -qP "^chore\(.*\): release"; then
            true
        elif echo "$commit_title" | grep -qP "\(\#$pr\)$"; then
            true
        else
            echo "✖   Headline does not end by '(#$pr)' PR number: $commit_title"
            found=1
        fi
    done < <(git log "$from..$to" --format="%H %s")
    if [ $found -gt 0 ]; then
        exit 1
    fi
}

check_shellcheck () {
    find . -name "*.sh" -exec shellcheck {} \+
}

check_black () {
    black --check .
}

check_flake8 () {
    flake8 .
}

check_pydocstyle () {
    pydocstyle reana
}

check_manifest () {
    check-manifest
}

check_sphinx () {
    sphinx-build -qnNW docs docs/_build/html
}

check_pytest () {
    python setup.py test
}

check_helm () {
    helm lint helm/reana
}

check_all () {
    check_commitlint
    check_shellcheck
    check_black
    check_flake8
    check_pydocstyle
    check_manifest
    check_sphinx
    check_pytest
    check_helm
}

if [ $# -eq 0 ]; then
    check_all
    exit 0
fi

arg="$1"
case $arg in
    --check-commitlint) check_commitlint "$@";;
    --check-shellcheck) check_shellcheck;;
    --check-black) check_black;;
    --check-flake8) check_flake8;;
    --check-pydocstyle) check_pydocstyle;;
    --check-manifest) check_manifest;;
    --check-sphinx) check_sphinx;;
    --check-pytest) check_pytest;;
    --check-helm) check_helm;;
    *) echo "[ERROR] Invalid argument '$arg'. Exiting." && exit 1;;
esac
