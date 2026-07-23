# Healthcheck

A healthcheck is a simple HTTP GET request to the `/healthcheck` endpoint. It returns a `200 OK` response if the server is healthy.

## Example

```shell
curl http://localhost:6157/healthcheck
```

```json
{"database":"ok","opengist":"ok","time":"2024-01-04T05:18:33+01:00"}
```

## Root path (`HEAD /`)

A `HEAD` request to the root path `/` also returns `200 OK` (with no body),
even when the client is not authenticated. This is handy for uptime monitors
and load balancers that probe the application with `curl -I`:

```shell
curl -I http://localhost:6157/
```

Without this, those monitors would see a `404` (since `GET /` requires
authentication) and could incorrectly report the service as down.
