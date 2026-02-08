# Deployment Instructions

## Environment Variables Required on Production

### Critical - Must be set before deployment:

1. **RAILS_MASTER_KEY**
   ```bash
   # Get from config/master.key
   cat config/master.key
   ```
   This key is required for:
   - Decrypting credentials.yml.enc
   - Active Record Encryption (encrypts :openrouter_api_key)
   - Session security

2. **DATABASE_URL**
   ```bash
   postgresql://user:password@host:5432/contentforce_production
   ```

3. **REDIS_URL**
   ```bash
   redis://host:6379/0
   ```

### Optional but recommended:

4. **OPENROUTER_API_KEY**
   - Fallback if admin doesn't set it in UI
   - Can be set via admin panel instead

5. **TELEGRAM_BOT_TOKEN**
   - For Telegram OAuth (if used)

6. **SENTRY_DSN**
   - For error tracking

## Deployment Steps on Coolify

1. **Set RAILS_MASTER_KEY environment variable:**
   - Go to Coolify → Your App → Environment Variables
   - Add: `RAILS_MASTER_KEY` = (value from config/master.key)
   - **IMPORTANT:** This must be set BEFORE first deployment

2. **Deploy the application:**
   ```bash
   git push origin main  # or trigger via Coolify
   ```

3. **Run migrations:**
   - Coolify should auto-run migrations
   - If not, manually: `rails db:migrate`

4. **Verify encryption works:**
   - Login as admin
   - Go to Admin → AI Settings
   - Try saving OpenRouter API key
   - Should save without 500 error

## Troubleshooting

### Error: "ActiveSupport::MessageEncryptor::InvalidMessage"
**Cause:** RAILS_MASTER_KEY not set or incorrect
**Fix:** Ensure RAILS_MASTER_KEY in Coolify matches config/master.key

### Error: 500 when saving API key
**Cause:** Missing migration or encryption not configured
**Fix:**
1. Run: `rails db:migrate`
2. Check RAILS_MASTER_KEY is set
3. Restart application

### Migration fails: column type mismatch
**Cause:** Old string column exists
**Fix:** Migration handles this automatically with `remove_column if column_exists?`

## Security Notes

- **Never commit config/master.key to git** (already in .gitignore)
- **Never share RAILS_MASTER_KEY publicly**
- API keys are encrypted at rest in database
- Only admin users can view/edit API keys
- Password fields never show actual key value

## Database Migrations

Recent migrations related to encryption:
- `20260115215352_add_api_key_to_ai_configuration.rb` - Initial (incorrect type)
- `20260116064017_fix_ai_configuration_encryption.rb` - Fixed (text type for encryption)

Both will run safely - the fix migration removes old column first.
