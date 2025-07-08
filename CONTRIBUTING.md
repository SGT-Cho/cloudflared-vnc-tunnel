# Contributing to VNC Cloudflared Docker Client

First off, thank you for considering contributing to VNC Cloudflared Docker Client! It's people like you that make this tool better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a new branch for your feature or fix
4. Make your changes
5. Push to your fork and submit a pull request

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear descriptive title**
- **Steps to reproduce** the issue
- **Expected behavior** vs what actually happened
- **System information** (OS, Docker version, etc.)
- **Relevant logs** and error messages
- **Screenshots** if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Use case** - Why is this enhancement needed?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other solutions did you think about?
- **Additional context** - Any other relevant information

### Code Contributions

#### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Simple issues perfect for beginners
- `help wanted` - Issues where we need community help
- `documentation` - Help improve our docs

#### Pull Requests

1. **Small, focused changes** - One feature/fix per PR
2. **Include tests** - If adding functionality
3. **Update documentation** - If changing behavior
4. **Follow style guidelines** - Consistent code is easier to maintain

## Development Setup

### Prerequisites

- Docker 20.10+
- Docker Compose v2.0+
- Bash 4.0+
- Git

### Local Development

```bash
# Clone your fork
git clone https://github.com/yourusername/vnc-cloudflared-docker.git
cd vnc-cloudflared-docker

# Create a branch
git checkout -b feature/your-feature-name

# Make changes and test
./vnc-client.sh test

# Run local validation
bash -n vnc-client.sh  # Syntax check
docker compose config  # Validate docker-compose.yml
```

### Testing

Before submitting a PR:

1. **Test basic functionality**:
   ```bash
   ./vnc-client.sh start
   ./vnc-client.sh status
   ./vnc-client.sh stop
   ```

2. **Test with different configurations**:
   - Different port numbers
   - Multiple profiles
   - Resource limits

3. **Check error handling**:
   - Missing configuration
   - Invalid values
   - Docker not running

## Style Guidelines

### Bash Script Guidelines

- Use `#!/usr/bin/env bash` shebang
- Set `set -euo pipefail` for error handling
- Use meaningful variable names
- Add comments for complex logic
- Prefer `[[ ]]` over `[ ]` for conditionals
- Use `readonly` for constants
- Quote variables: `"${var}"`

Example:
```bash
# Good
readonly CONFIG_FILE="${HOME}/.config/app.conf"
if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
fi

# Bad
config_file=$HOME/.config/app.conf
if [ -f $config_file ]; then
    source $config_file
fi
```

### Docker Guidelines

- Use official base images
- Run as non-root user
- Include HEALTHCHECK
- Add meaningful labels
- Minimize layers
- Use .dockerignore

### Documentation

- Use clear, simple English
- Include examples
- Explain the "why" not just "how"
- Keep line length under 80 characters
- Use markdown formatting consistently

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): subject

body

footer
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code changes that neither fix bugs nor add features
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(script): add support for custom health check intervals

- Allow HEALTHCHECK_INTERVAL environment variable
- Default to 30s if not specified
- Update documentation

Closes #123
```

```
fix(docker): correct port mapping for metrics endpoint

The metrics port was exposed on all interfaces instead of localhost only.
This could be a security issue in some deployments.
```

## Pull Request Process

1. **Update documentation** for any changed functionality
2. **Add tests** if applicable
3. **Update .env.example** if adding new configuration options
4. **Ensure CI passes** - All checks must be green
5. **Request review** from maintainers
6. **Address feedback** promptly
7. **Squash commits** if requested

### PR Title Format

Use the same format as commit messages:
- `feat: add support for RDP connections`
- `fix: resolve authentication timeout issue`
- `docs: improve troubleshooting guide`

## Release Process

Maintainers will:

1. Review and merge PRs
2. Update version numbers
3. Update CHANGELOG.md
4. Create GitHub release
5. Tag release commit

## Community

### Getting Help

- **GitHub Issues** - For bugs and features
- **Discussions** - For questions and ideas
- **Examples** - Check the `examples/` directory

### Communication Guidelines

- Be respectful and inclusive
- Provide context and be specific
- Search before asking
- Help others when you can

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- GitHub release notes
- Project documentation

Thank you for contributing to VNC Cloudflared Docker Client! 🎉