// UnivAI Cloud Chatbot Assistant
class UnivAIChatbot {
    constructor() {
        this.isOpen = false;
        this.knowledgeBase = {
            'what-is-univai': {
                question: "What is UnivAI Cloud Platform?",
                answer: "UnivAI Cloud Platform is an enterprise infrastructure automation solution that deploys production-ready cloud infrastructure in just 10 minutes. We provide 10 enterprise modules including Self-Service Portal, AIOps, Zero Trust Security, Disaster Recovery, and more, delivering $216K-407K in annual business value."
            },
            'modules': {
                question: "What modules are available?",
                answer: "We offer 10 enterprise modules:\n• Self-Service Portal ($40-80K value)\n• AIOps Automation ($30-60K value)\n• Zero Trust Security ($35-70K value)\n• Disaster Recovery ($25-50K value)\n• Compliance Automation ($22-45K value)\n• FinOps Cost Optimization ($20-40K value)\n• Multi-Cloud Management ($18-35K value)\n• GitOps & CI/CD ($15-30K value)\n• Service Mesh ($12-25K value)\n• Observability 2.0 ($10-20K value)\n\nTotal combined value: $216K-407K annually"
            },
            'pricing': {
                question: "What are your pricing plans?",
                answer: "We offer 4 flexible pricing tiers:\n\n• FREE: $0/month - 2 modules, perfect for learning\n• STARTER: $299/month - 5 modules, ideal for startups\n• PROFESSIONAL: $799/month - 8 modules, for growing teams\n• ENTERPRISE: $1,499/month - All 10 modules, full support\n\nAll plans include AWS deployment, 24/7 support, and automatic updates. Start with our free plan today!"
            },
            'deployment': {
                question: "How long does deployment take?",
                answer: "UnivAI Cloud deploys your complete infrastructure in just 10 minutes! Our automated platform handles everything:\n\n1. Infrastructure provisioning (VPC, subnets, security groups)\n2. Kubernetes cluster setup\n3. Module deployment\n4. Security configuration\n5. Monitoring setup\n\nYou can watch the entire process through our real-time deployment visualizer."
            },
            'roi': {
                question: "What's the ROI?",
                answer: "UnivAI Cloud delivers exceptional ROI:\n\n• 40% reduction in infrastructure costs\n• 60% faster time-to-market\n• 80% reduction in manual tasks\n• Payback period: 2-4 months\n• 3-year savings: $648K-1.2M\n\nUse our ROI Calculator to estimate your specific savings based on your team size and infrastructure needs."
            },
            'support': {
                question: "What support do you provide?",
                answer: "We provide comprehensive support:\n\n• 24/7 customer support (all paid plans)\n• Dedicated Slack channel\n• Email support: support@univaicloud.com\n• Video tutorials and documentation\n• Monthly webinars\n• Enterprise: Dedicated account manager\n\nOur average response time is under 2 hours for critical issues."
            },
            'security': {
                question: "Is it secure?",
                answer: "Security is our top priority:\n\n• Zero Trust Security architecture\n• End-to-end encryption\n• SOC 2 Type II certified\n• GDPR compliant\n• ISO 27001 certified\n• Regular security audits\n• Automated vulnerability scanning\n• Multi-factor authentication\n• Role-based access control (RBAC)\n\nYour infrastructure runs in your AWS account - we never access your data."
            },
            'trial': {
                question: "Can I try it for free?",
                answer: "Yes! We offer a completely FREE plan:\n\n• Access to 2 enterprise modules\n• Deploy to AWS (your account)\n• Community support\n• No credit card required\n• No time limit\n\nUpgrade anytime to unlock more modules and features. Click 'Start Free Trial' to begin!"
            },
            'contact': {
                question: "How can I contact you?",
                answer: "We'd love to hear from you!\n\n• Email: support@univaicloud.com\n• Sales: sales@univaicloud.com\n• Visit our Contact page for the contact form\n• Join our community Slack\n• Follow us on LinkedIn and Twitter\n\nFor urgent issues, paid plans get priority 24/7 support."
            },
            'tech-stack': {
                question: "What technology do you use?",
                answer: "UnivAI Cloud is built on enterprise-grade technologies:\n\n• Cloud: AWS (primary), Azure, GCP support\n• Orchestration: Kubernetes, Istio Service Mesh\n• IaC: Terraform, AWS CDK\n• CI/CD: ArgoCD, GitOps\n• Monitoring: Prometheus, Grafana, ELK Stack\n• Security: Vault, OPA, Falco\n\nAll components are production-tested and highly scalable."
            }
        };
    }

    init() {
        this.createChatbotHTML();
        this.attachEventListeners();
        this.showWelcomeMessage();
    }

    createChatbotHTML() {
        const chatbotHTML = `
            <button class="chatbot-trigger chatbot-pulse" id="chatbotTrigger">
                <i class="fas fa-comments"></i>
            </button>
            
            <div class="chatbot-window" id="chatbotWindow">
                <div class="chatbot-header">
                    <div class="chatbot-header-content">
                        <div class="chatbot-avatar">
                            <i class="fas fa-robot"></i>
                        </div>
                        <div class="chatbot-header-text">
                            <h3>UnivAI Assistant</h3>
                            <p>Ask me anything about our platform</p>
                        </div>
                    </div>
                    <button class="chatbot-close" id="chatbotClose">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                
                <div class="chatbot-messages" id="chatbotMessages">
                    <!-- Messages will be added here -->
                </div>
                
                <div class="quick-questions" id="quickQuestions">
                    <div class="quick-questions-title">Quick Questions</div>
                    <div class="quick-questions-grid">
                        <button class="quick-question-btn" data-question="what-is-univai">
                            <i class="fas fa-info-circle"></i>
                            <span>What is UnivAI?</span>
                        </button>
                        <button class="quick-question-btn" data-question="pricing">
                            <i class="fas fa-dollar-sign"></i>
                            <span>Pricing Plans</span>
                        </button>
                        <button class="quick-question-btn" data-question="modules">
                            <i class="fas fa-cubes"></i>
                            <span>Available Modules</span>
                        </button>
                        <button class="quick-question-btn" data-question="deployment">
                            <i class="fas fa-rocket"></i>
                            <span>Deployment Time</span>
                        </button>
                        <button class="quick-question-btn" data-question="roi">
                            <i class="fas fa-chart-line"></i>
                            <span>ROI & Savings</span>
                        </button>
                        <button class="quick-question-btn" data-question="security">
                            <i class="fas fa-shield-alt"></i>
                            <span>Security</span>
                        </button>
                        <button class="quick-question-btn" data-question="trial">
                            <i class="fas fa-gift"></i>
                            <span>Free Trial</span>
                        </button>
                        <button class="quick-question-btn" data-question="contact">
                            <i class="fas fa-envelope"></i>
                            <span>Contact Us</span>
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', chatbotHTML);
    }

    attachEventListeners() {
        const trigger = document.getElementById('chatbotTrigger');
        const closeBtn = document.getElementById('chatbotClose');
        const quickQuestionBtns = document.querySelectorAll('.quick-question-btn');

        trigger.addEventListener('click', () => this.toggleChat());
        closeBtn.addEventListener('click', () => this.toggleChat());
        
        quickQuestionBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const questionKey = e.currentTarget.dataset.question;
                this.handleQuickQuestion(questionKey);
            });
        });
    }

    toggleChat() {
        this.isOpen = !this.isOpen;
        const window = document.getElementById('chatbotWindow');
        const trigger = document.getElementById('chatbotTrigger');
        
        if (this.isOpen) {
            window.classList.add('active');
            trigger.classList.add('active');
            trigger.innerHTML = '<i class="fas fa-times"></i>';
            this.scrollToBottom();
        } else {
            window.classList.remove('active');
            trigger.classList.remove('active');
            trigger.innerHTML = '<i class="fas fa-comments"></i>';
        }
    }

    showWelcomeMessage() {
        const welcomeMessage = "👋 Hi! I'm your UnivAI assistant. I can help you learn about our platform, pricing, modules, and more. Click any question below or ask me anything!";
        this.addBotMessage(welcomeMessage);
    }

    handleQuickQuestion(questionKey) {
        const qa = this.knowledgeBase[questionKey];
        if (!qa) return;

        // Show user question
        this.addUserMessage(qa.question);
        
        // Show typing indicator
        this.showTypingIndicator();
        
        // Show bot answer with faster response (300ms instead of 1000ms)
        setTimeout(() => {
            this.hideTypingIndicator();
            this.addBotMessage(qa.answer);
        }, 300);
    }

    addUserMessage(message) {
        const messagesContainer = document.getElementById('chatbotMessages');
        const messageBubble = document.createElement('div');
        messageBubble.className = 'message-bubble user';
        messageBubble.textContent = message;
        messagesContainer.appendChild(messageBubble);
        this.scrollToBottom();
    }

    addBotMessage(message) {
        const messagesContainer = document.getElementById('chatbotMessages');
        const messageBubble = document.createElement('div');
        messageBubble.className = 'message-bubble bot';
        
        // Convert line breaks to HTML
        messageBubble.innerHTML = message.replace(/\n/g, '<br>');
        
        messagesContainer.appendChild(messageBubble);
        this.scrollToBottom();
    }

    showTypingIndicator() {
        const messagesContainer = document.getElementById('chatbotMessages');
        const typingIndicator = document.createElement('div');
        typingIndicator.className = 'typing-indicator';
        typingIndicator.id = 'typingIndicator';
        typingIndicator.innerHTML = '<span></span><span></span><span></span>';
        messagesContainer.appendChild(typingIndicator);
        this.scrollToBottom();
    }

    hideTypingIndicator() {
        const typingIndicator = document.getElementById('typingIndicator');
        if (typingIndicator) {
            typingIndicator.remove();
        }
    }

    scrollToBottom() {
        const messagesContainer = document.getElementById('chatbotMessages');
        // Faster scroll with reduced delay (50ms instead of 100ms)
        setTimeout(() => {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }, 50);
    }
}

// Initialize chatbot when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const chatbot = new UnivAIChatbot();
    chatbot.init();
});
