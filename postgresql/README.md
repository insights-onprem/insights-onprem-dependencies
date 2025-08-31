# PostgreSQL 16 Component

This directory contains the PostgreSQL 16 container image configuration for Insights On-Premise projects.

## Origin

All PostgreSQL files in this directory are sourced from the official PostgreSQL Docker library:

- **Repository**: https://github.com/docker-library/postgres
- **Specific version**: PostgreSQL 16 on Debian Trixie
- **Source URLs**:
  - `Dockerfile`: https://github.com/docker-library/postgres/blob/master/16/trixie/Dockerfile
  - `docker-entrypoint.sh`: https://github.com/docker-library/postgres/blob/master/16/trixie/docker-entrypoint.sh
  - `docker-ensure-initdb.sh`: https://github.com/docker-library/postgres/blob/master/16/trixie/docker-ensure-initdb.sh

## Image Details

- **Base Image**: `debian:trixie-slim`
- **PostgreSQL Version**: 16.10-1.pgdg13+1
- **Target Architecture**: `linux/amd64`
- **Registry**: `quay.io/insights-onprem/postgresql:16`

## Usage

### Build the image

```bash
# From the main project directory
make build-postgresql

# Or using the standalone script
cd postgresql && ./build.sh
```

### Push to registry

```bash
# From the main project directory
make push-postgresql

# Or using the standalone script
cd postgresql && ./build.sh push
```

### Run the container

```bash
podman run --rm -p 5432:5432 -e POSTGRES_PASSWORD=password quay.io/insights-onprem/postgresql:16
```

## Configuration

The image includes:

- PostgreSQL 16 server
- Standard PostgreSQL tools (psql, pg_dump, etc.)
- Initialization scripts support via `/docker-entrypoint-initdb.d/`
- Proper user/group setup (postgres:postgres, uid/gid 999)
- UTF-8 locale configuration
- Security tools (gosu for privilege dropping)

## Environment Variables

Standard PostgreSQL environment variables are supported:

- `POSTGRES_PASSWORD` - Required, sets password for postgres user
- `POSTGRES_USER` - Optional, creates additional user (default: postgres)
- `POSTGRES_DB` - Optional, creates additional database
- `POSTGRES_INITDB_ARGS` - Optional, additional arguments to initdb
- `POSTGRES_INITDB_WALDIR` - Optional, custom WAL directory
- `POSTGRES_HOST_AUTH_METHOD` - Optional, host authentication method

See the official PostgreSQL Docker documentation for complete details.

## License

The PostgreSQL Docker files are maintained by the Docker Official Images project and are licensed under the same terms as the PostgreSQL project itself.