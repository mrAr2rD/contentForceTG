# Coolify Deployment Guide for ContentForce

## Prerequisites
- Coolify instance running on your server
- GitHub repository with your code
- Domain name (optional, but recommended)

## Step 1: Prepare Your Repository

### 1.1 Create Production Environment File
Create `.env.production` (don't commit this):
```bash
# Database
DATABASE_URL=postgresql://postgres:tyVAGamoOg3sl3hMABKBybW9oZ2uIBxJvKIhRXMuCX5tod772H1z1mqPyAsrj5rt@qcwkg0w4ssscks44o48c0k8w:5432/postgres

# Redis
REDIS_URL=redis://redis:6379/0

# Telegram Bot
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# OpenRouter API
OPENROUTER_API_KEY=your_openrouter_api_key
OPENROUTER_API_URL=https://openrouter.ai/api/v1

# AWS S3 (optional)
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
AWS_BUCKET=contentforce-storage

# Rails
RAILS_ENV=production
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Secret Key Base (generate with: rails secret)
SECRET_KEY_BASE=GENERATE_THIS_WITH_RAILS_SECRET
```

### 1.2 Generate SECRET_KEY_BASE
```bash
cd contentforce
bundle exec rails secret
# Copy the output to SECRET_KEY_BASE in your env
```

### 1.3 Update .gitignore
Make sure these are in `.gitignore`:
```
.env.production
config/master.key
config/credentials/*.key
```

## Step 2: Coolify Setup

### 2.1 Create New Project in Coolify
1. Login to Coolify dashboard
2. Click "New Resource" → "Application"
3. Select "Public Repository"
4. Enter repository URL: `https://github.com/YOUR_USERNAME/CONTtg`
5. Branch: `main` (or your production branch)

### 2.2 Configure Build Settings
**Build Pack:** Docker

**Port Mappings:**
- Container Port: `80`
- Public Port: `80` (or `443` for SSL)

### 2.3 Add Required Services

#### PostgreSQL Database
1. In Coolify, go to your app → "Storages" → "Add Database"
2. Select "PostgreSQL 16"
3. Generate strong password
4. Note the connection details

#### Redis Cache
1. Go to "Storages" → "Add Database"
2. Select "Redis 7"
3. Note the connection details

### 2.4 Environment Variables

**CRITICAL: Set all secret variables as "Runtime Only" in Coolify!**

In Coolify app settings → "Environment Variables":

**Mark these as RUNTIME ONLY (not build-time):**
- `DATABASE_URL`
- `REDIS_URL`
- `RAILS_MASTER_KEY`
- `SECRET_KEY_BASE`
- `TELEGRAM_BOT_TOKEN`
- `OPENROUTER_API_KEY`

**Can be build-time:**
- `RAILS_ENV=production`
- `RAILS_LOG_TO_STDOUT=true`
- `RAILS_SERVE_STATIC_FILES=true`

```env
# CRITICAL: Fix the DATABASE_URL format!
# Correct format: postgresql://username:password@host:port/database
DATABASE_URL=postgresql://postgres:tyVAGamoOg3sl3hMABKBybW9oZ2uIBxJvKIhRXMuCX5tod772H1z1mqPyAsrj5rt@qcwkg0w4ssscks44o48c0k8w:5432/postgres

REDIS_URL=redis://redis-service-name:6379/0
RAILS_ENV=production
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
RAILS_MASTER_KEY=995a2f3b6ea26667605e7b925ed0b195
SECRET_KEY_BASE=7e8e8025083082bbeedda51f96cbda612bb96183538db25a276dca485c2f0ba7df59cbebfbbca7fbb4fefc8d882c20cdc0fb1d1044de9e1fe00af6191a45a121
TELEGRAM_BOT_TOKEN=7608089982:AAGx-Z4oG6qVIbqlva2Wwbt39nqNSZAi4YU
OPENROUTER_API_KEY=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
OPENROUTER_API_URL=https://openrouter.ai/api/v1
OPENROUTER_SITE_URL=https://your-domain.com
OPENROUTER_SITE_NAME=ContentForce
TELEGRAM_ORIGIN_URL=https://your-domain.com
```

### 2.5 Get RAILS_MASTER_KEY
```bash
# On your local machine
cat config/master.key
# Copy this value to RAILS_MASTER_KEY in Coolify
```

## Step 3: Configure Domain (Optional)

### 3.1 Add Domain in Coolify
1. Go to your app → "Domains"
2. Add your domain: `contentforce.yourdomain.com`
3. Coolify will auto-generate SSL with Let's Encrypt

### 3.2 DNS Settings
Point your domain to Coolify server:
```
Type: A
Name: contentforce (or @)
Value: YOUR_COOLIFY_SERVER_IP
TTL: 300
```

## Step 4: Deploy

### 4.1 Initial Deployment
1. Click "Deploy" in Coolify dashboard
2. Wait for build to complete (5-10 minutes first time)
3. Check logs for any errors

### 4.2 Run Database Migrations
After first deploy, run migrations:
1. Go to app → "Terminal"
2. Execute:
```bash
rails db:create
rails db:migrate
rails db:seed  # if you have seed data
```

Or via Coolify execute command:
```bash
./bin/rails db:prepare
```

## Step 5: Health Checks

### 5.1 Configure Health Check
In Coolify app settings:
- Health Check Path: `/up`
- Health Check Port: `80`
- Health Check Interval: `30s`

### 5.2 Verify Deployment
Visit your app:
- Via domain: `https://contentforce.yourdomain.com`
- Via IP: `http://YOUR_SERVER_IP`

## Step 6: Continuous Deployment

### 6.1 Auto-Deploy on Git Push
1. In Coolify → "Git" → "Automatic Deployment"
2. Enable "Deploy on Push"
3. Select branch: `main`
4. Coolify will auto-deploy on every push

### 6.2 Webhook (Alternative)
If auto-deploy doesn't work:
1. Copy webhook URL from Coolify
2. Add to GitHub: Settings → Webhooks → Add webhook
3. Paste webhook URL
4. Select "Just the push event"

## Step 7: Monitoring & Maintenance

### 7.1 View Logs
```bash
# In Coolify Terminal
tail -f log/production.log
```

### 7.2 Restart Application
- In Coolify dashboard: "Restart" button
- Or via terminal: `touch tmp/restart.txt`

### 7.3 Scale Workers
If you need background jobs:
1. Coolify → "Additional Services"
2. Add new service with command: `./bin/jobs`

## Common Issues & Solutions

### Issue 1: Assets Not Loading
**Solution:** Make sure these env vars are set:
```env
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### Issue 2: Database Connection Error
**Solution:** Check DATABASE_URL format:
```env
DATABASE_URL=postgresql://postgres:password@postgres:5432/dbname
```
Note: Use service name `postgres` not `localhost`

### Issue 3: Migration Errors
**Solution:** Run manually:
```bash
./bin/rails db:prepare RAILS_ENV=production
```

### Issue 4: CSS Not Applying
**Solution:** Rebuild assets:
```bash
./bin/rails assets:precompile RAILS_ENV=production
```

### Issue 5: Port Already in Use
**Solution:** In Coolify, change public port or use different container port mapping.

## Rollback Strategy

### Quick Rollback
1. In Coolify → "Deployments"
2. Find previous successful deployment
3. Click "Redeploy"

### Manual Rollback
```bash
git revert HEAD
git push origin main
# Coolify will auto-deploy the reverted version
```

## Performance Optimization

### 1. Enable Caching
```env
RAILS_CACHE_STORE=redis_cache_store
```

### 2. Add CDN (Optional)
- Cloudflare for static assets
- Configure in Coolify proxy settings

### 3. Database Connection Pool
```env
DB_POOL=10
RAILS_MAX_THREADS=10
```

## Security Checklist

- [ ] SECRET_KEY_BASE generated and set
- [ ] RAILS_MASTER_KEY properly configured
- [ ] Database password is strong
- [ ] SSL/HTTPS enabled via Coolify
- [ ] Environment variables not in git
- [ ] Firewall configured (ports 80, 443 only)
- [ ] Regular backups enabled in Coolify

## Backup Strategy

### Database Backups
1. Coolify → PostgreSQL service → "Backups"
2. Enable automatic backups
3. Schedule: Daily at 2 AM
4. Retention: 7 days

### Manual Backup
```bash
pg_dump -h postgres -U postgres contentforce_production > backup.sql
```

## Support

If deployment fails:
1. Check Coolify build logs
2. Check application logs
3. Verify all environment variables
4. Test Dockerfile locally:
```bash
docker build -t contentforce .
docker run -p 3000:80 contentforce
```

---

**Deployment Checklist:**
- [ ] Repository pushed to GitHub
- [ ] SECRET_KEY_BASE generated
- [ ] RAILS_MASTER_KEY obtained
- [ ] Database created in Coolify
- [ ] Redis created in Coolify
- [ ] All env vars configured
- [ ] Domain DNS configured (if using)
- [ ] Initial deployment successful
- [ ] Database migrations run
- [ ] Health check passing
- [ ] Application accessible
- [ ] Monitoring enabled
- [ ] Backups configured

**Next Steps After Deployment:**
1. Set up monitoring (Sentry/Rollbar)
2. Configure email delivery (SendGrid/AWS SES)
3. Set up log aggregation
4. Add performance monitoring
5. Configure CI/CD if needed
