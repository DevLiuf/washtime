# washtime

### **앱 주요 기능**

1. **QR 코드 스캔**
   - 기기의 QR 코드를 스캔하여 기기 ID를 서버로 전송.
   - 스캔 시 이용자 ID, 기기 ID, 시작 시간 등이 서버에 저장됨.
2. **기기 상태 관리**
   - 서버는 각 기기의 사용 상태를 관리(사용 중/미사용 중).
   - 앱 대시보드에서 실시간으로 기기의 사용 상태를 확인 가능.
3. **사용 종료 알림**
   - 이용자가 설정한 사용 종료 시간에 따라:
     - 종료 5분 전에 알람 발송(푸시 알림).
     - 대시보드에 '종료 5분 전' 경고 표시.
4. **기기 사용 종료 처리**
   - 이용자가 종료 버튼을 누르거나, 설정된 사용 시간이 지나면 자동으로 종료 처리.
   - 종료 시간 이후 기기 상태를 "미사용 중"으로 업데이트.

파일 및 역할 설명

Screens

- 각각의 화면에 해당하며, MaterialPageRoute로 네비게이션.

Components

- 대시보드와 기기 상태 화면에서 재사용할 수 있는 UI 컴포넌트
- 팝업, 타이머 등 공통 요소 정의.

Models

- Supabase 데이터베이스 구조를 반영한 데이터 모델.

Services

- QR 스캔, 기기 상태 업데이트, 알림 등 기능 처리.
- Supabase API와 연동.

Providers

- 전역 상태 관리를 통해 데이터 흐름 제어.
