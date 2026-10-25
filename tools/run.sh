#!/usr/bin/env bash
#
# Run jekyll serve and then launch the site.
#
# The site goes to port 4000 and its live reload to port 35729, or to the next free ports if
# something else holds them, such as an SSH tunnel to the preview of another machine, which
# also uses 4000 and 35729. The address the site is served at is printed before Jekyll starts.

prod=false
drafts=false
command="bundle exec jekyll s -l"
host="127.0.0.1"
port=4000
livereload_port=35729

help() {
  echo "Usage:"
  echo
  echo "   bash /path/to/run [options]"
  echo
  echo "Options:"
  echo "     -H, --host [HOST]    Host to bind to."
  echo "     -P, --port [PORT]    First port to try for the site (default 4000)."
  echo "     -p, --production     Run Jekyll in 'production' mode."
  echo "     -d, --drafts         Also show the drafts in _drafts/."
  echo "     -h, --help           Print this help information."
}

while (($#)); do
  opt="$1"
  case $opt in
  -H | --host)
    host="$2"
    shift 2
    ;;
  -P | --port)
    port="$2"
    shift 2
    ;;
  -p | --production)
    prod=true
    shift
    ;;
  -d | --drafts)
    drafts=true
    shift
    ;;
  -h | --help)
    help
    exit 0
    ;;
  *)
    echo -e "> Unknown option: '$opt'\n"
    help
    exit 1
    ;;
  esac
done

# Whether a server already listens on a port of the host, found by connecting to it; a
# server bound to every interface (0.0.0.0) is probed on loopback
in_use() {
  local probe="$host"
  [ "$probe" = "0.0.0.0" ] && probe="127.0.0.1"
  (exec 3<>"/dev/tcp/$probe/$1") 2>/dev/null
}

# The first free port from $1 on, trying at most 20
free_port() {
  local p="$1"
  while in_use "$p"; do
    p=$((p + 1))
    if [ "$p" -ge $(($1 + 20)) ]; then
      echo "> No free port from $1 to $p" >&2
      exit 1
    fi
  done
  echo "$p"
}

wanted="$port"
port="$(free_port "$port")" || exit 1
livereload_port="$(free_port "$livereload_port")" || exit 1
if [ "$port" != "$wanted" ]; then
  echo -e "\n> Port $wanted is in use, so the site goes to port $port"
fi
echo -e "\n> Serving at http://$host:$port (live reload on port $livereload_port)"

command="$command -H $host -P $port --livereload-port $livereload_port"

if $drafts; then
  command="$command --drafts"
fi

if $prod; then
  command="JEKYLL_ENV=production $command"
else
  command="$command --config _config.yml,_config_dev.yml"
fi

if [ -e /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
  command="$command --force_polling"
fi

echo -e "\n> $command\n"
eval "$command"
