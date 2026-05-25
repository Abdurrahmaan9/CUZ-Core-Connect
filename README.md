# CUZ-Core-Connect

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Elixir](https://img.shields.io/badge/elixir-1.19-blueviolet)
![Phoenix](https://img.shields.io/badge/phoenix-1.8.3-orange)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue)

A **Phoenix-based student course registration and approval workflow management system** for educational institutions. CUZ-Core-Connect streamlines the process of managing student registrations across multiple approval stages, enabling seamless collaboration between students, academics, finance, HOD (Head of Department), and retention teams.

## 🎯 Overview

CUZ-Core-Connect solves the complexity of student course registration by providing:

- **Multi-stage approval workflows** — Student registrations progress through payment, academics, HOD, finance, and retention approvals
- **Role-based access control** — Different dashboards and capabilities for students, academics, finance, HOD, and administrators
- **Real-time status tracking** — Students can track their registration progress at any time
- **Integrated payment tracking** — Link payment receipts to registrations for seamless finance workflows
- **Programme & course management** — Administrators can manage academic programmes and courses
- **Email notifications** — Automated communications at each approval stage

---

## ⚡ Quick Start

### Prerequisites

- **Elixir 1.19** or later
- **Erlang/OTP 27** or later
- **PostgreSQL 15** or later
- **Node.js 18** or later (for asset building)
- **Git**

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/Abdurrahmaan9/CUZ-Core-Connect
   cd CUZ-Core-Connect
   ```

2. **Install dependencies**
   ```bash
   mix setup
   ```
   This command runs:
   - `mix deps.get` — Fetch Elixir dependencies
   - `mix ecto.create` — Create the PostgreSQL database
   - `mix ecto.migrate` — Run all database migrations
   - `mix run priv/repo/seeds.exs` — Seed initial data (optional)
   - `mix assets.setup` — Install Tailwind and esbuild
   - `mix assets.build` — Compile CSS and JavaScript

3. **Start the development server**
   ```bash
   mix phx.server
   ```

4. **Open your browser**
   - Navigate to [`http://localhost:4000`](http://localhost:4000)
   - You're ready to go!

### Verify Installation

- The landing page should load at `http://localhost:4000`
- You can register a new student account or log in with test credentials (if seeded)
- Try the admin panel at `http://localhost:4000/admin` (requires admin login)

---

## 🚀 Features Overview

### For Students
- **Self-registration** — Create an account and register for courses
- **Programme selection** — Browse and select academic programmes
- **Course enrollment** — Choose courses within selected programmes
- **Payment tracking** — Upload and track payment receipts
- **Status monitoring** — Real-time visibility into approval progress
- **Registration confirmation** — Receive confirmation once all approvals complete

### For Academics
- **Registration review** — View all pending student registrations
- **Academic approval** — Approve/reject registrations from an academic perspective
- **Dashboard** — Dedicated academics dashboard at `/academics/dashboard`
- **Bulk management** — Process multiple registrations efficiently

### For Finance
- **Payment verification** — Review payment receipts submitted by students
- **Payment approval** — Approve or flag payment issues
- **Finance dashboard** — Dedicated dashboard at `/finance/dashboard`
- **Receipt tracking** — Track all payment documentation

### For HOD (Head of Department)
- **Department oversight** — Review registrations in your department
- **HOD approval** — Provide department-level approval on registrations
- **Departmental dashboards** — View department-specific metrics

### For Retention
- **Retention review** — Conduct final review before registration confirmation
- **Retention approval** — Approve or request additional information

### For Administrators
- **User management** — Create, edit, and manage user accounts and roles
- **Programme management** — Create and manage academic programmes
- **Course management** — Define courses and assign them to programmes
- **System configuration** — Configure system-wide settings
- **Admin dashboard** — Comprehensive admin panel at `/admin`

---

## 📋 Detailed Role-Based Workflows

### Student Registration Workflow

**Example Journey: A first-year student registering for courses**

1. **Create Account** (Public)
   - Visit [`http://localhost:4000`](http://localhost:4000)
   - Click "Register as Student"
   - Fill in email, name, password
   - Confirm email via verification link

2. **Begin Registration** (Student Dashboard)
   - Log in to your account
   - Navigate to "New Registration"
   - Select academic programme (e.g., "Bachelor of Science in Computer Science")

3. **Select Courses**
   - Browse courses available in your programme
   - Select required courses and electives
   - Review total course load

4. **Payment**
   - Proceed to payment section
   - Upload payment receipt image
   - Submit receipt for approval

5. **Wait for Approvals**
   - Status moves through: "Payment Review" → "Academic Review" → "HOD Review" → "Finance Review" → "Retention Review" → "Approved"
   - Receive email notifications at each stage
   - Can track status on dashboard at any time

6. **Registration Complete**
   - Receive confirmation email
   - Access finalized registration details
   - Download registration certificate (if available)

**Key Pages for Students:**
- Landing page: `http://localhost:4000/`
- Student dashboard: `http://localhost:4000/` (when logged in)
- Registration tracking: `http://localhost:4000/track` (by tracking number)

---

### Academics Approval Workflow

**Example Journey: An academics officer reviewing student registrations**

1. **Log In** (Academics Role)
   - Use account with "academics" role
   - Access academics dashboard: `http://localhost:4000/academics/dashboard`

2. **View Pending Registrations**
   - Dashboard displays all registrations awaiting academic approval
   - See student name, selected programme, courses, and submission date

3. **Review Course Selections**
   - Click on a registration to view full details
   - Review course selections for programme requirements compliance
   - Check student eligibility (prerequisites, etc.)

4. **Approve or Request Changes**
   - Click "Approve" if course selection is appropriate
   - Or click "Request Revision" with feedback if changes needed
   - Add optional notes for the student

5. **Status Update**
   - Registration moves to "Academic Approved" status
   - Next approval stage begins (Finance → HOD → Retention)
   - Student receives notification email

**Key Pages for Academics:**
- Academics dashboard: `http://localhost:4000/academics/dashboard`
- Registration detail view (inline or modal)

---

### Finance Approval Workflow

**Example Journey: A finance officer processing payment receipts**

1. **Log In** (Finance Role)
   - Use account with "finance" role
   - Access finance dashboard: `http://localhost:4000/finance/dashboard`

2. **View Pending Payments**
   - Dashboard shows registrations awaiting payment verification
   - See student name, amount due, payment receipt, and submission date

3. **Verify Payment Receipt**
   - View uploaded receipt image or document
   - Confirm payment amount matches tuition costs
   - Check transaction ID or bank reference if visible

4. **Approve or Reject Payment**
   - Click "Approve Payment" if receipt is valid
   - Or click "Reject" with reason if documentation is insufficient
   - Add optional notes (e.g., "Receipt unclear, requesting resubmission")

5. **Status Update**
   - Registration moves to "Finance Approved" status (if approved)
   - Moves to next approval: HOD → Retention
   - Student receives notification of payment status

**Key Pages for Finance:**
- Finance dashboard: `http://localhost:4000/finance/dashboard`
- Payment receipt view (with zoom/download capability)

---

### HOD Approval Workflow

**Example Journey: A Head of Department reviewing registrations in their department**

1. **Log In** (HOD Role)
   - Use account with "hod" role
   - Access HOD dashboard: `http://localhost:4000/hod/dashboard` (if implemented)

2. **View Department Registrations**
   - See all registrations from students in your department
   - Filter by academic programme or approval status

3. **Review & Approve**
   - Review academic and finance approvals already given
   - Provide HOD-level approval based on departmental capacity/policy
   - Add departmental notes if needed

4. **Status Update**
   - Registration moves to "HOD Approved" status
   - Proceeds to retention stage

---

### Admin Dashboard Workflow

**Example Journey: An administrator setting up programmes and managing users**

1. **Log In** (Admin Role)
   - Use account with "admin" role
   - Access admin panel: `http://localhost:4000/admin`

2. **Manage Users**
   - Navigate to "Users" section
   - Create new users by specifying:
     - Email, name, password
     - Role (student, academics, finance, hod, retention, admin)
     - Active/inactive status
   - Edit existing users or reset passwords
   - Deactivate accounts as needed

3. **Manage Programmes**
   - Navigate to "Programmes" section
   - Create new academic programmes:
     - Programme name, code, description
     - Number of years
   - Edit or archive programmes
   - View associated courses

4. **Manage Courses**
   - Navigate to "Courses" section
   - Create new courses:
     - Course code, name, credits, description
   - Assign courses to programmes
   - Edit course details

5. **View All Registrations**
   - See all student registrations in the system
   - Filter by status, programme, date range
   - Manually update registration status if needed (for corrections)

**Key Pages for Admins:**
- Admin dashboard: `http://localhost:4000/admin`
- Users management: `http://localhost:4000/admin/users`
- Programmes management: `http://localhost:4000/admin/programmes`
- Courses management: `http://localhost:4000/admin/courses`
- Registrations management: `http://localhost:4000/admin/registrations`

---

### Multi-Stage Approval Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  STUDENT REGISTRATION LIFECYCLE                                 │
└─────────────────────────────────────────────────────────────────┘

START
  │
  ├─> [PAYMENT STAGE]
  │   └─> Finance team reviews payment receipt
  │       ├─> Approve  → Next stage
  │       └─> Reject   → Back to student (request resubmission)
  │
  ├─> [ACADEMICS STAGE]
  │   └─> Academics team reviews course selection
  │       ├─> Approve  → Next stage
  │       └─> Request changes → Back to student
  │
  ├─> [HOD STAGE]
  │   └─> Head of Department approves
  │       ├─> Approve  → Next stage
  │       └─> Reject   → Back to student
  │
  ├─> [RETENTION STAGE]
  │   └─> Retention team conducts final review
  │       ├─> Approve  → REGISTRATION COMPLETE
  │       └─> Request info → Back to student
  │
  └─> ✓ APPROVED
      └─> Student receives confirmation
          Enrollment complete
```

---

## 🛠️ Tech Stack & Architecture

### Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | Phoenix | 1.8.3 |
| **Language** | Elixir | 1.19+ |
| **Web Server** | Bandit | 1.5+ |
| **Database** | PostgreSQL | 15+ |
| **ORM** | Ecto SQL | 3.13+ |
| **Frontend** | Phoenix LiveView | 1.1.0+ |
| **CSS** | TailwindCSS | 4.0 |
| **JavaScript** | TypeScript | Latest |
| **Asset Bundler** | esbuild | 0.10+ |
| **Icons** | Heroicons | v2.2.0 |
| **Authentication** | bcrypt_elixir | 3.0+ |
| **HTTP Client** | Req | 0.5+ |
| **Email** | Swoosh | 1.16+ |
| **Caching** | Cachex | 4.0+ |
| **Pagination** | Scrivener Ecto | 3.0+ |
| **Real-time** | Phoenix PubSub | Built-in |
| **Monitoring** | Telemetry | 1.0+ |

### Project Structure

```
lib/
├── cuz_core_connect/              # Core business logic (contexts)
│   ├── accounts/                  # User authentication & roles
│   ├── students/                  # Student registration logic
│   ├── academics/                 # Academic approval workflows
│   ├── finance/                   # Finance & payment workflows
│   ├── programmes/                  # Programme & course management
│   ├── notifications/             # Email & notification system
│   ├── repo.ex                    # Database repository
│   └── application.ex             # OTP application setup
│
├── cuz_core_connect_web/          # Web layer (routing, LiveViews, components)
│   ├── router.ex                  # Route definitions
│   ├── components/
│   │   ├── core_components.ex     # Reusable UI components (<.input>, <.button>, etc.)
│   │   └── layouts.ex             # Layout templates
│   ├── live/                      # LiveView pages
│   │   ├── home_live.ex           # Landing page
│   │   ├── admin_live/            # Admin dashboard pages
│   │   ├── academics_live/        # Academics dashboard pages
│   │   ├── finance_live/          # Finance dashboard pages
│   │   └── ...
│   ├── controllers/               # Traditional controller endpoints
│   └── plugs/                     # Custom middleware (authentication, authorization)
│
assets/
├── css/
│   └── app.css                    # TailwindCSS configuration & custom styles
├── js/
│   ├── app.js                     # Main JavaScript bundle entrypoint
│   └── hooks/                     # JavaScript hooks for LiveView interop
└── vendor/                        # Vendored libraries

priv/
├── repo/
│   └── migrations/                # Database migration files
└── static/                        # Static assets (images, fonts, etc.)

config/
├── config.exs                     # Base configuration
├── dev.exs                        # Development-specific config
├── prod.exs                       # Production-specific config
├── runtime.exs                    # Runtime configuration (env vars)
└── test.exs                       # Test-specific config

test/                              # Test suite
├── cuz_core_connect/              # Unit & integration tests
├── cuz_core_connect_web/          # LiveView & controller tests
├── support/                       # Test helpers & fixtures
└── test_helper.exs                # Test configuration
```

### Key Architectural Patterns

#### 1. **Context-Based Organization**
Business logic is organized into contexts (e.g., `Students`, `Academics`, `Finance`), each with their own schemas, changesets, and queries. This follows Phoenix best practices and makes the codebase maintainable.

#### 2. **Multi-Role RBAC (Role-Based Access Control)**
Users have roles (student, academics, finance, hod, retention, admin). Authentication plugs in the router enforce role-based access:
```elixir
:fetch_current_scope_for_user    # Fetch user, available to all
:require_authenticated_user       # Require login
:require_admin_user              # Admin-only
:require_academics_user          # Academics-only
# etc.
```

#### 3. **LiveView for Interactive UX**
Most pages use Phoenix LiveView for real-time updates without page reloads. Forms validate on change, and data updates push to all connected clients automatically.

#### 4. **TailwindCSS v4 (No Config File)**
Tailwind v4 eliminates the need for `tailwind.config.js`. Configuration is in `assets/css/app.css`:
```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/cuz_core_connect_web";
```

#### 5. **HEEx Templates with Colocated Hooks**
Phoenix templates use HEEx (HTML + Elixir embedded code) with support for colocated JavaScript hooks for enhanced interactivity without writing separate JS files.

### Database Schema Overview

#### Main Tables

**`tbl_users`** — User accounts and authentication
- `id` — Primary key
- `email` — Unique email address
- `hashed_password` — bcrypt hashed password
- `role` — User role (student, academics, finance, hod, retention, admin)
- `confirmed_at` — Email confirmation timestamp
- `active` — Account active/inactive status
- `created_at`, `updated_at`

**`tbl_registration`** — Student registration records
- `id` — Primary key
- `tracking_number` — Unique registration tracking identifier
- `student_id` — Foreign key to user (student)
- `program_id` — Foreign key to programme selected
- `payment_status` — (pending, approved, rejected)
- `academics_status` — (pending, approved, rejected)
- `hod_status` — (pending, approved, rejected)
- `finance_status` — (pending, approved, rejected)
- `retention_status` — (pending, approved, rejected)
- `registration_status` — (pending, in_progress, approved, rejected, completed)
- `payment_receipt_path` — Path to uploaded payment receipt
- `created_at`, `updated_at`

**`tbl_programs`** — Academic programmes (degrees, certificates)
- `id` — Primary key
- `name` — Programme name (e.g., "Bachelor of Science in Computer Science")
- `code` — Programme code (e.g., "BSC_CS")
- `description` — Programme description
- `years` — Number of years in programme
- `created_at`, `updated_at`

**`tbl_courses`** — Course definitions
- `id` — Primary key
- `code` — Course code (e.g., "CS101")
- `name` — Course name
- `credits` — Credit hours
- `description` — Course description
- `created_at`, `updated_at`

**`program_courses`** — Junction table linking programmes to courses
- `program_id` — Foreign key to programme
- `course_id` — Foreign key to course
- `required` — Boolean: is this course required for the programme?

**Entity Relationships:**
```
User (student role)
  ↓ (has_many)
Registration
  ├─→ Programme (belongs_to)
  └─→ Courses (many_to_many through registration_courses)
```

---

## 👨‍💻 Getting Started for Developers

### Development Environment Setup

#### 1. Install Dependencies

```bash
# Install Elixir dependencies
mix deps.get

# Install Node dependencies
cd assets && npm install && cd ..
```

#### 2. Database Setup

```bash
# Create database and run migrations
mix ecto.create
mix ecto.migrate

# (Optional) Seed initial data for testing
mix ecto.reset  # This also seeds
```

#### 3. Install Asset Compilers

```bash
# Install Tailwind and esbuild (only needed once)
mix assets.setup
```

#### 4. Start the Development Server

```bash
# Start Phoenix with hot reloading
mix phx.server
```

Your app runs at `http://localhost:4000` with:
- ✅ LiveReload enabled (auto-refresh on file changes)
- ✅ HEEx template compilation
- ✅ CSS/JS bundling
- ✅ Database connection pooling

### Running Tests

```bash
# Run entire test suite
mix test

# Run tests in a specific file
mix test test/cuz_core_connect_web/live/admin_live_test.exs

# Run only tests that previously failed
mix test --failed

# Run tests with verbose output
mix test --verbose
```

### Code Quality & Pre-Commit Checks

Before committing, run the `precommit` task to ensure code quality:

```bash
# Run all pre-commit checks: compilation, format, tests, unused deps
mix precommit
```

This command:
1. **Compiles** with warnings-as-errors enabled
2. **Unlocks** unused dependencies
3. **Formats** code to standard (uses `.formatter.exs`)
4. **Tests** the entire suite

**⚠️ Fix any failures before committing!**

### Project Guidelines Reference

For detailed Phoenix v1.8 conventions, Elixir best practices, form handling, testing patterns, and more, see [AGENTS.md](./AGENTS.md).

**Key Rules:**
- ✅ Always wrap `<Layouts.unauth>` in LiveView templates
- ✅ Use `<.input>` component for form fields
- ✅ Use `<.link navigate={href}>` instead of deprecated `live_redirect`
- ✅ Use LiveView streams for large collections
- ✅ Use Tailwind classes; never use `@apply` in custom CSS
- ✅ Use `to_form/2` for form assigns in LiveViews
- ✅ Reference [AGENTS.md](./AGENTS.md) for authentication route patterns

### Common Development Tasks

#### Creating a New LiveView Page

1. Create the module in `lib/cuz_core_connect_web/live/my_page_live.ex`
2. Add route to `lib/cuz_core_connect_web/router.ex` in appropriate scope
3. Create template `lib/cuz_core_connect_web/live/my_page_live.html.heex`
4. Wrap template with `<Layouts.unauth flash={@flash} ...>`
5. Run `mix format` to format code

#### Adding a Form to a LiveView

1. Create a changeset in your context (e.g., `Accounts.change_user(user)`)
2. In LiveView, use `assign(socket, :form, to_form(changeset))`
3. In template, use:
   ```heex
   <.form for={@form} id="my-form" phx-submit="save">
     <.input field={@form[:email]} type="email" />
     <.input field={@form[:name]} type="text" />
   </.form>
   ```
4. Handle `phx-submit` in `handle_event("save", params, socket)`

#### Testing a LiveView

```elixir
defmodule MyAppWeb.MyLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "render page", %{conn: conn} do
    {:ok, view, html} = live(conn, "/my-page")
    assert html =~ "Page Title"
  end

  test "handle form submission", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/my-page")

    view
    |> form("#my-form", %{"field" => "value"})
    |> render_submit()

    assert_redirect(view, "/success-path")
  end
end
```

---

## 📖 How to Use the System (End User Guide)

### For Students: Registering for Courses

#### Step 1: Create Your Account

1. Visit the home page at [`http://localhost:4000`](http://localhost:4000)
2. Click **"Register as Student"** or **"New to CUZ-Core-Connect?"**
3. Fill in your details:
   - **Email**: Your institutional or personal email
   - **Full Name**: Your legal full name
   - **Password**: A strong password (min. 8 characters recommended)
4. Click **"Sign Up"**
5. Check your email for a **confirmation link**
6. Click the link to verify your email
7. You're now registered and can log in!

#### Step 2: Start a New Registration

1. Log in with your email and password
2. On your dashboard, click **"Start New Registration"**
3. Choose your **Academic Programme** from the dropdown:
   - Bachelor of Science in Computer Science
   - Bachelor of Science in Information Technology
   - Bachelor of Arts in Business Administration
   - (Or other available programmes)
4. Click **"Next"** or **"Continue"**

#### Step 3: Select Your Courses

1. You'll see a list of **Required Courses** and **Elective Courses** for your programme
2. All required courses are pre-selected
3. Choose your **electives** from the available options:
   - Check the box next to each elective you want to take
   - You can only select the number of electives allowed
4. Review your total **credit hours** (should match programme requirements)
5. Click **"Confirm Selection"** or **"Next"**

#### Step 4: Submit Payment Receipt

1. You'll see the **tuition amount due**
2. Make a payment via the institution's payment portal (details provided)
3. Once paid, download or screenshot your **payment receipt** or **transaction confirmation**
4. Click **"Upload Payment Receipt"**
5. Select your receipt image/PDF file
6. Click **"Upload"**
7. Click **"Submit Registration"**

#### Step 5: Track Your Registration Status

1. A **Tracking Number** is generated (e.g., `REG-2024-0001234`)
2. You can track your registration on the **"My Registrations"** page:
   - Shows current stage (Payment Review → Academic Review → HOD Review → Finance Review → Retention Review)
   - Shows approval/rejection status at each stage
   - See reviewer comments if any stage is rejected
3. You'll receive **email notifications** when:
   - ✅ Your registration is approved by each stage
   - ❌ Your registration is rejected (with reason)
   - ✓ Your registration is complete

#### Step 6: Registration Complete!

- Once all stages are approved, you'll receive a **"Registration Approved"** email
- You can then access your **finalized course schedule**
- Download your **course registration certificate** (if available)
- You're enrolled and ready for classes!

#### Troubleshooting (Student)

**Q: I didn't receive the confirmation email**
- A: Check your spam/junk folder. Wait 5 minutes. You can request a new email from the login page.

**Q: My registration was rejected at one stage**
- A: Check the rejection reason in your dashboard. It may say "Course prerequisite not met" or similar. Click "Revise Registration" to resubmit.

**Q: I need to change my course selection**
- A: You can only modify during the "Pending" stage. If approval has begun, contact an administrator.

---

### For Academics: Approving Registrations

#### Step 1: Log In to Your Dashboard

1. Go to [`http://localhost:4000`](http://localhost:4000)
2. Enter your **academic team email** and **password**
3. Click **"Sign In"**
4. You'll be taken to your **Academics Dashboard** (`/academics/dashboard`)

#### Step 2: View Pending Registrations

1. On the dashboard, you'll see a **list of pending registrations** awaiting academic approval
2. Each row shows:
   - **Student Name**
   - **Programme Selected**
   - **Courses** (count or list)
   - **Status**: "Awaiting Academic Review"
   - **Submitted Date**

#### Step 3: Review a Registration

1. Click on a registration row or **"View Details"** button
2. A **detail panel** will open showing:
   - Student information (name, email, ID if available)
   - **Selected Programme**
   - **Courses Selected** (with credits and prerequisites)
   - **Payment Status** (showing if payment was approved)
   - **Notes** from previous stages
3. Verify:
   - ✅ Courses match the programme curriculum
   - ✅ Student has met course prerequisites
   - ✅ Course load is reasonable for the student's level
   - ✅ No course conflicts or scheduling issues

#### Step 4: Approve or Request Changes

**To Approve:**
1. Click **"Approve Registration"** button
2. (Optional) Add notes such as: "Approved - course selection meets programme requirements"
3. Click **"Confirm Approval"**
4. Status changes to "Academically Approved"
5. Registration moves to the **next approval stage** (Finance)
6. Student receives notification email

**To Request Changes:**
1. Click **"Request Revision"** button
2. In the feedback box, explain what needs to change:
   - Example: "Student needs to take CS101 (prerequisite for CS200) instead of CS199"
   - Example: "Total credits exceed maximum allowed for semester"
3. Click **"Send Revision Request"**
4. Status returns to "Revision Requested"
5. Student receives email with your feedback
6. Student can revise and resubmit

#### Step 5: Bulk Management (Optional)

1. Use **filters** at the top to find registrations:
   - By programme
   - By submission date
   - By student name
2. Select multiple registrations using checkboxes
3. Click **"Bulk Actions"** → **"Approve Selected"** or **"Reject Selected"**
4. Confirm the bulk action

#### Troubleshooting (Academics)

**Q: I see a course I don't recognize**
- A: Check the **Course Catalog** (in admin panel or reference section) to verify course details.

**Q: A student took a course without the prerequisite**
- A: Mark as "Revision Requested" and specify that the prerequisite is required.

---

### For Finance: Approving Payments

#### Step 1: Log In to Your Dashboard

1. Go to [`http://localhost:4000`](http://localhost:4000)
2. Enter your **finance team email** and **password**
3. Click **"Sign In"**
4. You'll be taken to your **Finance Dashboard** (`/finance/dashboard`)

#### Step 2: View Pending Payments

1. On the dashboard, you'll see a **list of payments awaiting verification**
2. Each row shows:
   - **Student Name**
   - **Amount Due**
   - **Receipt Status**: "Awaiting Review"
   - **Submitted Date**

#### Step 3: Review a Payment Receipt

1. Click on a payment row or **"View Receipt"** button
2. The **payment receipt** will display (image or PDF)
3. Verify:
   - ✅ Payment amount matches tuition costs in the system
   - ✅ Receipt is clear and not expired
   - ✅ Transaction date is recent
   - ✅ Payment method is approved (bank transfer, credit card, etc.)
   - ✅ Reference/confirmation number is visible

#### Step 4: Approve or Reject Payment

**To Approve:**
1. Click **"Approve Payment"** button
2. (Optional) Add notes: "Receipt verified - payment confirmed"
3. Click **"Confirm Approval"**
4. Status changes to "Payment Approved"
5. Registration moves to **next approval stage** (Academics or HOD)
6. Student receives notification

**To Reject:**
1. Click **"Reject Payment"** button
2. Select a **rejection reason**:
   - "Receipt unclear or illegible"
   - "Amount does not match tuition"
   - "Receipt appears fraudulent"
   - "Custom reason..."
3. Add detailed notes explaining what's wrong:
   - Example: "Receipt shows $500 but tuition is $750. Please resubmit correct receipt."
4. Click **"Send Rejection"**
5. Status returns to "Payment Rejected"
6. Student receives email with your feedback and can resubmit

---

### For Administrators: Managing the System

#### Step 1: Access the Admin Panel

1. Log in with an **admin account**
2. Navigate to [`http://localhost:4000/admin`](http://localhost:4000/admin)
3. You'll see the **Admin Dashboard** with options:
   - Users
   - Programmes
   - Courses
   - Registrations

#### Step 2: Manage Users

1. Click **"Users"** or **"Manage Users"**
2. You'll see a **list of all users** in the system

**Create a New User:**
1. Click **"+ New User"** or **"Add User"**
2. Fill in user details:
   - **Email**: user@institution.edu
   - **Name**: Full Name
   - **Role**: Choose from dropdown:
     - Student
     - Academics
     - Finance
     - HOD
     - Retention
     - Admin
   - **Password**: System-generated or custom
   - **Active**: Toggle "Yes" to activate account
3. Click **"Create User"**
4. User receives email with password/login instructions

**Edit a User:**
1. Find the user in the list
2. Click **"Edit"** or the row itself
3. Modify details (name, role, active status)
4. Click **"Update User"**

**Deactivate a User:**
1. Find the user
2. Click the **toggle** or **"Deactivate"** button
3. User can no longer log in (data is preserved)

**Reset User Password:**
1. Find the user
2. Click **"Reset Password"**
3. User receives email with password reset link

#### Step 3: Manage Programmes

1. Click **"Programmes"** or **"Manage Programmes"**
2. You'll see a **list of academic programmes**

**Create a New Programme:**
1. Click **"+ New Programme"** or **"Add Programme"**
2. Fill in programme details:
   - **Name**: Bachelor of Science in Computer Science
   - **Code**: BSC_CS (used internally)
   - **Description**: Programme description for students
   - **Years**: 4 (duration of programme)
3. Click **"Create Programme"**

**Edit a Programme:**
1. Click on the programme or **"Edit"** button
2. Modify details
3. Click **"Update Programme"**

**Assign Courses to Programme:**
1. Click on a programme
2. Scroll to **"Courses"** section
3. Click **"+ Add Course"**
4. Select courses from dropdown
5. Mark if **"Required"** (yes/no)
6. Click **"Add to Programme"**

#### Step 4: Manage Courses

1. Click **"Courses"** or **"Manage Courses"**
2. You'll see a **list of all courses**

**Create a New Course:**
1. Click **"+ New Course"** or **"Add Course"**
2. Fill in course details:
   - **Code**: CS101
   - **Name**: Introduction to Computer Science
   - **Credits**: 3
   - **Description**: Course description
   - **Prerequisites**: (if any)
3. Click **"Create Course"**

**Edit a Course:**
1. Click on the course or **"Edit"**
2. Modify details
3. Click **"Update Course"**

#### Step 5: View All Registrations

1. Click **"Registrations"** or **"Manage Registrations"**
2. You'll see **all registrations** in the system
3. Use **filters**:
   - By registration status (pending, approved, rejected, etc.)
   - By programme
   - By date range
   - By student
4. Click a registration to **view full details**
5. If needed, you can **manually update status** or **add admin notes**

---

## 📁 Project Structure Deep Dive

### Web Routes Structure

```
Public Routes (no auth required):
├── GET  /                           → Home/landing page
├── GET  /register                   → Student registration form
├── POST /users/register             → Register new student account
├── GET  /login                      → Login form
├── POST /users/login                → Process login
└── GET  /track                      → Track registration by number

Authenticated Routes (requires login):
├── GET  /dashboard                  → Student dashboard
├── GET  /my-registrations           → View student's registrations
├── POST /registrations              → Create new registration
├── GET  /registrations/:id          → View registration details
└── ...

Academics Routes (/academics/*):
├── GET  /academics/dashboard        → Academics approval dashboard
├── GET  /academics/registrations    → Registrations awaiting approval
└── ...

Finance Routes (/finance/*):
├── GET  /finance/dashboard          → Finance approval dashboard
├── GET  /finance/payments           → Payments awaiting review
└── ...

Admin Routes (/admin/*):
├── GET  /admin                      → Admin dashboard
├── GET  /admin/users                → User management
├── POST /admin/users                → Create user
├── GET  /admin/programmes             → Programme management
├── POST /admin/programmes             → Create programme
├── GET  /admin/courses              → Course management
├── POST /admin/courses              → Create course
├── GET  /admin/registrations        → Registration management
└── ...
```

### Key Files to Know

- [lib/cuz_core_connect_web/router.ex](lib/cuz_core_connect_web/router.ex) — Route definitions, auth scopes, plugs
- [lib/cuz_core_connect_web/plugs/user_auth.ex](lib/cuz_core_connect_web/plugs/user_auth.ex) — Authentication logic and role checks
- [lib/cuz_core_connect/accounts/user.ex](lib/cuz_core_connect/accounts/user.ex) — User schema and validations
- [lib/cuz_core_connect/accounts.ex](lib/cuz_core_connect/accounts.ex) — User management context
- [lib/cuz_core_connect_web/components/core_components.ex](lib/cuz_core_connect_web/components/core_components.ex) — Reusable UI components
- [lib/cuz_core_connect_web/components/layouts.ex](lib/cuz_core_connect_web/components/layouts.ex) — Layout templates

---

## 🤝 Contributing

### Code Style & Conventions

This project follows strict conventions for code quality. See [AGENTS.md](./AGENTS.md) for comprehensive guidelines.

**Key Rules:**
- **Format Code**: `mix format` (required before commit)
- **Compile Checks**: `mix compile --warnings-as-errors`
- **Tests**: All code changes must include tests
- **Import Usage**: Unused imports are not allowed
- **LiveView**: Always use `to_form/2` and `<.input>` component
- **CSS**: Use TailwindCSS; never use `@apply`
- **Database**: Preload Ecto associations when they'll be used in templates
- **Comments**: Use HEEx comment syntax `<%!-- comment --%>` in templates

### Commit Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes** and test locally

3. **Run pre-commit checks**
   ```bash
   mix precommit
   ```
   - ✅ Must pass all checks before committing
   - ✅ Fixes formatting issues automatically
   - ✅ Runs full test suite
   - ✅ Checks for unused dependencies

4. **Commit with meaningful message**
   ```bash
   git commit -m "Add new feature: brief description"
   ```

5. **Push to remote**
   ```bash
   git push origin feature/my-feature
   ```

6. **Create a Pull Request** with:
   - Clear description of changes
   - Screenshots/videos if UI changes
   - Test coverage for new features
   - Reference any related issues

### Testing Guidelines

- Write tests for **all new features**
- Use `Phoenix.LiveViewTest` for LiveView tests
- Use `ExUnit` for unit tests
- Test both **happy path** and **error cases**
- Test **user interactions** (form submissions, button clicks)
- Run tests frequently: `mix test`

### Pull Request Checklist

- [ ] All tests pass (`mix test`)
- [ ] `mix precommit` passes without errors
- [ ] Code follows project guidelines (see AGENTS.md)
- [ ] New features include test coverage
- [ ] Database migrations (if applicable) are included
- [ ] PR description explains what and why
- [ ] No debug statements or commented code left behind

---

## 🐛 Troubleshooting

### Common Issues & Solutions

#### Database Connection Error
**Problem:** `ERROR: FATAL: could not connect to server`

**Solution:**
```bash
# Ensure PostgreSQL is running
brew services start postgresql@15  # macOS
sudo service postgresql start       # Linux

# Check database credentials in config/dev.exs
# Ensure PostgreSQL user exists
createuser postgres -s

# Reset database
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

#### Dependencies Won't Compile
**Problem:** `Compilation failed or dependencies are missing`

**Solution:**
```bash
# Clean build artifacts
mix clean
mix deps.clean --all
mix deps.get

# Rebuild dependencies
mix deps.compile
```

#### Assets Not Compiling
**Problem:** CSS/JS not updating, build errors in assets

**Solution:**
```bash
# Reinstall asset compilers
cd assets && npm install && cd ..
mix assets.setup
mix assets.build

# If still broken, clear cache
rm -rf node_modules
npm install
```

#### LiveView Not Updating
**Problem:** Form changes don't reflect, page doesn't update

**Solution:**
1. Ensure LiveView is working: check browser console for errors
2. Verify `phx-change` or `phx-submit` attributes on form elements
3. Check LiveView `handle_event` callbacks are implemented
4. Restart dev server: `mix phx.server`
5. Clear browser cache (Ctrl+Shift+Delete)

#### Tests Failing Randomly
**Problem:** Tests pass locally but fail in CI, or fail intermittently

**Solution:**
```bash
# Run failed tests again
mix test --failed

# Run tests with verbose output to see what's happening
mix test --verbose

# Ensure database is clean between test runs
mix test --include pending

# Check for race conditions or timing issues in tests
# Consider using :timer.sleep/1 or waiting with assert_receive
```

#### Email Not Sending in Development
**Problem:** User confirmation emails not received

**Solution:**
1. Check `config/dev.exs` for Swoosh mailer configuration
2. For development, emails are typically printed to console
3. To test with real email:
   ```bash
   # Use Mailtrap or similar service
   # Update config/dev.exs with SMTP credentials
   ```

---

## 📚 Additional Resources

### Official Documentation
- [Phoenix Framework Docs](https://hexdocs.pm/phoenix/)
- [Phoenix LiveView Guide](https://hexdocs.pm/phoenix_live_view/)
- [Ecto Documentation](https://hexdocs.pm/ecto/)
- [Elixir Language Docs](https://elixir-lang.org/docs.html)

### Project Documentation
- [AGENTS.md](./AGENTS.md) — Project guidelines, conventions, best practices
- Database migrations in `priv/repo/migrations/`
- Test examples in `test/` directory

### Learning Resources
- [Programming Phoenix](https://pragprog.com/titles/phoenix14/programming-phoenix-1-4/) — Book by Chris McCord et al.
- [Elixir School](https://elixirschool.com/) — Free Elixir tutorials
- [Phoenix Community Forum](https://elixirforum.com/c/phoenix-forum)

---

## 📞 Support & Contact

### Getting Help

- **Documentation**: See [AGENTS.md](./AGENTS.md) for comprehensive guidelines
- **Bug Reports**: Create an issue on GitHub with:
  - Steps to reproduce
  - Expected vs. actual behavior
  - Your Elixir/Phoenix/OS versions
  - Error logs or screenshots
- **Feature Requests**: Create an issue with use case and proposed solution
- **Questions**: Check existing issues first, then create a discussion

### Development Team Contact

- **Project Lead**: abdurrahmaanchimalo5@gmail.com - Abdulramaan : hniyomen@gmail.com - Honore
- **Questions**: Email or project discussion board

---

## 📄 License

MIT

---

**Last Updated**: May 19, 2026
**Version**: 1.0.0
**Maintained By**: CUZ-Core-Connect Team
