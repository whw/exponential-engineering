---
name: prime
description: Prime Claude with project context by reading key files and understanding the codebase structure
argument-hint: [optional: specific area to focus on]
---

# Prime Command

Prime yourself with essential project context to work effectively in this codebase.

## Workflow

### 1. Discover Project Structure

<task>
First, understand the project layout:

```bash
# Find project root indicators
ls -la | head -20

# Check for common config files
ls -la *.json *.yml *.yaml *.toml 2>/dev/null | head -10

# Find source directories
ls -d */ 2>/dev/null | head -10
```
</task>

### 2. Read Key Documentation

<task>
Read project documentation in this order:

1. **CLAUDE.md** (if exists) - Project-specific Claude instructions
2. **README.md** - Project overview and setup
3. **CONTRIBUTING.md** (if exists) - Development guidelines
4. **.claude/** directory (if exists) - Custom commands and config
</task>

### 3. Understand Tech Stack

<task>
Identify the technology stack:

- **Ruby/Rails**: Look for `Gemfile`, `config/routes.rb`
- **JavaScript/Node**: Look for `package.json`, `tsconfig.json`
- **Python**: Look for `requirements.txt`, `pyproject.toml`, `setup.py`
- **Go**: Look for `go.mod`
- **Rust**: Look for `Cargo.toml`
</task>

### 4. Map Key Directories

<task>
For the identified stack, explore the structure:

**Rails projects:**
- `app/models/` - Domain models
- `app/controllers/` - Request handlers
- `app/views/` or `app/components/` - UI layer
- `config/` - Configuration
- `db/schema.rb` - Database structure

**Node/JS projects:**
- `src/` or `lib/` - Source code
- `components/` - UI components
- `api/` or `routes/` - API endpoints
- `tests/` or `__tests__/` - Test files
</task>

### 5. Summarize Context

<output>
After priming, provide a brief summary:

## Project Context

**Name:** [project name]
**Stack:** [technologies identified]
**Key directories:** [important paths]
**Special instructions:** [from CLAUDE.md if present]

Ready to help with: [list 3-5 things you can now assist with]
</output>

## Focus Areas

If the user specified a focus area ($ARGUMENTS), prioritize:

- **"models"** - Focus on data layer and business logic
- **"api"** - Focus on endpoints and request handling
- **"frontend"** - Focus on UI components and views
- **"tests"** - Focus on test structure and patterns
- **"config"** - Focus on configuration and environment
