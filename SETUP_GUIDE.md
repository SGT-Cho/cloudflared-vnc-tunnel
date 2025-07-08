# Cloudflare Tunnel VNC 정확한 설정 가이드 (2025)

## 🎯 핵심 이해사항

### TCP 터널 vs HTTP 터널
- **TCP 터널**: VNC처럼 TCP 프로토콜 사용하는 서비스 (브라우저 직접 접속 ❌)
- **HTTP 터널**: 웹 서비스 (브라우저 직접 접속 ✅)

### VNC는 TCP 터널 필요
```
[VNC Viewer] → [cloudflared access tcp] → [Cloudflare] → [서버의 cloudflared] → [VNC Server]
```

## 📦 서버 측 설정 (VNC 서버가 있는 곳)

### 1. Cloudflare 대시보드에서 터널 생성

1. [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) 로그인
2. **Access > Tunnels** 이동
3. **Create a tunnel** 클릭
4. 터널 이름 입력 (예: `my-vnc-tunnel`)
5. **Save tunnel** 클릭
6. **중요**: 토큰 복사 (한 번만 표시됨!)

### 2. 서버 Docker Compose 설정

**방법 1: VNC가 같은 서버에 있을 때 (간단)**

```yaml
# docker-compose.yml
version: '3.8'

services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared-server
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}
    network_mode: host  # 로컬 VNC 접근용
```

**.env 파일**:
```bash
TUNNEL_TOKEN=eyJhIjoiYm...실제토큰여기에...
```

**방법 2: VNC가 Docker 컨테이너일 때**

```yaml
# docker-compose.yml
version: '3.8'

services:
  vnc-server:
    image: dorowu/ubuntu-desktop-lxde-vnc:latest
    container_name: vnc-server
    environment:
      - VNC_PASSWORD=${VNC_PASSWORD}
      - RESOLUTION=1920x1080
    ports:
      - "127.0.0.1:5901:5900"  # 로컬만 허용
    restart: unless-stopped

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared-server
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}
    network_mode: host  # localhost:5901 접근용
    depends_on:
      - vnc-server
```

### 3. Public Hostname 설정 (중요!)

Cloudflare 대시보드로 돌아가서:

1. 생성한 터널 클릭
2. **Configure** → **Public Hostname** 탭
3. **Add a public hostname** 클릭
4. 설정:
   ```
   Subdomain: vnc
   Domain: yourdomain.com
   Type: TCP
   URL: tcp://localhost:5901  ← 반드시 tcp:// 프로토콜 명시
   ```

### 4. 서버 시작

```bash
# 권한 설정
chmod 600 .env

# 시작
docker-compose up -d

# 로그 확인 (터널 연결 확인)
docker-compose logs -f cloudflared
```

## 💻 클라이언트 측 설정 (VNC Viewer 사용하는 곳)

### 방법 1: Docker 클라이언트 (우리가 만든 것)

**docker-compose.yml 수정**:
```yaml
version: '3.8'

services:
  vnc-tunnel:
    image: cloudflare/cloudflared:latest
    container_name: vnc-cloudflared-client
    restart: unless-stopped
    command: 
      - access
      - tcp
      - --hostname=vnc.yourdomain.com  # 서버에서 설정한 도메인
      - --url=tcp://localhost:5901
    ports:
      - "5902:5901"  # 로컬 5902 → 컨테이너 5901
    volumes:
      - cloudflared-config:/home/nonroot/.cloudflared
```

**사용법**:
```bash
# 시작
./vnc-client.sh start

# 첫 실행시 브라우저로 인증 필요
# 로그에서 URL 확인: ./vnc-client.sh logs

# VNC Viewer에서 접속
localhost:5902
```

### 방법 2: 직접 명령어 (Docker 없이)

```bash
# Cloudflared 설치
brew install cloudflare/cloudflare/cloudflared  # macOS
# 또는 https://github.com/cloudflare/cloudflared/releases

# 터널 시작
cloudflared access tcp --hostname=vnc.yourdomain.com --url=tcp://localhost:5902

# VNC Viewer에서 localhost:5902 접속
```

## 🔐 보안 설정 (선택사항)

### Zero Trust Access 정책 추가

1. **Access > Applications** → **Add an application**
2. **Self-hosted** 선택
3. 설정:
   ```
   Application name: VNC Access
   Application domain: vnc.yourdomain.com
   ```
4. **Add policy**:
   ```
   Policy name: Authorized Users
   Action: Service Auth
   Include: 
   - Emails: your-email@domain.com
   - Email domain: @yourdomain.com
   ```

### 서비스 토큰 사용 (자동화용)

```bash
# 서비스 토큰 생성
# Access > Service Tokens → Create Service Token

# 클라이언트에서 사용
cloudflared access tcp \
  --hostname=vnc.yourdomain.com \
  --url=tcp://localhost:5902 \
  --service-token-id=<id> \
  --service-token-secret=<secret>
```

## 🚨 일반적인 실수

1. **URL에 tcp:// 누락**
   - ❌ `URL: localhost:5901`
   - ✅ `URL: tcp://localhost:5901`

2. **HTTP 터널로 착각**
   - ❌ 브라우저로 vnc.yourdomain.com 접속
   - ✅ cloudflared access tcp 후 VNC Viewer 사용

3. **포트 혼동**
   - 서버 VNC: 5900 또는 5901
   - Cloudflared는 이를 tcp://localhost:포트로 접근
   - 클라이언트는 다시 로컬 포트로 노출

## 📊 디버깅

### 서버 측 확인
```bash
# 터널 상태
docker logs cloudflared-server

# VNC 포트 확인
netstat -tlnp | grep 590

# 터널 정보
docker exec cloudflared-server cloudflared tunnel info
```

### 클라이언트 측 확인
```bash
# 연결 테스트
nc -zv localhost 5902

# 로그 확인
docker logs vnc-cloudflared-client

# DNS 확인
nslookup vnc.yourdomain.com
```

## 🎯 요약

1. **서버**: cloudflared가 VNC 포트를 Cloudflare로 터널링
2. **Cloudflare**: TCP 트래픽 중계 (Public Hostname 설정)
3. **클라이언트**: cloudflared access tcp로 로컬 포트 생성
4. **VNC Viewer**: localhost:5902로 접속

**절대 잊지 말 것**:
- TCP 터널은 브라우저 접속 불가
- URL에 반드시 `tcp://` 프로토콜 명시
- 클라이언트도 cloudflared 필요