# 🚀 LawVriksh Quick Deployment

## One-Command Deployment

```bash
chmod +x deploy-one-command.sh && ./deploy-one-command.sh
```

This single command will:
- ✅ Install Docker, Nginx, SSL tools
- ✅ Configure firewall and security
- ✅ Deploy MySQL, Redis, Backend, Frontend
- ✅ Setup admin user: `sahilsaurav2507@gmail.com` / `Sahil@123`
- ✅ Configure Nginx for `lawvriksh.com` and `lawvriksh.com/api`
- ✅ Setup SSL certificate (with confirmation)

## Manual Step-by-Step

If you prefer manual control:

```bash
# 1. System setup
chmod +x deploy-full-stack.sh && ./deploy-full-stack.sh

# 2. Deploy services
chmod +x deploy-services.sh && ./deploy-services.sh

# 3. Setup SSL
sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com
```

## After Deployment

### Test Your Application
- **Frontend**: https://lawvriksh.com
- **Backend API**: https://lawvriksh.com/api/docs
- **Admin Login**: sahilsaurav2507@gmail.com / Sahil@123

### Manage Services
```bash
cd /opt/lawvriksh

# View status
docker-compose ps

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Restart services
docker-compose restart backend
```

## Prerequisites

- Ubuntu 24.04 VPS (8GB RAM recommended)
- Domain `lawvriksh.com` pointing to your server
- Sudo access
- Internet connection

## What Gets Deployed

### Services
- **MySQL 8.0**: Database (port 3307, localhost only)
- **Redis 7**: Cache and sessions
- **FastAPI Backend**: API server (port 8000, localhost only)
- **React Frontend**: Web application (port 3000, localhost only)
- **Nginx**: Reverse proxy with SSL

### Configuration
- **Frontend**: `https://lawvriksh.com` → React app
- **Backend API**: `https://lawvriksh.com/api` → FastAPI
- **Admin User**: Auto-created from environment variables
- **SSL**: Let's Encrypt certificate
- **Security**: Firewall, security headers, HTTPS redirect

## Troubleshooting

### Services not starting?
```bash
cd /opt/lawvriksh
docker-compose logs -f
```

### Admin login not working?
```bash
cd /opt/lawvriksh
docker-compose exec backend python verify_admin.py
```

### SSL issues?
```bash
sudo certbot certificates
sudo nginx -t
```

## File Structure After Deployment

```
/opt/lawvriksh/
├── docker-compose.yml          # Services configuration
├── .env                        # Environment variables
├── Dockerfile.production       # Backend image
├── Dockerfile.frontend         # Frontend image
├── lawdata.sql                 # Database schema
├── setup_admin.py              # Admin setup script
├── verify_admin.py             # Admin verification
├── logs/                       # Application logs
├── cache/                      # Application cache
└── uploads/                    # File uploads
```

---

**Ready to deploy?** Run: `chmod +x deploy-one-command.sh && ./deploy-one-command.sh`
