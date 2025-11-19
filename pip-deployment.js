// Picture-in-Picture for Deployment Console and Workflow
class DeploymentPiP {
    constructor() {
        this.pipWindows = {
            console: null,
            workflow: null
        };
        this.updateIntervals = {
            console: null,
            workflow: null
        };
        this.init();
    }

    init() {
        // Console PiP Button
        const consolePipBtn = document.getElementById('consolePipBtn');
        if (consolePipBtn) {
            consolePipBtn.addEventListener('click', () => this.togglePiP('console'));
        }

        // Workflow PiP Button
        const workflowPipBtn = document.getElementById('workflowPipBtn');
        if (workflowPipBtn) {
            workflowPipBtn.addEventListener('click', () => this.togglePiP('workflow'));
        }

        // Handle page visibility change
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                // Auto-enable PiP when user leaves page (optional)
                console.log('Page hidden - PiP mode available');
            }
        });

        // Handle beforeunload - keep PiP alive
        window.addEventListener('beforeunload', (e) => {
            if (this.pipWindows.console || this.pipWindows.workflow) {
                const confirmMsg = 'You have active Picture-in-Picture windows. They will close if you leave.';
                e.returnValue = confirmMsg;
                return confirmMsg;
            }
        });
    }

    togglePiP(type) {
        if (this.pipWindows[type]) {
            this.closePiP(type);
        } else {
            this.openPiP(type);
        }
    }

    openPiP(type) {
        const button = document.getElementById(`${type}PipBtn`);
        
        if (type === 'console') {
            this.openConsolePiP();
        } else if (type === 'workflow') {
            this.openWorkflowPiP();
        }

        if (button) {
            button.classList.add('active');
            button.innerHTML = '<i class="fas fa-compress"></i>';
            button.title = 'Disable Picture-in-Picture';
        }
    }

    openConsolePiP() {
        // Create PiP window
        const width = 600;
        const height = 500;
        const left = window.screen.width - width - 50;
        const top = window.screen.height - height - 100;

        const pipWindow = window.open(
            '',
            'Console PiP',
            `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=no,status=no,toolbar=no,menubar=no,location=no`
        );

        if (!pipWindow) {
            alert('Please allow pop-ups to enable Picture-in-Picture mode');
            return;
        }

        this.pipWindows.console = pipWindow;

        // Build PiP window content
        pipWindow.document.write(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Deployment Console - PiP</title>
                <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
                <style>
                    * {
                        margin: 0;
                        padding: 0;
                        box-sizing: border-box;
                    }
                    body {
                        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                        color: #fff;
                        overflow: hidden;
                        height: 100vh;
                        display: flex;
                        flex-direction: column;
                    }
                    .pip-header {
                        background: rgba(0, 0, 0, 0.3);
                        padding: 12px 16px;
                        display: flex;
                        align-items: center;
                        justify-content: space-between;
                        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
                        backdrop-filter: blur(10px);
                    }
                    .pip-title {
                        display: flex;
                        align-items: center;
                        gap: 10px;
                        font-size: 16px;
                        font-weight: 600;
                    }
                    .pip-title i {
                        color: #00bfff;
                        font-size: 18px;
                    }
                    .pip-controls {
                        display: flex;
                        gap: 8px;
                    }
                    .pip-control-btn {
                        background: rgba(255, 255, 255, 0.1);
                        border: 1px solid rgba(255, 255, 255, 0.2);
                        color: #fff;
                        width: 32px;
                        height: 32px;
                        border-radius: 6px;
                        cursor: pointer;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        transition: all 0.2s ease;
                    }
                    .pip-control-btn:hover {
                        background: rgba(255, 255, 255, 0.2);
                        transform: scale(1.05);
                    }
                    .pip-control-btn.minimize {
                        color: #ffa500;
                    }
                    .pip-control-btn.close {
                        color: #ff4444;
                    }
                    .pip-content {
                        flex: 1;
                        overflow: hidden;
                        display: flex;
                        flex-direction: column;
                        padding: 16px;
                    }
                    .progress-section {
                        margin-bottom: 16px;
                    }
                    .progress-bar {
                        width: 100%;
                        height: 6px;
                        background: rgba(255, 255, 255, 0.1);
                        border-radius: 50px;
                        overflow: hidden;
                        margin-bottom: 8px;
                    }
                    .progress-fill {
                        height: 100%;
                        background: linear-gradient(90deg, #0066ff, #00bfff);
                        width: 0%;
                        transition: width 0.3s ease;
                    }
                    .progress-text {
                        font-size: 12px;
                        color: rgba(255, 255, 255, 0.7);
                        display: flex;
                        justify-content: space-between;
                        margin-bottom: 8px;
                    }
                    .console {
                        background: rgba(0, 0, 0, 0.4);
                        border-radius: 8px;
                        padding: 12px;
                        font-family: 'Courier New', monospace;
                        font-size: 12px;
                        color: #00ff00;
                        flex: 1;
                        overflow-y: auto;
                        line-height: 1.5;
                        border: 1px solid rgba(255, 255, 255, 0.1);
                    }
                    .console::-webkit-scrollbar {
                        width: 6px;
                    }
                    .console::-webkit-scrollbar-track {
                        background: rgba(255, 255, 255, 0.05);
                        border-radius: 3px;
                    }
                    .console::-webkit-scrollbar-thumb {
                        background: rgba(255, 255, 255, 0.2);
                        border-radius: 3px;
                    }
                    .console::-webkit-scrollbar-thumb:hover {
                        background: rgba(255, 255, 255, 0.3);
                    }
                    .console-line {
                        margin-bottom: 6px;
                        animation: fadeIn 0.3s ease;
                    }
                    @keyframes fadeIn {
                        from { opacity: 0; transform: translateY(3px); }
                        to { opacity: 1; transform: translateY(0); }
                    }
                    .console-line.info { color: #00bfff; }
                    .console-line.success { color: #00ff00; }
                    .console-line.warning { color: #ffa500; }
                    .console-line.error { color: #ff4444; }
                    .console-line.timestamp {
                        color: #888;
                        font-size: 10px;
                    }
                    .live-indicator {
                        display: flex;
                        align-items: center;
                        gap: 6px;
                        font-size: 11px;
                        color: rgba(255, 255, 255, 0.6);
                        text-transform: uppercase;
                        letter-spacing: 0.5px;
                    }
                    .live-dot {
                        width: 8px;
                        height: 8px;
                        background: #00ff00;
                        border-radius: 50%;
                        animation: pulse 2s infinite;
                    }
                    @keyframes pulse {
                        0%, 100% { opacity: 1; transform: scale(1); }
                        50% { opacity: 0.5; transform: scale(0.9); }
                    }
                </style>
            </head>
            <body>
                <div class="pip-header">
                    <div class="pip-title">
                        <i class="fas fa-terminal"></i>
                        <span>Deployment Console</span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div class="live-indicator">
                            <div class="live-dot"></div>
                            <span>Live</span>
                        </div>
                        <div class="pip-controls">
                            <button class="pip-control-btn minimize" onclick="window.blur()" title="Minimize">
                                <i class="fas fa-minus"></i>
                            </button>
                            <button class="pip-control-btn close" onclick="window.close()" title="Close">
                                <i class="fas fa-times"></i>
                            </button>
                        </div>
                    </div>
                </div>
                <div class="pip-content">
                    <div class="progress-section">
                        <div class="progress-bar">
                            <div class="progress-fill" id="pipProgressFill"></div>
                        </div>
                        <div class="progress-text">
                            <span id="pipProgressStatus">Waiting to start...</span>
                            <span id="pipProgressPercent">0%</span>
                        </div>
                    </div>
                    <div class="console" id="pipConsole">
                        <div class="console-line info">
                            <i class="fas fa-info-circle"></i> UnivAI Cloud Deployment Console v2.0 (PiP Mode)
                        </div>
                        <div class="console-line">
                            <i class="fas fa-check"></i> Picture-in-Picture mode activated
                        </div>
                        <div class="console-line timestamp">
                            Monitoring deployment in real-time...
                        </div>
                    </div>
                </div>
            </body>
            </html>
        `);

        pipWindow.document.close();

        // Auto-update console content
        this.updateIntervals.console = setInterval(() => {
            this.syncConsoleContent(pipWindow);
        }, 500);

        // Handle PiP window close
        pipWindow.addEventListener('beforeunload', () => {
            this.closePiP('console');
        });
    }

    openWorkflowPiP() {
        const width = 700;
        const height = 400;
        const left = window.screen.width - width - 50;
        const top = 50;

        const pipWindow = window.open(
            '',
            'Workflow PiP',
            `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=no,status=no,toolbar=no,menubar=no,location=no`
        );

        if (!pipWindow) {
            alert('Please allow pop-ups to enable Picture-in-Picture mode');
            return;
        }

        this.pipWindows.workflow = pipWindow;

        pipWindow.document.write(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Deployment Workflow - PiP</title>
                <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
                <style>
                    * {
                        margin: 0;
                        padding: 0;
                        box-sizing: border-box;
                    }
                    body {
                        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                        color: #fff;
                        overflow: hidden;
                        height: 100vh;
                        display: flex;
                        flex-direction: column;
                    }
                    .pip-header {
                        background: rgba(0, 0, 0, 0.3);
                        padding: 12px 16px;
                        display: flex;
                        align-items: center;
                        justify-content: space-between;
                        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
                        backdrop-filter: blur(10px);
                    }
                    .pip-title {
                        display: flex;
                        align-items: center;
                        gap: 10px;
                        font-size: 16px;
                        font-weight: 600;
                    }
                    .pip-title i {
                        color: #00bfff;
                        font-size: 18px;
                    }
                    .pip-controls {
                        display: flex;
                        gap: 8px;
                    }
                    .pip-control-btn {
                        background: rgba(255, 255, 255, 0.1);
                        border: 1px solid rgba(255, 255, 255, 0.2);
                        color: #fff;
                        width: 32px;
                        height: 32px;
                        border-radius: 6px;
                        cursor: pointer;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        transition: all 0.2s ease;
                    }
                    .pip-control-btn:hover {
                        background: rgba(255, 255, 255, 0.2);
                        transform: scale(1.05);
                    }
                    .pip-control-btn.minimize {
                        color: #ffa500;
                    }
                    .pip-control-btn.close {
                        color: #ff4444;
                    }
                    .pip-content {
                        flex: 1;
                        overflow: hidden;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        padding: 20px;
                    }
                    .workflow-canvas {
                        display: flex;
                        align-items: center;
                        gap: 12px;
                        overflow-x: auto;
                        padding: 20px;
                        width: 100%;
                    }
                    .workflow-node {
                        min-width: 80px;
                        background: rgba(255, 255, 255, 0.05);
                        border: 2px solid rgba(255, 255, 255, 0.1);
                        border-radius: 12px;
                        padding: 12px;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        gap: 8px;
                        transition: all 0.3s ease;
                    }
                    .workflow-node.running {
                        border-color: #00bfff;
                        background: rgba(0, 191, 255, 0.1);
                        box-shadow: 0 0 20px rgba(0, 191, 255, 0.3);
                        animation: pulse-node 2s infinite;
                    }
                    .workflow-node.success {
                        border-color: #00ff00;
                        background: rgba(0, 255, 0, 0.1);
                    }
                    .workflow-node.error {
                        border-color: #ff4444;
                        background: rgba(255, 68, 68, 0.1);
                    }
                    @keyframes pulse-node {
                        0%, 100% { transform: scale(1); }
                        50% { transform: scale(1.05); }
                    }
                    .node-icon {
                        width: 40px;
                        height: 40px;
                        background: rgba(255, 255, 255, 0.1);
                        border-radius: 50%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 18px;
                        color: #00bfff;
                    }
                    .workflow-node.running .node-icon {
                        animation: spin 2s linear infinite;
                    }
                    @keyframes spin {
                        100% { transform: rotate(360deg); }
                    }
                    .node-title {
                        font-size: 12px;
                        font-weight: 600;
                        text-align: center;
                    }
                    .node-subtitle {
                        font-size: 10px;
                        color: rgba(255, 255, 255, 0.6);
                        text-align: center;
                    }
                    .workflow-connector {
                        width: 30px;
                        height: 2px;
                        background: rgba(255, 255, 255, 0.2);
                        position: relative;
                    }
                    .workflow-connector.active {
                        background: #00bfff;
                        box-shadow: 0 0 10px rgba(0, 191, 255, 0.5);
                    }
                    .live-indicator {
                        display: flex;
                        align-items: center;
                        gap: 6px;
                        font-size: 11px;
                        color: rgba(255, 255, 255, 0.6);
                        text-transform: uppercase;
                        letter-spacing: 0.5px;
                    }
                    .live-dot {
                        width: 8px;
                        height: 8px;
                        background: #00ff00;
                        border-radius: 50%;
                        animation: pulse 2s infinite;
                    }
                    @keyframes pulse {
                        0%, 100% { opacity: 1; transform: scale(1); }
                        50% { opacity: 0.5; transform: scale(0.9); }
                    }
                </style>
            </head>
            <body>
                <div class="pip-header">
                    <div class="pip-title">
                        <i class="fas fa-project-diagram"></i>
                        <span>Deployment Workflow</span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div class="live-indicator">
                            <div class="live-dot"></div>
                            <span>Live</span>
                        </div>
                        <div class="pip-controls">
                            <button class="pip-control-btn minimize" onclick="window.blur()" title="Minimize">
                                <i class="fas fa-minus"></i>
                            </button>
                            <button class="pip-control-btn close" onclick="window.close()" title="Close">
                                <i class="fas fa-times"></i>
                            </button>
                        </div>
                    </div>
                </div>
                <div class="pip-content">
                    <div class="workflow-canvas" id="pipWorkflowCanvas">
                        <div class="workflow-node" id="pip-node-start">
                            <div class="node-icon"><i class="fas fa-play"></i></div>
                            <div class="node-title">Start</div>
                            <div class="node-subtitle">Initialize</div>
                        </div>
                        <div class="workflow-connector" id="pip-connector-1"></div>
                        <div class="workflow-node" id="pip-node-validate">
                            <div class="node-icon"><i class="fas fa-check-double"></i></div>
                            <div class="node-title">Validate</div>
                            <div class="node-subtitle">Check</div>
                        </div>
                        <div class="workflow-connector" id="pip-connector-2"></div>
                        <div class="workflow-node" id="pip-node-provision">
                            <div class="node-icon"><i class="fas fa-server"></i></div>
                            <div class="node-title">Provision</div>
                            <div class="node-subtitle">Create</div>
                        </div>
                        <div class="workflow-connector" id="pip-connector-3"></div>
                        <div class="workflow-node" id="pip-node-modules">
                            <div class="node-icon"><i class="fas fa-cubes"></i></div>
                            <div class="node-title">Deploy</div>
                            <div class="node-subtitle">Install</div>
                        </div>
                        <div class="workflow-connector" id="pip-connector-4"></div>
                        <div class="workflow-node" id="pip-node-configure">
                            <div class="node-icon"><i class="fas fa-cog"></i></div>
                            <div class="node-title">Configure</div>
                            <div class="node-subtitle">Apply</div>
                        </div>
                        <div class="workflow-connector" id="pip-connector-5"></div>
                        <div class="workflow-node" id="pip-node-test">
                            <div class="node-icon"><i class="fas fa-vial"></i></div>
                            <div class="node-title">Test</div>
                            <div class="node-subtitle">Verify</div>
                        </div>
                        <div class="workflow-connector" id="pip-connector-6"></div>
                        <div class="workflow-node" id="pip-node-complete">
                            <div class="node-icon"><i class="fas fa-check"></i></div>
                            <div class="node-title">Complete</div>
                            <div class="node-subtitle">Done</div>
                        </div>
                    </div>
                </div>
            </body>
            </html>
        `);

        pipWindow.document.close();

        // Auto-update workflow
        this.updateIntervals.workflow = setInterval(() => {
            this.syncWorkflowContent(pipWindow);
        }, 500);

        // Handle PiP window close
        pipWindow.addEventListener('beforeunload', () => {
            this.closePiP('workflow');
        });
    }

    syncConsoleContent(pipWindow) {
        if (!pipWindow || pipWindow.closed) {
            this.closePiP('console');
            return;
        }

        try {
            // Sync progress
            const progressFill = document.getElementById('progress-fill');
            const progressStatus = document.getElementById('progress-status');
            const progressPercent = document.getElementById('progress-percent');

            if (progressFill && pipWindow.document.getElementById('pipProgressFill')) {
                const width = progressFill.style.width;
                pipWindow.document.getElementById('pipProgressFill').style.width = width;
            }
            if (progressStatus && pipWindow.document.getElementById('pipProgressStatus')) {
                pipWindow.document.getElementById('pipProgressStatus').textContent = progressStatus.textContent;
            }
            if (progressPercent && pipWindow.document.getElementById('pipProgressPercent')) {
                pipWindow.document.getElementById('pipProgressPercent').textContent = progressPercent.textContent;
            }

            // Sync console logs
            const console = document.getElementById('console');
            const pipConsole = pipWindow.document.getElementById('pipConsole');
            
            if (console && pipConsole) {
                pipConsole.innerHTML = console.innerHTML;
                pipConsole.scrollTop = pipConsole.scrollHeight;
            }
        } catch (error) {
            console.error('Error syncing console:', error);
        }
    }

    syncWorkflowContent(pipWindow) {
        if (!pipWindow || pipWindow.closed) {
            this.closePiP('workflow');
            return;
        }

        try {
            // Sync workflow nodes state
            const nodes = ['start', 'validate', 'provision', 'modules', 'configure', 'test', 'complete'];
            
            nodes.forEach(nodeName => {
                const mainNode = document.getElementById(`node-${nodeName}`);
                const pipNode = pipWindow.document.getElementById(`pip-node-${nodeName}`);
                
                if (mainNode && pipNode) {
                    // Copy classes
                    pipNode.className = mainNode.className.replace('workflow-node', 'workflow-node');
                }
            });

            // Sync connectors
            for (let i = 1; i <= 6; i++) {
                const mainConnector = document.getElementById(`connector-${i}`);
                const pipConnector = pipWindow.document.getElementById(`pip-connector-${i}`);
                
                if (mainConnector && pipConnector) {
                    pipConnector.className = mainConnector.className;
                }
            }
        } catch (error) {
            console.error('Error syncing workflow:', error);
        }
    }

    closePiP(type) {
        const button = document.getElementById(`${type}PipBtn`);
        
        if (this.pipWindows[type] && !this.pipWindows[type].closed) {
            this.pipWindows[type].close();
        }
        
        this.pipWindows[type] = null;

        if (this.updateIntervals[type]) {
            clearInterval(this.updateIntervals[type]);
            this.updateIntervals[type] = null;
        }

        if (button) {
            button.classList.remove('active');
            button.innerHTML = '<i class="fas fa-external-link-alt"></i>';
            button.title = 'Enable Picture-in-Picture';
        }
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.deploymentPiP = new DeploymentPiP();
    console.log('🎬 Deployment PiP initialized');
});
