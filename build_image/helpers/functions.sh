#!/usr/bin/env bash
function err () {
    echo >&2 "===]> Error: $@ "
    exit 1
}

function inf () {
    echo >&2 "===]> Info: $@ ";
}
