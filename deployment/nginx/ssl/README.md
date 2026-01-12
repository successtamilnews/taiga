Place your TLS certificates here:

- /deployment/nginx/ssl/taiga.asia/fullchain.pem
- /deployment/nginx/ssl/taiga.asia/privkey.pem

These paths are mounted into the Nginx container at:

- /etc/nginx/ssl/taiga.asia/fullchain.pem
- /etc/nginx/ssl/taiga.asia/privkey.pem

After adding certs, restart Nginx via docker compose:

```
docker compose -f deployment/docker-compose.prod.yml restart nginx
```
