# Flutter production deployment

Deploy Flutter only after the backend action and `https://api.drokpharma.in/up` are healthy.

The **Deploy Flutter web to production** action is manual, requires `DEPLOY`, and uses the protected GitHub environment named `production`. Configure the same SSH secrets as the backend repository, plus `HOSTINGER_WEB_ROOT` for `drokpharma.in/public_html`.

The deployment copies only named Flutter web artifacts. It does not modify `admin/`, `api/`, `releases/`, or `.htaccess`. It keeps timestamped Flutter releases/backups for seven days; inspect older entries before manual removal.

The scheduled **Production Health Check** runs every 15 minutes. Turn on GitHub Actions failure notifications for this repository so an API or web outage is noticed quickly.
