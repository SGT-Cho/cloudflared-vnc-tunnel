# 다중 프로필 사용 예시

## 프로필별 환경 설정 파일 생성

### 개발 서버용 (.env.dev)
```bash
VNC_HOSTNAME=vnc-dev.yourdomain.com
VNC_LOCAL_PORT=5902
TUNNEL_LOGLEVEL=debug
```

### 프로덕션 서버용 (.env.prod)
```bash
VNC_HOSTNAME=vnc-prod.yourdomain.com
VNC_LOCAL_PORT=5903
TUNNEL_LOGLEVEL=info
```

### 테스트 서버용 (.env.test)
```bash
VNC_HOSTNAME=vnc-test.yourdomain.com
VNC_LOCAL_PORT=5904
TUNNEL_LOGLEVEL=warn
```

## 사용 방법

```bash
# 각 프로필로 터널 시작
./vnc-client.sh start dev
./vnc-client.sh start prod
./vnc-client.sh start test

# 각 프로필 상태 확인
./vnc-client.sh status dev
./vnc-client.sh status prod
./vnc-client.sh status test

# 특정 프로필 중지
./vnc-client.sh stop dev

# 모든 프로필 확인
docker ps --filter "name=vnc-tunnel-"
```

## VNC 접속

- 개발 서버: localhost:5902
- 프로덕션 서버: localhost:5903
- 테스트 서버: localhost:5904

## 주의사항

- 각 프로필은 독립적으로 실행됨
- 포트가 겹치지 않도록 주의
- 프로필별로 별도의 인증 필요