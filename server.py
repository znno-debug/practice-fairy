#!/usr/bin/env python3
"""
연습요정 (Practice Fairy) 🧚‍♀️ - 예체능 선생님 과외노트 & 학생 연습실 로컬 서버
실행: python3 server.py
"""

import http.server
import socketserver
import webbrowser
import os
import sys
import socket

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

def get_local_ip():
    # 1. ifconfig 파싱 시도 (macOS/Linux)
    try:
        import subprocess, re
        out = subprocess.check_output(["ifconfig"], text=True)
        ips = re.findall(r'inet\s+(\d+\.\d+\.\d+\.\d+)', out)
        for ip in ips:
            if not ip.startswith("127.") and not ip.startswith("169.254."):
                return ip
    except Exception:
        pass
    # 2. UDP 소켓 시도
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        pass
    return "127.0.0.1"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Service Worker 캐시 갱신 및 PWA 헤더 지원
        if self.path.endswith('sw.js'):
            self.send_header('Service-Worker-Allowed', '/')
            self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

def run():
    os.chdir(DIRECTORY)
    # SO_REUSEADDR 설정으로 즉시 재실행 가능하도록 설정
    socketserver.TCPServer.allow_reuse_address = True
    local_ip = get_local_ip()
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        url = f"http://localhost:{PORT}/index.html"
        mobile_url = f"http://{local_ip}:{PORT}/index.html"
        print("=" * 64)
        print("🧚‍♀️ [연습요정 - 스마트 과외노트 & 연습일지 PWA] 로컬 서버 구동 시작!")
        print(f"👉 PC 브라우저 주소:     {url}")
        print(f"👉 스마트폰(동일 Wi-Fi): {mobile_url}")
        print(f"👉 학부모 리포트 샘플:   http://localhost:{PORT}/share.html?id=sample_lesson_01")
        print("=" * 64)
        print("💡 안내: 모바일 기기에서 위 '스마트폰 주소'로 사파리나 크롬에서 접속하세요.")
        print("종료하려면 터미널에서 Ctrl+C를 누르세요.\n")
        
        # 브라우저 자동 오픈
        try:
            webbrowser.open(url)
        except Exception:
            pass

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n서버를 종료합니다.")
            sys.exit(0)

if __name__ == "__main__":
    run()
