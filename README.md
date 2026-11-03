# 그슨대

한국 귀신을 소재로 한 Godot 횡스크롤 로그라이트 데모입니다. 현재 실행 대상은 `godot/project.godot`입니다. 루트 HTML 파일들은 초기 디자인 시안입니다.

## 실행

Godot 4.7.2에서 `godot/project.godot`을 열고 실행합니다. 기본 창은 640×360입니다. 기존 창의 크기와 위치를 유지해 주세요.

- 이동: A/D 또는 방향키, 점프: Space, 대시: Shift (8방향)
- 공격: J / 마우스 왼쪽, 심장: Q, 주무기/보조무기 스킬: F/G
- 상호작용: E, 가방: Tab/I, 재시작: R, 다음 시드: N
- 장비 실험실: F6, 무기 변경: [ / ], 표적 초기화: T, 두억시니 세트: P, 정지: F9, 표적 AI: Y

시드 기반 방 연결, 상점, 장비 41종(무기 33종 포함), 전투와 1챕터 보스, 영혼조각 자동 획득, 방 클리어 보상을 구현했습니다. 현재 저장 기능은 없으며 일부 아트와 밸런스는 데모 상태입니다.

## 이어서 개발

먼저 [세션 인계](docs/SESSION_HANDOFF.md), [개발 화면 선호](docs/development-preferences.md), [장비 원안](geuseundae_equipment.md)을 읽어 주세요. 현재 구현은 `godot/scripts`와 `docs/equipment-implementation.md`를 기준으로 확인합니다.

모바일 터치 조작과 내보내기 프리셋은 준비 중입니다. APK/iOS 설치 검증은 완료하지 않았으며 사용자의 요청으로 보류했습니다. iOS 프리셋의 Team ID는 비어 있습니다. 모바일 출력물과 Web 빌드는 Git에서 제외합니다.

이펙트 재생성: `node vendor/pixelfx/tools/export-geuseundae.mjs`. 출처와 라이선스는 [THIRD_PARTY.md](THIRD_PARTY.md)를 참고하세요.
