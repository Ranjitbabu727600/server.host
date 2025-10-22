
#!/bin/bash

# DARKHOST-VORTEX v2.0 - Universal Smart Hosting
# Educational Purpose Only - Bug Bounty Testing
# Upgraded Version with Better Error Handling

clear
echo -e "\e[1;32m
    ██████╗  █████╗ ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ███████╗████████╗
    ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
    ██║  ██║███████║██████╔╝█████╔╝ ███████║██║   ██║███████╗   ██║   
    ██║  ██║██╔══██║██╔══██╗██╔═██╗ ██╔══██║██║   ██║╚════██║   ██║   
    ██████╔╝██║  ██║██║  ██║██║  ██╗██║  ██║╚██████╔╝███████║   ██║   
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   
\e[0m"

echo -e "\e[1;36m[*] DARKHOST-VORTEX v2.0 ACTIVATED\e[0m"
echo -e "\e[1;33m[!] Educational Purpose - Bug Bounty Lab Testing\e[0m"
echo ""

# Cleanup function
cleanup() {
    echo -e "\n\e[1;31m[!] SHUTTING DOWN...\e[0m"
    [ ! -z "$server_pid" ] && kill $server_pid 2>/dev/null
    [ ! -z "$ngrok_pid" ] && kill $ngrok_pid 2>/dev/null
    [ -d "$SERVE_DIR" ] && rm -rf "$SERVE_DIR" 2>/dev/null
    echo -e "\e[1;32m[✓] CLEANUP COMPLETE\e[0m"
    exit 0
}
trap cleanup INT TERM

# Check dependencies
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        echo -e "\e[1;31m[!] ERROR: python3 not found\e[0m"
        exit 1
    fi
}

check_dependencies

# INPUT
echo -e "\e[1;35m[+] ENTER FILE PATH OR SECRET MESSAGE:\e[0m"
echo -e "\e[1;33m    Tip: Enter file path for files, or type message directly\e[0m"
read -p ">>> " input_data

if [ -z "$input_data" ]; then
    echo -e "\e[1;31m[!] No input provided\e[0m"
    exit 1
fi

# PORT
echo ""
echo -e "\e[1;35m[+] ENTER PORT (default: 8080):\e[0m"
read -p ">>> " port
port=${port:-8080}

# Validate port
if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
    echo -e "\e[1;31m[!] Invalid port. Using 8080\e[0m"
    port=8080
fi

echo ""
echo -e "\e[1;32m[+] INITIATING HOSTING...\e[0m"
sleep 1

SERVE_DIR="/tmp/darkhost_$(date +%s)"
mkdir -p "$SERVE_DIR"
current_date=$(date '+%B %d, %Y at %I:%M %p')

# Clean path - remove quotes
input_data="${input_data%\"}"
input_data="${input_data#\"}"
input_data="${input_data#\'}"
input_data="${input_data%\'}"

# DETECT TYPE
content_type="unknown"
is_file=false

if [ -f "$input_data" ]; then
    is_file=true
    filetype=$(file -b --mime-type "$input_data")
    filename=$(basename "$input_data")
    filesize=$(du -h "$input_data" | cut -f1)
    
    # Copy file
    if ! cp "$input_data" "$SERVE_DIR/"; then
        echo -e "\e[1;31m[!] Failed to copy file\e[0m"
        cleanup
    fi
    
    # Detect content type with better matching
    case "$filetype" in
        image/*)
            content_type="image"
            ;;
        video/*)
            content_type="video"
            ;;
        audio/*)
            content_type="audio"
            ;;
        application/pdf)
            content_type="pdf"
            ;;
        application/*zip*|application/*rar*|application/*7z*|application/x-tar|application/gzip)
            content_type="archive"
            ;;
        text/*)
            content_type="text"
            ;;
        *)
            content_type="file"
            ;;
    esac
    
    echo -e "\e[1;32m[✓] Detected: ${content_type^^} FILE\e[0m"
else
    # Secret message mode
    content_type="secret"
    secret_text="$input_data"
    secret_length=${#secret_text}
    filename="secret_message.txt"
    filesize="${secret_length} chars"
    echo -e "\e[1;32m[✓] Detected: SECRET MESSAGE\e[0m"
fi

# Function to escape HTML special characters
escape_html() {
    local text="$1"
    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    text="${text//\"/&quot;}"
    text="${text//\'/&#39;}"
    echo "$text"
}

# Function to create HTML content
create_html() {
    local icon="$1"
    local type_label="$2"
    local content_html="$3"
    local button_html="$4"
    local script_html="$5"
    
    # Escape variables for safe HTML insertion
    local safe_filename=$(escape_html "$filename")
    local safe_filesize=$(escape_html "$filesize")
    local safe_type=$(escape_html "$type_label")
    local safe_date=$(escape_html "$current_date")
    
    cat > "$SERVE_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FileShare - Secure Sharing</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #1e1919;
            line-height: 1.6;
            padding: 20px;
        }
        .header {
            background: rgba(255,255,255,0.95);
            border-radius: 12px;
            border: 1px solid rgba(255,255,255,0.3);
            padding: 16px 24px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
            margin-bottom: 30px;
        }
        .logo {
            font-size: 22px;
            font-weight: 700;
            color: #667eea;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .container { max-width: 680px; margin: 0 auto; }
        .card {
            background: rgba(255,255,255,0.95);
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.15);
            overflow: hidden;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.3);
        }
        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 48px;
            text-align: center;
            color: white;
            position: relative;
            overflow: hidden;
        }
        .card-header::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            animation: pulse 4s ease-in-out infinite;
        }
        @keyframes pulse {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.1); opacity: 0.8; }
        }
        .icon { 
            font-size: 72px; 
            margin-bottom: 16px; 
            position: relative;
            z-index: 1;
            animation: bounce 2s ease-in-out infinite;
        }
        @keyframes bounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }
        .title { 
            font-size: 24px; 
            font-weight: 600; 
            margin-bottom: 8px; 
            word-break: break-word;
            position: relative;
            z-index: 1;
        }
        .subtitle { 
            font-size: 14px; 
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }
        .content-section { padding: 32px; }
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 16px 0;
            border-bottom: 1px solid #f0f2f5;
            transition: background 0.3s;
        }
        .info-row:hover {
            background: #f7f9fc;
            padding-left: 12px;
            padding-right: 12px;
            border-radius: 8px;
        }
        .info-row:last-child { border-bottom: none; }
        .info-label { color: #637381; font-size: 14px; font-weight: 500; }
        .info-value { color: #1e1919; font-size: 14px; font-weight: 600; }
        
        .media-container {
            margin: 20px 0;
            background: #000;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        .media-container img,
        .media-container video,
        .media-container audio {
            width: 100%;
            display: block;
        }
        
        .hidden-box {
            background: linear-gradient(135deg, #f7f9fc 0%, #e7e9ec 100%);
            border: 2px dashed #cbd5e0;
            border-radius: 12px;
            padding: 40px;
            margin: 20px 0;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        .hidden-box::before {
            content: '🔐';
            position: absolute;
            font-size: 120px;
            opacity: 0.1;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
        }
        .blur-text {
            filter: blur(10px);
            user-select: none;
            pointer-events: none;
            font-family: monospace;
            color: #cbd5e0;
            line-height: 2;
            font-size: 14px;
        }
        
        .btn {
            display: block;
            width: 100%;
            padding: 16px 24px;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            text-decoration: none;
            text-align: center;
            margin-bottom: 12px;
            position: relative;
            overflow: hidden;
        }
        .btn::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255,255,255,0.3);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
        }
        .btn:hover::before {
            width: 300px;
            height: 300px;
        }
        .btn span {
            position: relative;
            z-index: 1;
        }
        .btn-primary {
            background: linear-gradient(135deg, #0061ff 0%, #0052e0 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(0,97,255,0.3);
        }
        .btn-primary:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(0,97,255,0.4);
        }
        .btn-success {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(16,185,129,0.3);
        }
        .btn-success:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(16,185,129,0.4);
        }
        
        .status {
            padding: 12px;
            border-radius: 8px;
            font-size: 14px;
            text-align: center;
            display: none;
            margin-top: 12px;
            animation: slideIn 0.3s ease-out;
        }
        @keyframes slideIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .status.show {
            display: block;
            background: #d1fae5;
            color: #065f46;
            border: 1px solid #10b981;
        }
        
        .notice {
            margin-top: 20px;
            padding: 16px;
            background: linear-gradient(135deg, #fff3cd 0%, #ffe8a1 100%);
            border: 1px solid #ffd666;
            border-radius: 10px;
            font-size: 13px;
            color: #856404;
        }
        .footer { 
            text-align: center; 
            margin-top: 48px; 
            padding: 24px; 
            color: rgba(255,255,255,0.9); 
            font-size: 13px;
            background: rgba(255,255,255,0.1);
            border-radius: 12px;
            backdrop-filter: blur(10px);
        }
        
        @media (max-width: 640px) {
            .container { padding: 0 12px; }
            .card-header { padding: 32px 24px; }
            .title { font-size: 20px; }
            .icon { font-size: 56px; }
            .content-section { padding: 24px 16px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                    <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" fill="currentColor"/>
                </svg>
                FileShare Pro
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <div class="icon">${icon}</div>
                <div class="title">${safe_filename}</div>
                <div class="subtitle">${safe_filesize}</div>
            </div>
            
            <div class="content-section">
                <div class="info-row">
                    <span class="info-label">📝 Name</span>
                    <span class="info-value">${safe_filename}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">📊 Size</span>
                    <span class="info-value">${safe_filesize}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">📋 Type</span>
                    <span class="info-value">${safe_type}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">📅 Shared on</span>
                    <span class="info-value">${safe_date}</span>
                </div>
                
                ${content_html}
                
                ${button_html}
                
                <div class="notice">
                    <strong>⚠️ Security Notice:</strong> Only access files from trusted sources. Verify sender identity before downloading.
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>🔒 Shared securely via FileShare Pro</strong></p>
            <p style="margin-top: 8px; font-size: 12px; opacity: 0.8;">Educational Purpose - Bug Bounty Lab Testing</p>
        </div>
    </div>
    
    ${script_html}
</body>
</html>
EOF
}

# Generate content based on type
case "$content_type" in
    image)
        icon="🖼️"
        type_label="Image File"
        content_html="<div class='media-container'><img src='$(escape_html "$filename")' alt='Image' loading='lazy'></div>"
        button_html="<a href='$(escape_html "$filename")' download class='btn btn-primary'><span>⬇️ Download Image</span></a>"
        script_html=""
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
    video)
        icon="🎬"
        type_label="Video File"
        content_html="<div class='media-container'><video controls preload='metadata'><source src='$(escape_html "$filename")' type='$filetype'>Your browser does not support video playback.</video></div>"
        button_html="<a href='$(escape_html "$filename")' download class='btn btn-primary'><span>⬇️ Download Video</span></a>"
        script_html=""
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
    audio)
        icon="🎵"
        type_label="Audio File"
        content_html="<div class='media-container'><audio controls style='width:100%;' preload='metadata'><source src='$(escape_html "$filename")' type='$filetype'>Your browser does not support audio playback.</audio></div>"
        button_html="<a href='$(escape_html "$filename")' download class='btn btn-primary'><span>⬇️ Download Audio</span></a>"
        script_html=""
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
    pdf)
        icon="📕"
        type_label="PDF Document"
        content_html=""
        button_html="<a href='$(escape_html "$filename")' download class='btn btn-primary'><span>⬇️ Download PDF</span></a>"
        script_html=""
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
    archive)
        icon="📦"
        type_label="Archive File"
        content_html=""
        button_html="<a href='$(escape_html "$filename")' download class='btn btn-primary'><span>⬇️ Download Archive</span></a>"
        script_html=""
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
    text)
        icon="📝"
        type_label="Text File"
        content_html=""
        button_html="<a href='$(escape_html "$filename")' download class='btn btn-primary'><span>⬇️ Download Text File</span></a>"
        script_html=""
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
    secret)
        icon="🔐"
        type_label="Hidden Message"
        # Properly escape secret text for JavaScript
        secret_js=$(echo "$secret_text" | sed 's/\\/\\\\/g' | sed 's/`/\\`/g' | sed 's/\$/\\$/g' | sed "s/'/\\\\'/g")
        content_html="<div class='hidden-box'><div class='blur-text'>████████████████████████████████<br>████████████████████████████████<br>████████████████████████████████<br>████████████████████████████████<br>████████████████████████████████</div></div>"
        button_html="<button class='btn btn-success' onclick='copySecret()'><span>📋 Copy Secret Message</span></button><div id='status' class='status'></div>"
        script_html="<script>
const secretText = \`${secret_js}\`;
async function copySecret() {
    const statusEl = document.getElementById('status');
    try {
        await navigator.clipboard.writeText(secretText);
        statusEl.textContent = '✓ Secret copied to clipboard!';
        statusEl.className = 'status show';
        setTimeout(() => statusEl.className = 'status', 3000);
    } catch (err) {
        const textarea = document.createElement('textarea');
        textarea.value = secretText;
        textarea.style.position = 'fixed';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        try {
            document.execCommand('copy');
            statusEl.textContent = '✓ Secret copied!';
            statusEl.className = 'status show';
            setTimeout(() => statusEl.className = 'status', 3000);
        } catch (e) {
            statusEl.textContent = '✗ Failed to copy';
            statusEl.style.background = '#fee';
            statusEl.style.color = '#c00';
            statusEl.className = 'status show';
        }
        document.body.removeChild(textarea);
    }
}
</script>"
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
    *)
        icon="📄"
        type_label="File"
        content_html=""
        button_html="<a href='$(escape_html "$filename")' download class='btn btn-primary'><span>⬇️ Download File</span></a>"
        script_html=""
        create_html "$icon" "$type_label" "$content_html" "$button_html" "$script_html"
        ;;
esac

# START SERVER
cd "$SERVE_DIR"
python3 -m http.server $port > /dev/null 2>&1 &
server_pid=$!
sleep 2

if ! kill -0 $server_pid 2>/dev/null; then
    echo -e "\e[1;31m[!] FAILED TO START SERVER on port $port\e[0m"
    echo -e "\e[1;33m[!] Port might be in use. Try a different port.\e[0m"
    cleanup
fi

# GET IPs - IPv4 only
ip_address=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
[ -z "$ip_address" ] && ip_address=$(hostname -I | awk '{print $1}')
[ -z "$ip_address" ] && ip_address="127.0.0.1"

echo ""
echo -e "\e[1;32m╔═══════════════════════════════════════════════╗\e[0m"
echo -e "\e[1;32m║         ✓ HOSTING ACTIVE                     ║\e[0m"
echo -e "\e[1;32m╚═══════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "\e[1;36m[📁 CONTENT DETAILS]\e[0m"
echo "   Type: $type_label"
echo "   Name: $filename"
echo "   Size: $filesize"
echo ""
echo -e "\e[1;36m[📡 LOCAL ACCESS URLS]\e[0m"
echo -e "   \e[1;32mhttp://localhost:$port\e[0m"
echo -e "   \e[1;32mhttp://$ip_address:$port\e[0m"
echo ""

# NGROK with IMPROVED detection
echo -e "\e[1;35m╔═══════════════════════════════════════════════╗\e[0m"
echo -e "\e[1;35m║  Want PUBLIC URL? Activate Ngrok! (y/n)      ║\e[0m"
echo -e "\e[1;35m╚═══════════════════════════════════════════════╝\e[0m"
read -t 15 -p ">>> " ngrok_choice || ngrok_choice="n"
echo ""

if [[ "$ngrok_choice" =~ ^[Yy]$ ]]; then
    if command -v ngrok &> /dev/null; then
        echo -e "\e[1;36m[*] Starting Ngrok tunnel... Please wait\e[0m"
        
        # Start ngrok in background
        ngrok http $port --log=stdout > /tmp/ngrok_$.log 2>&1 &
        ngrok_pid=$!
        
        # Wait for ngrok to start
        echo -e "\e[1;33m[*] Waiting for tunnel to establish...\e[0m"
        sleep 6
        
        # Try to get URL - Multiple attempts
        ngrok_url=""
        max_attempts=5
        attempt=0
        
        while [ $attempt -lt $max_attempts ] && [ -z "$ngrok_url" ]; do
            attempt=$((attempt + 1))
            
            # Method 1: Check API
            if command -v curl &> /dev/null; then
                api_response=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
                ngrok_url=$(echo "$api_response" | grep -o '"public_url":"https://[^"]*' | head -1 | cut -d'"' -f4)
            fi
            
            # Method 2: Check log file if API failed
            if [ -z "$ngrok_url" ] && [ -f /tmp/ngrok_$.log ]; then
                ngrok_url=$(grep -o 'url=https://[^[:space:]]*' /tmp/ngrok_$.log | cut -d= -f2 | head -1)
            fi
            
            # If still not found, wait and retry
            if [ -z "$ngrok_url" ] && [ $attempt -lt $max_attempts ]; then
                sleep 2
            fi
        done
        
        if [ -n "$ngrok_url" ]; then
            echo ""
            echo -e "\e[1;32m╔═══════════════════════════════════════════════╗\e[0m"
            echo -e "\e[1;32m║       🌍 NGROK PUBLIC URL GENERATED          ║\e[0m"
            echo -e "\e[1;32m╚═══════════════════════════════════════════════╝\e[0m"
            echo ""
            echo -e "\e[1;32m   $ngrok_url\e[0m"
            echo ""
            echo -e "\e[1;33m   Share this URL - Works from anywhere! 🚀\e[0m"
            echo ""
        else
            echo -e "\e[1;33m[!] Could not detect Ngrok URL automatically\e[0m"
            echo -e "\e[1;33m[!] Check manually at: http://localhost:4040\e[0m"
            echo ""
        fi
        
        # Cleanup log
        rm -f /tmp/ngrok_$.log 2>/dev/null
    else
        echo -e "\e[1;31m[!] Ngrok not installed!\e[0m"
        echo -e "\e[1;33m[!] Install from: https://ngrok.com/download\e[0m"
        echo ""
    fi
fi

# CLOUDFLARED TUNNEL
echo -e "\e[1;35m╔═══════════════════════════════════════════════╗\e[0m"
echo -e "\e[1;35m║  Want Cloudflare Tunnel? (y/n)               ║\e[0m"
echo -e "\e[1;35m╚═══════════════════════════════════════════════╝\e[0m"
read -t 15 -p ">>> " cloudflared_choice || cloudflared_choice="n"
echo ""

if [[ "$cloudflared_choice" =~ ^[Yy]$ ]]; then
    cloudflared_pid=""
    
    # Check if cloudflared is installed
    if ! command -v cloudflared &> /dev/null; then
        echo -e "\e[1;33m[!] Cloudflared not found. Installing...\e[0m"
        echo ""
        
        # Detect architecture
        arch=$(uname -m)
        case "$arch" in
            x86_64)
                cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
                ;;
            aarch64|arm64)
                cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb"
                ;;
            armv7l|armhf)
                cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb"
                ;;
            *)
                echo -e "\e[1;31m[!] Unsupported architecture: $arch\e[0m"
                cloudflared_url=""
                ;;
        esac
        
        if [ -n "$cloudflared_url" ]; then
            echo -e "\e[1;36m[*] Downloading cloudflared for $arch...\e[0m"
            
            # Download to temp directory
            temp_deb="/tmp/cloudflared_$.deb"
            
            if wget -q --show-progress "$cloudflared_url" -O "$temp_deb" 2>&1; then
                echo -e "\e[1;36m[*] Installing cloudflared...\e[0m"
                
                # Try to install with dpkg
                if sudo dpkg -i "$temp_deb" > /dev/null 2>&1; then
                    echo -e "\e[1;32m[✓] Cloudflared installed successfully!\e[0m"
                    echo ""
                else
                    # Fix dependencies if needed
                    echo -e "\e[1;33m[*] Fixing dependencies...\e[0m"
                    sudo apt-get install -f -y > /dev/null 2>&1
                    echo -e "\e[1;32m[✓] Cloudflared installed successfully!\e[0m"
                    echo ""
                fi
                
                # Cleanup
                rm -f "$temp_deb"
            else
                echo -e "\e[1;31m[!] Failed to download cloudflared\e[0m"
                echo -e "\e[1;33m[!] Install manually from: https://github.com/cloudflare/cloudflared\e[0m"
                echo ""
            fi
        fi
    fi
    
    # Check again if cloudflared is available
    if command -v cloudflared &> /dev/null; then
        echo -e "\e[1;36m[*] Starting Cloudflare Tunnel... Please wait\e[0m"
        echo -e "\e[1;33m[*] Creating tunnel to localhost:$port\e[0m"
        echo ""
        
        # Start cloudflared tunnel
        cloudflared tunnel --url localhost:$port > /tmp/cloudflared_$.log 2>&1 &
        cloudflared_pid=$!
        
        # Wait for tunnel to establish
        sleep 8
        
        # Try to get the tunnel URL
        cf_url=""
        max_attempts=10
        attempt=0
        
        while [ $attempt -lt $max_attempts ] && [ -z "$cf_url" ]; do
            attempt=$((attempt + 1))
            
            if [ -f /tmp/cloudflared_$.log ]; then
                # Look for the trycloudflare.com URL in logs
                cf_url=$(grep -o 'https://[^[:space:]]*trycloudflare.com' /tmp/cloudflared_$.log | head -1)
                
                # Alternative pattern
                if [ -z "$cf_url" ]; then
                    cf_url=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/cloudflared_$.log | head -1)
                fi
            fi
            
            if [ -z "$cf_url" ] && [ $attempt -lt $max_attempts ]; then
                sleep 2
            fi
        done
        
        if [ -n "$cf_url" ]; then
            echo -e "\e[1;32m╔═══════════════════════════════════════════════╗\e[0m"
            echo -e "\e[1;32m║    ☁️  CLOUDFLARE TUNNEL ESTABLISHED         ║\e[0m"
            echo -e "\e[1;32m╚═══════════════════════════════════════════════╝\e[0m"
            echo ""
            echo -e "\e[1;32m   $cf_url\e[0m"
            echo ""
            echo -e "\e[1;33m   Free & Secure - Share anywhere! ☁️\e[0m"
            echo ""
        else
            echo -e "\e[1;33m[!] Could not detect Cloudflare URL\e[0m"
            echo -e "\e[1;33m[!] Check log: /tmp/cloudflared_$.log\e[0m"
            echo ""
        fi
    else
        echo -e "\e[1;31m[!] Cloudflared installation failed\e[0m"
        echo ""
    fi
fi

echo -e "\e[1;32m[✓] Server running on port $port\e[0m"
echo -e "\e[1;31m[!] Press Ctrl+C to stop and cleanup\e[0m"
echo ""

# Keep server running
while kill -0 $server_pid 2>/dev/null; do
    sleep 2
done

echo -e "\e[1;31m[!] Server stopped unexpectedly\e[0m"
cleanup
        
