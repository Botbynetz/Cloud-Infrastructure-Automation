# 🌐 Portfolio Website Integration Guide

## 📋 **Quick Copy-Paste untuk Portfolio Website Kamu**

Berikut adalah code snippets yang bisa langsung kamu pakai di **botbynetz.github.io**

---

## 🎨 **Project Card untuk Projects Page**

### **HTML Structure**
```html
<!-- Cloud Infrastructure Automation Project Card -->
<div class="project-card featured" data-aos="fade-up">
  <!-- Badge Feature -->
  <div class="project-badge">
    <span class="badge-featured">⭐ Featured Project</span>
    <span class="badge-status">🟢 Active</span>
  </div>

  <!-- Project Thumbnail/Preview -->
  <div class="project-thumbnail">
    <img src="assets/img/projects/cloud-infra-preview.png" 
         alt="Cloud Infrastructure Automation"
         loading="lazy">
    <div class="project-overlay">
      <div class="project-stats">
        <span><i class="fas fa-code"></i> 5,000+ LOC</span>
        <span><i class="fas fa-star"></i> Production Ready</span>
        <span><i class="fas fa-shield-alt"></i> Security Hardened</span>
      </div>
    </div>
  </div>

  <!-- Project Info -->
  <div class="project-content">
    <div class="project-header">
      <h3 class="project-title">
        <span class="title-icon">🏗️</span>
        Cloud Infrastructure Automation
      </h3>
      <div class="project-date">
        <i class="far fa-calendar"></i> January 2025
      </div>
    </div>

    <p class="project-description">
      Enterprise-grade AWS infrastructure automation platform using 
      <strong>Terraform</strong> and <strong>Ansible</strong>. 
      Features multi-environment deployment, automated CI/CD, security 
      hardening, and comprehensive monitoring for scalable cloud operations.
    </p>

    <!-- Key Highlights -->
    <div class="project-highlights">
      <div class="highlight-item">
        <div class="highlight-icon">📊</div>
        <div class="highlight-text">
          <strong>5,000+</strong>
          <span>Lines of Code</span>
        </div>
      </div>
      <div class="highlight-item">
        <div class="highlight-icon">⚡</div>
        <div class="highlight-text">
          <strong>90%</strong>
          <span>Faster Deployment</span>
        </div>
      </div>
      <div class="highlight-item">
        <div class="highlight-icon">💰</div>
        <div class="highlight-text">
          <strong>40%</strong>
          <span>Cost Reduction</span>
        </div>
      </div>
      <div class="highlight-item">
        <div class="highlight-icon">🧪</div>
        <div class="highlight-text">
          <strong>95%</strong>
          <span>Test Coverage</span>
        </div>
      </div>
    </div>

    <!-- Tech Stack -->
    <div class="tech-stack">
      <span class="tech-badge tech-aws">
        <i class="fab fa-aws"></i> AWS
      </span>
      <span class="tech-badge tech-terraform">
        <i class="fas fa-code-branch"></i> Terraform
      </span>
      <span class="tech-badge tech-ansible">
        <i class="fas fa-server"></i> Ansible
      </span>
      <span class="tech-badge tech-github">
        <i class="fab fa-github"></i> GitHub Actions
      </span>
      <span class="tech-badge tech-go">
        <i class="fab fa-golang"></i> Go (Terratest)
      </span>
    </div>

    <!-- Action Buttons -->
    <div class="project-actions">
      <a href="https://github.com/botbynetz/cloud-infra" 
         class="btn btn-primary" 
         target="_blank"
         rel="noopener noreferrer">
        <i class="fab fa-github"></i> View Code
      </a>
      <a href="https://github.com/botbynetz/cloud-infra/blob/main/SHOWCASE.md" 
         class="btn btn-secondary"
         target="_blank"
         rel="noopener noreferrer">
        <i class="fas fa-info-circle"></i> Details
      </a>
      <a href="https://github.com/botbynetz/cloud-infra/blob/main/docs" 
         class="btn btn-outline"
         target="_blank"
         rel="noopener noreferrer">
        <i class="fas fa-book"></i> Docs
      </a>
    </div>

    <!-- Additional Info -->
    <div class="project-meta">
      <div class="meta-item">
        <i class="fas fa-folder"></i>
        <span>50+ Files</span>
      </div>
      <div class="meta-item">
        <i class="fas fa-layer-group"></i>
        <span>3 Environments</span>
      </div>
      <div class="meta-item">
        <i class="fas fa-file-alt"></i>
        <span>15+ Documentation</span>
      </div>
      <div class="meta-item">
        <i class="fas fa-clock"></i>
        <span>10-min Setup</span>
      </div>
    </div>
  </div>
</div>
```

---

## 🎨 **CSS Styling**

```css
/* Cloud Infrastructure Project Card Styles */

.project-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 20px;
  padding: 2rem;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  position: relative;
  overflow: hidden;
}

.project-card.featured {
  border: 2px solid #ffd700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.project-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.project-badge {
  display: flex;
  gap: 10px;
  margin-bottom: 1rem;
}

.badge-featured {
  background: linear-gradient(45deg, #ffd700, #ffed4e);
  color: #1a1a1a;
  padding: 5px 15px;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 600;
  animation: pulse 2s infinite;
}

.badge-status {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  padding: 5px 15px;
  border-radius: 20px;
  font-size: 0.85rem;
}

.project-thumbnail {
  position: relative;
  border-radius: 15px;
  overflow: hidden;
  margin-bottom: 1.5rem;
  height: 250px;
}

.project-thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.5s ease;
}

.project-card:hover .project-thumbnail img {
  transform: scale(1.1);
}

.project-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(180deg, transparent 0%, rgba(0,0,0,0.8) 100%);
  display: flex;
  align-items: flex-end;
  padding: 1.5rem;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.project-card:hover .project-overlay {
  opacity: 1;
}

.project-stats {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
}

.project-stats span {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  padding: 8px 15px;
  border-radius: 20px;
  color: white;
  font-size: 0.85rem;
  font-weight: 500;
}

.project-content {
  color: white;
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.project-title {
  font-size: 1.75rem;
  font-weight: 700;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 10px;
}

.title-icon {
  font-size: 2rem;
}

.project-date {
  font-size: 0.9rem;
  opacity: 0.8;
}

.project-description {
  line-height: 1.7;
  margin-bottom: 1.5rem;
  opacity: 0.95;
}

.project-highlights {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 15px;
  margin-bottom: 1.5rem;
}

.highlight-item {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 10px;
  padding: 15px;
  text-align: center;
  transition: all 0.3s ease;
}

.highlight-item:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateY(-5px);
}

.highlight-icon {
  font-size: 2rem;
  margin-bottom: 8px;
}

.highlight-text strong {
  display: block;
  font-size: 1.5rem;
  font-weight: 700;
  margin-bottom: 3px;
}

.highlight-text span {
  font-size: 0.85rem;
  opacity: 0.9;
}

.tech-stack {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 1.5rem;
}

.tech-badge {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  color: white;
  padding: 8px 15px;
  border-radius: 20px;
  font-size: 0.9rem;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.3s ease;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.tech-badge:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: translateY(-2px);
}

.tech-badge i {
  font-size: 1rem;
}

.project-actions {
  display: flex;
  gap: 10px;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
}

.btn {
  padding: 12px 25px;
  border-radius: 25px;
  font-weight: 600;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.3s ease;
  border: none;
  cursor: pointer;
  font-size: 0.95rem;
}

.btn-primary {
  background: white;
  color: #667eea;
}

.btn-primary:hover {
  background: #f0f0f0;
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 2px solid white;
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.btn-outline {
  background: transparent;
  color: white;
  border: 2px solid rgba(255, 255, 255, 0.5);
}

.btn-outline:hover {
  background: rgba(255, 255, 255, 0.1);
  border-color: white;
}

.project-meta {
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 15px;
  padding-top: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.9rem;
  opacity: 0.9;
}

.meta-item i {
  opacity: 0.7;
}

/* Animations */
@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

/* Responsive Design */
@media (max-width: 768px) {
  .project-card {
    padding: 1.5rem;
  }

  .project-title {
    font-size: 1.5rem;
  }

  .project-highlights {
    grid-template-columns: repeat(2, 1fr);
  }

  .project-actions {
    flex-direction: column;
  }

  .btn {
    width: 100%;
    justify-content: center;
  }

  .project-meta {
    flex-direction: column;
    gap: 10px;
  }
}
```

---

## 📱 **Mobile-Optimized Version**

```html
<!-- Mobile Compact Card -->
<div class="project-card-mobile">
  <div class="mobile-header">
    <span class="mobile-icon">🏗️</span>
    <h3>Cloud Infrastructure Automation</h3>
  </div>

  <p class="mobile-desc">
    AWS automation with Terraform & Ansible. 
    Multi-env deployment, CI/CD, 95% test coverage.
  </p>

  <div class="mobile-stats">
    <span>📊 5K+ LOC</span>
    <span>⚡ 90% Faster</span>
    <span>💰 40% Savings</span>
  </div>

  <div class="mobile-tech">
    <span>AWS</span>
    <span>Terraform</span>
    <span>Ansible</span>
  </div>

  <a href="[github-url]" class="mobile-btn">
    <i class="fab fa-github"></i> View Project
  </a>
</div>
```

---

## 🎯 **Featured Section (Homepage)**

```html
<!-- Featured Project Banner (Homepage) -->
<section class="featured-project-banner">
  <div class="container">
    <div class="row align-items-center">
      <div class="col-lg-6">
        <span class="label-featured">⭐ Featured Project</span>
        <h2 class="banner-title">
          Cloud Infrastructure 
          <span class="gradient-text">Automation</span>
        </h2>
        <p class="banner-subtitle">
          Enterprise-grade AWS deployment automation demonstrating 
          modern DevOps practices and production-ready architecture.
        </p>

        <div class="quick-stats">
          <div class="stat-item">
            <div class="stat-number">5,000+</div>
            <div class="stat-label">Lines of Code</div>
          </div>
          <div class="stat-item">
            <div class="stat-number">90%</div>
            <div class="stat-label">Faster Deploy</div>
          </div>
          <div class="stat-item">
            <div class="stat-number">95%</div>
            <div class="stat-label">Test Coverage</div>
          </div>
        </div>

        <div class="banner-actions">
          <a href="[github-url]" class="btn-large btn-primary">
            <i class="fab fa-github"></i> View on GitHub
          </a>
          <a href="#projects" class="btn-large btn-outline">
            See All Projects
          </a>
        </div>
      </div>

      <div class="col-lg-6">
        <div class="project-preview">
          <img src="assets/img/cloud-infra-showcase.png" 
               alt="Cloud Infrastructure Preview"
               class="preview-image">
          
          <!-- Floating Tech Badges -->
          <div class="floating-badge badge-1">
            <i class="fab fa-aws"></i> AWS
          </div>
          <div class="floating-badge badge-2">
            <i class="fas fa-code-branch"></i> Terraform
          </div>
          <div class="floating-badge badge-3">
            <i class="fas fa-server"></i> Ansible
          </div>
        </div>
      </div>
    </div>
  </div>
</section>
```

---

## 🔗 **Navigation Link Update**

```html
<!-- Add to Navigation Menu -->
<nav>
  <ul>
    <li><a href="#home">Home</a></li>
    <li><a href="#about">About</a></li>
    <li><a href="#skills">Skills</a></li>
    <li>
      <a href="#projects" class="nav-highlight">
        Projects
        <span class="badge-new">New!</span>
      </a>
    </li>
    <li><a href="#contact">Contact</a></li>
  </ul>
</nav>
```

---

## 📊 **Stats Dashboard (About Section)**

```html
<!-- Add to About Section -->
<div class="achievement-highlight">
  <div class="achievement-icon">🏆</div>
  <h4>Recent Achievement</h4>
  <p>
    Developed enterprise-grade cloud infrastructure automation platform 
    with <strong>5,000+ lines of code</strong>, achieving 
    <strong>90% deployment time reduction</strong> and 
    <strong>40% cost optimization</strong>.
  </p>
  <a href="#projects" class="link-arrow">
    View Project Details <i class="fas fa-arrow-right"></i>
  </a>
</div>
```

---

## 🎨 **Skills Section Update**

```html
<!-- Add to Skills Section -->
<div class="skill-category">
  <h3>
    <i class="fas fa-cloud"></i> 
    Cloud & DevOps
  </h3>
  <div class="skills-grid">
    <div class="skill-item featured">
      <div class="skill-icon">
        <i class="fab fa-aws"></i>
      </div>
      <div class="skill-name">AWS</div>
      <div class="skill-level">
        <div class="skill-bar" style="width: 90%"></div>
      </div>
      <div class="skill-project">
        <a href="#cloud-infra-project">
          Used in Cloud Infrastructure Project
        </a>
      </div>
    </div>

    <div class="skill-item featured">
      <div class="skill-icon">
        <i class="fas fa-code-branch"></i>
      </div>
      <div class="skill-name">Terraform</div>
      <div class="skill-level">
        <div class="skill-bar" style="width: 85%"></div>
      </div>
      <div class="skill-project">
        <a href="#cloud-infra-project">
          5,000+ LOC in Production
        </a>
      </div>
    </div>

    <!-- Add similar for Ansible, GitHub Actions, etc. -->
  </div>
</div>
```

---

## 📸 **GitHub Stats Widget Integration**

```html
<!-- GitHub Stats Section -->
<div class="github-stats-section">
  <h3>📊 Project Statistics</h3>
  
  <div class="stats-grid">
    <!-- GitHub Readme Stats -->
    <img src="https://github-readme-stats.vercel.app/api/pin/?username=botbynetz&repo=cloud-infra&theme=radical" 
         alt="Cloud Infrastructure Stats">
    
    <!-- Languages Used -->
    <img src="https://github-readme-stats.vercel.app/api/top-langs/?username=botbynetz&layout=compact&theme=radical"
         alt="Top Languages">
  </div>
</div>
```

---

## 🎯 **SEO Meta Tags**

```html
<!-- Add to <head> section -->
<head>
  <!-- Primary Meta Tags -->
  <title>Hamdanu Edy - Cloud Infrastructure Automation | DevOps Engineer</title>
  <meta name="title" content="Hamdanu Edy - Cloud Infrastructure Automation">
  <meta name="description" content="Enterprise-grade AWS infrastructure automation using Terraform and Ansible. 5,000+ LOC, 95% test coverage, production-ready DevOps project.">
  <meta name="keywords" content="Cloud Engineer, DevOps, AWS, Terraform, Ansible, Infrastructure as Code, Portfolio">
  <meta name="author" content="Hamdanu Edy">

  <!-- Open Graph / Facebook -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://botbynetz.github.io/">
  <meta property="og:title" content="Cloud Infrastructure Automation - Hamdanu Edy">
  <meta property="og:description" content="Enterprise-grade AWS infrastructure automation with Terraform & Ansible. Production-ready DevOps project.">
  <meta property="og:image" content="https://botbynetz.github.io/assets/img/cloud-infra-og.png">

  <!-- Twitter -->
  <meta property="twitter:card" content="summary_large_image">
  <meta property="twitter:url" content="https://botbynetz.github.io/">
  <meta property="twitter:title" content="Cloud Infrastructure Automation - Hamdanu Edy">
  <meta property="twitter:description" content="Enterprise-grade AWS infrastructure automation with Terraform & Ansible.">
  <meta property="twitter:image" content="https://botbynetz.github.io/assets/img/cloud-infra-twitter.png">

  <!-- JSON-LD Structured Data -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "SoftwareSourceCode",
    "name": "Cloud Infrastructure Automation",
    "description": "Enterprise-grade AWS infrastructure automation platform",
    "author": {
      "@type": "Person",
      "name": "Hamdanu Edy",
      "url": "https://botbynetz.github.io"
    },
    "programmingLanguage": ["HCL", "YAML", "Go", "Bash"],
    "codeRepository": "https://github.com/botbynetz/cloud-infra"
  }
  </script>
</head>
```

---

## 🚀 **Call-to-Action Sections**

```html
<!-- CTA Section (Before Footer) -->
<section class="cta-section">
  <div class="container">
    <div class="cta-content">
      <h2>Interested in My Work?</h2>
      <p>
        Check out my cloud infrastructure automation project and 
        explore how I build scalable, secure, and cost-effective solutions.
      </p>
      <div class="cta-buttons">
        <a href="[github-url]" class="btn-cta-primary">
          <i class="fab fa-github"></i> View on GitHub
        </a>
        <a href="#contact" class="btn-cta-secondary">
          <i class="fas fa-envelope"></i> Get in Touch
        </a>
      </div>
    </div>
  </div>
</section>
```

---

## 📱 **JSON Resume Integration**

```json
{
  "projects": [
    {
      "name": "Cloud Infrastructure Automation",
      "description": "Enterprise-grade AWS infrastructure automation platform",
      "highlights": [
        "5,000+ lines of Infrastructure as Code (Terraform & Ansible)",
        "90% deployment time reduction (hours to 10 minutes)",
        "40% cost optimization through automation",
        "95% test coverage with automated CI/CD",
        "Multi-environment support (dev/staging/prod)",
        "Security-hardened with AWS best practices"
      ],
      "keywords": [
        "AWS",
        "Terraform",
        "Ansible",
        "DevOps",
        "CI/CD",
        "Infrastructure as Code"
      ],
      "startDate": "2024-12",
      "endDate": "2025-01",
      "url": "https://github.com/botbynetz/cloud-infra",
      "roles": ["Lead Developer", "DevOps Engineer"],
      "entity": "Personal Project",
      "type": "application"
    }
  ]
}
```

---

**🎯 Implementation Checklist:**

- [ ] Update `index.html` with project card
- [ ] Add CSS styling to `style.css`
- [ ] Create project screenshots/preview images
- [ ] Update SEO meta tags
- [ ] Add to skills section with project reference
- [ ] Update GitHub stats widget
- [ ] Add featured section to homepage
- [ ] Create mobile-responsive version
- [ ] Test all links and buttons
- [ ] Deploy and verify changes

**Your portfolio is now SHOWCASE-READY! 🚀**