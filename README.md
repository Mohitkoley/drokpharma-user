# Drok Pharma — Flutter Customer App (`drokpharma-user`)

Cross-platform customer mobile and web application for Drok Healthcare, built with **Flutter 3.41+** and **GetX**.

For the complete project map and architecture, please see the [Root README.md](../README.md).

---

## Key Files & Directories

- **API Base URL & Endpoints**: [`lib/util/app_constants.dart`](lib/util/app_constants.dart)
  - Configure `baseUrl` for localhost, emulator, or production.
- **HTTP Client & Real-time Request Logging**: [`lib/api/api_client.dart`](lib/api/api_client.dart)
  - Intercepts and logs all outgoing requests, headers, bodies, responses, duration, and errors.
- **Features & Screens**: [`lib/features/`](lib/features/)
  - `auth/` — Login, registration, OTP verification.
  - `item/` — Medicines, products, lab tests.
  - `store/` — Pharmacies, clinics, diagnostic centers.
  - `cart/` & `checkout/` — Cart management & order placement.
  - `order/` — Order history & live tracking.
  - `location/` & `address/` — Zone detection, address management.
- **Routes & Navigation**: [`lib/helper/route_helper.dart`](lib/helper/route_helper.dart)
- **Theme & Styles**: [`lib/theme/`](lib/theme/) and [`lib/util/styles.dart`](lib/util/styles.dart)

---

## Running Locally

```bash
flutter run
```
Make sure the backend is running on `http://127.0.0.1:8000`.
