# Dockerizing the Go VPN Account Management API

This guide explains how to containerize the Go VPN Account Management API using Docker and upload it to Docker Hub.

## Pre-built Docker Image

You can pull the pre-built Docker image from Docker Hub:

```bash
docker pull hidessh99/vpn-rest:v1
```


## Running the Container from Docker Hub

To run the container from Docker Hub:

```bash
docker run -d \
  --name vpn-api \
  -p 3000:3005 \
  -e PORT=3005 \
  -e API_KEY=your_api_key_here \
  -e AllowOrigins=* \
  hidessh99/vpn-rest:v1
```

You can also pull the latest version:

```bash
docker pull hidessh99/vpn-rest:latest
```

## Environment Variables

The container accepts the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Port for the API to listen on | 3005 |
| API_KEY | API key for authentication | (required) |
| AllowOrigins | only access | *(required)* |


## Docker Compose (Optional)

Create a `docker-compose.yml` file for easier deployment:

```yaml
version: '3.8'

services:
  vpn-api:
    image: hidessh99/vpn-rest:v1
    container_name: vpn-api
    ports:
      - "3005:3005"
    environment:
      - PORT=3005
      - API_KEY=your_api_key_here
      - AllowOrigins=*your_jwt_secret_here*
    restart: unless-stopped
```

You can also use the latest version:

```yaml
version: '3.8'

services:
  vpn-api:
    image: hidessh99/vpn-rest:latest
    container_name: vpn-api
    ports:
      - "3005:3005"
    environment:
      - PORT=3005
      - API_KEY=your_api_key_here
      - AllowOrigins=*your_jwt_secret_here*
    restart: unless-stopped
```

Run with:
```bash
docker-compose up -d
```

## Best Practices

1. **Security**: Always use a non-root user in production containers
2. **Multi-stage builds**: Use multi-stage builds to reduce image size
3. **Tagging**: Use semantic versioning for your Docker images
4. **Health checks**: Add health checks to your Dockerfile:
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
     CMD curl -f http://localhost:3000/health || exit 1
   ```

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure the binary is executable
2. **Port already in use**: Change the port mapping in the docker run command
3. **Missing dependencies**: Make sure all required shell commands are available 