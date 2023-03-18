/^COPY /{
  start = $2 == "--link" || $2 ~ /^--chown=.*:.*/ ? 3 : 2
  for (i = start; i < NF; ++i ) {
    sources = sources == "" ? $i : sources " " $i
  }
}
END{print sources}
