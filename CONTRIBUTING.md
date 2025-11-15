# Contributing to Cloud Infrastructure Project

Thank you for your interest in contributing to this project! 🎉

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in [Issues](../../issues)
2. If not, create a new issue with:
   - Clear description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (OS, Terraform version, etc.)

### Submitting Changes

1. **Fork the repository**
   ```bash
   # Click "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/cloud-infra.git
   cd cloud-infra
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**
   - Follow existing code style
   - Add tests if applicable
   - Update documentation

5. **Test your changes**
   ```bash
   # Terraform
   cd terraform
   terraform fmt -check -recursive
   terraform validate
   
   # Ansible
   cd ../ansible
   ansible-lint playbook.yml
   
   # Run tests
   cd ../tests
   go test -v
   ```

6. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   ```

   **Commit message format:**
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `refactor:` Code refactoring
   - `test:` Adding tests
   - `chore:` Maintenance tasks

7. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill in the PR template
   - Wait for review

## Development Guidelines

### Code Style

- **Terraform**: Use `terraform fmt`
- **Ansible**: Follow [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- **Shell scripts**: Use [ShellCheck](https://www.shellcheck.net/)
- **Go**: Use `gofmt`

### Documentation

- Update README.md if adding new features
- Add inline comments for complex logic
- Update architecture.md if changing infrastructure
- Include examples when relevant

### Testing

- Add Terratest cases for new modules
- Test in multiple environments (dev/staging)
- Ensure all tests pass before submitting PR
- Test both Linux and Windows compatibility (scripts)

## What We're Looking For

### Good First Issues

- Documentation improvements
- Bug fixes
- Additional examples
- Test coverage improvements

### Feature Ideas

- New AWS resource modules (RDS, ALB, etc.)
- Additional monitoring capabilities
- Security enhancements
- Cost optimization features
- Multi-region support

### Areas We Need Help

- [ ] Additional cloud provider support (Azure, GCP)
- [ ] Kubernetes integration
- [ ] Docker Compose examples
- [ ] More comprehensive testing
- [ ] CI/CD improvements

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information

## Questions?

- Open a [Discussion](../../discussions)
- Check existing [Issues](../../issues)
- Review [Documentation](docs/)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing!** 🚀
