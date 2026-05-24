# BillPro Flutter — Phase-wise Implementation Guide

> **Backend API:** `http://localhost:8587/api/v1`  
> **Auth:** JWT Bearer Token + `X-Company-Id` header on all protected routes  
> **Response format:** `{ success: bool, message: string, data: object }`

---

## Project Architecture (Clean Architecture + BLoC)

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + GoRouter
├── core/
│   ├── config/
│   │   ├── app_config.dart           # Environment config
│   │   ├── api_endpoints.dart        # All API endpoint constants
│   │   └── app_constants.dart        # GST rates, states, roles, enums
│   ├── network/
│   │   ├── dio_client.dart           # Dio instance, interceptors
│   │   ├── api_interceptor.dart      # Auth token injection, refresh
│   │   ├── api_response.dart         # Generic response wrapper
│   │   └── network_info.dart         # Connectivity check
│   ├── error/
│   │   ├── exceptions.dart           # Custom exceptions
│   │   └── failures.dart             # Failure classes
│   ├── theme/
│   │   ├── app_theme.dart            # Light/dark themes
│   │   ├── app_colors.dart           # Color palette
│   │   └── app_text_styles.dart      # Typography
│   ├── utils/
│   │   ├── validators.dart           # Form validators
│   │   ├── gst_calculator.dart       # Client-side GST calc
│   │   ├── formatters.dart           # Currency, date formatters
│   │   └── extensions.dart           # Dart extensions
│   └── widgets/                      # Shared reusable widgets
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── loading_overlay.dart
│       ├── empty_state.dart
│       └── error_widget.dart
│
├── features/
│   ├── auth/                         # Phase 1
│   │   ├── data/
│   │   │   ├── models/               # UserModel, TokenModel
│   │   │   ├── datasources/          # AuthRemoteDataSource
│   │   │   └── repositories/         # AuthRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/             # User, Token
│   │   │   ├── repositories/         # AuthRepository (abstract)
│   │   │   └── usecases/             # Login, Register, VerifyOTP...
│   │   └── presentation/
│   │       ├── bloc/                  # AuthBloc, AuthState, AuthEvent
│   │       └── pages/                # LoginPage, RegisterPage, OTPPage
│   │
│   ├── company/                      # Phase 2
│   ├── vendors/                      # Phase 3
│   ├── customers/                    # Phase 3
│   ├── items/                        # Phase 3
│   ├── purchase/                     # Phase 4
│   ├── sales/                        # Phase 5
│   ├── dashboard/                    # Phase 6
│   └── reports/                      # Phase 7
│
└── di/
    └── injection_container.dart      # Dependency injection setup
```

---

## ⚙️ Pre-Setup Checklist (DONE)

- [x] Flutter project created (`com.billpro.app`)
- [x] `pubspec.yaml` — all dependencies configured
- [x] `android/app/build.gradle.kts` — minSdk 24, signing, ProGuard, multidex
- [x] `AndroidManifest.xml` — INTERNET, CAMERA, storage permissions
- [x] `proguard-rules.pro` — R8 keep rules
- [x] `key.properties.example` — signing template
- [x] `.env` — API base URL config
- [x] `.gitignore` — secrets excluded
- [x] Asset directories created

---

# PHASE 1 — Core Setup + Authentication

**Goal:** App skeleton, networking, auth flow (register → OTP → login → token management)

## 1.1 Core Infrastructure

### Files to create:
| File | Purpose |
|------|---------|
| `lib/core/config/app_config.dart` | Load `.env`, expose `apiBaseUrl` |
| `lib/core/config/api_endpoints.dart` | All endpoint paths as constants |
| `lib/core/config/app_constants.dart` | Roles, GST rates, states, invoice types |
| `lib/core/network/dio_client.dart` | Dio with baseUrl, timeouts, logging |
| `lib/core/network/api_interceptor.dart` | Inject `Authorization` header, auto-refresh on 401 |
| `lib/core/network/api_response.dart` | `ApiResponse<T>` generic wrapper |
| `lib/core/error/exceptions.dart` | `ServerException`, `CacheException`, `NetworkException` |
| `lib/core/error/failures.dart` | `ServerFailure`, `NetworkFailure` |
| `lib/core/theme/app_theme.dart` | Material 3 light/dark theme |
| `lib/core/theme/app_colors.dart` | Brand colors |
| `lib/di/injection_container.dart` | Register Dio, repos, blocs |
| `lib/app.dart` | `MaterialApp.router` + GoRouter |
| `lib/main.dart` | Init env, Hive, DI, runApp |

### Key API Endpoints (Auth):
```
POST /auth/register        → { fullName, email, mobile, password, confirmPassword, acceptTerms }
POST /auth/verify-otp      → { identifier, otp, purpose }
POST /auth/login           → { email, password }
POST /auth/login/otp       → { mobile }
POST /auth/login/otp/verify→ { identifier, otp, purpose: "login" }
POST /auth/refresh         → { refreshToken }
POST /auth/forgot-password → { email }
POST /auth/reset-password  → { token, password, confirmPassword }
POST /auth/change-password → { currentPassword, newPassword, confirmPassword }
GET  /auth/me              → returns user profile
POST /auth/logout          → invalidates token
```

### Validation Rules:
- **Password:** min 8 chars, 1 uppercase, 1 number, 1 special char
- **Mobile:** 10 digits, starts with 6-9 (Indian)
- **OTP:** exactly 6 digits
- **fullName:** 3-100 chars

## 1.2 Auth Feature

### Data Models:
```dart
// UserModel
{ id, fullName, email, mobile, role, isEmailVerified, isMobileVerified,
  isActive, activeCompanyId, companies: [{companyId, role, isOwner}],
  onboardingCompleted, createdAt, updatedAt }

// TokenModel
{ accessToken, refreshToken, expiresIn }
```

### BLoC States:
```
AuthInitial → AuthLoading → AuthAuthenticated(user, token)
                           → AuthUnauthenticated
                           → AuthOTPSent(identifier)
                           → AuthError(message)
```

### Screens:
1. **Splash Screen** — Check stored token → auto-login or show auth
2. **Login Page** — Email + Password, "Login with OTP" option
3. **Register Page** — fullName, email, mobile, password, confirmPassword, acceptTerms
4. **OTP Verification Page** — 6-digit Pinput, resend timer
5. **Forgot Password Page** — Email input → sends reset link
6. **Reset Password Page** — New password + confirm

### Token Storage:
- Store `accessToken` and `refreshToken` in `flutter_secure_storage`
- On 401 response → call `/auth/refresh` → retry original request
- On refresh failure → redirect to login

---

# PHASE 2 — Company Setup & Onboarding

**Goal:** Company creation, GSTIN/IFSC validation, branch & bank account management

### Key API Endpoints:
```
POST /companies                       → Create company (huge payload — see below)
GET  /companies                       → Get active company
PUT  /companies                       → Update company
GET  /companies/validate/gstin/:gstin → Validate GSTIN (returns business details)
GET  /companies/validate/ifsc/:ifsc   → Validate IFSC (returns bank/branch info)
POST /companies/branches              → Add branch
PUT  /companies/branches/:branchId    → Update branch
POST /companies/bank-accounts         → Add bank account
```

### Company Create Payload:
```dart
{
  legalName: String,        // required, max 200
  tradeName: String?,       // max 100
  businessType: enum,       // Proprietorship|Partnership|Private Limited|LLP|...
  gstin: String?,           // 15-char GSTIN
  pan: String,              // required, 10-char PAN
  gstType: enum,            // regular|composition|unregistered
  isGSTRegistered: bool,
  businessCategory: enum,   // Retail|Wholesale|Service|Manufacturing|Other
  mobile: String,           // required
  email: String,            // required
  registeredAddress: {
    line1, line2?, city, state, stateCode, pinCode, country
  },
  fyStartMonth: int,        // 1-12, default 4 (April)
  invoiceSettings: {
    prefix, purchasePrefix, defaultPaymentTerms, defaultNotes, defaultTerms,
    showSignature, showLogo
  }
}
```

### Screens:
1. **Onboarding Stepper** — Multi-step form:
   - Step 1: Business Info (legalName, tradeName, businessType, PAN)
   - Step 2: GST Details (GSTIN, gstType, businessCategory)
   - Step 3: Address (line1, city, state, pinCode)
   - Step 4: Invoice Settings (prefix, payment terms, FY start)
2. **Company Profile Page** — View/edit company details
3. **Branches Page** — List, add, edit branches
4. **Bank Accounts Page** — List, add bank accounts with IFSC validation

### Indian States Dropdown Data:
```
Andhra Pradesh(37), Arunachal Pradesh(12), Assam(18), Bihar(10),
Chhattisgarh(22), Delhi(07), Goa(30), Gujarat(24), Haryana(06),
HP(02), Jharkhand(20), Karnataka(29), Kerala(32), MP(23),
Maharashtra(27), ... (36 total — see constants.js)
```

---

# PHASE 3 — Master Data (Vendors, Customers, Items)

**Goal:** CRUD for all master entities with search, filters, and pagination

## 3.1 Vendors (Suppliers)

### API Endpoints:
```
GET    /vendors      → List (supports ?search=, ?page=, ?limit=, ?isActive=)
POST   /vendors      → Create vendor
GET    /vendors/:id  → Get by ID
PUT    /vendors/:id  → Update
DELETE /vendors/:id  → Soft-deactivate
```

### Vendor Model Fields:
```
companyId, vendorCode, name, tradeName, gstin, pan,
gstType, mobile, email, contactPerson,
billingAddress: { line1, line2, city, state, stateCode, pinCode },
shippingAddress, bankDetails: { bankName, accountNumber, ifscCode, accountType },
paymentTerms, creditLimit, balanceDue, isActive, notes
```

### Screens:
- Vendor List (with search bar, filter chips)
- Vendor Detail / View
- Add/Edit Vendor Form

## 3.2 Customers (Buyers) — Same pattern as vendors

### API Endpoints:
```
GET    /customers      → List
POST   /customers      → Create
GET    /customers/:id  → Get by ID
PUT    /customers/:id  → Update
DELETE /customers/:id  → Soft-deactivate
```

## 3.3 Items (Products & Services)

### API Endpoints:
```
GET    /items      → List (supports ?itemType=product|service, ?search=, ?category=)
POST   /items      → Create
GET    /items/:id  → Get by ID
PUT    /items/:id  → Update
DELETE /items/:id  → Soft-deactivate
```

### Item Model Fields:
```
companyId, itemCode, name, description, itemType(product|service),
hsnCode, sacCode, category, brand, unit(pcs|kg|ltr|mtr|box),
sellingPrice, purchasePrice, mrp, priceInclGST,
gstRate(0|5|12|18|28), cessRate, isExempt, itcEligibility(full|partial|blocked),
trackInventory, openingStock, currentStock, reorderLevel,
valuationMethod(WAC|FIFO), avgCost, isActive, imageUrl
```

### Screens:
- Item List (tabs: Products / Services, search, category filter)
- Item Detail / View (with stock info)
- Add/Edit Item Form (with HSN/SAC code input, GST rate dropdown)

---

# PHASE 4 — Purchase Bills

**Goal:** Create, view, edit, void purchase bills with GST calculation and inventory impact

### API Endpoints:
```
GET    /purchase              → List bills (?status=, ?vendorId=, ?from=, ?to=, ?page=)
POST   /purchase              → Create purchase bill
GET    /purchase/:id          → Get bill by ID
PUT    /purchase/:id          → Update bill (draft/saved only)
DELETE /purchase/:id          → Void bill (with reason)
GET    /purchase/outstanding  → Vendor outstanding amounts
```

### Purchase Bill Create Payload:
```dart
{
  vendorId: String,           // required
  vendorBillNumber: String?,  // vendor's original bill #
  vendorBillDate: DateTime,   // required
  billDate: DateTime,         // required
  dueDate: DateTime?,
  supplyType: enum,           // intra_state|inter_state|export
  placeOfSupply: String?,
  isRCM: bool,
  paymentTerms: String?,
  narration: String?,

  lineItems: [                // min 1 item required
    {
      itemId: String?,
      itemName: String,       // required
      hsnCode: String?,
      quantity: double,       // required, > 0
      unit: String,
      unitPrice: double,      // required, > 0
      discountPercent: double?,
      discountFlat: double?,
      gstRate: int,           // 0|5|12|18|28
      cessRate: double?,
      itcEligibility: enum,   // full|partial|blocked
    }
  ]
}
```

### GST Calculation Logic (client-side preview):
```
For each line item:
  taxableValue = (quantity × unitPrice) - discountAmount
  if supplyType == intra_state:
    cgst = taxableValue × (gstRate / 2) / 100
    sgst = taxableValue × (gstRate / 2) / 100
    igst = 0
  else: // inter_state or export
    igst = taxableValue × gstRate / 100
    cgst = 0; sgst = 0
  cess = taxableValue × cessRate / 100
  lineTotal = taxableValue + cgst + sgst + igst + cess

grandTotal = sum(lineTotal) + roundOff
```

### Bill Statuses: `draft → saved → paid / partially_paid / overdue / void`

### Screens:
1. **Purchase Bill List** — Filterable by status, vendor, date range
2. **Create/Edit Purchase Bill** — Dynamic line item form with live GST preview
3. **Purchase Bill Detail** — Full view with line items, taxes, status badge
4. **Vendor Outstanding Report** — Grouped by vendor, total due amounts

---

# PHASE 5 — Sales Invoices

**Goal:** Create tax invoices & proformas, convert proforma→invoice, aging report

### API Endpoints:
```
GET    /sales              → List invoices (?invoiceType=, ?customerId=, ?status=, ?from=, ?to=)
POST   /sales              → Create invoice
GET    /sales/:id          → Get by ID
DELETE /sales/:id          → Void invoice (with reason)
POST   /sales/:id/convert  → Convert proforma → tax invoice
GET    /sales/aging         → Receivables aging report
```

### Sales Invoice Create Payload:
```dart
{
  customerId: String,         // required
  invoiceType: enum,          // tax_invoice|proforma|bill_of_supply|export_invoice|delivery_challan
  invoiceDate: DateTime,      // required
  dueDate: DateTime?,
  supplyType: enum,           // intra_state|inter_state|export
  placeOfSupply: String?,
  isRCM: bool,
  customerPONumber: String?,
  paymentTerms: String?,
  notes: String?,
  termsAndConditions: String?,
  validUntil: DateTime?,      // for proforma only

  // Export fields (if isExport)
  isExport: bool,
  exportType: enum?,          // with_tax|without_tax|LUT|bond
  shippingBillNo: String?,
  portCode: String?,

  // E-Way Bill (if applicable)
  vehicleNumber: String?,
  transporterName: String?,
  transportMode: enum?,       // road|rail|air|ship

  lineItems: [ /* same structure as purchase */ ]
}
```

### Invoice Types:
| Type | Use Case |
|------|----------|
| `tax_invoice` | Standard GST invoice |
| `proforma` | Quotation (convertible to tax invoice) |
| `bill_of_supply` | For composition dealers (no tax breakup) |
| `export_invoice` | For exports (zero-rated / LUT) |
| `delivery_challan` | Goods delivery without sale |
| `credit_note` | Return / discount adjustment |
| `debit_note` | Price increase adjustment |

### Key Features:
- **Proforma → Tax Invoice** conversion (POST `/sales/:id/convert`)
- **Aging Report** — Groups receivables by 0-30, 31-60, 61-90, 90+ days
- **E-Invoice fields** — IRN, QR code, ACK number (future IRP integration)

### Screens:
1. **Invoice List** — Tabs: All / Tax Invoice / Proforma / Draft, search & filters
2. **Create/Edit Invoice** — Customer picker, line items, live total, discount
3. **Invoice Detail** — Full view, status, payment info, action buttons (void/convert/share)
4. **Invoice PDF Preview** — Generate PDF using `pdf` package
5. **Aging Report** — Table with customer-wise outstanding bucketed by age

---

# PHASE 6 — Dashboard & Analytics

**Goal:** Business KPIs, charts, and visual analytics

### API Endpoints:
```
GET /dashboard/kpis              → 12 KPI cards
GET /dashboard/sales-trend       → Monthly sales (line chart data)
GET /dashboard/sales-vs-purchase → Monthly comparison (bar chart data)
GET /dashboard/top-customers     → Top 10 customers by revenue
GET /dashboard/invoice-status    → Status distribution (donut chart data)
GET /dashboard/gst-summary       → Monthly GST liability
```

### KPI Cards (12):
```
totalSales, totalPurchases, netProfit, totalReceivables,
totalPayables, cashInHand, invoiceCount, overdueCount,
topSellingItem, avgInvoiceValue, gstLiability, currentMonthSales
```

### Chart Library: `fl_chart`

### Screens:
1. **Dashboard Home** — KPI cards grid + charts:
   - Sales Trend (Line Chart)
   - Sales vs Purchase (Bar Chart)
   - Invoice Status (Donut/Pie Chart)
   - Top Customers (Horizontal Bar)
   - GST Summary (Monthly table)
2. **Pull-to-refresh** on all dashboard data

---

# PHASE 7 — Reports & Export

**Goal:** Generate downloadable Excel reports and GSTR-1 JSON for GST filing

### API Endpoints:
```
GET /reports/sales-register/excel     → Downloads .xlsx file
GET /reports/purchase-register/excel  → Downloads .xlsx file
GET /reports/gstr1/json               → Downloads GSTR-1 JSON
```

### Implementation:
- Use Dio with `responseType: ResponseType.bytes` for file downloads
- Save to device using `path_provider` → `getApplicationDocumentsDirectory()`
- Open using `open_file` package
- Share using `share_plus`

### Screens:
1. **Reports Page** — List of available reports with date range picker
2. **Report Viewer** — After download, option to Open / Share

---

# PHASE 8 — Polish, Deploy & Publish

## 8.1 UI Polish
- Splash screen with native splash (`flutter_native_splash`)
- App icon generation (`flutter_launcher_icons`)
- Empty states with illustrations
- Skeleton/shimmer loading
- Error retry screens
- Pull-to-refresh everywhere
- Dark mode support

## 8.2 Android Release Build

### Step 1: Generate Keystore
```bash
keytool -genkey -v -keystore billpro-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias billpro
```

### Step 2: Create `android/key.properties`
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=billpro
storeFile=../app/billpro-release.jks
```

### Step 3: Build APK / App Bundle
```bash
# APK (for direct distribution)
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### Step 4: Output locations
```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

## 8.3 Play Store Deployment Checklist
- [ ] App icon (512×512 PNG)
- [ ] Feature graphic (1024×500)
- [ ] Screenshots (min 2, phone + tablet)
- [ ] Privacy policy URL
- [ ] App description (short + full)
- [ ] Content rating questionnaire
- [ ] Data safety section
- [ ] Financial features declaration (this is a billing app, declare accordingly)
- [ ] Target API level ≥ 34

## 8.4 iOS Release (if needed)
- Configure `ios/Runner/Info.plist` with camera/photo permissions descriptions
- Set up Apple Developer account, provisioning profile, certificates
- `flutter build ipa --release`

---

# Quick Reference — All API Endpoints

| # | Method | Endpoint | Module | Auth |
|---|--------|----------|--------|------|
| 1 | GET | `/health` | General | No |
| 2 | POST | `/auth/register` | Auth | No |
| 3 | POST | `/auth/verify-otp` | Auth | No |
| 4 | POST | `/auth/login` | Auth | No |
| 5 | POST | `/auth/login/otp` | Auth | No |
| 6 | POST | `/auth/login/otp/verify` | Auth | No |
| 7 | POST | `/auth/refresh` | Auth | No |
| 8 | POST | `/auth/forgot-password` | Auth | No |
| 9 | POST | `/auth/reset-password` | Auth | No |
| 10 | GET | `/auth/me` | Auth | ✅ |
| 11 | POST | `/auth/logout` | Auth | ✅ |
| 12 | POST | `/auth/change-password` | Auth | ✅ |
| 13 | POST | `/companies` | Company | ✅ |
| 14 | GET | `/companies` | Company | ✅ |
| 15 | PUT | `/companies` | Company | ✅ |
| 16 | GET | `/companies/validate/gstin/:gstin` | Company | ✅ |
| 17 | GET | `/companies/validate/ifsc/:ifsc` | Company | ✅ |
| 18 | POST | `/companies/branches` | Company | ✅ |
| 19 | PUT | `/companies/branches/:branchId` | Company | ✅ |
| 20 | POST | `/companies/bank-accounts` | Company | ✅ |
| 21 | GET | `/vendors` | Vendors | ✅ |
| 22 | POST | `/vendors` | Vendors | ✅ |
| 23 | GET | `/vendors/:id` | Vendors | ✅ |
| 24 | PUT | `/vendors/:id` | Vendors | ✅ |
| 25 | DELETE | `/vendors/:id` | Vendors | ✅ |
| 26-30 | CRUD | `/customers` | Customers | ✅ |
| 31-35 | CRUD | `/items` | Items | ✅ |
| 36 | GET | `/purchase` | Purchase | ✅ |
| 37 | POST | `/purchase` | Purchase | ✅ |
| 38 | GET | `/purchase/outstanding` | Purchase | ✅ |
| 39 | GET | `/purchase/:id` | Purchase | ✅ |
| 40 | PUT | `/purchase/:id` | Purchase | ✅ |
| 41 | DELETE | `/purchase/:id` | Purchase | ✅ |
| 42 | GET | `/sales` | Sales | ✅ |
| 43 | POST | `/sales` | Sales | ✅ |
| 44 | GET | `/sales/aging` | Sales | ✅ |
| 45 | GET | `/sales/:id` | Sales | ✅ |
| 46 | DELETE | `/sales/:id` | Sales | ✅ |
| 47 | POST | `/sales/:id/convert` | Sales | ✅ |
| 48 | GET | `/dashboard/kpis` | Dashboard | ✅ |
| 49 | GET | `/dashboard/sales-trend` | Dashboard | ✅ |
| 50 | GET | `/dashboard/sales-vs-purchase` | Dashboard | ✅ |
| 51 | GET | `/dashboard/top-customers` | Dashboard | ✅ |
| 52 | GET | `/dashboard/invoice-status` | Dashboard | ✅ |
| 53 | GET | `/dashboard/gst-summary` | Dashboard | ✅ |
| 54 | GET | `/reports/sales-register/excel` | Reports | ✅ |
| 55 | GET | `/reports/purchase-register/excel` | Reports | ✅ |
| 56 | GET | `/reports/gstr1/json` | Reports | ✅ |

---

# Role-Based Access Control (RBAC)

| Role | Permissions |
|------|------------|
| `super_admin` | ALL |
| `company_admin` | ALL |
| `accountant` | Purchase, Sales, Reports, Dashboard, Items, Vendors/Customers |
| `sales_executive` | Sales, Export, Vendors/Customers |
| `purchase_manager` | Purchase, Export, Items, Vendors/Customers |
| `viewer` | Reports, Export, Dashboard (read-only) |

**Implementation:** Check `user.role` after login and conditionally show/hide UI elements and navigation items.

---

# Headers Required for Protected Routes

```dart
headers: {
  'Authorization': 'Bearer $accessToken',
  'X-Company-Id': '$activeCompanyId',
  'Content-Type': 'application/json',
}
```

---

# Phase Summary Timeline

| Phase | What | Screens | Estimated |
|-------|------|---------|-----------|
| **1** | Core + Auth | Splash, Login, Register, OTP, Forgot/Reset Password | 3-4 days |
| **2** | Company Setup | Onboarding Stepper, Company Profile, Branches, Bank Accounts | 2-3 days |
| **3** | Masters | Vendor/Customer/Item CRUD (List, Detail, Form) × 3 | 3-4 days |
| **4** | Purchase | Bill List, Create/Edit, Detail, Outstanding Report | 3-4 days |
| **5** | Sales | Invoice List, Create/Edit, Detail, PDF, Aging, Convert | 4-5 days |
| **6** | Dashboard | KPI Cards, 5 Charts, Pull-to-refresh | 2-3 days |
| **7** | Reports | Report List, Download, Open/Share | 1-2 days |
| **8** | Polish & Deploy | Splash, Icons, Dark Mode, Build, Play Store | 2-3 days |
| | **TOTAL** | | **~20-28 days** |
