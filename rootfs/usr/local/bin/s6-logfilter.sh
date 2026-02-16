#!/usr/bin/env bash
# shellcheck shell=bash

awk '
function emit(level, color, line) {
  printf "[ \033[00;%sm%s\033[0m ] %s\n", color, level, line
  fflush()
}

function strip_cr_progress(s,    n, a) {
  # Als er carriage returns in zitten, neem alleen het stuk na de laatste \r
  n = split(s, a, "\r")
  return a[n]
}

{
  line = $0
  sub(/\r$/, "", line)
  line = strip_cr_progress(line)

  # Soms is de laatste segment leeg door een pure \r update, dan niets printen
  if (line == "") next

  # Primary matches, zetten ook state voor multiline continuation
  if (line ~ /^s6-rc: info:/) {
    last_level = "INFO"
    last_color = "34"
    last_prefixed = 1
    emit(last_level, last_color, line)
    next
  }

  if (line ~ /^s6-rc: warning:/ || line ~ /^s6-rc: warn:/) {
    last_level = "WARN"
    last_color = "33"
    last_prefixed = 1
    emit(last_level, last_color, line)
    next
  }

  if (line ~ /^s6-rc: fatal:/ || line ~ /^s6-rc: error:/) {
    last_level = "FAIL"
    last_color = "31"
    last_prefixed = 1
    emit(last_level, last_color, line)
    next
  }

  if (line ~ /^s6-supervise:/ || line ~ /^s6-svscan:/ || line ~ /^s6-linux-init:/) {
    last_level = "INFO"
    last_color = "34"
    last_prefixed = 1
    emit(last_level, last_color, line)
    next
  }

  # Multiline continuation: alleen als de regel begint met spatie of tab
  if (last_prefixed == 1 && line ~ /^[ \t]/) {
    emit(last_level, last_color, line)
    next
  }

  # Alles anders ongewijzigd
  last_prefixed = 0
  print line
  fflush()
}
'
