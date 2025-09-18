# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.0 API-only application called "Hommuting" - a Korean real estate property aggregation service. The app provides RESTful APIs for property search and management, with CORS configured for React frontend integration.

## 🚀 MVP Development Priority

**CRITICAL**: This project prioritizes **fast MVP delivery**.

### Development Principles:
- **Simple over complex**: Choose straightforward solutions over sophisticated ones
- **Working over perfect**: Ship functional code first, optimize later
- **Essential features only**: Focus on core functionality, avoid feature creep
- **Minimal boilerplate**: Use helpers and shared modules to reduce code duplication
- **Quick iterations**: Prefer rapid prototyping and feedback cycles

### Code Style for MVP:
- Keep controllers thin and focused
- Use shared schemas and helpers for API documentation
- Prioritize readability over optimization
- Write tests for core functionality only
- Defer complex features until post-MVP

## Key Architecture

- **API-only Rails Application**: No views, assets pipeline, or frontend components
- **Property Data Model**: Central entity storing real estate listings from multiple sources
- **Namespaced API**: All endpoints under `/api/v1/` namespace
- **Korean Real Estate Types**: Supports property types like 아파트, 빌라, 오피스텔, 단독주택, 다가구, 주상복합
- **Deal Types**: 매매 (purchase), 전세 (key money lease), 월세 (monthly rent)
- **Geolocation Support**: Properties have latitude/longitude for area-based searching

## Development Commands

### Database Operations
```bash
bin/rails db:create          # Create databases
bin/rails db:migrate         # Run migrations
bin/rails db:seed            # Load seed data
bin/rails db:reset           # Drop, recreate, and seed database
```

### Testing
```bash
bin/rails test               # Run all tests except system tests
bin/rails test:db           # Reset DB and run tests
bundle exec rspec            # Run RSpec tests
```

### API Documentation (MVP Approach)
```bash
bundle exec rake rswag:specs:swaggerize  # Generate Swagger docs from specs
```

**MVP Documentation Strategy**:
- Use `SharedSchemas` helper for common parameters
- Keep specs focused on essential endpoints only
- Prioritize working documentation over comprehensive coverage
- Use simple response schemas (avoid complex nested objects)

### Development Server
```bash
bin/rails server             # Start development server (port 3000)
```

### Code Quality
```bash
bundle exec rubocop          # Run linter (Rubocop with Rails Omakase config)
bundle exec brakeman         # Security vulnerability scanner
```

## API Endpoints Structure

All API endpoints are versioned under `/api/v1/`:

- `GET /api/v1/properties` - List properties with filtering and pagination
- `GET /api/v1/properties/:id` - Show specific property
- `GET /api/v1/properties/search` - Text search across properties
- `GET /api/v1/properties/stats` - Property statistics
- `GET /api/v1/properties/by_area` - Location-based property search
- `GET /up` - Health check endpoint
- `GET /api-docs` - Swagger UI for API documentation

### 🚧 PLANNED REFACTORING: Property Type-Specific Endpoints

**IMPORTANT**: Before implementing this refactoring, ALWAYS ask the user for permission first.

Following 직방(Zigbang) UX pattern, the API should be refactored to have 4 separate property type endpoints for better frontend usability:

1. **아파트 (Apartment)** - `GET /api/v1/apartments`
   - Deal types: 매매/전세/신축분양
   - Specific filters for apartment complexes

2. **빌라/투룸+ (Villa/Multi-room)** - `GET /api/v1/villas`
   - Deal types: 신축분양/매매/전세/월세
   - Filters for villa-type properties

3. **원룸 (Studio)** - `GET /api/v1/studios`
   - Deal types: 전월세 focused
   - Studio-specific filters

4. **오피스텔 (Officetel)** - `GET /api/v1/officetels`
   - Deal types: 도시형생활주택/매매/전세/월세
   - Officetel-specific features

**Benefits**:
- Each endpoint can have optimized filters for specific property types
- Frontend can implement type-specific UI/UX patterns
- Better caching strategies per property type
- Specialized response schemas for each type

**Implementation Notes**:
- Current unified endpoint can remain for backward compatibility
- Crawling code requires no changes (data collection remains unified)
- Each new endpoint filters by appropriate `property_type` enum values

## Property Model Features

The Property model includes:
- Validation for Korean property types and deal types
- Scopes for filtering by type, source, and geographic area
- Geolocation queries using latitude/longitude bounds
- External ID tracking for source deduplication
- JSON raw data storage for original listing information

## Key Dependencies

- **Rails 8.0**: Main framework
- **SQLite**: Database (development/test)
- **Puma**: Web server
- **rack-cors**: CORS handling for frontend
- **httparty**: HTTP client for API requests
- **nokogiri**: HTML/XML parsing
- **oj**: Fast JSON processing
- **selenium-webdriver**: Browser automation for testing
- **solid_cache/solid_queue/solid_cable**: Rails built-in adapters
- **rswag**: API documentation with Swagger/OpenAPI 3.0
- **rspec-rails**: RSpec testing framework
- **factory_bot_rails**: Test data generation

## Development Environment

- **Ruby Version**: 3.3.0 (managed via mise.toml)
- **Rails Environment**: API-only mode enabled
- **CORS**: Configured to allow all origins in development
- **Database**: SQLite with proper indexing for geolocation queries

## Testing Setup

- **Rails Test Framework**: Default test framework with fixtures in `test/` directory
- **RSpec**: Alternative testing framework configured in `spec/` directory
- **FactoryBot**: Test data generation with factories in `spec/factories/`
- **API Documentation Tests**: rswag specs with `SharedSchemas` helper for MVP speed
- **MVP Testing Strategy**: Focus on core functionality, skip edge cases initially
- **FactoryBot**: Simple test data generation, avoid complex scenarios

## Deployment

- **Docker**: Production-ready Dockerfile included
- **Kamal**: Deploy configuration in `config/deploy.yml`
- **Thruster**: Production server with HTTP caching and compression