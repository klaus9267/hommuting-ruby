# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

This is a Rails 8.0.2 application named "Hommuting" using modern Rails features including Hotwire (Turbo + Stimulus), Solid Queue/Cache/Cable, and Propshaft for asset management.

## Development Commands

### Setup and Installation
```bash
bin/setup                    # Complete development environment setup (installs deps, prepares DB, starts server)
bin/setup --skip-server     # Setup without starting the server
bundle install              # Install Ruby dependencies
bin/rails db:prepare        # Setup database
```

### Running the Application
```bash
bin/dev                      # Start development server (Rails server)
bin/rails server            # Alternative way to start server
bin/rails console           # Rails console
bin/jobs                     # Start background job processing (Solid Queue)
```

### Testing
```bash
bin/rails test              # Run all tests
bin/rails test test/path/to/specific_test.rb  # Run specific test file
bin/rails test:system       # Run system tests (Capybara + Selenium)
```

### Code Quality and Security
```bash
bin/rubocop                  # Run RuboCop linter (Rails Omakase style)
bin/rubocop -a               # Auto-fix RuboCop issues
bin/brakeman                 # Security vulnerability scanner
```

### Database Operations
```bash
bin/rails db:migrate         # Run pending migrations
bin/rails db:rollback        # Rollback last migration
bin/rails db:seed            # Load seed data
bin/rails db:reset           # Drop, create, migrate, and seed database
```

### Asset Management
```bash
bin/importmap pin <package>  # Pin JavaScript packages
bin/rails assets:precompile  # Precompile assets for production
```

### Deployment
```bash
bin/kamal setup              # Initial deployment setup (Docker-based)
bin/kamal deploy             # Deploy application
bin/thrust                   # HTTP caching/compression tool
```

## Architecture

### Modern Rails 8.0 Stack
- **Frontend**: Hotwire (Turbo + Stimulus) with importmap for JavaScript modules
- **Asset Pipeline**: Propshaft (modern replacement for Sprockets)
- **Background Jobs**: Solid Queue (database-backed job processor)
- **Caching**: Solid Cache (database-backed cache store)
- **WebSockets**: Solid Cable (database-backed Action Cable adapter)
- **Database**: SQLite3 (development/test), configurable for production

### Key Design Patterns
- Modern browser support only (webp, web push, CSS nesting, etc.)
- Database-backed infrastructure (queue, cache, cable) for simplified deployment
- Omakase Ruby styling conventions via RuboCop
- Parallel test execution enabled by default

### Database Schema Files
- `db/queue_schema.rb` - Solid Queue job processing tables
- `db/cache_schema.rb` - Solid Cache storage tables  
- `db/cable_schema.rb` - Solid Cable WebSocket tables

### Testing Setup
- Parallel test execution using all CPU cores
- System tests with Capybara and Selenium WebDriver
- Fixture-based test data loading