#!/bin/bash

# DARKHOST-VORTEX - Universal Smart Hosting
# Educational Purpose Only - Bug Bounty Testing

clear
echo -e "\e[1;32m
    ██████╗  █████╗ ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ███████╗████████╗
    ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
    ██║  ██║███████║██████╔╝█████╔╝ ███████║██║   ██║███████╗   ██║   
    ██║  ██║██╔══██║██╔══██╗██╔═██╗ ██╔══██║██║   ██║╚════██║   ██║   
    ██████╔╝██║  ██║██║  ██║██║  ██╗██║  ██║╚██████╔╝███████║   ██║   
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   
\e[0m"

echo -e "\e[1;36m[*] DARKHOST-VORTEX ACTIVATED\e[0m"
echo -e "\e[1;33m[!] Educational Purpose - Bug Bounty Lab Testing\e[0m"
echo ""

# Cleanup
cleanup() {
    echo -e "\n\e[1;31m[!] SHUTTING DOWN...\e[0m"
    kill $server_pid 2>/dev/null
    kill $ngrok_pid 2>/dev/null
    rm -rf "$SERVE_DIR" 2>/dev/null
    echo -e "\e[1;32m[✓] CLEANUP COMPLETE\e[0m"
    exit 0
}
trap cleanup INT TERM

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

echo ""
echo -e "\e[1;32m[+] INITIATING HOSTING...\e[0m"
sleep 1

SERVE_DIR="/tmp/darkhost_$(date +%s)"
mkdir -p "$SERVE_DIR"
current_date=$(date '+%B %d, %Y at %I:%M %p')

# Clean path
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
    cp "$input_data" "$SERVE_DIR/"
    
    # Detect content type
    case "$filetype" in
        image/*) content_type="image" ;;
        video/*) content_type="video" ;;
        audio/*) content_type="audio" ;;
        application/pdf) content_type="pdf" ;;
        application/*zip*|application/*rar*|application/*7z*) content_type="archive" ;;
        *) content_type="file" ;;
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

# CREATE HTML
cat > "$SERVE_DIR/index.html" << 'HTMLEOF'
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
            background: #f7f9fc;
            color: #1e1919;
            line-height: 1.6;
        }
        .header {
            background: #fff;
            border-bottom: 1px solid #e7e9ec;
            padding: 16px 24px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
        }
        .logo {
            font-size: 22px;
            font-weight: 700;
            color: #0061ff;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .container { max-width: 680px; margin: 60px auto; padding: 0 24px; }
        .card {
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 48px;
            text-align: center;
            color: white;
        }
        .icon { font-size: 72px; margin-bottom: 16px; }
        .title { font-size: 24px; font-weight: 600; margin-bottom: 8px; word-break: break-word; }
        .subtitle { font-size: 14px; opacity: 0.9; }
        .content-section { padding: 32px; }
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 16px 0;
            border-bottom: 1px solid #f0f2f5;
        }
        .info-row:last-child { border-bottom: none; }
        .info-label { color: #637381; font-size: 14px; font-weight: 500; }
        .info-value { color: #1e1919; font-size: 14px; font-weight: 500; }
        
        .media-container {
            margin: 20px 0;
            background: #000;
            border-radius: 8px;
            overflow: hidden;
        }
        .media-container img,
        .media-container video,
        .media-container audio {
            width: 100%;
            display: block;
        }
        
        .hidden-box {
            background: #f7f9fc;
            border: 2px dashed #cbd5e0;
            border-radius: 8px;
            padding: 40px;
            margin: 20px 0;
            text-align: center;
        }
        .blur-text {
            filter: blur(10px);
            user-select: none;
            pointer-events: none;
            font-family: monospace;
            color: #cbd5e0;
            line-height: 2;
        }
        
        .btn {
            display: block;
            width: 100%;
            padding: 16px 24px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            text-align: center;
            margin-bottom: 12px;
        }
        .btn-primary {
            background: #0061ff;
            color: white;
        }
        .btn-primary:hover {
            background: #0052e0;
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(0,97,255,0.24);
        }
        .btn-success {
            background: #10b981;
            color: white;
        }
        .btn-success:hover {
            background: #059669;
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(16,185,129,0.24);
        }
        
        .status {
            padding: 12px;
            border-radius: 6px;
            font-size: 14px;
            text-align: center;
            display: none;
            margin-top: 12px;
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
            background: #fff3cd;
            border: 1px solid #ffd666;
            border-radius: 8px;
            font-size: 13px;
            color: #856404;
        }
        .footer { text-align: center; margin-top: 48px; padding: 24px; color: #637381; font-size: 13px; }
        
        @media (max-width: 640px) {
            .container { margin: 24px auto; }
            .card-header { padding: 32px 24px; }
            .title { font-size: 20px; }
            .icon { font-size: 56px; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" fill="currentColor"/>
            </svg>
            FileShare
        </div>
    </div>
    
    <div class="container">
        <div class="card">
            <div class="card-header">
                <div class="icon">ICON_PLACEHOLDER</div>
                <div class="title">TITLE_PLACEHOLDER</div>
                <div class="subtitle">SIZE_PLACEHOLDER</div>
            </div>
            
            <div class="content-section">
                <div class="info-row">
                    <span class="info-label">Name</span>
                    <span class="info-value">NAME_PLACEHOLDER</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Size</span>
                    <span class="info-value">SIZE_PLACEHOLDER</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Type</span>
                    <span class="info-value">TYPE_PLACEHOLDER</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Shared on</span>
                    <span class="info-value">DATE_PLACEHOLDER</span>
                </div>
                
                CONTENT_PLACEHOLDER
                
                BUTTON_PLACEHOLDER
                
                <div class="notice">
                    <strong>⚠️ Security:</strong> Only access files from trusted sources.
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>Shared securely via FileShare</p>
            <p style="margin-top: 8px; font-size: 12px;">Educational Purpose - Bug Bounty Lab Testing</p>
        </div>
    </div>
    
    SCRIPT_PLACEHOLDER
</body>
</html>
HTMLEOF

# CUSTOMIZE HTML BASED ON TYPE
case "$content_type" in
    image)
        icon="🖼️"
        type_label="Image File"
        content_html="<div class='media-container'><img src='$filename' alt='Image'></div>"
        button_html="<a href='$filename' download class='btn btn-primary'>⬇️ Download Image</a>"
        script_html=""
        ;;
    video)
        icon="🎬"
        type_label="Video File"
        content_html="<div class='media-container'><video controls><source src='$filename'></video></div>"
        button_html="<a href='$filename' download class='btn btn-primary'>⬇️ Download Video</a>"
        script_html=""
        ;;
    audio)
        icon="🎵"
        type_label="Audio File"
        content_html="<div class='media-container'><audio controls style='width:100%;'><source src='$filename'></audio></div>"
        button_html="<a href='$filename' download class='btn btn-primary'>⬇️ Download Audio</a>"
        script_html=""
        ;;
    pdf)
        icon="📕"
        type_label="PDF Document"
        content_html=""
        button_html="<a href='$filename' download class='btn btn-primary'>⬇️ Download PDF</a>"
        script_html=""
        ;;
    archive)
        icon="📦"
        type_label="Archive File"
        content_html=""
        button_html="<a href='$filename' download class='btn btn-primary'>⬇️ Download Archive</a>"
        script_html=""
        ;;
    secret)
        icon="🔐"
        type_label="Hidden Message"
        secret_escaped=$(echo "$secret_text" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | awk '{printf "%s\\n", $0}')
        content_html="<div class='hidden-box'><div class='blur-text'>████████████████████████████████<br>████████████████████████████████<br>████████████████████████████████<br>████████████████████████████████<br>████████████████████████████████</div></div>"
        button_html="<button class='btn btn-success' onclick='copySecret()'>📋 Copy Secret Message</button><div id='status' class='status'></div><textarea id='secret' style='position:absolute;left:-9999px;'>$secret_escaped</textarea>"
        script_html="<script>async function copySecret(){const t=document.getElementById('secret'),s=document.getElementById('status');try{await navigator.clipboard.writeText(t.value);s.textContent='✓ Copied to clipboard!';s.className='status show';setTimeout(()=>s.className='status',3000)}catch(e){t.style.position='static';t.select();document.execCommand('copy');t.style.position='absolute';s.textContent='✓ Copied!';s.className='status show'}}</script>"
        ;;
    *)
        icon="📄"
        type_label="File"
        content_html=""
        button_html="<a href='$filename' download class='btn btn-primary'>⬇️ Download File</a>"
        script_html=""
        ;;
esac

# Replace placeholders
sed -i "s|ICON_PLACEHOLDER|$icon|g" "$SERVE_DIR/index.html"
sed -i "s|TITLE_PLACEHOLDER|$filename|g" "$SERVE_DIR/index.html"
sed -i "s|NAME_PLACEHOLDER|$filename|g" "$SERVE_DIR/index.html"
sed -i "s|SIZE_PLACEHOLDER|$filesize|g" "$SERVE_DIR/index.html"
sed -i "s|TYPE_PLACEHOLDER|$type_label|g" "$SERVE_DIR/index.html"
sed -i "s|DATE_PLACEHOLDER|$current_date|g" "$SERVE_DIR/index.html"
sed -i "s|CONTENT_PLACEHOLDER|$content_html|g" "$SERVE_DIR/index.html"
sed -i "s|BUTTON_PLACEHOLDER|$button_html|g" "$SERVE_DIR/index.html"
sed -i "s|SCRIPT_PLACEHOLDER|$script_html|g" "$SERVE_DIR/index.html"

# START SERVER
cd "$SERVE_DIR"
python3 -m http.server $port > /dev/null 2>&1 &
server_pid=$!
sleep 2

if ! kill -0 $server_pid 2>/dev/null; then
    echo -e "\e[1;31m[!] FAILED TO START SERVER\e[0m"
    exit 1
fi

# GET IPs
ip_address=$(hostname -I | awk '{print $1}')
public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")

echo ""
echo -e "\e[1;32m╔═══════════════════════════════════════════════╗\e[0m"
echo -e "\e[1;32m║         ✓ HOSTING ACTIVE                     ║\e[0m"
echo -e "\e[1;32m╚═══════════════════════════════════════════════╝\e[0m"
echo ""
echo -e "\e[1;36m[📁 CONTENT]\e[0m"
echo "   Type: $type_label"
echo "   Name: $filename"
echo "   Size: $filesize"
echo ""
echo -e "\e[1;36m[📡 ACCESS URLS]\e[0m"
echo "   Local:   http://$ip_address:$port"
echo "   Network: http://$public_ip:$port"
echo ""

# NGROK
echo -e "\e[1;35m[?] Activate Ngrok? (y/n):\e[0m"
read -p ">>> " ngrok_choice

if [[ "$ngrok_choice" =~ ^[Yy]$ ]]; then
    if command -v ngrok &> /dev/null; then
        echo -e "\e[1;36m[*] Starting Ngrok...\e[0m"
        ngrok http $port > /dev/null 2>&1 &
        ngrok_pid=$!
        sleep 5
        
        if command -v jq &> /dev/null; then
            ngrok_url=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null)
            if [ "$ngrok_url" != "null" ] && [ -n "$ngrok_url" ]; then
                echo -e "\e[1;32m[🔗 NGROK] $ngrok_url\e[0m"
            fi
        fi
    fi
fi

echo ""
echo -e "\e[1;32m[✓] Server running on port $port\e[0m"
echo -e "\e[1;33m[!] Press Ctrl+C to stop\e[0m"
echo ""

while true; do sleep 1; done