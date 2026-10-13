#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT_DIR}/manifest.csv"
RAW_DIR="${ROOT_DIR}/data/raw/2013-2014"
DOC_DIR="${ROOT_DIR}/docs/2013-2014"
LOCKFILE="${ROOT_DIR}/manifest.lock.csv"

mkdir -p "${RAW_DIR}" "${DOC_DIR}"

printf 'modality,kind,filename,source_url,bytes,sha256\n' > "${LOCKFILE}"

tail -n +2 "${MANIFEST}" | while IFS=, read -r modality kind filename source_url source_page join_key notes; do
  case "${kind}" in
    xpt) target_dir="${RAW_DIR}" ;;
    html) target_dir="${DOC_DIR}" ;;
    *) echo "Unsupported kind: ${kind}" >&2; exit 1 ;;
  esac
  target="${target_dir}/${filename}"

  if [[ ! -s "${target}" ]]; then
    echo "Downloading ${filename}"
    curl --fail --http1.1 --location --retry 3 --retry-all-errors --connect-timeout 30 --max-time 300 --silent --show-error "${source_url}" --output "${target}"
  else
    echo "Keeping existing ${filename}"
  fi

  bytes="$(wc -c < "${target}" | tr -d ' ')"
  sha256="$(sha256sum "${target}" | awk '{print $1}')"
  printf '%s,%s,%s,%s,%s,%s\n' "${modality}" "${kind}" "${filename}" "${source_url}" "${bytes}" "${sha256}" >> "${LOCKFILE}"
done

echo "Wrote ${LOCKFILE}"
